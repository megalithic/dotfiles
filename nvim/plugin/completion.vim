" ## asyncomplete

" let g:asyncomplete_auto_popup = 1

" inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"

" " autocmd CursorHold * lua vim.lsp.util.show_line_diagnostics()
" " autocmd CursorMoved * lua vim.lsp.util.show_line_diagnostics()

" autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
"       \   'name': 'omni',
"       \   'whitelist': ['python', 'c', 'cpp', 'rust', 'vim', 'lua', 'elm', 'elixir', 'eelixir'],
"       \   'completor': function('asyncomplete#sources#omni#completor'),
"       \ }))

" set completeopt=menuone,noinsert,noselect
"
" important: :help Ncm2PopupOpen for more information
set completeopt=menuone,noinsert,noselect
" limit completion popup size
set pumheight=20
" suppress the annoying 'match x of y', 'The only match' and 'Pattern not found' messages
set shortmess+=c

let g:ncm2#matcher = 'substrfuzzy'

" When the <Enter> key is pressed while the popup menu is visible, it only
" hides the menu. Use this mapping to close the menu and also start a new line.
" inoremap <expr> <CR> (pumvisible() ? "\<C-y>\<CR>" : "\<CR>")

" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

inoremap <silent> <C-Space> <C-r>=ncm2#manual_trigger()<CR>

augroup _ncm2
  autocmd!
  " autocmd BufEnter * call ncm2#enable_for_buffer()
augroup END
