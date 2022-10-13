-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  mappings = true,
  autocmds = true,
  megaline = true,
  lsp = true,
  term = true,
  cursorline = true,
  colorcolumn = true,
  windows = true,
  numbers = true,
  quickfix = true,
  simplef = false, -- WIP: trialing flit/leap
  folds = true,
  tmux = false,
  env = false,
  winbar = false, -- TODO
}

vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.notifier_enabled = true

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
end)
