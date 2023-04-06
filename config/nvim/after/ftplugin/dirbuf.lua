-- REF: https://github.com/elihunter173/dirbuf.nvim/issues/8
vim.bo.bufhidden = "wipe"
vim.wo.signcolumn = "no"
vim.opt_local.listchars:remove("tab:>·")
vim.opt_local.listchars:append("tab:  ")

-- easy quit
vim.cmd([[nnoremap <buffer> q :q<CR>]])
-- go-to parent dir
vim.cmd([[nmap <buffer> - <Plug>(dirbuf_up)]])
-- go-to parent dirup a dir
vim.cmd([[nmap <buffer> <BS> <Plug>(dirbuf_up)]])
-- acts like toggle-off
vim.cmd([[nmap <buffer> <leader>ed :q<CR>]])

nnoremap("<C-v>", function() require("dirbuf").enter("vsplit") end, "dirbuf: open in vsplit")
nnoremap("<C-s>", function() require("dirbuf").enter("vsplit") end, "dirbuf: open in split")
nnoremap("<C-t>", function() require("dirbuf").enter("tabedit") end, "dirbuf: open in tab")

-- vim.api.nvim_win_set_width(0, 60)
