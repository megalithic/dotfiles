 " lua require'nvim_lsp'.ccls.setup{on_attach=require'diagnostic'.on_attach}
 " lua require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
 " lua require'nvim_lsp'.rust_analyzer.setup{on_attach=require'diagnostic'.on_attach}
 " lua require'nvim_lsp'.vimls.setup{on_attach=require'diagnostic'.on_attach}
 " lua require'nvim_lsp'.elmls.setup{on_attach=require'diagnostic'.on_attach}
 " 
 " autocmd! User Filetype rust,c,cpp,elm,python,vim call SetLspDefaults()
 " 
 " function! SetLspDefaults()
 "   setlocal omnifunc=v:lua.vim.lsp.omnifunc
 " 
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
 " 
 "   " nnoremap <silent> <leader>gD <cmd>lua vim.lsp.buf.declaration()<CR>
 "   " nnoremap <silent> <leader>gd <cmd>lua vim.lsp.buf.definition()<CR>
 "   " nnoremap <silent> <leader>k  <cmd>lua vim.lsp.buf.hover()<CR>
 "   " nnoremap <silent> <leader>gi  <cmd>lua vim.lsp.buf.implementation()<CR>
 "   " nnoremap <silent> <leader>gs  <cmd>lua vim.lsp.buf.signature_help()<CR>
 "   " nnoremap <silent> <leader>gt <cmd>lua vim.lsp.buf.type_definition()<CR>
 " endfunction
