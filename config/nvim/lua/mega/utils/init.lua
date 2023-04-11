local vcmd, lsp, fn = vim.cmd, vim.lsp, vim.fn
local fmt = string.format
local hl_ok, H = mega.require("mega.utils.highlights", { silent = true })

local M = {
  ext = {
    tmux = {},
    kitty = {},
    wezterm = {},
  },
  lsp = {},
  hl = {},
}
local function fileicon()
  local name = fn.bufname()
  local icon, hl
  local loaded, devicons = mega.require("nvim-web-devicons")
  if loaded then
    icon, hl = devicons.get_icon(name, fn.fnamemodify(name, ":e"), { default = true })
  end
  return icon, hl
end

function M.format_markdown(contents)
  if type(contents) ~= "table" or not vim.tbl_islist(contents) then contents = { contents } end

  local parts = {}

  for _, content in ipairs(contents) do
    if type(content) == "string" then
      table.insert(parts, ("```\n%s\n```"):format(content))
    elseif content.language then
      table.insert(parts, ("```%s\n%s\n```"):format(content.language, content.value))
    elseif content.kind == "markdown" then
      table.insert(parts, content.value)
    elseif content.kind == "plaintext" then
      table.insert(parts, ("```\n%s\n```"):format(content.value))
    end
  end

  return vim.split(table.concat(parts, "\n"), "\n")
end

function M.ext.title_string()
  if not hl_ok then return end
  local dir = fn.fnamemodify(fn.getcwd(), ":t")
  local icon, hl = fileicon()
  if not hl then return (icon or "") .. " " end
  -- return fmt("%s %s ", dir, icon)
  local has_tmux = vim.env.TMUX ~= nil
  return has_tmux and fmt("%s %s ", dir, icon) or dir .. " " .. icon
  -- return has_tmux and fmt("%s #[fg=%s]%s ", dir, mega.colors().Normal.fg.hex, icon) or dir .. " " .. icon
  -- return has_tmux and fmt("%s #[fg=%s]%s ", dir, H.get_hl(hl, "fg"), icon) or dir .. " " .. icon
  -- return fmt("%s #[fg=%s]%s ", dir, H.get_hl(hl, "fg"), icon)
end

--- Get the color of the current vim background and update tmux accordingly
---@param reset boolean?
function M.ext.tmux.set_statusline(reset)
  if not hl_ok then return end
  local hl = reset and "Normal" or "MsgArea"
  local bg = H.get_hl(hl, "bg")
  -- TODO: we should correctly derive the previous bg value
  fn.jobstart(fmt("tmux set-option -g status-style bg=%s", bg))
end

--- Displays a message in the tmux status-line
---@param msg string?
function M.ext.tmux.display_message(msg)
  if not msg then return end
  fn.jobstart(fmt("tmux display-message '%s'", msg))
end

function M.ext.tmux.set_popup_colorscheme()
  if not hl_ok then return end
  local bg = H.get_hl("Background", "bg")
end

function M.ext.kitty.set_background()
  if not hl_ok then return end
  if vim.env.KITTY_LISTEN_ON then
    local bg = H.get_hl("MsgArea", "bg")
    fn.jobstart(fmt("kitty @ --to %s set-colors background=%s", vim.env.KITTY_LISTEN_ON, bg))
  end
end

---Reset the kitty terminal colors
function M.ext.kitty.clear_background()
  if not hl_ok then return end
  if vim.env.KITTY_LISTEN_ON then
    local bg = require("mega.lush_theme.colors").bg0
    -- local bg = H.get_hl("Normal", "bg")
    -- this is intentionally synchronous so it has time to execute fully
    fn.system(fmt("kitty @ --to %s set-colors background=%s", vim.env.KITTY_LISTEN_ON, bg))
  end
end

