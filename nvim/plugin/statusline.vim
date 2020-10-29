" " This function just outputs the content colored by the supplied colorgroup
" " number, e.g. num = 2 -> User2 it only colors the input if the window is the
" " currently focused one
" function! s:Color(active, num, content)
"   if a:active
"     return '%#' . a:num . '#' . a:content . '%*'
"   else
"     return a:content
"   endif
" endfunction

" function! UpdateModeColors(mode) abort
"   " Normal mode
"   if a:mode ==# 'n'
"     exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:normal_color
"     exe 'hi StatuslineAccent gui=bold guifg=' . g:normal_color . ' guibg=' . g:black
"     " Insert mode
"   elseif a:mode ==# 'i'
"     exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:insert_color
"     exe 'hi StatuslineAccent gui=bold guifg=' . g:insert_color . ' guibg=' . g:black
"     " Replace mode
"   elseif a:mode ==# 'R'
"     exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:replace_color
"     exe 'hi StatuslineAccent gui=bold guifg=' . g:replace_color . ' guibg=' . g:black
"     " Command mode
"   elseif a:mode ==# 'c'
"     " FIXME: this is the original color, convert to nova colors
"     exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:magenta
"     exe 'hi StatuslineAccent gui=bold guifg=' . g:magenta . ' guibg=' . g:black
"     " Terminal mode
"   elseif a:mode ==# 't'
"     exe 'hi StatuslineMode gui=bold guifg=' . g:white . ' guibg=#6f6f6f'
"     exe 'hi StatuslineAccent gui=bold guifg=#6f6f6f guibg=' . g:black
"     " Visual mode
"   else
"     exe 'hi StatuslineMode gui=bold guifg=' . g:black . ' guibg=' . g:visual_color
"     exe 'hi StatuslineAccent gui=bold guifg=' . g:visual_color . ' guibg=' . g:black
"   endif

"   " Return empty string so as not to display anything in the statusline
"   return ''
" endfunction

" function! SetModifiedSymbol(modified) abort
"   if a:modified == 1
"     exe 'hi StatuslineModified gui=bold guifg=' . g:light_red . ' guibg=' . g:black
"     exe 'hi StatuslineFilename gui=bold guifg=' . g:light_red . ' guibg=' . g:black

"     return g:modified_symbol
"   else
"     exe 'hi StatuslineModified gui=bold guifg=' . g:normal_color . ' guibg=' . g:black
"     exe 'hi StatuslineFilename gui=NONE guifg=' . g:normal_color . ' guibg=' . g:black
"     return ''
"   endif
" endfunction

" function! Statusline(winnum) abort
"   let active = a:winnum == winnr()
"   let bufnum = winbufnr(a:winnum)

"   let type = getbufvar(bufnum, '&buftype')
"   let name = bufname(bufnum)
"   let modified = getbufvar(bufnum, '&modified')

"   let sl = ''

"   " Mode
"   if active
"     let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
"     let sl .= '%{UpdateModeColors(mode())}'
"     let sl .= <SID>Color(active, 'StatuslineMode', '%{statusline#get_mode(mode())}')
"     " let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
"     " let sl .= <SID>Color(active, 'StatuslineAccent', g:right_sep)
"     let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
"   endif

"   " VCS
"   if active
"     let sl .= <SID>Color(active, 'StatuslineVCS', ' %<')
"     let sl .= <SID>Color(active, 'StatuslineVCS', '%<')
"     let sl .= <SID>Color(active, 'StatuslineVCS', '%{statusline#vc_status()}')
"     let sl .= <SID>Color(active, 'StatuslineVCS', '%<')
"   endif

"   " File name
"   let sl .= <SID>Color(active, 'StatuslineFilename', ' %<')
"   let sl .= <SID>Color(active, modified ? 'StatuslineFilenameModified' : 'StatuslineFilename', '%{statusline#filename()}')
"   let sl .= <SID>Color(active, 'StatuslineFilename', ' %<')

"   " File modified
"   let sl .= <SID>Color(active, 'StatuslineModified', modified ? g:modified_symbol : '')

