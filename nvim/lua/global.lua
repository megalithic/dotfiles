local M = {}

M.map_opts = {noremap = false, silent = true, expr = false}
M.autocmd = function(cmd) vim.cmd("autocmd " .. cmd) end

M.map = function(mode, lhs, rhs, opts)
    opts = vim.tbl_extend('force', M.map_opts, opts or {})
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

M.new_command = function(s)
	vim.cmd('command! ' .. s)
end

return M
