" Usages of Nuake and other elixir things
" REF: https://github.com/alexcastano/dotfiles/blob/master/vim/.vim/vimrc#L402-L418
augroup ft_elixir
  au!

  nnoremap <silent> <buffer> <leader>ed orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>
  nnoremap <silent> <buffer> <leader>ep o\|> <ESC>a
  nnoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
  nnoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi
  inoremap <silent> <buffer> <leader>ep o\|> <ESC>a
  inoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
  inoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi

  " NOTE: use ctrl-] to complete without adding the space, otherwise just use
  " space to complete the `iabbrev` expansions.
  iabbrev epry  require IEx; IEx.pry
  iabbrev ep    \|>
  iabbrev ei    IO.inspect
  " iabbrev ei    IO.inspect<c-o>:call getchar()<CR>
  iabbrev eputs IO.puts

  nmap <silent> <leader>tf :let g:elixir_test_nearest=0<CR>\|:TestFile --trace<CR>
  nmap <silent> <leader>tt :let g:elixir_test_nearest=0<CR>\|:TestVisit<CR>
  nmap <silent> <leader>tn :let g:elixir_test_nearest=1<CR>\|:TestNearest<CR>
  nmap <silent> <leader>tl :let g:elixir_test_nearest=0<CR>\|:TestLast<CR>
  nmap <silent> <leader>tv :let g:elixir_test_nearest=0<CR>\|:TestVisit<CR>

  " not quite working with elixir in vim-test
  nmap <silent> <leader>ta :let g:elixir_test_nearest=0<CR>\|:TestSuite<CR>
  " nmap <silent> <leader>ta :let g:elixir_test_nearest=0<CR>\|:TestSuite --only-failures<CR>

  " https://github.com/janko/vim-test/issues/136
  " -- modified for my work needs (sims, blech) and handles generic case.
  function! ElixirUmbrellaTransform(cmd) abort
    " echom "a:cmd -> " . a:cmd

    " if a:cmd =~ ':\d+'
    "   echo "is_nearest mode"
    " else
    "   echo "not is_nearest mode"
    " endif


    if match(a:cmd, 'vpp/') != -1
      if g:elixir_test_nearest == 1
        return substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color \2', '') .. ":" .. line(".")
      else
        return substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color \2', '')
      end

    elseif match(a:cmd, 'sims/') != -1
      if g:elixir_test_nearest == 1
        return substitute(a:cmd, 'mix test \([^/]*/\)\(.*\)', '(cd \1 \&\& mix test --color \2)', '') .. ":" .. line(".")
      else
        return substitute(a:cmd, 'mix test \([^/]*/\)\(.*\)', '(cd \1 \&\& mix test --color \2)', '')
      end
    else
      " if g:elixir_test_nearest == 1
      " return a:cmd .. ":" .. line(".")
      " else
      " return a:cmd
      let s:cmd = substitute(a:cmd, 'mix test', 'mix test --color', '')
      " echom "s:cmd -> " . s:cmd

      return s:cmd
      " end
    end
  endfunction
  let g:test#custom_transformations = {'elixir_umbrella': function('ElixirUmbrellaTransform')}
  let g:test#transformation = 'elixir_umbrella'

  " REF: https://nts.strzibny.name/elixir-interactive-shell-iex/#inspecting-failing-tests
  " let test#elixir#exunit#executable = "mix test --trace"
  " let test#elixir#exunit#executable = "MIX_ENV=test mix test"

  let test#elixir#exunit#executable = "mix test"
  let test#elixir#exunit#options = '--stale'
  let test#elixir#exunit#options = {
        \ 'suite':   '--stale',
        \}
augroup END
