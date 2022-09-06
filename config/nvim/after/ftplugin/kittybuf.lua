vim.cmd([[
  setlocal nonumber
  setlocal norelativenumber
  setlocal nowrap
  setlocal nolist
  setlocal showtabline=0
  setlocal foldcolumn=0
  setlocal signcolumn=no
  setlocal colorcolumn=
  setlocal nobuflisted " quickfix buffers should not pop up when doing :bn or :bp
  " setlocal modifiable=off
  setlocal bufhidden=wipe
  autocmd VimEnter * normal G
]])

nnoremap("q", [[:q!<cr>]], { buffer = 0, label = "quit kittybuf" })
nnoremap(",q", [[:q!<cr>]], { buffer = 0, label = "quit kittybuf" })
