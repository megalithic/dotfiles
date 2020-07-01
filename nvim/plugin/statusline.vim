scriptencoding utf-8
" set noshowmode
" set laststatus=2

" Statusline functions
function! statusline#icon() abort
  return luaeval("require('utils').icons.lookup_filetype(_A)", &filetype)
endfunction

function! statusline#filetype() abort
  return &filetype !=# '' ? &filetype : 'no filetype'
endfunction

let g:indicator_checking = "\uf110"
let g:indicator_warnings = "\uf071"
let g:indicator_errors = "\uf05e"
let g:indicator_ok = "\uf00c"
let g:indicator_info = '🛈'
let g:indicator_hint = '❗'
let g:modified_symbol = ''
let g:vcs_symbol = ''

let g:spinner_frames = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']

let s:ale_frame_idx = 0

function! statusline#ale_warnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:all_non_errors == 0 ? '' : printf(g:indicator_warnings . ' %d', all_non_errors)
endfunction

function! statusline#ale_errors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  return l:all_errors == 0 ? '' : printf(g:indicator_errors . ' %d', all_errors)
endfunction

function! statusline#ale_ok() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  return l:counts.total == 0 ? g:indicator_ok : ''
endfunction

function! statusline#ale_checking() abort
  let result = ''
  if ale#engine#IsCheckingBuffer(bufnr(''))
    let result = g:spinner_frames[s:ale_frame_idx % len(g:spinner_frames)]
    let s:ale_frame_idx = s:ale_frame_idx + 1
  else
    let s:ale_frame_idx = 0
  endif
  return result
endfunction

function! statusline#ale_enabled() abort
  return (get(g:, 'ale_enabled', 0) == 1 && getbufvar(bufnr(''), 'ale_linted', 0) > 0) || getbufvar(bufnr(''), 'ale_linted', 0) > 0
endfunction

