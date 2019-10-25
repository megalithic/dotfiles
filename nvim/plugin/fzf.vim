" let g:fzf_layout = { "window": "silent botright 16split vnew" }
let g:fzf_layout = { 'down': '~15%' }
" let g:fzf_layout = { 'window': 'call FloatingFZF()' }
let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit',
      \ 'enter': 'vsplit'
      \ }
let g:fzf_commits_log_options = '--graph --color=always
      \ --format="%C(yellow)%h%C(red)%d%C(reset)
      \ - %C(bold green)(%ar)%C(reset) %s %C(blue){%an}%C(reset)"'

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
noremap <Space>/ :Rg<Space>
noremap <leader>a :Rg<Space>
" Mapping selections for various modes.
nmap <Space>! <Plug>(fzf-maps-n)
omap <Space>! <Plug>(fzf-maps-o)
xmap <Space>! <Plug>(fzf-maps-x)
imap <C-x>!   <Plug>(fzf-maps-i)

" if filereadable('config/routes.rb')
"     " This looks like a Rails app.
"     nnoremap <silent> <Space>ec :Files app/controllers<CR>
"     nnoremap <silent> <Space>eh :Files app/helpers<CR>
"     nnoremap <silent> <Space>em :Files app/models<CR>
"     nnoremap <silent> <Space>es :Files app/assets/stylesheets<CR>
"     nnoremap <silent> <Space>et :Files spec<CR>
"     nnoremap <silent> <Space>ev :Files app/views<CR>
" elseif filereadable('src/index.js')
"     " This looks like a React app.
"     nnoremap <silent> <Space>ec :Files src/components<CR>
"     nnoremap <silent> <Space>es :Files src/styles<CR>
"     nnoremap <silent> <Space>et :Files src/__tests__/components<CR>
" endif

" UltiSnips is a slow plugin to load, hence, only load it on demand once fuzzy
" snippet searching has been selected.
"
function! LoadUltiSnipsAndFuzzySearch()
  execute plug#load('ultisnips')
  :Snippets
  return ""
endfunction

function! FloatingFZF()
  let buf = nvim_create_buf(v:false, v:true)
  call setbufvar(buf, '&signcolumn', 'no')

  let width = float2nr(&columns - (&columns * 2 / 10))
  let height = 35

  let col = float2nr((&columns - width) / 2)
  let row = float2nr((&lines - height) / 2)

  let opts = {
        \ 'relative': 'editor',
        \ 'row': row,
        \ 'col': col,
        \ 'width': width,
        \ 'height': height
        \ }

  let win = nvim_open_win(buf, v:true, opts)
  call setwinvar(win, '&number', 0)
  call setwinvar(win, '&relativenumber', 0)
endfunction
