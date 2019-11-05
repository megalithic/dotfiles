nnoremap <silent> <buffer> <leader>ed orequire IEx; IEx.pry<ESC>:w<CR>
nnoremap <silent> <buffer> <leader>ep o\|> <ESC>a
nnoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
nnoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi
inoremap <silent> <buffer> <leader>ep o\|> <ESC>a
inoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
inoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi

iabbrev epry  require IEx; IEx.pry
iabbrev ep    \|>
iabbrev ei    IO.inspect
iabbrev eputs IO.puts

if has('nvim')
  function! s:iex_for_project() abort
    echo "HERE WE GO with an iex for the project"

    let l:root = finddir('.git/..', expand('%:p:h').';')

    if !empty(glob(l:root .. "/mix.exs"))
      echohl Comment | echom printf('iex -S mix (%s)', l:root) | echohl None
      :Repl iex -S mix
    else
      echohl Comment | echom printf('iex (%s)', l:root) | echohl None
      :Repl iex
    endif
  endfunction

  nnoremap <silent> <buffer> <leader>er :call <SID>iex_for_project()<CR>
endif

let g:test#transformation = 'elixir'
