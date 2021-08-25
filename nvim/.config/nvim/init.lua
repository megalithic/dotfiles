_G["mega"] = require("global")

local load = mega.load
local cmd = vim.cmd

cmd("runtime .vimrc")

-- [ debugging ] ----------------------------------------------------------- {{{
--
-- We can set this lower if needed (used in tandem with `mega.inspect`) ->
-- vim.lsp.set_log_level(vim.lsp.log_levels.DEBUG)

-- LSP log location ->
--  `tail -n150 -f $HOME/.cache/nvim/lsp.log`
--  -or-
--  :lua vim.cmd('vnew'..vim.lsp.get_log_path())
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
load("ftplugin").setup()
load("ftplugin").trigger_ft()
--
-- }}}
