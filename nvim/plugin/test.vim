" custom test display strategy:
function! TerminalSplit(cmd)
  vert new | set filetype=test | call termopen(['/usr/local/bin/zsh', '-c', a:cmd], {'curwin':1})
endfunction

let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
let g:test#strategy = 'terminal_split'


" custom transform for different filetypes/test-runners
function! ElixirUmbrellaTransform(cmd) abort
  if match(a:cmd, 'vpp/') != -1
    echo "match(a:cmd, 'vpp/') != -1 -> " .. substitute(a:cmd, 'mix test vpp/apps/\([^/]*/\)\(.*\)', '(cd vpp/apps/\1 \&\& mix test \2)', '')
    return substitute(a:cmd, 'mix test vpp/apps/\([^/]*/\)\(.*\)', '(cd vpp/apps/\1 \&\& mix test \2)', '')
  elseif match(a:cmd, 'sims/') != -1
    echo "match(a:cmd, 'sims/') != -1 -> " .. a:cmd .. " -> " .. substitute(a:cmd, 'mix test \([^/]*/\)\(.*\)', '(cd \1 \&\& mix test \2)', '')
    return substitute(a:cmd, 'mix test sims/\([^/]*/\)\(.*\)', '(cd sims/\1 \&\& mix test \2)', '')
  else
    echo "else -> " .. a:cmd
    return a:cmd
  end
endfunction

let g:test#custom_transformations = {
      \ 'elixir': function('ElixirUmbrellaTransform'),
      \ }
" TODO: should it be this? function('<SID>ElixirUmbrellaTransform')

let g:test#filename_modifier = ':.'
let g:test#preserve_screen = 0
let g:test#elixir#exunit#executable = 'mix test'
" let g:test#javascript#cypress#file_pattern = '\v(__tests__/.*|(spec|test))\.(js|jsx|coffee|ts|tsx)$'

nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>tt :TestVisit<CR>
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> <leader>tv :TestVisit<CR>
nmap <silent> <leader>tP :A<CR>
nmap <silent> <leader>tp :AV<CR>
" ref: https://github.com/Dkendal/dot-files/blob/master/nvim/.config/nvim/init.vim