"   " Read only
"   let readonly = getbufvar(bufnum, '&readonly')
"   let sl .= <SID>Color(active, 'StatuslineBoolean', readonly ? ' ' . g:readonly_symbol : '')

"   " Paste
"   if active && &paste
"     let sl .= <SID>Color(active, 'StatuslineBoolean', ' P')
"   endif

"   " Right side
"   let sl .= <SID>Color(active, 'Statusline', '%=')

"   " Filetype & icon
"   if active
"     let sl .= <SID>Color(active, 'StatuslineFiletype', ' %<')
"     let sl .= <SID>Color(active, 'StatuslineFiletypeIcon', '%{statusline#icon()} ')
"     let sl .= <SID>Color(active, 'StatuslineFiletype', '%{statusline#filetype()}')
"     let sl .= <SID>Color(active, 'StatuslineFiletype', ' %<')
"   endif

"   " LSP status
"   if active
"     let sl .= <SID>Color(active, 'Statusline', '%{statusline#lsp_status()}')
"     let sl .= <SID>Color(active, 'StatuslineError', '%{statusline#lsp_errors()}')
"     let sl .= <SID>Color(active, 'StatuslineWarning', '%{statusline#lsp_warnings()}')
"     let sl .= <SID>Color(active, 'StatuslineHint', '%{statusline#lsp_hints()}')
"     let sl .= <SID>Color(active, 'StatuslineInformation', '%{statusline#lsp_informations()}')
"   endif

"   " Line, Column and Percent
"   if active
"     " let sl .= <SID>Color(active, 'StatuslineAccent', g:left_sep)
"     let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
"     let sl .= <SID>Color(active, 'StatuslineMode', '%{statusline#lineinfo()}')
"     let sl .= <SID>Color(active, 'StatuslineMode', ' %<')
"   endif

"   return sl
" endfunction

" function! s:RefreshStatusline()
"   for nr in range(1, winnr('$'))
"     call setwinvar(nr, '&statusline', '%!Statusline(' . nr . ')')
"   endfor
" endfunction

" augroup statusline
"   autocmd!
"   autocmd VimEnter,WinEnter,BufWinEnter * call <SID>RefreshStatusline()
"   " autocmd User LspDiagnosticsChanged call <SID>RefreshStatusline()
"   " autocmd User LspMessageUpdate call <SID>RefreshStatusline()
"   " autocmd User LspStatusUpdate call <SID>RefreshStatusline() "redrawstatus!
" augroup END

scriptencoding utf-8
set noshowmode
set laststatus=2

" Setup the colors
function! s:setup_colors() abort
  hi StatuslineSeparator guifg=#3a3a3a gui=none guibg=none
  hi StatuslineFiletype guifg=#d9d9d9 gui=none guibg=#3a3a3a
  hi StatuslinePercentage guibg=#3a3a3a gui=none guifg=#dab997
  hi StatuslineNormal guibg=#3a3a3a gui=none guifg=#e9e9e9
  hi StatuslineVC guibg=#3a3a3a gui=none guifg=#a9a9a9
  hi StatuslineLintWarn guibg=#3a3a3a gui=none guifg=#ffcf00
  hi StatuslineLintChecking guibg=#3a3a3a gui=none guifg=#458588
  hi StatuslineLintError guibg=#3a3a3a gui=none guifg=#d75f5f
  hi StatuslineLintOk guibg=#3a3a3a gui=none guifg=#b8bb26
  hi StatuslineLint guibg=#e9e9e9 guifg=#3a3a3a
  hi StatuslineLineCol guibg=#3a3a3a gui=none guifg=#878787
  hi StatuslineFiletype guibg=#3a3a3a gui=none guifg=#e9e9e9
endfunction

augroup statusline_colors
  au!
  au ColorScheme * call s:setup_colors()
augroup END

call s:setup_colors()

lua require('statusline').activate()
" lua statusline = require('statusline')
" lua vim.o.statusline = '%!v:lua.statusline()'
