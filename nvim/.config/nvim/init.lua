_G["mega"] = require("global")

local load = mega.load
local cmd = vim.cmd

cmd("runtime .vimrc")

-- [ debugging ] ----------------------------------------------------------- {{{
-- Can set this lower if needed (used in tandem with `mega.inspect`) ->
-- vim.lsp.set_log_level("debug")

-- To execute in :cmd ->
--  :lua <the_command>

-- LSP log location ->
--  `tail -n150 -f $HOME/.config/nvim/lsp.log`
--  :lua vim.cmd('vnew'..vim.lsp.get_log_path())
-- }}}

-- [ loaders ] ------------------------------------------------------------- {{{
load("preflight")
load("colors").setup()
load("settings")
load("lsp")
load("autocmds")
load("mappings")
load("statusline")
load("ftplugin").setup()
load("ftplugin").trigger_ft()
-- }}}
