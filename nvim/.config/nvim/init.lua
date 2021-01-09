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
  local data_dir = {
    mega.cache_dir .. "backup",
    mega.cache_dir .. "session",
    mega.cache_dir .. "swap",
    mega.cache_dir .. "tags",
    mega.cache_dir .. "undo"
  }
  -- Only check once that If cache_dir exists
  -- Then I don't want to check subs dir exists
  if not mega.isdir(mega.cache_dir) then
    os.execute("mkdir -p " .. mega.cache_dir)

    for _, v in pairs(data_dir) do
      if not mega.isdir(v) then
        os.execute("mkdir -p " .. v)
      end
    end
  end

  vim.cmd([[runtime vimrc]])

  -- [ loaders ] ---------------------------------------------------------------

  mega.load("packages", "mega.packages", "activate")
  mega.load("nova", "mega.colors.nova", "activate")
  mega.load("settings", "mega.settings", "activate")
  mega.load("lc", "mega.lc", "activate")
  mega.load("mappings", "mega.mappings", "activate")
  mega.load("autocmds", "mega.autocmds", "activate")
  mega.load("ft", "mega.ft", "setup")
  mega.load("ft", "mega.ft", "trigger_ft")
  mega.load("statusline", "mega.statusline", "activate")
end
