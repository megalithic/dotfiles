let g:NERDTreeDirArrowExpandable  = "▷"
let g:NERDTreeDirArrowCollapsible = "◢"
let NERDTreeHijackNetrw           = 0
let NERDTreeStatusline            = " NERDTree "

noremap <silent> <Leader>n :NERDTreeToggle<CR> <C-w>=
noremap <silent> <Leader>f :NERDTreeFind<CR>   <C-w>=

" Upon entering the NERDTree window do a root directoy refresh to automatically
" pick up any file or directory changes.
"
function! s:NERDTreeRefresh()
    if &filetype == "nerdtree"
        silent exe substitute(mapcheck("R"), "<CR>", "", "")
    endif
endfunction

augroup PersonalNERDTreeAutocmds
    autocmd!
    autocmd BufEnter * call s:NERDTreeRefresh()
augroup END
