augroup ft_elixir
  au!

  nnoremap <silent> <buffer> <leader>ed orequire IEx; IEx.pry<ESC>:w<CR>
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

  " sets up an IEx session with or without mix support based upon existence
  function! s:iex_for_project() abort
    let l:root = findfile('mix.exs', expand('%:p:h').';')
    echo "Attempting to find root for IEx execution: " .. l:root

    if !empty(glob(l:root))
      echo "-> mix " .. glob(l:root)
      echohl Comment | echom printf('iex -S mix (%s)', l:root) | echohl None
      :Repl iex -S mix
    else
      echo "-> no mix " .. glob(l:root)
      echohl Comment | echom printf('iex (%s)', l:root) | echohl None
      :Repl iex
    endif
  endfunction

  " NOTE: presently failing silently. :(
  nnoremap <silent> <buffer> <leader>er :call <SID>iex_for_project()<CR>

  nmap <silent> <leader>tf :let g:elixir_test_nearest=0<CR>\|:TestFile<CR>
  nmap <silent> <leader>tt :let g:elixir_test_nearest=0<CR>\|:TestVisit<CR>
  nmap <silent> <leader>tn :let g:elixir_test_nearest=1<CR>\|:TestNearest<CR>
  " nnoremap <silent> <leader>tn :let g:exlixir_test_nearest=v:true | TestNearest
  nmap <silent> <leader>tl :let g:elixir_test_nearest=0<CR>\|:TestLast<CR>
  nmap <silent> <leader>tv :let g:elixir_test_nearest=0<CR>\|:TestVisit<CR>
  " not quite working with elixir in vim-test
  nmap <silent> <leader>ta :let g:elixir_test_nearest=0<CR>\|:TestSuite --only-failures<CR>

  " https://github.com/janko/vim-test/issues/136 -- modified for my work needs
  function! ElixirUmbrellaTransform(cmd) abort
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
      if g:elixir_test_nearest == 1
      return a:cmd .. ":" .. line(".")
    else
      return a:cmd
    end
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

  " :Lab to open an Elixir buffer with some boilerplate to experiment with stuff.
  " By Henrik Nyh <http://henrik.nyh.se> under the MIT license.
  function! s:Lab()
    tabe
    set filetype=elixir

    " Make it a scratch (temporary) buffer.
    "setlocal buftype=nofile bufhidden=wipe noswapfile

    " Close on q.
    "map <buffer> q ZZ

    " Some boilerplate please.
    " Lab + Run so you can e.g. implement a macro in Lab and require it in Run.
    let @x = "defmodule Lab do\nend\n\ndefmodule Run do\n  def run do\n  end\nend\n\nRun.run"
    -1put x

    " Delete blank line at end.
    $d

    " Jump to first line.
    1
  endfunction
  command! Lab call <SID>Lab()

  " <leader>,r to run the current buffer as Elixir (even if it's not written to a file).
  " Only enabled when the filetype is 'elixir'.
  "
  " By Henrik Nyh 2015-06-24 under the MIT license.
  command! RunElixir call <SID>RunElixir()
  function! s:RunElixir()
    exe "! elixir -e " . shellescape(join(getline(1, "$"), "\n"), 1)
  endfunction

  au BufNewFile,BufRead */live/*.ex,*.html.leex command! -buffer R call <SID>RelatedFileForPhoenixLiveView()
  au BufNewFile,BufRead */live/*.ex,*.html.leex nnoremap <silent> <buffer> <leader>eR :call <SID>RelatedFileForPhoenixLiveView()<CR>
  au FileType elixir map <buffer> <leader>r :RunElixir<CR>
augroup END
