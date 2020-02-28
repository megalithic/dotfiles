" let $FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --color=always -E .git --ignore-file ~/.gitignore'
" let $FZF_DEFAULT_OPTS='--ansi --layout=reverse'
" let g:fzf_files_options = '--preview "(bat --color \"always\" --line-range 0:100 {} || head -'.&lines.' {})"'

" autocmd! FileType fzf
" autocmd  FileType fzf set noshowmode noruler nonu

" if has('nvim')
"   " set winblend=10
"   " function! FloatingFZF(width, height, border_highlight)
"   "   function! s:create_float(hl, opts)
"   "     let buf = nvim_create_buf(v:false, v:true)
"   "     let opts = extend({'relative': 'editor', 'style': 'minimal'}, a:opts)
"   "     let win = nvim_open_win(buf, v:true, opts)
"   "     call setwinvar(win, '&winhighlight', 'NormalFloat:'.a:hl)
"   "     call setwinvar(win, '&colorcolumn', '')
"   "     return buf
"   "   endfunction

"   "   " Size and position
"   "   let width = float2nr(&columns * a:width)
"   "   let height = float2nr(&lines * a:height)
"   "   let row = float2nr((&lines - height) / 2)
"   "   let col = float2nr((&columns - width) / 2)

"   "   " Border
"   "   let top = '╭' . repeat('─', width - 2) . '╮'
"   "   let mid = '│' . repeat(' ', width - 2) . '│'
"   "   let bot = '╰' . repeat('─', width - 2) . '╯'
"   "   let border = [top] + repeat([mid], height - 2) + [bot]

"   "   " Draw frame
"   "   let s:frame = s:create_float(a:border_highlight, {'row': row, 'col': col, 'width': width, 'height': height})
"   "   call nvim_buf_set_lines(s:frame, 0, -1, v:true, border)

"   "   " Draw viewport
"   "   call s:create_float('Normal', {'row': row + 1, 'col': col + 2, 'width': width - 4, 'height': height - 2})
"   "   autocmd BufWipeout <buffer> execute 'bwipeout' s:frame
"   " endfunction

"   " let g:fzf_layout = { 'window': 'call FloatingFZF(0.9, 0.6, "Comment")' }
"   " let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
" endif

" function! FZFOpen(command_str)
"   if (expand('%') =~# 'NERD_tree' && winnr('$') > 1)
"     exe "normal! \<c-w>\<c-w>"
"   endif
"   exe 'normal! ' . a:command_str . "\<cr>"
" endfunction

" command! -bang -nargs=* FzfRg
"   \ call fzf#vim#grep(
"   \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
"   \   <bang>0 ? fzf#vim#with_preview('up:60%')
"   \           : fzf#vim#with_preview('right:50%:hidden', '?'),
"   \   <bang>0)


" nnoremap <silent> <leader>m      :Files<CR>
" " nnoremap <silent> <Space><Space> :Files<CR>
" " nnoremap <silent> <Space>.       :Files <C-r>=expand("%:h")<CR>/<CR>
" " nnoremap <silent> <Space>,       :Buffers<CR>
" " nnoremap <silent> <Space>]       :Tags<CR>
" " nnoremap <silent> <Space>[       :BTags<CR>
" " nnoremap <silent> <Space>c       :BCommits<CR>
" " nnoremap <silent> <Space>g       :GFiles?<CR>
" " nnoremap <silent> <Space>s       :call LoadUltiSnipsAndFuzzySearch()<CR>
" " nnoremap <silent> <Space>?       :Helptags<CR>

" " Project-wide search for the supplied term.
" noremap <leader>a :Rg<Space>
" noremap <leader>a :FzfRg<Space>
" nnoremap <silent><leader>A  <ESC>:exe('FzfRg '.expand('<cword>'))<CR>
" vnoremap <silent><leader>A  <ESC>:exe('FzfRg '.expand('<cword>'))<CR>

if has('nvim')
  let g:fzf_layout = { 'down': '~15%' }

  let g:fzf_action = {
        \ 'ctrl-s': 'split',
        \ 'ctrl-v': 'vsplit',
        \ 'enter': 'vsplit'
        \ }

  if has('nvim') || has('gui_running')
    let $FZF_DEFAULT_OPTS .= ' --inline-info'
  endif
  let $FZF_DEFAULT_COMMAND='fd --type file --hidden --follow --exclude .git'

  nnoremap <silent> <leader>m      :Files<CR>
  " nnoremap <silent> <Space><Space> :Files<CR>
  " nnoremap <silent> <Space>.       :Files <C-r>=expand("%:h")<CR>/<CR>
  " nnoremap <silent> <Space>,       :Buffers<CR>
  " nnoremap <silent> <Space>]       :Tags<CR>
  " nnoremap <silent> <Space>[       :BTags<CR>
  " nnoremap <silent> <Space>c       :BCommits<CR>
  " nnoremap <silent> <Space>g       :GFiles?<CR>
  " nnoremap <silent> <Space>s       :call LoadUltiSnipsAndFuzzySearch()<CR>
  " nnoremap <silent> <Space>?       :Helptags<CR>

  " Project-wide search for the supplied term.
  noremap <leader>a :Rg<Space>
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
