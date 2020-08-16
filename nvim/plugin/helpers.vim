
" ┌───────────────────────────────────────────────────────────────────────────┐
" │ FUNCTIONS & HELPERS                                                       │
" │───────────────────────────────────────────────────────────────────────────│
" │                                                                           │
" │ * this file includes functions, their commands, and their keymaps.        │
" │                                                                           │
" └───────────────────────────────────────────────────────────────────────────┘


" --[ flip to the alternate live (*.ex/*.html.leex file) ]---------------------------------------
" Lets you use the :R command to jump between e.g. foo_live.ex and foo_live.html.leex in Phoenix LiveView.
" Inspired by corresponding functionality in vim-rails.
" REF: https://github.com/henrik/dotfiles/blob/master/vim/plugin/related_file_for_phoenix_live_view.vim
function! s:RelatedFileForPhoenixLiveView()
  let l:path = expand("%")
  if l:path =~ "/live/.*\\.ex$"
    let l:rel = substitute(l:path, "\\.ex$", ".html.leex", "")
  elseif l:path =~ "\\.html\\.leex$"
    let l:rel = substitute(l:path, "\\.html\\.leex$", ".ex", "")
  else
    return
  end

  if filereadable(l:rel)
    execute "edit" l:rel
  else
    echoerr "No such related file: " l:rel
  endif
endfunction
au BufNewFile,BufRead */live/*.ex,*.html.leex command! -buffer RL call <SID>RelatedFileForPhoenixLiveView()
au BufNewFile,BufRead */live/*.ex,*.html.leex nnoremap <silent> <leader>el :RL<CR>


" --[ open current buffer with some Elixir boilerplate ]---------------------------------------
" :Lab to open an Elixir buffer with some boilerplate to experiment with stuff.
" By Henrik Nyh <http://henrik.nyh.se> under the MIT license.
command! Lab call <SID>Lab()
function! s:Lab()
  tabe
  set filetype=elixir

  " Make it a scratch (temporary) buffer.
  setlocal buftype=nofile bufhidden=wipe noswapfile

  " Close on q.
  "map <buffer> q ZZ

  " Some boilerplate please.
  " Lab + Run so you can e.g. implement a macro in Lab and require it in Run.
  call append(0, ["defmodule Lab do", "end", "", "defmodule Run do", "  def run do", "  end", "end", "", "Run.run"])

  " Delete blank line at end.
  $d

  " Jump to first line.
  1
endfunction


" --[ run the current buffer as Elixir ]---------------------------------------
" <leader>,r to run the current buffer as Elixir (even if it's not written to a file).
" Only enabled when the filetype is 'elixir'.
"
" By Henrik Nyh 2015-06-24 under the MIT license.
command! RunElixir call <SID>RunElixir()
function! s:RunElixir()
  exe "! elixir -e " . shellescape(join(getline(1, "$"), "\n"), 1)
endfunction
au! FileType elixir map <buffer> <leader>ee :RunElixir<CR>



" --[ execute the current line (vim and elm supported) ]---------------------------------------
command! Executor call <SID>executor()
function! s:executor() abort
  if &ft == 'lua'
    call execute(printf(":lua %s", getline(".")))
  elseif &ft == 'vim'
    exe getline(">")
  endif
endfunction
" nnoremap <leader>x :call <SID>executor()<CR>


" --[ execute the current file (vim and lua supported) ]---------------------------------------
command! SaveExec call <SID>save_and_exec()
function! s:save_and_exec() abort
  if &filetype == 'vim'
    :silent! write
    :source %
  elseif &filetype == 'lua'
    :silent! write
    :luafile %
  endif

  return
endfunction
nmap <leader>x :call <SID>save_and_exec()<CR>


" --[ launch repl for elixir project ]---------------------------------------
" -- - sets up an IEx session with or without mix support based upon existence
function! s:iex_for_project() abort
  let l:root = findfile('mix.exs', expand('%:p:h').';')
  if !empty(glob(l:root))
    " echo "-> mix " .. glob(l:root)
    " echohl Comment | echom printf('iex -S mix (%s)', l:root) | echohl None
    :25 Repl iex -S mix
  else
    " echo "-> no mix " .. glob(l:root)
    " echohl Comment | echom printf('iex (%s)', l:root) | echohl None
    :25 Repl iex
  endif
endfunction
autocmd! FileType elixir,eelixir nnoremap <silent> <buffer> <leader>er :call <SID>iex_for_project()<CR>


" --[ launch repl for elm project ]---------------------------------------
function! s:elm_repl_for_project() abort
  let l:root = finddir('.git/..', expand('%:p:h').';')

  if !empty(glob(l:root .. "/elm.json"))
    echohl Comment | echom printf('elm repl (%s)', l:root) | echohl None
    :Repl elm repl
  else
    echohl Comment | echom printf('elm_repl (%s)', l:root) | echohl None
    :Repl elm_repl
  endif
endfunction

autocmd! FileType elm nnoremap <silent> <buffer> <leader>er :call <SID>elm_repl_for_project()<CR>
