if has('nvim')
  let $FZF_DEFAULT_COMMAND='fd --type file --hidden --follow --exclude .git'

  " let g:fzf_layout = { 'down': '~15%', 'window': { 'width': 0.6, 'height': 0.5, 'highlight': 'Todo', 'border': 'rounded' } }
  let g:fzf_layout = { 'down': '~15%' }
  " let g:fzf_colors = {}
  let g:fzf_action = {
        \ 'ctrl-s': 'split',
        \ 'ctrl-v': 'vsplit',
        \ 'enter': 'vsplit'
        \ }

  function! RipgrepFzf(query, fullscreen)
    let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
    let initial_command = printf(command_fmt, shellescape(a:query))
    let reload_command = printf(command_fmt, '{q}')
    let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
    call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
  endfunction

  command! -nargs=* -bang Rg call RipgrepFzf(<q-args>, <bang>0)

  " Project-wide search for the supplied term.
  nnoremap <silent> <leader>m      :Files<CR>
  nnoremap <leader>a :Rg<Space>
  nnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>
  vnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>

  " Mapping selections for various modes.
  nmap <Space>! <Plug>(fzf-maps-n)
  omap <Space>! <Plug>(fzf-maps-o)
  xmap <Space>! <Plug>(fzf-maps-x)
  imap <C-x>!   <Plug>(fzf-maps-i)

  " https://github.com/junegunn/dotfiles/blob/master/vimrc#L1648
  " Terminal buffer options for fzf
  autocmd! FileType fzf
  autocmd  FileType fzf set noshowmode noruler nonu
endif

if has('nvim') && !exists('g:fzf_layout')
  autocmd! FileType fzf
  autocmd  FileType fzf set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
endif

if has('nvim') || has('gui_running')
  let $FZF_DEFAULT_OPTS .= ' --inline-info'
endif
