-- vim.wo.colorcolumn = "50,72"
-- vim.opt.colorcolumn = "50,72"
-- vim.opt_local.colorcolumn = "50,72"
--
-- vim.opt_local.cursorline = false
-- vim.opt_local.textwidth = 72
-- vim.opt_local.spell = true
-- vim.opt_local.spelllang = "en_us"
-- vim.opt_local.list = false
-- vim.opt_local.number = false
-- vim.opt_local.relativenumber = false
-- vim.opt_local.wrap = true
-- vim.opt_local.linebreak = true
-- vim.opt_local.foldenable = false
-- vim.opt_local.signcolumn = "no"
-- vim.b.EditorConfig_disable = 1
--
-- vim.cmd([[setlocal comments+=fb:*]])
-- vim.cmd([[setlocal comments+=fb:-]])
-- vim.cmd([[setlocal comments+=fb:+]])
-- vim.cmd([[setlocal comments+=b:>]])
--
-- vim.cmd([[setlocal formatoptions+=c]])
-- vim.cmd([[setlocal formatoptions+=q]])
--
-- vim.cmd([[setlocal spell]])
--
-- vim.cmd("set bufhidden=delete")
-- vim.cmd([[exec 'norm gg']])
-- if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then vim.cmd([[startinsert]]) end
--
-- vim.bo.formatoptions = vim.bo.formatoptions .. "t"
--
local opt = vim.opt_local

opt.list = false
opt.number = false
opt.relativenumber = false
opt.cursorline = false
opt.list = false
opt.spell = true
opt.spelllang = "en_gb"
opt.colorcolumn = "50,72"

vim.fn.matchaddpos("DiagnosticVirtualTextError", { { 1, 50, 10000 } })

vim.cmd([[exec 'norm gg']])
if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then vim.cmd([[startinsert]]) end

mega.iabbrev("cabag", "Co-authored-by: Aaron Gunderson <aaron@ternit.com>")
mega.iabbrev("cabdt", "Co-authored-by: Dan Thiffault <dan@ternit.com>")
mega.iabbrev("cabjm", "Co-authored-by: Jia Mu <jia@ternit.com>")
mega.iabbrev("cabam", "Co-authored-by: Ali Marsh<ali@ternit.com>")
mega.iabbrev("cbag", "Co-authored-by: Aaron Gunderson <aaron@ternit.com>")
mega.iabbrev("cbdt", "Co-authored-by: Dan Thiffault <dan@ternit.com>")
mega.iabbrev("cbjm", "Co-authored-by: Jia Mu <jia@ternit.com>")
mega.iabbrev("cbam", "Co-authored-by: Ali Marsh<ali@ternit.com>")

-- REF: https://github.com/arsham/shark/blob/master/after/ftplugin/gitcommit.lua
