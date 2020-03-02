" inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"
" let g:asyncomplete_auto_popup = 1
" " lua << EOF
" " do
" " local default_callback = vim.lsp.callbacks["textDocument/publishDiagnostics"]
" " local err, method, params, client_id

" " vim.lsp.callbacks["textDocument/publishDiagnostics"] = function(...)
" " err, method, params, client_id = ...
" " if vim.api.nvim_get_mode().mode ~= "i" and vim.api.nvim_get_mode().mode ~= "ic" then
" " publish_diagnostics()
" " end
" " end

" " function publish_diagnostics()
" " default_callback(err, method, params, client_id)
" " end
" " end

" " local on_attach = function(_, bufnr)
" " vim.api.nvim_command [[autocmd InsertLeave,BufEnter <buffer> lua publish_diagnostics()]]
" " end
" " EOF

" lua require'nvim_lsp'.ccls.setup{on_attach=require'diagnostic'.on_attach}
" au Filetype c,cpp setl omnifunc=v:lua.vim.lsp.omnifunc
" lua require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
" au Filetype python setl omnifunc=v:lua.vim.lsp.omnifunc
" lua require'nvim_lsp'.rust_analyzer.setup{on_attach=require'diagnostic'.on_attach}
" au Filetype rust setl omnifunc=v:lua.vim.lsp.omnifunc
" " lua require'nvim_lsp'.sumneko_lua.setup{on_attach=require'diagnostic'.on_attach}
" " au Filetype lua setl omnifunc=v:lua.vim.lsp.omnifunc
" lua require'nvim_lsp'.vimls.setup{on_attach=require'diagnostic'.on_attach}
" au Filetype vim setl omnifunc=v:lua.vim.lsp.omnifunc

" " autocmd CursorHold * lua vim.lsp.util.show_line_diagnostics()
" " autocmd CursorMoved * lua vim.lsp.util.show_line_diagnostics()


" autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
" let g:ale_python_pyls_executable = "/home/vagrant/.local/bin/pyls"
" let g:ale_lua_luac_executable = "/bin/luac"


" call asyncomplete#register_source(asyncomplete#sources#omni#get_source_options({
"       \   'name': 'omni',
"       \   'whitelist': ['python', 'c', 'cpp', 'rust', 'vim', 'lua', 'elm', 'elixir', 'eelixir'],
"       \   'completor': function('asyncomplete#sources#omni#completor'),
"       \ }))

" " call asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
" " \ 'name': 'ultisnips',
" " \ 'whitelist': ['*'],
" " \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
" " \ }))

" " let g:asyncomplete_auto_completeopt=0
" set completeopt=menuone,noinsert,noselect
