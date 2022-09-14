-- [ speed ] -------------------------------------------------------------------

vim.api.nvim_create_augroup("vimrc", {})

-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  mappings = true,
  autocmds = true,
  megaline = false,
  treesitter = false, -- presently loading via packer config
  lsp = true,
  term = true,
  cursorline = true,
  colorcolumn = true,
  numbers = true,
  quickfix = true,
  simplef = true,
  folds = true,
  tmux = true,
  env = false,
}

vim.g.use_packer = true
vim.g.use_term_plugin = true
vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "

-- [ globals ] -----------------------------------------------------------------

local ns = {
  fn = {},
  dirs = {},
  mappings = {},
  term = {},
  lsp = {},
  colors = require("mega.lush_theme.colors"),
  icons = require("mega.icons"),
}

_G.mega = mega or ns

-- [ loaders ] -----------------------------------------------------------------

local reload_ok, reload = pcall(require, "plenary.reload")
RELOAD = reload_ok and reload.reload_module or function(...) return ... end
function R(name)
  RELOAD(name)
  return require(name)
end

R("mega.globals")
R("mega.options")

if vim.g.use_packer then
  -- vim.defer_fn(function() R("mega.plugins.packer") end, 0)
  R("mega.plugins.packer")
else
  R("mega.plugins").config()
end

R("mega.megaline")
