-- [ speed ] -------------------------------------------------------------------

vim.api.nvim_create_augroup("vimrc", {})
local impatient_ok, impatient = pcall(require, "impatient")
if impatient_ok then impatient.enable_profile() end

-- [ settings ] ----------------------------------------------------------------

vim.g.disable_plugins = {
  autocmds = false,
  megaline = false,
  quickfix = false,
  env = false,
  lsp = false,
  treesitter = false,
  mappings = false,
  cursorline = false,
  colorcolumn = false,
  numbers = false,
  folds = false,
  term = false,
  tmux = false,
}

vim.g.use_packer = false
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
