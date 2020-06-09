" if match(&runtimepath, 'nvim-lsp') != -1
"   inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
"   inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
"   au Filetype c,cpp setl omnifunc=v:lua.vim.lsp.omnifunc
"   au Filetype python setl omnifunc=v:lua.vim.lsp.omnifunc
"   au Filetype rust setl omnifunc=v:lua.vim.lsp.omnifunc
"   au Filetype lua setl omnifunc=v:lua.vim.lsp.omnifunc
"   au Filetype vim setl omnifunc=v:lua.vim.lsp.omnifunc
"   au Filetype elixir,eelixir setl omnifunc=v:lua.vim.lsp.omnifunc
"   au Filetype elm setl omnifunc=v:lua.vim.lsp.omnifunc

"   let g:completion_chain_complete_list = {
"         \ 'default' : {
"         \   'default': [
"         \       {'complete_items': ['lsp', 'snippet']},
"         \       {'complete_items': ['buffers']},
"         \       {'mode': '<c-p>'},
"         \       {'mode': '<c-n>'}],
"         \   'string' : [
"         \       {'complete_items': ['path'], 'triggered_only': ['/']}]
"         \   },
"         \ 'cpp' : {
"         \   'default': [
"         \       {'complete_items': ['lsp', 'snippet']},
"         \       {'complete_items': ['buffers']},
"         \       {'mode': '<c-p>'},
"         \       {'mode': '<c-n>'}],
"         \   'comment': [],
"         \   'string' : [
"         \       {'complete_items': ['path']}]
"         \   },
"         \ 'markdown' : {
"         \   'default': [
"         \       {'mode': 'spel'}],
"         \   'comment': [],
"         \   },
"         \ 'verilog' : {
"         \   'default': [
"         \       {'complete_items': ['ts']},
"         \       {'mode': '<c-p>'},
"         \       {'mode': '<c-n>'}],
"         \   'comment': [],
"         \   }
"         \}

"   " et g:completion_customize_lsp_label = {
"   "       \ 'Function': ' [function]',
"   "       \ 'Method': ' [method]',
"   "       \ 'Reference': ' [refrence]',
"   "       \ 'Enum': ' [enum]',
"   "       \ 'Field': 'ﰠ [field]',
"   "       \ 'Keyword': ' [key]',
"   "       \ 'Variable': ' [variable]',
"   "       \ 'Folder': ' [folder]',
"   "       \ 'Snippet': ' [snippet]',
"   "       \ 'Operator': ' [operator]',
"   "       \ 'Module': ' [module]',
"   "       \ 'Text': 'ﮜ[text]',
"   "       \ 'Class': ' [class]',
"   "       \ 'Interface': ' [interface]'
"   "       \}

"   let g:completion_customize_lsp_label = {
"         \ 'Function': "\uf794",
"         \ 'Method': "\uf6a6",
"         \ 'Variable': "\uf71b",
"         \ 'Constant': "\uf8ff",
"         \ 'Struct': "\ufb44",
"         \ 'Class': "\uf0e8",
"         \ 'Interface': "\ufa52",
"         \ 'Text': "\ue612",
"         \ 'Enum': "\uf435",
"         \ 'EnumMember': "\uf02b",
"         \ 'Module': "\uf668",
"         \ 'Color': "\ue22b",
"         \ 'Property': "\ufab6",
"         \ 'Field': "\uf93d",
"         \ 'Unit': "\uf475",
"         \ 'File': "\uf471",
"         \ 'Value': "\uf8a3",
"         \ 'Event': "\ufacd",
"         \ 'Folder': "\uf115",
"         \ 'Keyword': "\uf893",
"         \ 'Snippet': "\uf64d",
"         \ 'Operator': "\uf915",
"         \ 'Reference': "\uf87a",
"         \ 'TypeParameter': "\uf278",
"         \ 'Default': "\uf29c"
"         \}
"   " autocmd CursorHold * lua vim.lsp.util.show_line_diagnostics()
"   " autocmd CursorMoved * lua vim.lsp.util.show_line_diagnostics()

