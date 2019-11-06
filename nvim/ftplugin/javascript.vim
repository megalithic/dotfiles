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
