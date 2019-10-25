let g:signify_line_highlight         = 0
let g:signify_sign_show_text         = 1
let g:signify_sign_show_count        = 0
let g:signify_sign_add               = '▎'
let g:signify_sign_delete            = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change            = '▏'
let g:signify_sign_changedelete      = g:signify_sign_change

omap ic <plug>(signify-motion-inner-pending)
xmap ic <plug>(signify-motion-inner-visual)
omap ac <plug>(signify-motion-outer-pending)
xmap ac <plug>(signify-motion-outer-visual)
nnoremap <silent><leader>p :SignifyHunkDiff<cr>
nnoremap <silent><leader>u :SignifyHunkUndo<cr>
