-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  mappings = true,
  autocmds = true,
  megaline = true,
  lsp = true,
  term = true,
  repls = true,
  cursorline = true,
  colorcolumn = true,
  windows = true,
  numbers = true,
  quickfix = true,
  folds = true,
  env = true,
  vscode = false,
  tmux = false,
  winbar = false, -- FIXME: add more!
}

-- disable certain plugins for firenvim
for plugin, _ in pairs(vim.g.enabled_plugin) do
  if not vim.tbl_contains({ "autocmds", "mappings", "quickfix" }, plugin) and vim.g.started_by_firenvim then
    plugin = false
  end
end

vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.notifier_enabled = true
vim.g.debug_enabled = false

-- [ globals ] -----------------------------------------------------------------

_G.mega = mega
  or {
    fn = {},
    dirs = {},
    mappings = {},
    term = {},
    lsp = {},
    colors = require("mega.lush_theme.colors"),
    icons = require("mega.icons"),
    -- original vim.notify: REF: https://github.com/folke/dot/commit/b0f6a2db608cb090b969e2ef5c018b86d11fc4d6
    notify = vim.notify,
  }

-- [ loaders ] -----------------------------------------------------------------

local reload_ok, reload = pcall(require, "plenary.reload")
RELOAD = reload_ok and reload.reload_module or function(...) return ... end
function R(name)
  RELOAD(name)
  return require(name)
end

R("mega.globals")
R("mega.options")
vim.schedule(function()
  mega.packer_deferred()
  R("mega.plugins")

  -- loads a local .nvimrc for our current working directory
  -- local local_vimrc = vim.fn.getcwd() .. "/.nvimrc"
  -- if vim.loop.fs_stat(local_vimrc) then
  --   if vim.bo.filetype == "lua" then
  --     vim.cmd.luafile(local_vimrc)
  --   elseif vim.bo.filetype == "vim" then
  --     vim.cmd.source(local_vimrc)
  --   end

  --   vim.notify(fmt("Read **%s**", local_vimrc), vim.log.levels.INFO, {
  --     title = "Nvim (.nvimrc)",
  --   })
  -- end
end)
