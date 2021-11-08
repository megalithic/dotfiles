-- REF:
-- running tests in iex:
-- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar

vim.cmd([[setlocal iskeyword+=!,?]])

vim.api.nvim_set_keymap("n", "<leader>etp", ":ToPipe<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>efp", ":FromPipe<CR>", { noremap = true })

vim.api.nvim_exec(
  [[
      set filetype=elixir
  nnoremap <silent> <buffer> <leader>ed orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>
  nnoremap <silent> <buffer> <leader>ep o\|> <ESC>a
  nnoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
  nnoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi
  inoremap <silent> <buffer> <leader>ep o\|> <ESC>a
  inoremap <silent> <buffer> <leader>ei o\|> IO.inspect()<ESC>i
  inoremap <silent> <buffer> <leader>eil o\|> IO.inspect(label: "")<ESC>hi

"au FileType elixir nnoremap io o\|> IO.inspect(printable_limit: :infinity)<Esc>
"au FileType elixir nnoremap IO o\|> IO.inspect(label: "<C-r>=line(".")<C-M>: ", printable_limit: :infinity)<Esc>F"i
"au FileType elixir nnoremap ii a \|> IO.inspect(printable_limit: :infinity)<Esc>i
"au FileType elixir nnoremap II a \|> IO.inspect(label: "<C-r>=line(".")<C-M>: ", printable_limit: :infinity)<Esc>F"i
"au FileType elixir nnoremap <leader>r orequire IEx; IEx.pry<esc>

  " NOTE: use ctrl-] to complete without adding the space, otherwise just use
  " space to complete the `iabbrev` expansions.
  iabbrev epry  require IEx; IEx.pry
  iabbrev ep    \|>
  " iabbrev ei    IO.inspect
  iabbrev ei    IO.inspect\(\)
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
    let sub = ""

    if match(a:cmd, 'vpp/') != -1
      if g:elixir_test_nearest == 1
        let sub = substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color \2', '') .. ":" .. line(".")
        echom "sub in vpp nearest -> " . sub
        return sub
      else
        let sub  = substitute(a:cmd, 'mix test vpp/apps/\([^/]*\)/', 'cd vpp \&\& mix cmd --app \1 mix test --color \2', '')
        echom "sub in vpp NOT nearest -> " . sub
        return sub
      end
    elseif match(a:cmd, 'sims/') != -1
      if g:elixir_test_nearest == 1
        let sub = substitute(a:cmd, 'mix test \([^/]*/\)\(.*\)', '(cd \1 \&\& mix test --color \2)', '') .. ":" .. line(".")
        echom "sub in sims nearest -> " . sub
        return sub
      else
        let sub = substitute(a:cmd, 'mix test \([^/]*/\)\(.*\)', '(cd \1 \&\& mix test --color \2)', '')
        echom "sub in sims NOT nearest -> " . sub
        return sub
      end
    else
      let sub = substitute(a:cmd, 'mix test', 'eval $(desk load); mix test --color', '')
      echom "sub in somewhere else -> " . sub
      return sub
    end
  endfunction

  let g:test#custom_transformations = {'elixir_umbrella': function('ElixirUmbrellaTransform')}
  let g:test#transformation = 'elixir_umbrella'

  " REF: https://nts.strzibny.name/elixir-interactive-shell-iex/#inspecting-failing-tests
  " let test#elixir#exunit#executable = "mix test --trace"
  " let test#elixir#exunit#executable = "MIX_ENV=test mix test"

  let test#elixir#exunit#executable = "mix test"
  " let test#elixir#exunit#options = '--trace'
  " let test#elixir#exunit#options = {
  "       \ 'suite':   '--stale',
  "       \}
      ]],

  true
)
