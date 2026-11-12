-- Neovim side of snap.lua: replays the pane capture into a terminal buffer and
-- runs the requested mode. Started with -u NONE and NVIM_APPNAME=rex-snap.
-- Focus restore and cleanup adapted from CJNE/rex-copy-mode (MIT, see LICENSE).
local root = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)")
local common = dofile(root .. "common.lua")
local dir = vim.g.rex_snap_dir
local stat = vim.uv.fs_lstat(dir)
assert(dir:match("/rex%-snap%-%w+$") and stat and stat.type == "directory" and stat.uid == vim.uv.getuid(),
  "not an owned rex-snap temp dir")
local meta = {}

local function rex_cli(args)
  local result = vim.system(vim.list_extend({ meta.rex }, args), { text = true, timeout = 2000 }):wait()
  if result.code ~= 0 then error("rex " .. args[1] .. " failed", 0) end
  return result.stdout
end

-- Give focus back to the source pane, unless the user already moved away.
local function restore_focus()
  if not meta.session then return end
  local own = vim.env.REX_BLOCK or vim.json.decode(rex_cli({ "whoami", "--json" })).block_id
  local current = vim.json.decode(rex_cli({ "session", "inspect", meta.session, "--json" }))
  if current.active_window_id ~= meta.source_window then return end
  for _, window in ipairs(current.windows or {}) do
    if window.window_id == meta.source_window and window.focused_block_id == own then
      rex_cli({ "focus", "-s", meta.session, meta.source_block })
      if meta.source_zoomed then rex_cli({ "zoom", "-s", meta.session, meta.source_block, "--on" }) end
    end
  end
end

-- Installed before reading anything, so startup errors also clean up.
vim.api.nvim_create_autocmd("VimLeavePre", {
  once = true,
  callback = function()
    pcall(restore_focus)
    vim.fn.delete(dir, "rf")
  end,
})

local function read(path)
  local file = assert(io.open(path, "rb"))
  local data = file:read("*a")
  file:close()
  return data
end

local function options()
  local o = vim.opt
  o.termguicolors = true
  o.clipboard = "unnamedplus"
  o.laststatus, o.cmdheight, o.showtabline = 0, 0, 0
  o.showmode, o.showcmd, o.ruler = false, false, false
  o.number, o.relativenumber, o.signcolumn, o.foldcolumn = false, false, "no", "0"
  o.scrollback = 100000
  o.swapfile, o.shadafile = false, "NONE"
end

local function start()
  meta = vim.json.decode(read(dir .. "/meta.json"))
  local snapshot = common.sanitize_vt(read(dir .. "/capture.vt"))
  options()

  local buf = vim.api.nvim_get_current_buf()
  local chan = vim.api.nvim_open_term(buf, { force_crlf = true, on_input = function() end })
  assert(chan ~= 0, "could not open the internal terminal")
  vim.bo[buf].bufhidden = "wipe"
  for offset = 1, #snapshot, 65536 do
    vim.api.nvim_chan_send(chan, snapshot:sub(offset, offset + 65535))
  end
  vim.cmd.stopinsert()

  local mode = dofile(root .. meta.mode .. ".lua")
  -- The terminal flushes scrollback on Neovim's refresh timer.
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.cmd.stopinsert()
    vim.api.nvim_win_set_cursor(0, { math.max(1, vim.fn.prevnonblank("$")), 0 })
    vim.cmd("normal! zb")
    mode.start(buf, meta)
  end, 50)
end

local function run()
  local ok, err = pcall(start)
  if not ok then
    -- The overlay closes at once, so leave the reason in ~/.local/state/rex-snap.
    vim.fn.mkdir(vim.fn.stdpath("state"), "p")
    local file = io.open(vim.fn.stdpath("state") .. "/error.log", "a")
    if file then file:write(os.date("%H:%M:%S ") .. tostring(err) .. "\n") file:close() end
    vim.cmd("cquit 1")
  end
end

-- The terminal buffer takes the window's width when it opens, and -c runs
-- before the TUI reports its size. Feed the capture once the UI is in.
if #vim.api.nvim_list_uis() > 0 then
  run()
else
  vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = function() vim.schedule(run) end })
end
