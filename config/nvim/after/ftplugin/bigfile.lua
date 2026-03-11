local buf = vim.api.nvim_get_current_buf()

vim.schedule(function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end)

vim.b.ts_highlight = false
if vim.treesitter.highlighter.active[buf] then vim.treesitter.stop(buf) end

vim.opt_local.syntax = "off"

vim.b.completion = false

vim.b.minipairs_disable = true
vim.b.miniindentscope_disable = true
vim.b.minidiff_disable = true

vim.opt_local.swapfile = false
vim.opt_local.foldmethod = "manual"
vim.opt_local.foldenable = false
vim.opt_local.foldcolumn = "0"
vim.opt_local.undolevels = -1
vim.opt_local.undoreload = 0
vim.opt_local.list = false
vim.opt_local.spell = false
vim.opt_local.cursorline = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
