vim.opt.cursorline = false -- Show a line where the current cursor is
vim.opt.textwidth = 72
vim.opt.colorcolumn = "50,72"
vim.opt.spell = true
vim.opt.spelllang = "en_us"
vim.opt.list = false
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.foldenable = false
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

-- set specific sources for nvim-cmp for specific filetype
-- require("cmp").setup.buffer({ enabled = false })
require("cmp").setup.buffer({
  sources = {
    require("mega.plugins.cmp").sources.buffer,
    { name = "spell" },
    { name = "emoji" },
  },
})
