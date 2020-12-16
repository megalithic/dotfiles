-- ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
--
--   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
--   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: DOTFILES > nvim/init.vim
--   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
--   Brought to you by: Seth Messer / @megalithic
--
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
--
-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │                                                                           │
-- │ Setup for Lua-based plugins                                               │
-- │ --> REF: https://github.com/nanotee/nvim-lua-guide                        │
-- │                                                                           │
-- └───────────────────────────────────────────────────────────────────────────┘

_G["mega"] = require("mega.global")

-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with mega.inspect) ->
-- require('vim.lsp.log').set_level("trace")
-- require("vim.lsp.log").set_level("debug")

-- To execute in :cmd ->
--  :lua <the_command>

-- LSP log location ->
--  `tail -n150 -f $HOME/.local/share/nvim/lsp.log`

do
  -- [ leader ] ---------------------------------------------------------------
  -- mega.map('n', '<Space>', '', {})
  -- mega.map("n", ",", "", {})
  -- vim.g.mapleader = ","
  -- vim.g.maplocalleader = ","

  vim.cmd([[runtime vimrc]])

  -- [ loaders ] ---------------------------------------------------------------
  mega.load("packages", "mega.packages", "activate")
  mega.load("nova", "mega.colors.nova", "activate")
  mega.load("settings", "mega.settings", "activate")
  mega.load("lc", "mega.lc", "activate")
  mega.load("keymaps", "mega.keymaps", "activate")
  mega.load("autocmds", "mega.autocmds", "activate")
  mega.load("ft", "mega.ft", "setup")
  mega.load("ft", "mega.ft", "trigger_ft")
  mega.load("statusline", "mega.statusline", "activate")
end
