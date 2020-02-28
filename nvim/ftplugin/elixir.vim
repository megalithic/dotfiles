echo "elixir."

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


  " https://github.com/janko/vim-test/issues/136 -- modified for my work needs
  function! ElixirUmbrellaTransform(cmd) abort
    if match(a:cmd, 'vpp/') != -1
      return substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color ', '')
    elseif match(a:cmd, 'sims/') != -1
      return substitute(a:cmd, 'mix test \([^/]*/\)\(.*\)', '(cd \1 \&\& mix test --color \2)', '')
    else
      return a:cmd
    end
  endfunction

  let g:test#custom_transformations = {'elixir_umbrella': function('ElixirUmbrellaTransform')}
  let g:test#transformation = 'elixir_umbrella'

  let g:test#elixir#exunit#executable = 'mix test'
endif
