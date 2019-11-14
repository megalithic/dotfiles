if !has('nvim')
  call lsp#set_log_level("error")

  try
    call lsp#add_filetype_config({
          \ 'name': 'elixir',
          \ 'filetype': ['elixir', 'eelixir'],
          \ 'cmd': [$HOME.'/.elixir_ls/rel/language_server.sh'],
          \ 'rootPatterns': ['mix.exs'],
          \ 'initializationOptions': {
          \   'dialyzerEnabled': v:false,
          \ },
          \ })
  catch /unique/
  endtry

  try
    call lsp#add_filetype_config({
          \ 'name': 'elm',
          \ 'filetype': ['elm'],
          \ 'cmd': ['elm-language-server'],
          \ 'rootPatterns': ['elm.json'],
          \ 'initializationOptions': {
          \   'elmAnalyseTrigger': 'change',
          \ },
          \ })
  catch /unique/
  endtry

  try
    call lsp#add_filetype_config({
          \ 'name': 'rls',
          \ 'filetype': ['rust'],
          \ 'cmd': ['rls'],
          \ 'capabilities': {
          \   'clippy_preference': 'on',
          \   'all_targets': v:false,
          \   'build_on_save': v:true,
          \   'wait_to_build': 0
          \ }})
  catch /unique/
  endtry

  try
    call lsp#add_filetype_config({
          \ 'name': 'lua',
          \ 'filetype': ['lua'],
          \ 'cmd': ['lua-lsp'],
          \ })
  catch /unique/
  endtry

  try
    call lsp#add_filetype_config({
          \ 'name': 'shell',
          \ 'filetype': ['sh', 'bash', 'zsh', 'shell'],
          \ 'cmd': ['bash-language-server', 'start', '--stdio'],
          \ })
  catch /unique/
  endtry

  try
    call lsp#add_filetype_config({
          \ 'name': 'clangd',
          \ 'filetype': 'cpp',
          \ 'cmd': 'clangd'
          \ })
  catch /unique/
  endtry

  try
    call lsp#add_filetype_config({
          \ 'name': 'pyls',
          \ 'filetype': 'python',
          \ 'cmd': 'pyls'
          \ })
  catch /unique/
  endtry

  " call lsp#add_filetype_config({
  "   \ 'name': 'js',
  "   \ 'filetype': ['javascript'],
  "   \ 'cmd': [$JAVASCRIPT_LANGUAGE_SERVER_DIRECTORY.'/lib/language-server-stdio.js'],
  "   \ })

  " call lsp#add_filetype_config({
  "   \ 'name': 'lua2',
  "   \ 'filetype': 'lua',
  "   \ 'cmd': './run.sh',
  "   \ 'cmd_cwd': '/home/ashkan/works/3rd/lua-language-server/',
  "   \ })

  function! TextDocumentCompletion() abort
    lua vim.lsp.buf_request(nil, 'textDocument/completion', vim.lsp.protocol.make_text_document_position_params())
    return ''
  endfunction
  inoremap <buffer> <c-n> <c-r>=TextDocumentCompletion()<CR>

  function! LSPRename()
    let s:newName = input('Enter new name: ', expand('<cword>'))
    lua vim.lsp.buf_request(nil, 'textDocument/rename',vim.lsp.protocol.make_text_document_position_params({'newName': s:newName}))
  endfunction
  nnoremap <silent> <buffer> <F2> :call LSPRename()<CR>

  augroup lsp
    au!
    autocmd CompleteDone * pclose
    autocmd InsertLeave <buffer> if pumvisible() == 0 | pclose | endif
    " autocmd FileType lua,elixir,eelixir,elm,rust,python,go,c,cpp,javascript,javascript.jsx,typescript,typescript.tsx,sh,zsh,bash setlocal omnifunc=lsp#complete
    autocmd FileType lua,elixir,eelixir,elm,rust,python,go,c,cpp,javascript,javascript.jsx,typescript,typescript.tsx,sh,zsh,bash setlocal omnifunc=lsp#omnifunc
  augroup END

  " nnoremap <silent> <leader>ldc :call lsp#text_document_declaration()<CR>
  " nnoremap <silent> <leader>ldf :call lsp#text_document_definition()<CR>
  " nnoremap <silent> <leader>lh  :call lsp#text_document_hover()<CR>
  " nnoremap <silent> <leader>li  :call lsp#text_document_implementation()<CR>
  " nnoremap <silent> <leader>ls  :call lsp#text_document_signature_help()<CR>
  " nnoremap <silent> <leader>ltd :call lsp#text_document_type_definition()<CR>

  nnoremap <silent> <space>dc :call lsp#text_document_declaration()<CR>
  nnoremap <silent> <space>df :call lsp#text_document_definition()<CR>
  nnoremap <silent> <space>h  :call lsp#text_document_hover()<CR>
  nnoremap <silent> <space>i  :call lsp#text_document_implementation()<CR>
  nnoremap <silent> <space>s  :call lsp#text_document_signature_help()<CR>
  nnoremap <silent> <space>td :call lsp#text_document_type_definition()<CR>
  nnoremap <silent> <space>ds :lua vim.lsp.util.show_line_diagnostics()<CR>
endif
