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

function! UpdateModeColors(mode) abort
  " Normal mode
  if a:mode ==# 'n'
    exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:normal_color
    exe 'hi StatuslineAccent gui=bold guifg=' . g:normal_color . ' guibg=' . g:black
    " Insert mode
  elseif a:mode ==# 'i'
    exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:insert_color
    exe 'hi StatuslineAccent gui=bold guifg=' . g:insert_color . ' guibg=' . g:black
    " Replace mode
  elseif a:mode ==# 'R'
    exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:replace_color
    exe 'hi StatuslineAccent gui=bold guifg=' . g:replace_color . ' guibg=' . g:black
    " Command mode
  elseif a:mode ==# 'c'
    " FIXME: this is the original color, convert to nova colors
    exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:magenta
    exe 'hi StatuslineAccent gui=bold guifg=' . g:magenta . ' guibg=' . g:black
    " Terminal mode
  elseif a:mode ==# 't'
    exe 'hi StatuslineMode gui=bold guifg=' . g:white . ' guibg=#6f6f6f'
    exe 'hi StatuslineAccent gui=bold guifg=#6f6f6f guibg=' . g:black
    " Visual mode
  else
    exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:visual_color
    exe 'hi StatuslineAccent gui=bold guifg=' . g:visual_color . ' guibg=' . g:black
  endif

  " Return empty string so as not to display anything in the statusline
  return ''
endfunction

function! SetModifiedSymbol(modified) abort
  if a:modified == 1
    exe 'hi StatuslineModified gui=bold guifg=' . g:light_red . ' guibg=' . g:black
    exe 'hi StatuslineFilename gui=bold guifg=' . g:light_red . ' guibg=' . g:black

    return g:modified_symbol
  else
    exe 'hi StatuslineModified gui=bold guifg=' . g:normal_color . ' guibg=' . g:black
    exe 'hi StatuslineFilename gui=NONE guifg=' . g:normal_color . ' guibg=' . g:black
    return ''
  endif
endfunction

function! StatuslineLsp() abort
  let lsp = ''

  let l:errors = luaeval('vim.lsp.util.buf_diagnostics_count("Error")')
  let l:warnings = luaeval('vim.lsp.util.buf_diagnostics_count("Warning")')
  let l:infos = luaeval('vim.lsp.util.buf_diagnostics_count("Information")')
  let l:hints = luaeval('vim.lsp.util.buf_diagnostics_count("Hint")')

  if l:errors
    " let lsp .= ' %#StatuslineError %< '
    " let lsp .= ' %#StatuslineError#' .. g:indicator_errors .. l:errors
    " let lsp .= ' %#StatuslineError %< '

    let lsp .= <SID>Color(active, 'Statusline', ' %<')
    let lsp .= <SID>Color(active, 'StatuslineError', ' ' . l:errors . ' ')
    " ' ' . g:readonly_symbol : ''
  endif

  if l:warnings
    " let lsp .= ' %#StatuslineWarning# %< '
    " let lsp .= ' %#StatuslineWarning#' .. g:indicator_warnings .. l:warnings
    " let lsp .= ' %#StatuslineWarning# %< '

    let lsp .= <SID>Color(active, 'StatuslineWarning', ' ' . l:warnings . ' ')
  endif

  if l:infos
    " let lsp .= ' %#StatuslineInformation# %< '
    " let lsp .= ' %#StatuslineInformation#' .. g:indicator_infos .. l:warnings
    " let lsp .= ' %#StatuslineInformation# %< '

    let lsp .= <SID>Color(active, 'StatuslineInformation', ' ' . l:infos . ' ')
  endif

  if l:hints
    " let lsp .= ' %#StatuslineHint# %< '
    " let lsp .= ' %#StatuslineHint#' .. g:indicator_hints .. l:warnings
    " let lsp .= ' %#StatuslineHint# %< '

    let lsp .= <SID>Color(active, 'StatuslineHint', ' ' . l:hints . ' ')
  endif

  return ''
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
    let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
    let sl .= '%{UpdateModeColors(mode())}'
    let sl .= <SID>Color(active, 'StatuslineMode', '%{statusline#get_mode(mode())}')
    " let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
    " let sl .= <SID>Color(active, 'StatuslineAccent', g:right_sep)
    let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
  endif

  " VCS
  if active
    let sl .= <SID>Color(active, 'StatuslineVCS', ' %<')
    let sl .= <SID>Color(active, 'StatuslineVCS', '%<')
    let sl .= <SID>Color(active, 'StatuslineVCS', '%{statusline#vc_status()}')
    let sl .= <SID>Color(active, 'StatuslineVCS', '%<')
  endif

  " File name
  let sl .= <SID>Color(active, 'StatuslineFilename', ' %<')
  let sl .= <SID>Color(active, modified ? 'StatuslineFilenameModified' : 'StatuslineFilename', '%{statusline#filename()}')
  " let sl .= <SID>Color(active, modified ? 'StatuslineFilenameModified' : 'StatuslineFilename', '%{expand("%:p:h:t")}/%{expand("%:p:t")}')
  let sl .= <SID>Color(active, 'StatuslineFilename', ' %<')

  " File modified
  let sl .= <SID>Color(active, 'StatuslineModified', modified ? g:modified_symbol : '')

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

  " LSP status
  if active
    " let sl .= <SID>Color(active, 'Statusline', <SID>LspStatus(bufnum))
    " let sl .= <SID>Color(active, 'Statusline', ' %<')
    let sl .= <SID>Color(active, 'StatuslineError', '%{statusline#lsp_errors()}')
    let sl .= <SID>Color(active, 'StatuslineWarning', '%{statusline#lsp_warnings()}')
    let sl .= <SID>Color(active, 'StatuslineHint', '%{statusline#lsp_hints()}')
    let sl .= <SID>Color(active, 'StatuslineInformation', '%{statusline#lsp_informations()}')
    " let sl .= <SID>Color(active, 'Statusline', ' %<')
  endif

  " if active
  "   let sl .= <SID>Color(active, 'Statusline', '%{StatuslineLsp()}')
  " endif

  " Line, Column and Percent
  if active
    " let sl .= <SID>Color(active, 'StatuslineAccent', g:left_sep)
    let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
    let sl .= <SID>Color(active, 'StatuslineMode', '%{statusline#lineinfo()}')
    let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
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
