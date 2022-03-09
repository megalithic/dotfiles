-- REF: https://github.com/elihunter173/dirbuf.nvim/issues/8
vim.bo.bufhidden = "wipe"

-- easy quit
vim.cmd([[nnoremap <buffer> q :q<CR>]])
-- go up a dir
vim.cmd([[nmap <buffer> - <Plug>(dirbuf_up)]])
-- go up a dir
vim.cmd([[nmap <buffer> <BS> <Plug>(dirbuf_up)]])
-- acts like toggle-off
vim.cmd([[nmap <buffer> <C-t> :q<CR>]])

nnoremap("<C-v>", [[<cmd>lua require('dirbuf').enter('vsplit')<cr>]], "dirbuf: open in vsplit")
