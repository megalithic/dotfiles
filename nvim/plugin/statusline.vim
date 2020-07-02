scriptencoding utf-16
" set noshowmode
" set laststatus=2

let g:light_red     = [ '#DF8C8C', 'NONE' ]
let g:dark_red      = [ '#F2C38F', 'NONE' ]
let g:green         = [ '#A8CE93', 'NONE' ]
let g:blue          = [ '#83AFE5', 'NONE' ]
let g:cyan          = [ '#7FC1CA', 'NONE' ]
let g:magenta       = [ '#9A93E1', 'NONE' ]
let g:light_yellow  = [ '#DADA93', 'NONE' ]
let g:dark_yellow   = [ '#DADA93', 'NONE' ]

let g:black         = [ '#3C4C55', 'NONE' ]
let g:white         = [ '#C5D4DD', 'NONE' ]
let g:comment_grey  = [ '#C5D4DD', 'NONE' ]
let g:gutter_grey   = [ '#899BA6', 'NONE' ]
" middle
let g:cursor_grey   = [ '#3C4C55', 'NONE' ]
" second
let g:visual_grey   = [ '#6A7D89', 'NONE' ]
let g:menu_grey     = g:visual_grey
let g:special_grey  = [ '#1E272C', 'NONE' ]
let g:vertsplit     = [ '#181a1f', 'NONE' ]

let g:tab_color     = g:blue
let g:normal_color  = g:blue
let g:insert_color  = g:green
let g:replace_color = g:light_red
let g:visual_color  = g:light_yellow
let g:active_bg     = g:visual_grey
let g:inactive_bg   = g:special_grey


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
    exe 'hi StatuslineFilename gui=bold guifg=' . g:normal_color . ' guibg=' . g:black
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
