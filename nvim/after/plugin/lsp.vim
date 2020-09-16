set completeopt=menuone,noinsert,noselect


" -- mappings

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

imap <expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ completion#trigger_completion()
smap <expr> <Tab> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'

imap <expr> <S-Tab>
      \ pumvisible() ? "\<C-p>" :
      \ vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' :
      \ "\<C-h>"
smap <expr> <S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>'

let g:endwise_no_mappings = 1
let g:completion_confirm_key = ""
imap <expr> <CR>  pumvisible() ?
			\ complete_info()["selected"] != "-1" ?
				\ "\<Plug>(completion_confirm_completion)" :
				\ get(b:, 'closer') ?
					\ "\<c-e>\<CR>\<Plug>DiscretionaryEnd\<Plug>CloserClose"
					\ : "\<c-e>\<CR>\<Plug>DiscretionaryEnd"
			\ : get(b:, 'closer') ?
				\ "\<CR>\<Plug>DiscretionaryEnd\<Plug>CloserClose"
				\ : "\<CR>\<Plug>DiscretionaryEnd"

" let g:completion_confirm_key = ""
" imap <expr> <CR>
"       \ pumvisible() ?
"       \ complete_info()["selected"] != "-1" ? "\<Plug>(completion_confirm_completion)" : "\<C-E>\<CR>" :
"       \ "\<C-R>=lexima#expand('<CR>', 'i')\<CR>"

" let g:completion_confirm_key = ""
" imap <expr> <CR>
"       \ pumvisible() ? complete_info()["selected"] != "-1" ?
"       \ "\<Plug>(completion_confirm_completion)" : "\<C-E>\<CR>" : "\<CR>"

" -- vsnip

let g:vsnip_snippet_dir = "~/.dotfiles/nvim/vsnips"


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
"       \ 'Function': "\uf794",
"       \ 'Method': "\uf6a6",
"       \ 'Variable': "\uf71b",
"       \ 'Constant': "\uf8ff",
"       \ 'Struct': "\ufb44",
"       \ 'Class': "\uf0e8",
"       \ 'Interface': "\ufa52",
"       \ 'Text': "\ue612",
"       \ 'Enum': "\uf435",
"       \ 'EnumMember': "\uf02b",
"       \ 'Module': "\uf668",
"       \ 'Color': "\ue22b",
"       \ 'Property': "\ufab6",
"       \ 'Field': "\uf93d",
"       \ 'Unit': "\uf475",
"       \ 'File': "\uf471",
"       \ 'Value': "\uf8a3",
"       \ 'Event': "\ufacd",
"       \ 'Folder': "\uf115",
"       \ 'Keyword': "\uf893",
"       \ 'Snippet': "\uf64d",
"       \ 'Operator': "\uf915",
"       \ 'Reference': "\uf87a",
"       \ 'TypeParameter': "\uf278",
"       \ 'Default': "\uf29c",
"       \ 'Buffers': "\ufb18",
"       \ 'Function': "\uf794",
"       \ 'Method': ' ',
"       \ 'Reference': ' ',
"       \ 'Enum': ' ',
"       \ 'Field': 'ﰠ ',
"       \ 'Keyword': ' ',
"       \ 'Variable': ' ',
"       \ 'Folder': ' ',
"       \ 'Snippet': ' ',
"       \ 'Operator': ' ',
"       \ 'Module': ' ',
"       \ 'Text': 'ﮜ',
"       \ 'Class': ' ',
"       \ 'Interface': ' '
"       \}

