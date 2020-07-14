function! s:ArgForVerticalEdit() abort
  vertical argument
  execute "normal! \<c-w>="
  silent :ColorizerAttachToBuffer
  update
endfunction
command! ArgForVerticalEdit call <sid>ArgForVerticalEdit()

function! s:ArgNext() abort
  update
  argdelete %
  bdelete
  if !empty(argv())
    argument
  endif
endfunction
command! ArgNext call <sid>ArgNext()
command! NextArg call <sid>ArgNext()
