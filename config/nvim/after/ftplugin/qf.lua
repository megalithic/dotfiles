vim.cmd([[
  " Autosize quickfix to match its minimum content
  " https://vim.fandom.com/wiki/Automatically_fitting_a_quickfix_window_height
  function! s:adjust_height(minheight, maxheight)
    exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
  endfunction

  " force quickfix to open beneath all other splits
  wincmd J

  setlocal nonumber
  setlocal norelativenumber
  setlocal nowrap
  setlocal signcolumn=yes
  setlocal colorcolumn=
  setlocal nobuflisted " quickfix buffers should not pop up when doing :bn or :bp
  call s:adjust_height(3, 10)
  setlocal winfixheight

  "--------------------------------------------------------------------------------
  " Helper functions
  "--------------------------------------------------------------------------------
  " nnoremap <silent><buffer>dd :lua as.qf.delete()<CR>
  " vnoremap <silent><buffer>d  :lua as.qf.delete()<CR>

  " Resources and inspiration
  " 2. https://github.com/romainl/vim-qf/blob/2e385e6d157314cb7d0385f8da0e1594a06873c5/autoload/qf.vim#L22
]])

nnoremap("<C-n>", [[:cnext<cr>]], { buffer = 0, label = "QF: next" })
nnoremap("<C-p>", [[:cprevious<cr>]], { buffer = 0, label = "QF: previous" })
