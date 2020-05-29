" vim-clap config (TODO: move to its own module)
if has('nvim')
  let g:clap_theme = 'nord'
  let g:clap_open_action = { 'ctrl-t': 'tab split', 'ctrl-x': 'split', 'ctrl-v': 'vsplit', 'enter': 'vsplit', 'cr': 'vsplit' }
  let g:clap_layout = { 'relative': 'editor' }

  nnoremap <silent> <leader>m      :Clap files<CR>
  nnoremap <silent> <leader>a      :Clap grep<CR>

  " nnoremap <silent> <leader>a :Clap grep<Space>
  " nnoremap <silent> <leader>A  <ESC>:exe('Clap grep '.expand('<cword>'))<CR>
  " vnoremap <silent> <leader>A  <ESC>:exe('Clap grep '.expand('<cword>'))<CR>
endif
