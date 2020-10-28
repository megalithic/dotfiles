if has('nvim')
  " let g:fzf_layout = { 'down': '~15%', 'window': { 'width': 0.6, 'height': 0.5, 'highlight': 'Todo', 'border': 'rounded' } }
  let g:fzf_layout = { 'down': '~15%' }
  let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.5 } }
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
  nnoremap <silent><leader>m  :Files<CR>
  " nnoremap <silent><leader>m  <cmd>lua require'telescope.builtin'.find_files{}<CR>
  nnoremap <leader>a          :Rg<Space>
  nnoremap <silent><leader>A  <ESC>:exe('Rg '.expand('<cword>'))<CR>

  " nnoremap <leader>a          <cmd>lua require'telescope.builtin'.grep_string{}
  " nnoremap <silent><leader>A  <cmd>lua require'telescope.builtin'.live_grep{}

  " Mapping selections for various modes.
  nmap <Space>! <Plug>(fzf-maps-n)
  omap <Space>! <Plug>(fzf-maps-o)
  xmap <Space>! <Plug>(fzf-maps-x)
  imap <C-x>!   <Plug>(fzf-maps-i)

  " https://github.com/junegunn/dotfiles/blob/master/vimrc#L1648
  " Terminal buffer options for fzf
  autocmd! FileType fzf
  autocmd  FileType fzf set noshowmode noruler nonu

  " https://github.com/pwntester/dotfiles/blob/master/config/nvim/plugins.vim#L273-L286
  let g:nvim_lsp_code_action_menu = 'FZFCodeActionMenu'
  function! FZFCodeActionMenu(actions, callback) abort
    call fzf#run(fzf#wrap({
          \ 'source': map(deepcopy(a:actions), {idx, item -> string(idx).'::'.item.title}),
          \ 'sink': function('ApplyAction', [a:callback]),
          \ 'options': '+m --with-nth 2.. -d "::"',
          \ }))
  endfunction
  function! ApplyAction(callback, chosen) abort
    let l:idx = split(a:chosen, '::')[0] + 1
    execute 'call '.a:callback.'('.l:idx.')'
  endfunction


  function! GetColorFromHighlight(hl, element) abort
    return synIDattr(synIDtrans(hlID(a:hl)), a:element.'#')
  endfunction

  let cobalt1_color = GetColorFromHighlight('Normal', 'bg')
  let cobalt2_color = GetColorFromHighlight('EndOfBuffer', 'fg')
  let blue_color = GetColorFromHighlight('Comment', 'fg')
  let yellow_color = GetColorFromHighlight('Function', 'fg')
  let green_color = GetColorFromHighlight('Title', 'fg')
  let grey_color = GetColorFromHighlight('PMenu', 'fg')
  let orange_color = GetColorFromHighlight('Identifier', 'fg')

  " nnoremap <silent> <leader>R :call <SID>RgCurrentWord()<CR>
  " function! s:RgCurrentWord()
  "   let @/ = ''
  "   let wordUnderCursor = expand("<cword>")
  "   execute 'Rg '. wordUnderCursor
  " endfunction

  vnoremap <silent> <leader>A :call <SID>RgCurrentSelected()<CR>
  function! s:RgCurrentSelected()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
      return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    let currentSelected = join(lines, "\n")
    execute 'Rg '. currentSelected
  endfunction

  " let g:fzf_layout = { 'window': 'lua require("window").floating_window(false, 0.6, 0.6)' }
  " let $FZF_DEFAULT_OPTS='--no-inline-info --layout=reverse --margin=1,2 --color=dark '.
  "       \ '--color=fg:'.grey_color.',bg:'.cobalt1_color.',hl:'.blue_color.' '.
  "       \ '--color=fg+:'.yellow_color.',bg+:'.cobalt1_color.',hl+:'.yellow_color.' '.
  "       \ '--color=marker:'.green_color.',spinner:'.orange_color.',header:'.blue_color.' '.
  "       \ '--color=info:'.cobalt1_color.',prompt:'.blue_color.',pointer:'.blue_color

  " nnoremap <leader>m :call fzf#vim#files('.', {'options': '--prompt ""'})<Return>
  " nnoremap <leader>f :call fzf#vim#files('.', {'options': '--prompt ""'})<Return>
  " nnoremap <leader>h :FZFFreshMru --prompt ""<Return>
  " nnoremap <leader>c :BCommits<Return>
  " nnoremap <leader>s :Snippets<Return>
  " nnoremap <leader>o :Buffers<Return>
  " nnoremap <leader>/ :call fzf#vim#search_history()<Return>
  " nnoremap <leader>: :call fzf#vim#command_history()<Return>
endif

if has('nvim') && !exists('g:fzf_layout')
  autocmd! FileType fzf
  autocmd  FileType fzf set laststatus=0 noshowmode noruler
        \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
endif
