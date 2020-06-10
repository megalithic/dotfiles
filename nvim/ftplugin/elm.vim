autocmd FileType elm nnoremap <leader>ep o\|> <ESC>a

if has('nvim')
  function! s:elm_repl_for_project() abort
    let l:root = finddir('.git/..', expand('%:p:h').';')

    if !empty(glob(l:root .. "/elm.json"))
      echohl Comment | echom printf('elm repl (%s)', l:root) | echohl None
      :Repl elm repl
    else
      echohl Comment | echom printf('elm_repl (%s)', l:root) | echohl None
      :Repl elm_repl
    endif
  endfunction

  autocmd FileType elm nnoremap <silent> <buffer> <leader>er :call <SID>elm_repl_for_project()<CR>
endif

autocmd FileType elm iabbrev ep    \|>
