" ## test file `.only` add/remove
" TODO: https://github.com/tandrewnichols/dotstar/blob/master/.vim/settings/only.vim

" function! TestNearest()
"   mo/it(<CR><S-N>ea.only<Esc>`o:delmarks o<CR>
"   TestFile
"   %s/\.only//g<CR>`o:delmarks o<CR>
" endfunction
" nmap <silent> tn<C-d> :call TestNearest()<CR>

" Top-only: Add .only to top-most describe
nnoremap <silent> <leader>tto moG/describe<CR>ea.only<Esc>`o:delmarks o<CR>

" Describe-only: Add .only to nearest describe
nnoremap <silent> <leader>tdo mo/describe<CR><S-N>ea.only<Esc>`o:delmarks o<CR>

" Context-only: Add .only to nearest context
nnoremap <silent> <leader>tco mo/context<CR><S-N>ea.only<Esc>`o:delmarks o<CR>

" It-only: Add .only to nearest it
nnoremap <silent> <leader>tio mo/it(<CR><S-N>ea.only<Esc>`o:delmarks o<CR>
nnoremap <silent> <leader>tn mo/it(<CR><S-N>ea.only<Esc>`o:delmarks o<CR>:TestNearest<CR>

" nnoremap <silent> <leader>tio <Esc>/^\s*it(<cr>N0f(i.only<Esc>
" nnoremap <silent> <leader>tco <Esc>/^\s*context(<cr>N0f(c.only<Esc>
" nnoremap <silent> <leader>tco <Esc>/^\s*describe(<cr>N0f(d.only<Esc>

" Remove-only: Remove all occurrences of .only
nnoremap <silent> <leader>tro mo:%s/\.only//g<CR>`o:delmarks o<CR>


" https://github.com/janko/vim-test/issues/136 -- modified for my work needs
function! JavaScriptTransform(cmd) abort
  echo "JS cmd -> " .. a:cmd

  if match(a:cmd, 'integration_tests/') != -1
    echo "match integration_tests/ -> " .. substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color ', '')
    return substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color ', '')
  else
    return a:cmd
  end

  return a:cmd
endfunction

" NOTE: disabled for now; these transforms not needed when using mattn/find-root
" let g:test#custom_transformations = {'javascript': function('JavaScriptTransform')}
" let g:test#transformation = 'javascript'