"   set completeopt=menuone,noinsert,noselect

"   call sign_define("LspDiagnosticsErrorSign", {"text" : ">>", "texthl" : "LspDiagnosticsError"})
"   call sign_define("LspDiagnosticsWarningSign", {"text" : "⚡", "texthl" : "LspDiagnosticsWarning"})
"   call sign_define("LspDiagnosticsInformationSign", {"text" : "", "texthl" : "LspDiagnosticsInformation"})
"   call sign_define("LspDiagnosticsHintSign", {"text" : "", "texthl" : "LspDiagnosticsWarning"})

"   " diagnostic-nvim
"   let g:diagnostic_level = 'Warning'
"   let g:diagnostic_enable_virtual_text = 0
"   let g:diagnostic_virtual_text_prefix = ' '
"   let g:diagnostic_trimmed_virtual_text = 0
"   let g:diagnostic_insert_delay = 1

"   " completion-nvim
"   let g:completion_enable_auto_hover = 1
"   let g:completion_auto_change_source = 1
"   " let g:completion_enable_snippet = 'UltiSnips'

"   " let g:completion_max_items = 10
"   let g:completion_enable_auto_paren = 0
"   let g:completion_timer_cycle = 80
"   let g:completion_auto_change_source = 1
"   let g:completion_trigger_keyword_length = 2
"   " let g:completion_confirm_key = ""

"   " imap <expr> <cr> pumvisible() ? complete_info()["selected"] != "-1" ?
"   "       \ "\<Plug>(completion_confirm_completion)"  : "\<c-e>\<CR>" : "\<CR>"
"   " let g:completion_confirm_key_rhs = "\<Plug>AutoPairsReturn"

"   imap <c-j> <cmd>lua require'source'.prevCompletion()<CR>
"   imap <c-k> <cmd>lua require'source'.nextCompletion()<CR>

"   function! s:check_back_space() abort
"     let col = col('.') - 1
"     return !col || getline('.')[col - 1]  =~ '\s'
"   endfunction

"   smap <expr> <Tab>   vsnip#available(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
"   imap <silent><expr> <TAB>
"         \ pumvisible() ? "\<C-n>" :
"         \ vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' :
"         \ <SID>check_back_space() ? "\<TAB>" :
"         \ completion#trigger_completion()
"   inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"


"   " lsp
"   nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
"   nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
"   nnoremap <silent> gi    <cmd>lua vim.lsp.buf.implementation()<CR>
"   nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
"   nnoremap <silent> pd    <cmd>lua require'lsp_util'.peek_definition()<CR>
"   nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
"   nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
"   nnoremap <silent> <leader>f <cmd>lua vim.lsp.buf.formatting()<CR>
"   nnoremap <silent> <leader>a <cmd>lua vim.lsp.buf.code_action()<CR>
"   nnoremap <silent> <leader>rn <cmd>lua vim.lsp.buf.rename()<CR>
"   nnoremap <silent> ]d :NextDiagnostic<CR>
"   nnoremap <silent> [d :PrevDiagnostic<CR>
"   nnoremap <silent> <leader>do :OpenDiagnostic<CR>
"   nnoremap <leader>dl <cmd>lua require'diagnostic.util'.show_line_diagnostics()<CR>

"   " lua require 'nvim-lsp'
" endif

" " lua require'nvim_lsp'.ccls.setup{on_attach=require'diagnostic'.on_attach}
" " lua require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
" " lua require'nvim_lsp'.rust_analyzer.setup{on_attach=require'diagnostic'.on_attach}
" " lua require'nvim_lsp'.vimls.setup{on_attach=require'diagnostic'.on_attach}
" " lua require'nvim_lsp'.elmls.setup{on_attach=require'diagnostic'.on_attach}