-- REF:
-- https://www.reddit.com/r/neovim/comments/xn1q75/comment/iprdrpr
-- https://github.com/folke/zen-mode.nvim/pull/61
-- https://github.com/wez/wezterm/discussions/3211
-- https://github.com/wez/wezterm/issues/2979#issuecomment-1447519267
function M.ext.wezterm.toggle_screen_share_mode(enabled)
  local mode = enabled and "on" or "off"
  -- fn.jobstart(fmt("wezterm-cli SCREEN_SHARE_MODE %s", mode))

  local stdout = vim.loop.new_tty(1, false)
  if vim.env.TMUX then
    -- just wezterm: \033]1337;SetUserVar=%s=%s\007
    -- from zen-mode example: \x1b]1337;SetUserVar=%s=%s\b
    -- \033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\
    stdout:write(
      ("\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\b"):format(
        "SCREEN_SHARE_MODE",
        vim.fn.system({ "base64" }, tostring(mode))
      )
    )
    dd("doing a thing with stdout in tmux")
    -- stdout:write(('\x1b]1337;SetUserVar=%s=%s\b'):format('SCREEN_SHARE_MODE', vim.fn.system({ 'base64' }, tostring(enabled))))
    -- else
    --   stdout:write(
    --     ("\x1b]1337;SetUserVar=%s=%s\b"):format("SCREEN_SHARE_MODE", vim.fn.system({ "base64" }, tostring(mode)))
    --   )
  end
  -- vim.cmd([[redraw]])
end

function M.check_back_space()
  local col = fn.col(".") - 1
  return col == 0 or fn.getline("."):sub(col, col):match("%s") ~= nil
end

function M.root_has_file(name)
  local cwd = vim.loop.cwd()
  local lsputil = require("lspconfig.util")
  return lsputil.path.exists(lsputil.path.join(cwd, name)), lsputil.path.join(cwd, name)
end

-- # [ lsp_commands ] ----------------------------------------------------------------
local lsputil = require("lspconfig.util")

local function dir_has_file(dir, name)
  return lsputil.path.exists(lsputil.path.join(dir, name)), lsputil.path.join(dir, name)
end

local function workspace_root()
  local cwd = vim.loop.cwd()

  if dir_has_file(cwd, "compose.yml") or dir_has_file(cwd, "docker-compose.yml") then return cwd end

  local function cb(dir, _) return dir_has_file(dir, "compose.yml") or dir_has_file(dir, "docker-compose.yml") end

  local root, _ = lsputil.path.traverse_parents(cwd, cb)
  return root
end

--- Build the language server command.
-- @param opts options
-- @param opts.locations table Locations to search relative to the workspace root
-- @param opts.fallback_dir string Path to use if locations don't contain the binary
-- @return a string containing the command
local function language_server_cmd(opts)
  opts = opts or {}
  local fallback_dir = opts.fallback_dir
  local locations = opts.locations or {}
  local cmd = vim.fn.expand(fallback_dir)

  local root = workspace_root()
  if not root then root = vim.loop.cwd() end
  -- P(fmt("root: %s", root))

  for _, location in ipairs(locations) do
    local exists, dir = dir_has_file(root, location)
    if exists then
      -- logger.fmt_debug("language_server_cmd: %s", vim.fn.expand(dir))
      cmd = vim.fn.expand(dir)
    end
  end

  -- P(fmt("cmd: %s", cmd))
  return cmd
end

