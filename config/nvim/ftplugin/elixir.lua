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
