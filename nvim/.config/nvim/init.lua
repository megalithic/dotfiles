-- [ lua runtime ] ----------------------------------------------------------- {{{
-- REF: https://github.com/neovim/neovim/pull/14686#issue-907487329
-- colors [First found]
-- compiler [First found]
-- ftplugin [All]
-- ftdetect [All | Ran at startup or packadd]
-- indent [All]
-- plugin [All | Ran at startup or packadd]
-- syntax [All]

-- vim.cmd([[
-- " Intelligently navigate tmux panes and Vim splits using the same keys.
-- " See https://sunaku.github.io/tmux-select-pane.html for documentation.

-- let progname = substitute($VIM, '.*[/\\]', '', '')
-- set title titlestring=%{progname}\ %f\ +%l\ #%{tabpagenr()}.%{winnr()}
-- if &term =~ '^screen' && !has('nvim') | exe "set t_ts=\e]2; t_fs=\7" | endif
-- ]])

_G["mega"] = require("global")

local load = mega.load
local cmd = vim.cmd

cmd("runtime .vimrc")

-- [ debugging ] ----------------------------------------------------------- {{{
--
-- We can set this lower if needed (used in tandem with `mega.inspect`) ->
-- vim.lsp.set_log_level(vim.log.levels.DEBUG)

-- LSP/efm log locations ->
--  `tail -n150 -f $HOME/.cache/nvim/lsp.log`
--  `tail -n150 -f $HOME/.cache/nvim/efm-lsp.log`
--  -or-
--  :lua vim.cmd('vnew '..vim.lsp.get_log_path())
--  -or-
--  :LspLog
--
-- }}}

-- [ loaders ] ------------------------------------------------------------- {{{
--
load("preflight")
load("colors").setup()
load("settings")
load("lsp")
load("autocmds")
load("mappings")
load("megaline")
--
-- }}}
