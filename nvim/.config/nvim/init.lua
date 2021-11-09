-- [ lua runtime ] --------------------------------------------------------- {{{
--
-- REF: https://github.com/neovim/neovim/pull/14686#issue-907487329
--
-- order of operations:
--
-- colors [first]
-- compiler [first]
-- ftplugin [all]
-- ftdetect [all | ran at startup or packadd]
-- indent [all]
-- plugin [all | ran at startup or packadd]
-- syntax [all]
--
-- }}}

-- [ assigns ] ------------------------------------------------------------- {{{
--
_G["mega"] = require("global")
local load = mega.load
local cmd = vim.cmd
--
-- }}}

-- [ speed ] --------------------------------------------------------------- {{{
--
local ok, impatient = load("impatient", { safe = true })
if ok then
  impatient.enable_profile()
end
--
-- }}}

-- [ plain old vim ] ------------------------------------------------------- {{{
--
-- TODO: migrate to lua?
cmd("runtime .vimrc")
--
-- }}}

-- [ debugging ] ----------------------------------------------------------- {{{
--
-- Discover runtime files (change path) ->
--  :lua mega.dump(vim.api.nvim_get_runtime_file('ftplugin/**/*.lua', true))
--
-- Debug LSP traffic ->
-- vim.lsp.set_log_level("trace")
-- if vim.fn.has("nvim-0.5.1") == 1 then
--   require("vim.lsp.log").set_format_func(vim.inspect)
-- end
--
-- LSP/efm log locations ->
--  `tail -n150 -f $HOME/.cache/nvim/lsp.log`
--  `tail -n150 -f $HOME/.cache/nvim/efm-lsp.log`
--  -or-
--  :lua vim.cmd('vnew'..vim.lsp.get_log_path())
--  -or-
--  :LspLog
--
-- }}}

-- [ loaders ] ------------------------------------------------------------- {{{
--
load("preflight")
load("colors").setup("megaforest")
load("settings")
load("lsp")
load("autocmds")
load("mappings")
load("megaline")
--
-- }}}
