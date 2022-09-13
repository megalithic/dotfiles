-- [ speed ] -------------------------------------------------------------------

vim.api.nvim_create_augroup("vimrc", {})
require("impatient")

-- [ settings ] ----------------------------------------------------------------

vim.g.disable_plugins = {
  mappings = false,
  autocmds = false,
  megaline = false,
  treesitter = false,
  lsp = false,
  term = false,
  cursorline = false,
  colorcolumn = false,
  numbers = false,
  quickfix = false,
  folds = false,
  tmux = false,
  env = true,
}

vim.g.use_packer = true
vim.g.use_term_plugin = true
vim.g.colorscheme = "megaforest"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.default_colorcolumn = "81"

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
  R("mega.plugins.packer")
else
  R("mega.plugins").config()
end
