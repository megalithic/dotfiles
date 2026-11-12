-- Neovim side of snap.lua: replays the pane capture into a terminal buffer and
-- runs the requested mode. Started with -u NONE and NVIM_APPNAME=rex-snap.
-- Focus restore and cleanup adapted from CJNE/rex-copy-mode (MIT, see LICENSE).
local root = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)")
local common = dofile(root .. "common.lua")
local dir = vim.g.rex_snap_dir
local pane = vim.g.rex_snap_pane or 1
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
  -- Default colors, so the pane's own background shows through.
  vim.api.nvim_set_hl(0, "Normal", {})
  o.clipboard = "unnamedplus"
  o.laststatus, o.cmdheight, o.showtabline = 0, 0, 0
  o.showmode, o.showcmd, o.ruler = false, false, false
  o.number, o.relativenumber, o.signcolumn, o.foldcolumn = false, false, "no", "0"
  o.scrollback = 100000
  o.swapfile, o.shadafile = false, "NONE"
end

-- The overlay closes at once, so leave the reason in ~/.local/state/rex-snap.
local function fail(err)
  vim.fn.mkdir(vim.fn.stdpath("state"), "p")
  local file = io.open(vim.fn.stdpath("state") .. "/error.log", "a")
  if file then file:write(os.date("%H:%M:%S ") .. tostring(err) .. "\n") file:close() end
  vim.cmd("cquit 1")
end

local function start()
  assert(meta.mode, "cannot read meta.json")
  local snapshot = common.sanitize_vt(read(dir .. "/capture." .. pane .. ".vt"))
  if meta.mode == "hints" then
    -- Keep the screen only, as buffer lines 2 to rows + 1. Autowrap off below
    -- loses a row's last cell, so hints read the captured rows instead.
    snapshot = table.concat(common.screen(snapshot, meta.rows), "\n")
  end
  -- Rows exactly as the pane has them. Autowrap off: a float at the window's
  -- right edge is a column narrower than the pane, and a wrapped row would
  -- shift every row below it. The blank first line fills the float's title
  -- bar row when there is no scrollback above the screen.
  snapshot = "\27[?7l\n" .. snapshot
  local last = 1 -- buffer line of the screen's last row
  for _ in snapshot:gmatch("\n") do last = last + 1 end
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
    -- A float that couldn't be lifted over the title bar (top or zoomed pane)
    -- ends a row above the pane, so its last row is the pane's next to last.
    local bottom = meta.lifted and last or last - 1
    vim.api.nvim_win_set_cursor(0, { bottom, 0 })
    vim.cmd("normal! zb")
    vim.api.nvim_win_set_cursor(0, { math.max(1, vim.fn.prevnonblank(bottom)), 0 })
    local ok, err = pcall(mode.start, buf, meta)
    if not ok then fail(err) end
  end, 50)
end

local function run()
  local ok, err = pcall(start)
  if not ok then fail(err) end
end

-- The terminal buffer takes the window's width when it opens. The layer's pty
-- starts at 80x24 and gets the float's size later, so feed the capture once
-- the UI is in and at least as wide as the pane minus the float's one column.
-- Give up waiting after a second, for a float narrower than that.
pcall(function() meta = vim.json.decode(read(dir .. "/meta." .. pane .. ".json")) end)
local want = (meta.cols or 1) - 1
local started = false
local function launch()
  if started then return true end
  started = true
  vim.schedule(run)
  return true
end
local function sized()
  if #vim.api.nvim_list_uis() > 0 and vim.o.columns >= want then return launch() end
end
if not sized() then
  vim.api.nvim_create_autocmd({ "UIEnter", "VimResized" }, { callback = sized })
  vim.defer_fn(launch, 1000)
end