" " autocmd! User Filetype rust,c,cpp,elm,python,vim call SetLspDefaults()

" " function! SetLspDefaults()
" "   setlocal omnifunc=v:lua.vim.lsp.omnifunc

" "   nnoremap <silent> gc <cmd>lua vim.lsp.buf.declaration()<CR>
" "   nnoremap <silent> gc <cmd>lua vim.lsp.buf.declaration()<CR>
" "   nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
" "   nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
" "   nnoremap <silent> gi    <cmd>lua vim.lsp.buf.implementation()<CR>
" "   inoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
" "   nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
" "   nnoremap <silent> pd    <cmd>lua vim.lsp.buf.peek_definition()<CR>
" "   nnoremap <silent> ]d :NextDiagnostic<CR>
" "   nnoremap <silent> [d :PrevDiagnostic<CR>
" "   nnoremap <silent> <leader>do :OpenDiagnostic<CR>
" "   nnoremap <leader>dl <cmd>lua vim.lsp.util.show_line_diagnostics()<CR>

" "   " nnoremap <silent> <leader>gD <cmd>lua vim.lsp.buf.declaration()<CR>
" "   " nnoremap <silent> <leader>gd <cmd>lua vim.lsp.buf.definition()<CR>
" "   " nnoremap <silent> <leader>k  <cmd>lua vim.lsp.buf.hover()<CR>
" "   " nnoremap <silent> <leader>gi  <cmd>lua vim.lsp.buf.implementation()<CR>
" "   " nnoremap <silent> <leader>gs  <cmd>lua vim.lsp.buf.signature_help()<CR>
" "   " nnoremap <silent> <leader>gt <cmd>lua vim.lsp.buf.type_definition()<CR>
" " endfunction

" " let g:diagnostic_enable_virtual_text = 1
" " let g:diagnostic_virtual_text_prefix = ' '
" " let g:diagnostic_insert_delay = 1
" " let g:diagnostic_auto_popup_while_jump = 1


" " function! LSPSetup()
" " lua << EOF
" " require'nvim_lsp'.gopls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.bashls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.clangd.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.cssls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.dockerls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.elmls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.jsonls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.rust_analyzer.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.sumneko_lua.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.terraformls.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.tsserver.setup{on_attach=require'diagnostic'.on_attach}
" " require'nvim_lsp'.vimls.setup{on_attach=require'diagnostic'.on_attach}
" " EOF
" " endfunction
" " function! LSPUpdate()
" "   LspInstall gopls
" "   LspInstall bashls
" "   LspInstall clangd
" "   LspInstall cssls
" "   LspInstall dockerls
" "   LspInstall elmls
" "   LspInstall jsonls
" "   LspInstall pyls
" "   LspInstall rust_analyzer
" "   LspInstall sumneko_lua
" "   LspInstall terraformls
" "   LspInstall tsserver
" "   LspInstall vimls
" " endfunction

" " call LSPSetup()

" " autocmd Filetype \
" "       \go,
" "       \bash,
" "       \c,
" "       \cpp,
" "       \objcpp,
" "       \sh,
" "       \objc,
" "       \css,
" "       \scss,
" "       \less,
" "       \vim,
" "       \javascript,
" "       \javascriptreact,
" "       \javascript.jsx,
" "       \typescript,
" "       \typescriptreact,
" "       \typescript.tsx,
" "       \terraform,
" "       \lua,
" "       \rust,
" "       \python,
" "       \json,
" "       \rust,
" "       \dockerfile,
" "       \Dockerfile,
" "       \ setlocal omnifunc=v:lua.vim.lsp.omnifunc

" " nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
" " nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
" " nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
" " nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
" " nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
" " nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
" " nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
" " nnoremap <silent> gF    <cmd>lua vim.lsp.buf.formatting()<CR>
" " nnoremap <silent> ]d :NextDiagnostic<CR>
" " nnoremap <silent> [d :PrevDiagnostic<CR>
