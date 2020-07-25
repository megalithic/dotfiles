set completeopt=menuone,noinsert,noselect

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

smap <expr> <Tab> vsnip#available(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>'
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ completion#trigger_completion()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" -- completion-nvim
let g:completion_enable_auto_hover = 1
let g:completion_enable_auto_popup = 1
let g:completion_enable_auto_signature = 1
let g:completion_auto_change_source = 1
let g:completion_enable_fuzzy_match = 1
let g:completion_enable_snippet = 'vim-vsnip'
let g:completion_enable_auto_paren = 0
" let g:completion_timer_cycle = 80
let g:completion_auto_change_source = 1
let g:completion_trigger_keyword_length = 2
let g:completion_max_items = 20
let g:completion_sorting = "none" " none, length, alphabet
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

" let g:completion_customize_lsp_label = {
"       \ 'Function': '',
"       \ 'Method': '',
"       \ 'Reference': '',
"       \ 'Enum': '',
"       \ 'Field': 'ﰠ',
"       \ 'Keyword': '',
"       \ 'Variable': '',
"       \ 'Folder': '',
"       \ 'Snippet': '',
"       \ 'Operator': '',
"       \ 'Module': '',
"       \ 'Text': 'ﮜ',
"       \ 'Class': '',
"       \ 'Interface': ''
"       \}

let g:completion_customize_lsp_label = {
      \ 'Function': "\uf794",
      \ 'Method': "\uf6a6",
      \ 'Variable': "\uf71b",
      \ 'Constant': "\uf8ff",
      \ 'Struct': "\ufb44",
      \ 'Class': "\uf0e8",
      \ 'Interface': "\ufa52",
      \ 'Text': "\ue612",
      \ 'Enum': "\uf435",
      \ 'EnumMember': "\uf02b",
      \ 'Module': "\uf668",
      \ 'Color': "\ue22b",
      \ 'Property': "\ufab6",
      \ 'Field': "\uf93d",
      \ 'Unit': "\uf475",
      \ 'File': "\uf471",
      \ 'Value': "\uf8a3",
      \ 'Event': "\ufacd",
      \ 'Folder': "\uf115",
      \ 'Keyword': "\uf893",
      \ 'Snippet': "\uf64d",
      \ 'Operator': "\uf915",
      \ 'Reference': "\uf87a",
      \ 'TypeParameter': "\uf278",
      \ 'Default': "\uf29c"
      \}

let g:completion_chain_complete_list = {
      \ 'default' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'snippet']},
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']},
      \       {'complete_items': ['buffers']}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}]
      \   },
      \ 'elixirls': [
      \    {'complete_items': ['lsp', 'snippet']},
      \    {'mode': 'keyn'},
      \    {'mode': 'tags'},
      \    {'mode': '<c-p>'},
      \    {'mode': '<c-n>'},
      \],
      \ 'elmls': [
      \    {'complete_items': ['lsp', 'snippet']},
      \    {'mode': 'keyn'},
      \    {'mode': 'tags'},
      \    {'mode': '<c-p>'},
      \    {'mode': '<c-n>'},
      \],
      \ 'vim' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'snippet']},
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}]
      \   },
      \ 'cpp' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'snippet']},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'comment': [],
      \   'string' : [
      \       {'complete_items': ['path']}]
      \   },
      \ 'markdown' : {
      \   'default': [
      \       {'mode': 'spel'}],
      \   'comment': [],
      \   },
      \}

" -- diagnostic-nvim
let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_virtual_text_prefix = "\uf63d" "
let g:diagnostic_show_sign = 1
let g:diagnostic_auto_popup_while_jump = 1
let g:diagnostic_insert_delay = 1
let g:diagnostic_enable_underline = 0
" let g:space_before_virtual_text = 5

" FIXME:
" https://github.com/wbthomason/dotfiles/blob/linux/neovim/.config/nvim/plugin/lsp.vim#L58-L61
call sign_define("LspDiagnosticsErrorSign", {"text" : g:sign_error, "texthl" : "LspDiagnosticsErrorSign"})
call sign_define("LspDiagnosticsWarningSign", {"text" : g:sign_warning, "texthl" : "LspDiagnosticsWarningSign"})
call sign_define("LspDiagnosticsInformationSign", {"text" : g:sign_info, "texthl" : "LspDiagnosticsInformationSign"})
call sign_define("LspDiagnosticsHintSign", {"text" : g:sign_hint, "texthl" : "LspDiagnosticsWarningSign"})

augroup lsp
  " au! * <buffer>
  au!
  au User LspDiagnosticsChanged redrawstatus!
  au User LspMessageUpdate redrawstatus!
  au User LspStatusUpdate redrawstatus!
augroup END

lua require 'lsp'
