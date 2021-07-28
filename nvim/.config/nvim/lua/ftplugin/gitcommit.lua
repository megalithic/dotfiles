return function(_) -- bufnr
  -- vim.cmd([[normal gg0]])

  vim.bo.textwidth = 72
  vim.wo.colorcolumn = "72"
  vim.wo.spell = true
  vim.bo.spelllang = "en_us"
  vim.wo.list = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.foldenable = false

  vim.cmd([[setlocal comments+=fb:*]])
  vim.cmd([[setlocal comments+=fb:-]])
  vim.cmd([[setlocal comments+=fb:+]])
  vim.cmd([[setlocal comments+=b:>]])

  vim.cmd([[setlocal formatoptions+=c]])
  vim.cmd([[setlocal formatoptions+=q]])

  vim.cmd([[setlocal spell]])

  vim.bo.formatoptions = vim.bo.formatoptions .. "t"
end
