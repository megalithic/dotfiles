" ====================================
" Vista.vim
" ====================================

" use coc as backend
let g:vista_default_executive = 'coc'

let g:vista_finder_alternative_executives = ['ctags']

" enable fzf preview
let g:vista_fzf_preview = ['right:50%']

" enable icons (must have patched fonts)
let g:vista#renderer#enable_icon = 1

" enable nicer indentation using patched fonts
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]

" how long before scrolling / floating the definition
let g:vista_cursor_delay = 200

" how to show the definition
let g:vista_echo_cursor_strategy = 'floating_win'

" update symbol list when text changed (really it should be on file saved or
" different file opened)
let g:vista_update_on_text_changed = 1

" mappings
nnoremap <leader>vv :Vista!<CR>
nnoremap <leader>vf :Vista finder<CR>
