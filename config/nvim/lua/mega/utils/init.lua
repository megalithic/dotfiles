local vcmd, lsp, api, fn, g = vim.cmd, vim.lsp, vim.api, vim.fn, vim.g
local bmap, au = mega.bmap, mega.au
local fmt = string.format
local hl_ok, H = mega.safe_require("mega.utils.highlights", { silent = true })

local M = {
  ext = {
    tmux = {},
    kitty = {},
  },
  lsp = {},
}
local windows = {}

local function fileicon()
  local name = fn.bufname()
  local icon, hl
  local loaded, devicons = mega.load("nvim-web-devicons", { safe = true })
  if loaded then
    icon, hl = devicons.get_icon(name, fn.fnamemodify(name, ":e"), { default = true })
  end
  return icon, hl
end

function M.ext.title_string()
  if not hl_ok then
    return
  end
  local dir = fn.fnamemodify(fn.getcwd(), ":t")
  local icon, hl = fileicon()
  if not hl then
    return (icon or "") .. " "
  end
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
  if not hl_ok then
    return
  end
  local hl = reset and "Normal" or "MsgArea"
  local bg = H.get_hl(hl, "bg")
  -- TODO: we should correctly derive the previous bg value
  fn.jobstart(fmt("tmux set-option -g status-style bg=%s", bg))
end

function M.ext.tmux.set_popup_colorscheme()
  if not hl_ok then
    return
  end
  local bg = H.get_hl("Background", "bg")
end

function M.ext.kitty.set_background()
  if not hl_ok then
    return
  end
  if vim.env.KITTY_LISTEN_ON then
    local bg = H.get_hl("MsgArea", "bg")
    fn.jobstart(fmt("kitty @ --to %s set-colors background=%s", vim.env.KITTY_LISTEN_ON, bg))
  end
end

---Reset the kitty terminal colors
function M.ext.kitty.clear_background()
  if not hl_ok then
    return
  end
  if vim.env.KITTY_LISTEN_ON then
    local bg = mega.colors().Background.bg.hex
    -- local bg = H.get_hl("Normal", "bg")
    -- this is intentionally synchronous so it has time to execute fully
    fn.system(fmt("kitty @ --to %s set-colors background=%s", vim.env.KITTY_LISTEN_ON, bg))
  end
end

function M.t(cmd_str)
  -- return api.nvim_replace_termcodes(cmd, true, true, true) -- TODO: why 3rd param false?
  return api.nvim_replace_termcodes(cmd_str, true, false, true)
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

-- # [ hover ] -----------------------------------------------------------------
function M.lsp.hover()
  if next(lsp.buf_get_clients()) == nil then
    vcmd([[execute printf('h %s', expand('<cword>'))]])
  else
    lsp.buf.hover()
  end
end

-- # [ lsp_commands ] ----------------------------------------------------------------
function M.lsp.elixirls_cmd(opts)
  opts = opts or {}
  local fallback_dir = opts.fallback_dir or vim.env.XDG_DATA_HOME or "~/.local/share"

  local locations = {
    ".bin/elixir_ls.sh",
    ".elixir_ls/release/language_server.sh",
  }

  for _, location in ipairs(locations) do
    local exists, dir = M.root_has_file(location)
    if exists then
      return fn.expand(dir)
    end
  end

  return fn.expand(fmt("%s/lsp/elixir-ls/%s", fallback_dir, "language_server.sh"))
end

return M
