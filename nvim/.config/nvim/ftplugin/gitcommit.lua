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