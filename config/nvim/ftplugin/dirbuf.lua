-- REF: https://github.com/elihunter173/dirbuf.nvim/issues/8
vim.bo.bufhidden = "wipe"

-- easy quit
vim.cmd([[nnoremap <buffer> q :q<CR>]])
vim.cmd([[nmap <buffer> - <Plug>(dirbuf_up)]])
vim.cmd([[nmap <buffer> <BS> <Plug>(dirbuf_up)]])
vim.cmd([[nmap <buffer> <C-t> <Nop>]])
