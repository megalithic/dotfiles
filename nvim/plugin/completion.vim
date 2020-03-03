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
