let g:gitgutter_grep                    = 'rg'
let g:gitgutter_map_keys                = 0
let g:gitgutter_sign_added              = '▎'
let g:gitgutter_sign_modified           = '▏'
let g:gitgutter_sign_removed            ='◢'
let g:gitgutter_sign_removed_first_line ='◥'
let g:gitgutter_sign_modified_removed   ='◢'
let g:gitgutter_preview_win_floating    = 1

nmap [g       <Plug>(GitGutterPrevHunk)zz
nmap ]g       <Plug>(GitGutterNextHunk)zz
nmap <Space>+ <Plug>(GitGutterStageHunk)
nmap <Space>- <Plug>(GitGutterUndoHunk)
" nmap <Space>p <Plug>(GitGutterPreviewHunk)
nmap <leader>gp <Plug>(GitGutterPreviewHunk)
