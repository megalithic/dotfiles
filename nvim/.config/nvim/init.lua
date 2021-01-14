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

vim.cmd [[packadd vimball]]

_G["mega"] = require("mega.global")

-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with mega.inspect) ->
-- require('vim.lsp.log').set_level("trace")
-- require("vim.lsp.log").set_level("debug")

-- To execute in :cmd ->
--  :lua <the_command>

-- LSP log location ->
--  `tail -n150 -f $HOME/.local/share/nvim/lsp.log`

-- [ engage! ] ---------------------------------------------------------------

do
  vim.cmd([[runtime vimrc]])

  -- [ loaders ] ---------------------------------------------------------------

  mega.load("preflight", "mega.preflight").activate()
  mega.load("packages", "mega.packages").activate()
  mega.load("nova", "mega.colors.nova").activate()
  mega.load("settings", "mega.settings").activate()
  mega.load("lc", "mega.lc").activate()
  mega.load("mappings", "mega.mappings").activate()
  mega.load("autocmds", "mega.autocmds").activate()
  vim.schedule(
    function()
      mega.load("ft", "mega.ft").setup()
    end
  )
  vim.schedule(
    function()
      mega.load("ft", "mega.ft").trigger_ft()
    end
  )
  mega.load("statusline", "mega.statusline").activate()
end
