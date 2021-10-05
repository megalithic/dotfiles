-- [ lua runtime ] ----------------------------------------------------------- {{{
-- REF: https://github.com/neovim/neovim/pull/14686#issue-907487329
--
-- order:
-- colors [first]
-- compiler [first]
-- ftplugin [all]
-- ftdetect [all | ran at startup or packadd]
-- indent [all]
-- plugin [all | ran at startup or packadd]
-- syntax [all]

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
