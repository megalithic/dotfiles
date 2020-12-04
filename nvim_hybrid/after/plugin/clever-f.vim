let g:clever_f_across_no_line    = 1
let g:clever_f_fix_key_direction = 1
let g:clever_f_timeout_ms        = 2000
" let g:clever_f_mark_char_color   =

" keep the original functionality to jump between found chars
map ; <Plug>(clever-f-repeat-forward)
map , <Plug>(clever-f-repeat-back)
