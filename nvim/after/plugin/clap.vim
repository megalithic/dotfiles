" vim-clap config (TODO: move to its own module)
if has('nvim')
  let &l:scroll *= 2

  let g:clap_theme = 'nord'
  let g:clap_open_action = { 'ctrl-t': 'tab split', 'ctrl-x': 'split', 'ctrl-v': 'vsplit', 'enter': 'vsplit', 'cr': 'vsplit' }
  let g:clap_layout = { 'relative': 'editor' }

  function! s:clap_mappings()
    " inoremap <silent> <buffer> <Esc>   <C-R>=clap#navigation#linewise('down')<CR><C-R>=clap#navigation#linewise('up')<CR><Esc>
    " inoremap <silent> <buffer> jj      <C-R>=clap#navigation#linewise('down')<CR><C-R>=clap#navigation#linewise('up')<CR><Esc>
    " inoremap <silent> <buffer> <Tab>   <C-R>=clap#navigation#linewise('down')<CR>
    " inoremap <silent> <buffer> <S-Tab> <C-R>=clap#navigation#linewise('up')<CR>

    " nnoremap <silent> <buffer> <C-f> :<c-u>call clap#navigation#scroll('down')<CR>
    " nnoremap <silent> <buffer> <C-b> :<c-u>call clap#navigation#scroll('up')<CR>
    " nnoremap <silent> <buffer> <nowait>' :call clap#handler#tab_action()<CR>

    " nnoremap <silent> <buffer> sg  :<c-u>call clap#handler#try_open('ctrl-v')<CR>
    " nnoremap <silent> <buffer> sv  :<c-u>call clap#handler#try_open('ctrl-x')<CR>
    " nnoremap <silent> <buffer> st  :<c-u>call clap#handler#try_open('ctrl-t')<CR>

    " nnoremap <silent> <buffer> q     :<c-u>call clap#handler#exit()<CR>
    " nnoremap <silent> <buffer> <Esc> :call clap#handler#exit()<CR>
    " nnoremap <silent> <buffer> <C-c> :call clap#handler#exit()<CR>

    " Exit clap with esc rather than going to normal mode
    inoremap <silent><buffer> <Esc> <Esc>:call clap#handler#exit()<CR>
    inoremap <silent><buffer> <C-c> <Esc>:call clap#handler#exit()<CR>
    inoremap <silent><buffer> <Esc> <Esc>:<C-U>call clap#handler#exit()<CR>
    inoremap <silent><buffer> <C-c> <Esc>:<C-U>call clap#handler#exit()<CR>
    inoremap <silent><buffer> <Esc> <C-O>:<C-u>call clap#handler#exit() <Bar> stopinsert<CR>
  endfunction

  augroup clap
    autocmd!
    autocmd FileType clap_input call s:clap_mappings()

    " " Exit clap with esc rather than going to normal mode
    " autocmd FileType clap_input inoremap <silent><buffer> <Esc> <Esc>:call clap#handler#exit()<CR>
    " autocmd FileType clap_input inoremap <silent><buffer> <C-c> <Esc>:call clap#handler#exit()<CR>
    " autocmd FileType clap_input inoremap <silent><buffer> <Esc> <Esc>:<C-U>call clap#handler#exit()<CR>
    " autocmd FileType clap_input inoremap <silent><buffer> <C-c> <Esc>:<C-U>call clap#handler#exit()<CR>

    " autocmd FileType clap_input inoremap <silent><buffer> <Esc> <C-O>:<C-u>call clap#handler#exit() <Bar> stopinsert<CR>

    " " Use <C-O> to goto normal mode
    " inoremap <silent><buffer> <C-O> <Esc>

    " " Press <Esc> to exit
    " nnoremap <silent><buffer> <Esc> :call clap#handler#exit()<CR>
    " inoremap <silent><buffer> <Esc> <Esc>:<C-U>call clap#handler#exit()<CR>
  augroup END

  nnoremap <silent> <leader>ff      :Clap files<CR>
  nnoremap <leader>fr               :Clap grep<CR>
  nnoremap <leader>fR               :Clap grep ++query=<cword><CR>

  " nnoremap <silent> <leader>a      :Clap grep<CR>

  " nnoremap <silent> <leader>a :Clap grep<Space>
  " nnoremap <silent> <leader>A  <ESC>:exe('Clap grep '.expand('<cword>'))<CR>
  " vnoremap <silent> <leader>A  <ESC>:exe('Clap grep '.expand('<cword>'))<CR>
endif
