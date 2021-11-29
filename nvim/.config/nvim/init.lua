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

--[ debugging ] ----------------------------------------------------------------

   Discover runtime files (change path) ->
    :lua mega.dump(vim.api.nvim_get_runtime_file('ftplugin/**/*.lua', true))

   Debug LSP traffic ->
   vim.lsp.set_log_level("trace")
   if vim.fn.has("nvim-0.5.1") == 1 then
     require("vim.lsp.log").set_format_func(vim.inspect)
   end

   LSP/efm log locations ->
    `tail -n150 -f $HOME/.cache/nvim/lsp.log`
    `tail -n150 -f $HOME/.cache/nvim/efm-lsp.log`
    -or-
    :lua vim.cmd('vnew'..vim.lsp.get_log_path())
    -or-
    :LspLog

--]]

-- [ leader bindings ] ---------------------------------------------------------

vim.g.mapleader = "," -- Remap leader to ,
vim.g.maplocalleader = " " -- Remap localleader to <Space>

-- [ loaders ] -----------------------------------------------------------------

local reload_ok, reload = pcall(require, "plenary.reload")
RELOAD = reload_ok and reload.reload_module or function(...)
  return ...
end
function R(name)
  RELOAD(name)
  return require(name)
end

require("globals")

R("preflight")
-- R("options")
R("opts")
R("colors").setup("megaforest")
R("settings")
R("lsp")
R("autocmds")
R("mappings")
R("megaline")
-- R("statusline")

-- vim:foldmethod=marker