let g:completion_customize_lsp_label = {
      \ 'Constant': "\uf8ff",
      \ 'Struct': "\ufb44",
      \ 'EnumMember': "\uf02b",
      \ 'Color': "\ue22b",
      \ 'Property': "\ufab6",
      \ 'Unit': "\uf475",
      \ 'File': "\uf471",
      \ 'Value': "\uf8a3",
      \ 'Event': "\ufacd",
      \ 'TypeParameter': "\uf278",
      \ 'Default': "\uf29c",
      \ 'Buffers': "\ufb18",
      \ 'Function': "\uf794",
      \ 'Method': ' ',
      \ 'Reference': ' ',
      \ 'Enum': ' ',
      \ 'Field': 'ﰠ ',
      \ 'Keyword': ' ',
      \ 'Variable': ' ',
      \ 'Folder': ' ',
      \ 'Snippet': ' ',
      \ 'vim-vsnip': ' ',
      \ 'Operator': ' ',
      \ 'Module': ' ',
      \ 'Text': 'ﮜ',
      \ 'Class': ' ',
      \ 'Interface': ' '
      \}

let g:completion_chain_complete_list = {
      \ 'default' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'vim-vsnip', 'buffers']},
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}]
      \   },
      \ 'elixir' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'vim-vsnip', 'buffers']},
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']},
      \       {'mode': 'keyn'},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}]
      \   },
      \ 'elm' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'vim-vsnip', 'buffers']},
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']},
      \       {'mode': 'keyn'},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}]
      \   },
      \ 'vim' : {
      \   'default': [
      \       {'complete_items': ['lsp', 'vim-vsnip', 'buffers']},
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']},
      \       {'mode': '<c-p>'},
      \       {'mode': '<c-n>'}],
      \   'string' : [
      \       {'complete_items': ['path'], 'triggered_only': ['./', '/']}]
      \   },
      \ 'markdown' : {
      \   'default': [
      \       {'mode': 'spel'}],
      \   'comment': [],
      \   },
      \}

" let g:completion_items_priority = {
"       \ 'Field': 5,
"       \ 'Function': 7,
"       \ 'Variables': 7,
"       \ 'Method': 10,
"       \ 'Interfaces': 5,
"       \ 'Constant': 5,
"       \ 'Class': 5,
"       \ 'Keyword': 4,
"       \ 'UltiSnips' : 1,
"       \ 'vim-vsnip' : 0,
"       \ 'Buffers' : 1,
"       \ 'TabNine' : 0,
"       \ 'File' : 0,
"       \}

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'vert h '.expand('<cword>')
	elseif (index(['c','sh'], &filetype) >=0)
		execute 'vert Man '.expand('<cword>')
	else
		lua vim.lsp.buf.hover()
  endif
endfunction
nnoremap <silent> K :call <SID>show_documentation()<CR>


" -- diagnostic-nvim

let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_virtual_text_prefix = "\uf63d" "
let g:diagnostic_trimmed_virtual_text = '300'
let g:diagnostic_show_sign = 1
let g:diagnostic_auto_popup_while_jump = 1
let g:diagnostic_insert_delay = 1
let g:diagnostic_enable_underline = 0
" let g:space_before_virtual_text = 5

" FIXME:
" https://github.com/wbthomason/dotfiles/blob/linux/neovim/.config/nvim/plugin/lsp.vim#L58-L61
call sign_define("LspDiagnosticsErrorSign", {"text" : g:sign_error, "texthl" : "LspDiagnosticsErrorSign", "linehl": "", "numhl": ""})
call sign_define("LspDiagnosticsWarningSign", {"text" : g:sign_warning, "texthl" : "LspDiagnosticsWarningSign", "linehl": "", "numhl": ""})
call sign_define("LspDiagnosticsInformationSign", {"text" : g:sign_info, "texthl" : "LspDiagnosticsInformationSign", "linehl": "", "numhl": ""})
call sign_define("LspDiagnosticsHintSign", {"text" : g:sign_hint, "texthl" : "LspDiagnosticsWarningSign", "linehl": "", "numhl": ""})

augroup lsp
  au!
  au User LspDiagnosticsChanged redrawstatus!
  au User LspMessageUpdate redrawstatus!
  au User LspStatusUpdate redrawstatus!
augroup END

lua require 'lsp'
