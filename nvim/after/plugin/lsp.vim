inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction

smap <expr> <Tab>   vsnip#available(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ completion#trigger_completion()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"


let g:completion_customize_lsp_label = {
      \ 'Function': ' [fun]',
      \ 'Method': ' [method]',
      \ 'Reference': ' [ref]',
      \ 'Enum': ' [enum]',
      \ 'Field': 'ﰠ [field]',
      \ 'Keyword': ' [key]',
      \ 'Variable': ' [var]',
      \ 'Folder': ' [folder]',
      \ 'Snippet': ' [snip]',
      \ 'Operator': ' [operator]',
      \ 'Module': ' [module]',
      \ 'Text': 'ﮜ [text]',
      \ 'Class': ' [class]',
      \ 'Interface': ' [interface]'
      \}

let g:completion_chain_complete_list = {
      \ 'default' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'snippet']},
      \       {'complete_items': ['path'], 'triggered_only': ['/']},
      \       {'complete_items': ['buffers']}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['/']}]
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
      \       {'complete_items': ['path'], 'triggered_only': ['/']},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['/']}]
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
      \ 'verilog' : {
      \   'default': [
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'comment': [],
      \   }
      \}

set completeopt=menuone,noinsert,noselect

call sign_define("LspDiagnosticsErrorSign", {"text" : "✖", "texthl" : "LspDiagnosticsError"})
call sign_define("LspDiagnosticsWarningSign", {"text" : "⬥", "texthl" : "LspDiagnosticsWarning"})
call sign_define("LspDiagnosticsInformationSign", {"text" : "‣", "texthl" : "LspDiagnosticsInformation"})
call sign_define("LspDiagnosticsHintSign", {"text" : "‣", "texthl" : "LspDiagnosticsWarning"})

" diagnostic-nvim
let g:diagnostic_level = 'Warning'
let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_virtual_text_prefix = ' '
let g:diagnostic_trimmed_virtual_text = 0
let g:diagnostic_show_sign = 1
let g:diagnostic_auto_popup_while_jump = 1
let g:diagnostic_insert_delay = 1

" completion-nvim
let g:completion_enable_auto_hover = 1
let g:completion_enable_auto_popup = 1
let g:completion_auto_change_source = 1
let g:completion_enable_snippet = 'UltiSnips'
let g:completion_max_items = 10
let g:completion_enable_auto_paren = 0
let g:completion_timer_cycle = 80
let g:completion_auto_change_source = 1
let g:completion_trigger_keyword_length = 3

" let g:completion_chain_complete_list = {
"   \ 'elixirls': [
"   \    {'complete_items': ['lsp']},
"   \    {'mode': 'keyn'},
"   \    {'mode': 'tags'},
"   \    {'mode': '<c-p>'},
"   \    {'mode': '<c-n>'},
"   \],
"   \ 'elmls': [
"   \    {'complete_items': ['lsp']},
"   \    {'mode': 'keyn'},
"   \    {'mode': 'tags'},
"   \    {'mode': '<c-p>'},
"   \    {'mode': '<c-n>'},
"   \],
"   \ 'default': [
"   \    {'mode': 'keyn'},
"   \    {'mode': '<c-p>'},
"   \    {'mode': '<c-n>'},
"   \],
"   \}

lua require 'lsp'
