" custom test display strategy:
function! TerminalSplit(cmd)
  vert new | set filetype=test | call termopen(['/usr/local/bin/zsh', '-c', a:cmd], {'curwin':1})
endfunction

let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
let g:test#strategy = 'terminal_split'
" let test#strategy = 'dispatch'
" FIXME: do we want to have custom strategies per test scenario? File, Nearest,
" Suite? Maybe using https://github.com/hauleth/asyncdo.vim?
" let test#strategy = {
"   \ 'nearest': 'neovim',
"   \ 'file':    'dispatch',
"   \ 'suite':   'basic',
" \}

let g:test#filename_modifier = ':.'
let g:test#preserve_screen = 0
let g:test#elixir#exunit#executable = 'mix test' " FIXME: this needed?

nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>tt :TestVisit<CR>
nmap <silent> <leader>tn :TestNearest<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> <leader>tv :TestVisit<CR>
nmap <silent> <leader>tP :A<CR>
nmap <silent> <leader>tp :AV<CR>

" give me test error output when using dispatch as test strategy
nmap <silent> <leader>to :copen<CR>
" autocmd QuickFixCmdPost * copen " auto-opens quickfix error window
