" if match(&runtimepath, 'nvim-lsp') != -1
"   inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
"   inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

"   set completeopt=menuone,noinsert,noselect

"   call sign_define("LspDiagnosticsErrorSign", {"text" : ">>", "texthl" : "LspDiagnosticsError"})
"   call sign_define("LspDiagnosticsWarningSign", {"text" : "⚡", "texthl" : "LspDiagnosticsWarning"})
"   call sign_define("LspDiagnosticsInformationSign", {"text" : "", "texthl" : "LspDiagnosticsInformation"})
"   call sign_define("LspDiagnosticsHintSign", {"text" : "", "texthl" : "LspDiagnosticsWarning"})

"   " Neovim LSP Diagnostics
"   let g:diagnostic_enable_virtual_text = 1
"   let g:diagnostic_virtual_text_prefix = ' '
"   let g:diagnostic_show_sign = 1
"   let g:diagnostic_auto_popup_while_jump = 1
"   let g:diagnostic_insert_delay = 1

"   " For nvim-completion
"   let g:completion_enable_auto_popup = 1
"   let g:completion_auto_change_source = 1
"   let g:completion_chain_complete_list = {
"         \ 'c': [
"         \    {'mode': 'keyn'},
"         \    {'mode': 'tags'},
"         \    {'mode': '<c-p>'},
"         \    {'mode': '<c-n>'}
"         \],
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
"         \ 'haskell': [
"         \    {'complete_items': ['lsp']},
"         \    {'mode': 'keyn'},
"         \    {'mode': 'tags'},
"         \    {'mode': '<c-p>'},
"         \    {'mode': '<c-n>'},
"         \],
"         \ 'rust': [
"         \    {'complete_items': ['lsp']},
"         \    {'mode': 'keyn'}
"         \],
"         \ 'purescript': [
"         \    {'complete_items': ['lsp']},
"         \    {'mode': 'keyn'},
"         \    {'mode': '<c-p>'},
"         \    {'mode': '<c-n>'}
"         \],
"         \ 'default': [
"         \    {'complete_items': ['lsp', 'snippet']},
"         \    {'complete_items': ['buffers']},
"         \    {'mode': 'keyn'},
"         \    {'mode': '<c-p>'},
"         \    {'mode': '<c-n>'},
"         \],
"         \}

"   " let g:completion_customize_lsp_label = {
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

"   lua require 'lsp'
" endif
