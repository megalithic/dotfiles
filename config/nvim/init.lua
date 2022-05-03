--[[ lua runtime ] -------------------------------------------------------------

   REF: https://github.com/neovim/neovim/pull/14686#issue-907487329

   order of operations:

   colors [first]
   compiler [first]
   ftplugin [all]
   ftdetect [all | ran at startup or packadd]
   indent [all]
   plugin [all | ran at startup or packadd]
   syntax [all]
   after/plugin ?
   after/ftplugin ?
   after/indent ?
   after/syntax ?

   NOTE: paq management and installer are in nvim/lua/mega/plugins.lua

--[ debugging ] ----------------------------------------------------------------

   Discover runtime files (change path) ->
    :lua mega.dump(vim.api.nvim_get_runtime_file('ftplugin/**/*.lua', true))

   Debug LSP traffic ->
    vim.lsp.set_log_level("trace")
    require("vim.lsp.log").set_format_func(vim.inspect)

   LSP/efm log locations ->
    htail -n150 -f $HOME/.cache/nvim/lsp.log`
    `tail -n150 -f $HOME/.cache/nvim/efm-lsp.log`
    -or-
    :lua vim.cmd('vnew '..vim.lsp.get_log_path())
    -or-
    :LspLog

--]]

-- [ speed ] -------------------------------------------------------------------

local impatient_ok, impatient = pcall(require, "impatient")
if impatient_ok then
  impatient.enable_profile()
end

-- [ loaders ] -----------------------------------------------------------------

require("mega.globals")
require("mega.options")
require("mega.plugins").config()
