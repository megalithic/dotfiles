setmetatable(_G, {__index = vim})
_G["mega"] = require("global")

local load = mega.load
local cmd, schedule = vim.cmd, vim.schedule

-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with `mega.inspect`) ->
-- vim.lsp.set_log_level("debug")

-- To execute in :cmd ->
--  :lua <the_command>

-- LSP log location ->
--  `tail -n150 -f $HOME/.config/nvim/lsp.log`
--  :lua vim.cmd('vnew'..vim.lsp.get_log_path())

cmd([[source ~/.vimrc]])

-- [ loaders ] ------------------------------------------------------------- {{{
load("preflight")
load("settings")
load("autocmds")
load("colors").load()
load("mappings")
load("lsp")
load("statusline")
load("ftplugin").setup()
load("ftplugin").trigger_ft()
-- schedule(function() load("ftplugin").setup() end)
-- schedule(function() load("ftplugin").trigger_ft() end)
-- }}}
