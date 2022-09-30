-- REF:
-- running tests in iex:
-- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar

vim.cmd([[setlocal iskeyword+=!,?]])

nnoremap("<leader>ed", [[orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>]])
nnoremap("<leader>ep", [[o|><ESC>a]])
nnoremap("<leader>ei", [[o|> IO.inspect()<ESC>i]])
nnoremap("<leader>eil", [[o|> IO.inspect(label: "")<ESC>hi]])
inoremap("<leader>eil", [[o|> <ESC>a]])
inoremap("<leader>ei", [[o|> IO.inspect()<ESC>i]])
inoremap("<leader>eil", [[o|> IO.inspect(label: "")<ESC>hi]])

vim.cmd([[iabbrev ep    \|>]])
vim.cmd([[iabbrev epry  require IEx; IEx.pry]])
vim.cmd([[iabbrev ei    IO.inspect]])
vim.cmd([[iabbrev eputs IO.puts]])

-- get back matchit things for elixir (from elixir.vim)
-- https://github.com/elixir-editors/vim-elixir/blob/master/ftplugin/elixir.vim#L6-L16
vim.cmd([[
  " Matchit support
  if exists('loaded_matchit') && !exists('b:match_words')
    let b:match_ignorecase = 0

    let b:match_words = '\:\@<!\<\%(do\|fn\)\:\@!\>' .
          \ ':' .
          \ '\<\%(else\|elsif\|catch\|after\|rescue\)\:\@!\>' .
          \ ':' .
          \ '\:\@<!\<end\>' .
          \ ',{:},\[:\],(:)'
  endif
]])

mega.augroup("FtPluginElixir", {
  {
    event = { "User" },
    pattern = { "ProjectionistDetect" },
    command = function(args)
      vim.cmd([[
        let s:base_dir = resolve(expand("<sfile>:p:h"))
        let s:proj_jsn = s:base_dir . "/elixir_projectionist.json"
        let l:json = readfile(s:proj_jsn)
        let l:dict = projectionist#json_parse(l:json)
        call projectionist#append(getcwd(), l:dict)

        echo "elixir_projectionist loaded.."
      ]])
    end,
  },
})
