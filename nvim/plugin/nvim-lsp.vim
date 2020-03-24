if match(&runtimepath, 'nvim-lsp') != -1
  echo "we have nvim-lsp installed"
endif

" lua require'nvim_lsp'.ccls.setup{on_attach=require'diagnostic'.on_attach}
" lua require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
" lua require'nvim_lsp'.rust_analyzer.setup{on_attach=require'diagnostic'.on_attach}
" lua require'nvim_lsp'.vimls.setup{on_attach=require'diagnostic'.on_attach}
" lua require'nvim_lsp'.elmls.setup{on_attach=require'diagnostic'.on_attach}

" autocmd! User Filetype rust,c,cpp,elm,python,vim call SetLspDefaults()

" function! SetLspDefaults()
"   setlocal omnifunc=v:lua.vim.lsp.omnifunc

"   nnoremap <silent> gc <cmd>lua vim.lsp.buf.declaration()<CR>
"   nnoremap <silent> gc <cmd>lua vim.lsp.buf.declaration()<CR>
"   nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
"   nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
"   nnoremap <silent> gi    <cmd>lua vim.lsp.buf.implementation()<CR>
"   inoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
"   nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
"   nnoremap <silent> pd    <cmd>lua vim.lsp.buf.peek_definition()<CR>
"   nnoremap <silent> ]d :NextDiagnostic<CR>
"   nnoremap <silent> [d :PrevDiagnostic<CR>
"   nnoremap <silent> <leader>do :OpenDiagnostic<CR>
"   nnoremap <leader>dl <cmd>lua vim.lsp.util.show_line_diagnostics()<CR>

"   " nnoremap <silent> <leader>gD <cmd>lua vim.lsp.buf.declaration()<CR>
"   " nnoremap <silent> <leader>gd <cmd>lua vim.lsp.buf.definition()<CR>
"   " nnoremap <silent> <leader>k  <cmd>lua vim.lsp.buf.hover()<CR>
"   " nnoremap <silent> <leader>gi  <cmd>lua vim.lsp.buf.implementation()<CR>
"   " nnoremap <silent> <leader>gs  <cmd>lua vim.lsp.buf.signature_help()<CR>
"   " nnoremap <silent> <leader>gt <cmd>lua vim.lsp.buf.type_definition()<CR>
" endfunction

" let g:diagnostic_enable_virtual_text = 1
" let g:diagnostic_virtual_text_prefix = ' '
" let g:diagnostic_insert_delay = 1
" let g:diagnostic_auto_popup_while_jump = 1


" function! LSPSetup()
" lua << EOF
" require'nvim_lsp'.gopls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.bashls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.clangd.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.cssls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.dockerls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.elmls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.jsonls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.rust_analyzer.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.sumneko_lua.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.terraformls.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.tsserver.setup{on_attach=require'diagnostic'.on_attach}
" require'nvim_lsp'.vimls.setup{on_attach=require'diagnostic'.on_attach}
" EOF
" endfunction
" function! LSPUpdate()
"   LspInstall gopls
"   LspInstall bashls
"   LspInstall clangd
"   LspInstall cssls
"   LspInstall dockerls
"   LspInstall elmls
"   LspInstall jsonls
"   LspInstall pyls
"   LspInstall rust_analyzer
"   LspInstall sumneko_lua
"   LspInstall terraformls
"   LspInstall tsserver
"   LspInstall vimls
" endfunction

" call LSPSetup()

" autocmd Filetype \
"       \go,
"       \bash,
"       \c,
"       \cpp,
"       \objcpp,
"       \sh,
"       \objc,
"       \css,
"       \scss,
"       \less,
"       \vim,
"       \javascript,
"       \javascriptreact,
"       \javascript.jsx,
"       \typescript,
"       \typescriptreact,
"       \typescript.tsx,
"       \terraform,
"       \lua,
"       \rust,
"       \python,
"       \json,
"       \rust,
"       \dockerfile,
"       \Dockerfile,
"       \ setlocal omnifunc=v:lua.vim.lsp.omnifunc

" nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
" nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
" nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
" nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
" nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
" nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
" nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
" nnoremap <silent> gF    <cmd>lua vim.lsp.buf.formatting()<CR>
" nnoremap <silent> ]d :NextDiagnostic<CR>
" nnoremap <silent> [d :PrevDiagnostic<CR>
