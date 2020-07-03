scriptencoding utf-16

" function! PrintStatusline(part) abort
"   return &buftype ==? 'nofile' ? '' : a:part
" endfunction

function! UpdateModeColors(mode) abort
  " Normal mode
  if a:mode ==# 'n'
    exe 'hi StatuslineAccent gui=bold guifg=' . g:black . ' guibg=' . g:normal_color
    " Insert mode
  elseif a:mode ==# 'i'
    exe 'hi StatuslineAccent gui=bold guifg=' . g:black . ' guibg=' . g:insert_color
    " Replace mode
  elseif a:mode ==# 'R'
    exe 'hi StatuslineAccent gui=bold guifg=' . g:black . ' guibg=' . g:replace_color
    " Command mode
  elseif a:mode ==# 'c'
    " FIXME: this is the original color, convert to nova colors
    exe 'hi StatuslineAccent gui=bold guifg=#e9e9e9 guibg=#83adad'
    " Terminal mode
  elseif a:mode ==# 't'
    " FIXME: this is the original color, convert to nova colors
    exe 'hi StatuslineAccent gui=bold guifg=#e9e9e9 guibg=#6f6f6f'
    " Visual mode
  else
    exe 'hi StatuslineAccent gui=bold guifg=' . g:black . ' guibg=' . g:visual_color
  endif

  if &modified
    exe 'hi StatuslineFilename gui=bold guifg=' . g:light_red . ' guibg=' . g:black
  else
    exe 'hi StatuslineFilename gui=NONE guifg=' . g:normal_color . ' guibg=' . g:black
  endif

  " Return empty string so as not to display anything in the statusline
  return ''
endfunction

function! SetModifiedSymbol(modified) abort
  if a:modified == 1
    exe 'hi StatuslineModified gui=bold guifg=' . g:light_red . ' guibg=' . g:black

    return g:modified_symbol
  else
    exe 'hi StatuslineModified gui=bold guifg=' . g:normal_color . ' guibg=' . g:black
    return ''
  endif
endfunction


" -- generate the statusline --

function! s:LspStatus(bufnum) abort
  let l:sl = ''
  let l:ale_diagnostics = ale#statusline#Count(a:bufnum)
  let l:errors = luaeval('vim.lsp.util.buf_diagnostics_count("Error")')

  " Add ALE errors
  let l:errors = l:errors + l:ale_diagnostics.error
  let l:errors = l:errors + l:ale_diagnostics.style_error
  if l:errors
    let l:sl .= ' %#StatuslineError %< '
    let l:sl .= ' %#StatuslineError#' .. g:indicator_errors .. l:errors
    let l:sl .= ' %#StatuslineError %< '
  endif
  let l:warnings = luaeval('vim.lsp.util.buf_diagnostics_count("Warning")')
  " Add ALE warnings
  let l:warnings = l:warnings + l:ale_diagnostics.warning
  let l:warnings = l:warnings + l:ale_diagnostics.style_warning
  if l:warnings
    let l:sl .= ' %#StatuslineWarning# %< '
    let l:sl .= ' %#StatuslineWarning#' .. g:indicator_warnings .. l:warnings
    let l:sl .= ' %#StatuslineWarning# %< '
  endif
  return l:sl
endfunction

" This function just outputs the content colored by the supplied colorgroup
" number, e.g. num = 2 -> User2 it only colors the input if the window is the
" currently focused one
function! s:Color(active, num, content)
  if a:active
    return '%#' . a:num . '#' . a:content . '%*'
  else
    return a:content
  endif
endfunction

function! Statusline(winnum) abort
  let active = a:winnum == winnr()
  let bufnum = winbufnr(a:winnum)

  let type = getbufvar(bufnum, '&buftype')
  let name = bufname(bufnum)
  let modified = getbufvar(bufnum, '&modified')

  let sl = ''

  " Mode
  if active
    let sl .= <SID>Color(active, 'StatuslineAccent', ' %<')
    let sl .= '%{UpdateModeColors(mode())}'
    let sl .= <SID>Color(active, 'StatuslineAccent', '%{statusline#get_mode(mode())}')
    let sl .= <SID>Color(active, 'StatuslineAccent', ' %<')
  endif

  " VCS
  if active
    let sl .= <SID>Color(active, 'StatuslineVCS', ' %<')
    let sl .= <SID>Color(active, 'StatuslineVCS', '%{statusline#vc_status()}')
    let sl .= <SID>Color(active, 'StatuslineVCS', ' %<')
  endif

  " File name
  let sl .= <SID>Color(active, 'StatuslineFilename', ' %<')
  let sl .= <SID>Color(active, modified ? 'StatuslineFilenameModified' : 'StatuslineFilename', '%{expand("%:p:h:t")}/%{expand("%:p:t")}')
  let sl .= <SID>Color(active, 'StatuslineFilename', ' %<')

  " File modified
  let sl .= <SID>Color(active, 'StatuslineModified', modified ? ' ' . g:modified_symbol : '')

  " Read only
  let readonly = getbufvar(bufnum, '&readonly')
  let sl .= <SID>Color(active, 'StatuslineBoolean', readonly ? ' ' . g:readonly_symbol : '')

  " Paste
  if active && &paste
    let sl .= <SID>Color(active, 'StatuslineBoolean', ' P')
  endif

  " Right side
  let sl .= <SID>Color(active, 'Statusline', '%=')
  " let sl .= '%='

  " Filetype & icon
  if active
    let sl .= <SID>Color(active, 'StatuslineFiletype', ' %<')
    let sl .= <SID>Color(active, 'StatuslineFiletypeIcon', '%{statusline#icon()} ')
    let sl .= <SID>Color(active, 'StatuslineFiletype', '%{statusline#filetype()}')
    let sl .= <SID>Color(active, 'StatuslineFiletype', ' %<')
  endif

  " LSP & ALE status
  if active
    " let sl .= <SID>Color(active, 'Statusline', <SID>LspStatus(bufnum))
    "" set statusline+=%(%#StatuslineLint#%{statusline#lint_lsp()}%)%#StatuslineFiletype#
    let sl .= <SID>Color(active, 'StatuslineLspError', '%{statusline#lsp_errors()}')
    let sl .= <SID>Color(active, 'StatuslineLspWarning', '%{statusline#lsp_warnings()}')
    " set statusline+=%(%#StatuslineLspError#%{statusline#lsp_errors()}%)
    " set statusline+=%(%#StatuslineLspWarning#%{statusline#lsp_warnings()}%)
    " set statusline+=%(%#StatuslineLspInformation%{statusline#lsp_informations()}%)
    " set statusline+=%(%#StatuslineLspHint%{statusline#lsp_hints()}%)
  endif

  " Line, Column and Percent
  if active
    let sl .= <SID>Color(active, 'StatuslineAccent', ' %<')
    let sl .= <SID>Color(active, 'StatuslineAccent', '%{statusline#lineinfo()}')
    let sl .= <SID>Color(active, 'StatuslineAccent', ' %<')
  endif

  return sl
endfunction

function! s:RefreshStatusline()
  for nr in range(1, winnr('$'))
    call setwinvar(nr, '&statusline', '%!Statusline(' . nr . ')')
  endfor
endfunction

augroup statusline
  autocmd!
  autocmd VimEnter,WinEnter,BufWinEnter * call <SID>RefreshStatusline()
augroup END
