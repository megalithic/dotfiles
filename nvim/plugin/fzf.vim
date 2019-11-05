" let g:fzf_layout = { "window": "silent botright 16split vnew" }
let g:fzf_layout = { 'down': '~15%' }
" let g:fzf_layout = { 'window': 'call FloatingFZF()' }
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

" function! FloatingFZF()
"   let buf = nvim_create_buf(v:false, v:true)
"   call setbufvar(buf, '&signcolumn', 'no')

"   let width = float2nr(&columns - (&columns * 2 / 10))
"   let height = 35

"   let col = float2nr((&columns - width) / 2)
"   let row = float2nr((&lines - height) / 2)

"   let opts = {
"         \ 'relative': 'editor',
"         \ 'row': row,
"         \ 'col': col,
"         \ 'width': width,
"         \ 'height': height
"         \ }

"   let win = nvim_open_win(buf, v:true, opts)
"   call setwinvar(win, '&number', 0)
"   call setwinvar(win, '&relativenumber', 0)
" endfunction

" https://github.com/junegunn/dotfiles/blob/master/vimrc#L1648
" Terminal buffer options for fzf
autocmd! FileType fzf
autocmd  FileType fzf set noshowmode noruler nonu

" if has('nvim') && exists('&winblend') && &termguicolors
"   set winblend=10

"   if exists('g:fzf_colors.bg')
"     call remove(g:fzf_colors, 'bg')
"   endif

"   if stridx($FZF_DEFAULT_OPTS, '--border') == -1
"     let $FZF_DEFAULT_OPTS .= ' --border --margin=0,2'
"   endif

"   function! FloatingFZF()
"     let width = float2nr(&columns * 0.9)
"     let height = float2nr(&lines * 0.6)
"     let opts = { 'relative': 'editor',
"                \ 'row': (&lines - height) / 2,
"                \ 'col': (&columns - width) / 2,
"                \ 'width': width,
"                \ 'height': height }

"     let win = nvim_open_win(nvim_create_buf(v:false, v:true), v:true, opts)
"     call setwinvar(win, '&winhighlight', 'NormalFloat:Normal')
"   endfunction

"   let g:fzf_layout = { 'window': 'call FloatingFZF()' }
" endif

" command! -bang -nargs=? -complete=dir Files
"   \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

" " nnoremap <silent> <Leader><Leader> :Files<CR>
" nnoremap <silent> <expr> <Leader><Leader> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":Files\<cr>"
