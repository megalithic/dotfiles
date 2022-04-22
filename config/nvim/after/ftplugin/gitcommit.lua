vim.wo.colorcolumn = "50,72"
vim.opt.colorcolumn = "50,72"
vim.opt_local.colorcolumn = "50,72"

vim.opt_local.cursorline = false
vim.opt_local.textwidth = 72
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"
vim.opt_local.list = false
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.foldenable = false
vim.opt_local.signcolumn = "no"
vim.b.EditorConfig_disable = 1

vim.cmd([[setlocal comments+=fb:*]])
vim.cmd([[setlocal comments+=fb:-]])
vim.cmd([[setlocal comments+=fb:+]])
vim.cmd([[setlocal comments+=b:>]])

vim.cmd([[setlocal formatoptions+=c]])
vim.cmd([[setlocal formatoptions+=q]])

vim.cmd([[setlocal spell]])

vim.cmd([[startinsert]])
vim.bo.formatoptions = vim.bo.formatoptions .. "t"