function! statusline#ale() abort
  if !statusline#ale_enabled()
    return ''
  endif

  let l:icon = ' 🍺 '
  let l:checking = statusline#ale_checking()

  if l:checking !=# ''
    return l:icon . l:checking . ' '
  endif

  let l:ok = statusline#ale_ok()
  if l:ok !=# ''
    return l:icon . l:ok . ' '
  endif

  let l:warnings = statusline#ale_warnings()
  let l:errors = statusline#ale_errors()
  return l:icon . l:warnings . (l:warnings ==# '' ? '' : (l:errors ==# '' ? '' : ' ')) . l:errors . ' '
endfunction

function! statusline#gutentags_enabled() abort
  return exists('g:gutentags_enabled') && g:gutentags_enabled == 1 && gutentags#statusline() !=# ''
endfunction

function! statusline#gutentags()
  if !statusline#gutentags_enabled()
    return ''
  endif

  return gutentags#statusline('[', '] ')
endfunction

function! s:trim(str)
  if exists('*trim')
    return trim(a:str)
  endif
  return substitute(a:str, '\s\+$', '', '')
endfunction

function! statusline#vc_status() abort
  " let l:mark = ''
  let l:mark = g:vcs_symbol
  let l:branch = gitbranch#name()
  let l:changes = sy#repo#get_stats()
  let l:status = l:changes[0] > 0 ? '+' . l:changes[0] : ''
  let l:prefix = l:changes[0] > 0 ? ' ' : ''
  let l:status = l:changes[1] > 0 ? l:status . l:prefix . '~' . l:changes[1] : l:status
  let l:prefix = l:changes[1] > 0 ? ' ' : ''
  let l:status = l:changes[2] > 0 ? l:status . l:prefix . '-' . l:changes[2] : l:status
  let l:status = l:status ==# '' ? '' : l:status . ' '
  return l:branch !=# '' ? l:status . l:mark . ' ' . l:branch . ' ' : ''
endfunction

function! statusline#have_lsp() abort
  return luaeval('#vim.lsp.buf_get_clients() > 0')
endfunction

function! statusline#lsp() abort
  return luaeval("require('lsp-status').status()")
endfunction

function! statusline#lint_lsp()
  let l:segment = ''
  let l:have_ale = v:false
  if statusline#ale_enabled()
    let l:have_ale = v:true
    let l:segment = statusline#ale()
  endif

  if statusline#have_lsp()
    let l:segment = l:segment . statusline#lsp()
  endif

  return l:segment
endfunction

function! statusline#get_mode(mode) abort
  let l:currentmode={
        \'n' : 'Normal',
        \'no' : 'N·Operator Pending',
        \'v' : 'Visual',
        \'V' : 'V·Line',
        \'^V' : 'V·Block',
        \'s' : 'Select',
        \'S': 'S·Line',
        \'^S' : 'S·Block',
        \'i' : 'Insert',
        \'R' : 'Replace',
        \'Rv' : 'V·Replace',
        \'c' : 'Command',
        \'cv' : 'Vim Ex',
        \'ce' : 'Ex',
        \'r' : 'Prompt',
        \'rm' : 'More',
        \'r?' : 'Confirm',
        \'!' : 'Shell',
        \'t' : 'Terminal'
        \}
  return toupper(get(l:currentmode, a:mode, 'V-Block'))
endfunction

function! statusline#filename() abort
  let base_name = fnamemodify(bufname('%'), ':~:.')
  let space = min([60, float2nr(floor(0.6 * winwidth(0)))])
  if len(base_name) <= space
    return base_name
  endif

  return pathshorten(base_name)
endfunction


function! UpdateModeColors(mode) abort
  " Normal mode
  if a:mode ==# 'n'
    " hi StatuslineAccent guibg=#d75f5f gui=bold guifg=#e9e9e9
    exe 'hi StatuslineAccent guibg=#d75f5f gui=bold guifg=#e9e9e9'
    " Insert mode
  elseif a:mode ==# 'i'
    exe 'hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#dab997'
    " Replace mode
  elseif a:mode ==# 'R'
    exe 'hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#afaf00'
    " Command mode
  elseif a:mode ==# 'c'
    exe 'hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#83adad'
    " Terminal mode
  elseif a:mode ==# 't'
    exe 'hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#6f6f6f'
    " Visual mode
  else
    exe 'hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#f485dd'
  endif

  if &modified
    " hi StatuslineFilename guifg=#d75f5f gui=bold guibg=#3a3a3a
    exe 'hi StatuslineFilename guifg=#d75f5f gui=bold guibg=#3a3a3a'
  else
    exe 'hi StatuslineFilename guifg=#e9e9e9 gui=bold guibg=#3a3a3a'
  endif
  " Return empty string so as not to display anything in the statusline
  return ''
endfunction

function! SetModifiedSymbol(modified) abort
  if a:modified == 1
    " hi StatuslineModified guibg=#3a3a3a gui=bold guifg=#d75f5f
    exe 'hi StatuslineModified guibg=#3a3a3a gui=bold guifg=#d75f5f'

    return g:modified_symbol
  else
    exe 'hi StatuslineModified guibg=#3a3a3a gui=bold guifg=#afaf00'
    return ''
  endif
endfunction


" function! generate_statusline() abort

" endfunction

" -- generate the statusline

set statusline=%{UpdateModeColors(mode())}

" Left side items
set statusline+=%#StatuslineAccent#\ %{statusline#get_mode(mode())}\ %<

" Filetype icon
set statusline+=%#StatuslineFiletype#\ %{statusline#icon()}

" Modified status
set statusline+=%#StatuslineModified#%{SetModifiedSymbol(&modified)}

" Filename
set statusline+=%#StatuslineFilename#\ %{statusline#filename()}\ %<

" Paste and RO
set statusline+=%#StatuslineFilename#%{&paste?'PASTE\ ':''}
set statusline+=%{&paste&&&readonly?'\ ':''}%r%{&readonly?'\ ':''}

" Line and Column
set statusline+=%#StatuslineLineCol#(Ln\ %l/%L,\ %#StatuslineLineCol#Col\ %c)\ %<

" Right side items
set statusline+=%=

" VCS
set statusline+=%#StatuslineVC#%{statusline#vc_status()}\

" Linters/LSP
set statusline+=%(%#StatuslineLint#%{statusline#lint_lsp()}%)%#StatuslineFiletype#
"
" " ALE status
" set statusline+=%{statusline#ale_enabled()?'':'\ '}%(%#StatuslineLint#%{statusline#ale()}%)
"
" " LSP
" set statusline+=%{statusline#have_lsp()?'':'\ '}%(%#StatuslineLint#%{statusline#lsp()}%)%#StatuslineFiletype#
