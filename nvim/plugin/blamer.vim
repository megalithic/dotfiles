let g:blamer_template = '<author> <author-time> <commit-short> <summary>'
let g:blamer_date_format = '%Y-%m-%d'

let g:blamer_enabled = 0
let g:blamer_delay = 500
let g:blamer_prefix = ' > '

nnoremap <silent> <leader>b :BlamerToggle<CR>
