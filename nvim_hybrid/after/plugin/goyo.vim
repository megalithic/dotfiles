" -- limelight

" Color name (:help gui-colors) or RGB color
let g:limelight_conceal_guifg = '#777777'

" Default: 0.5
" let g:limelight_default_coefficient = 0.7

" Number of preceding/following paragraphs to include (default: 0)
" let g:limelight_paragraph_span = 1

" Beginning/end of paragraph
"   When there's no empty line between the paragraphs
"   and each paragraph starts with indentation
" let g:limelight_bop = '^\s'
" let g:limelight_eop = '\ze\n^\s'

" Highlighting priority (default: 10)
"   Set it to -1 not to overrule hlsearch
" let g:limelight_priority = -1


" -- goyo


" REF: consider this: https://github.com/aerosol/dotfiles/blob/develop/silos/nvim/.config/nvim/plugin/07-writing.vim

nnoremap <leader>gy :Goyo<CR>
nnoremap <leader>G :Goyo<CR>
let g:goyo_width = 120
let g:goyo_height = 100

" function! GoyoBefore()
"   silent !tmux set status off
"   " silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
"   set tw=78
"   set wrap
"   set noshowmode
"   set noshowcmd
"   set scrolloff=999
"   Limelight
"   color off
" endfunction

" function! GoyoAfter()
"   silent !tmux set status on
"   " silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
"   set tw=0
"   set nowrap
"   set showmode
"   set showcmd
"   set scrolloff=8
"   Limelight!
"   color nova
" endfunction

function! GoyoBefore()
  if exists('$TMUX')
    silent !tmux set status off
  endif
  set wrap
  set noshowmode
  set noshowcmd
  set scrolloff=999
  Limelight
  " PencilSoft
  color off
endfunction

function! GoyoAfter()
  set nowrap
  set nowrap
  set showmode
  set showcmd
  set scrolloff=8
  Limelight!
  " PencilOff
  if has('gui_running')
    set showtabline=0
  elseif exists('$TMUX')
    silent !tmux set status on
  endif
  color nova
endfunction

let g:goyo_callbacks = [function('GoyoBefore'), function('GoyoAfter')]
