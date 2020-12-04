let g:gist_open_url = 1
let g:gist_default_private = 1
" Send visual selection to gist.github.com as a private, filetyped Gist
" Requires the gist command line too (brew install gist)
" vnoremap <leader>G :Gist -po<CR>
vnoremap <leader>gG :Gist -po<CR>