--- Build the elixir-ls command.
-- @param opts options
-- @param opts.fallback_dir string Path to use if locations don't contain the binary
-- @param opts.debugger boolean Whether this is a debug elixirls_cmd binary or not
function M.lsp.elixirls_cmd(opts)
  opts = opts or {}

  local cmd = "language_server.sh"
  local debugger = opts["debugger"] or false

  if debugger then cmd = "debugger.sh" end

  opts = vim.tbl_deep_extend("force", opts, {
    locations = {
      ".elixir-ls-release/" .. cmd,
      ".elixir_ls/release/" .. cmd,
    },
  })

  opts.fallback_dir = string.format("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, cmd)

  -- P(fmt("opts: %s", I(opts)))

  return language_server_cmd(opts)
end

function M.get_open_filelist(cwd)
  local Path = require("plenary.path")
  -- local flatten = vim.tbl_flatten
  local filter = vim.tbl_filter

  cwd = cwd or vim.loop.cwd()

  local bufnrs = filter(function(b)
    if 1 ~= vim.fn.buflisted(b) then return false end
    return true
  end, vim.api.nvim_list_bufs())
  if not next(bufnrs) then return end

  local filelist = {}
  for _, bufnr in ipairs(bufnrs) do
    local file = vim.api.nvim_buf_get_name(bufnr)
    table.insert(filelist, Path:new(file):make_relative(cwd))
  end
  return filelist
end

function M.hl.get(name)
  local ok, data = pcall(vim.api.nvim_get_hl_by_name, name, true)

  if not ok then
    vim.notify(fmt("Failed to find highlight by name \"%s\"", name), vim.log.levels.ERROR, { title = "nvim" })
    return {}
  end

  return data
end

function M.hl.set(group, color)
  local ok, msg = pcall(vim.api.nvim_set_hl, 0, group, color)

  if not ok then
    vim.notify(
      fmt("Failed to set highlight (%s): group %s | color: %s", msg, group, I(color)),
      vim.log.levels.ERROR,
      { title = "nvim" }
    )
  end
end

function M.hl.extend(target, source, opts) M.hl.set(target, vim.tbl_extend("force", M.hl.get(source), opts or {})) end

local function tbl_length(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

-- https://github.com/ibhagwan/fzf-lua/blob/455744b9b2d2cce50350647253a69c7bed86b25f/lua/fzf-lua/utils.lua#L401
function M.get_visual_selection()
  -- this will exit visual mode
  -- use 'gv' to reselect the text
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    -- if we are in visual mode use the live position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      -- visual line doesn't provide columns
      cscol, cecol = 0, 999
    end
    -- exit visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  else
    -- otherwise, use the last known visual position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  -- swap vars if needed
  if cerow < csrow then
    csrow, cerow = cerow, csrow
  end
  if cecol < cscol then
    cscol, cecol = cecol, cscol
  end
  local lines = vim.fn.getline(csrow, cerow)
  -- local n = cerow-csrow+1
  local n = tbl_length(lines)
  if n <= 0 then return "" end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, "\n")
end
-- OR --------------------------------------------------------------------------
-- REF: https://github.com/fdschmidt93/dotfiles/blob/master/nvim/.config/nvim/lua/fds/utils/init.lua
function M.get_selection()
  local rv = vim.fn.getreg("v")
  local rt = vim.fn.getregtype("v")
  vim.cmd([[noautocmd silent normal! "vy]])
  local selection = vim.fn.getreg("v")
  vim.fn.setreg("v", rv, rt)
  return vim.split(selection, "\n")
end

---@return string
function M.get_root()
  local path = vim.loop.fs_realpath(vim.api.nvim_buf_get_name(0))
  ---@type string[]
  local roots = {}
  if path ~= "" then
    for _, client in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
      local workspace = client.config.workspace_folders
      local paths = workspace and vim.tbl_map(function(ws) return vim.uri_to_fname(ws.uri) end, workspace)
        or client.config.root_dir and { client.config.root_dir }
        or {}
      for _, p in ipairs(paths) do
        local r = vim.loop.fs_realpath(p)
        if path:find(r, 1, true) then roots[#roots + 1] = r end
      end
    end
  end
  ---@type string?
  local root = roots[1]
  if not root then
    path = path == "" and vim.loop.cwd() or vim.fs.dirname(path)
    ---@type string?
    root = vim.fs.find({ ".git" }, { path = path, upward = true })[1]
    root = root and vim.fs.dirname(root) or vim.loop.cwd()
  end
  ---@cast root string
  return root
end

return M
