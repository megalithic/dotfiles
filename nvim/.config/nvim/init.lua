setmetatable(_G, {__index = vim})
_G["mega"] = require("global")

-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with `mega.inspect`) ->
-- vim.lsp.set_log_level("debug")

-- To execute in :cmd ->
--  :lua <the_command>

-- LSP log location ->
--  `tail -n150 -f $HOME/.config/nvim/lsp.log`
--  :lua vim.cmd('vnew'..vim.lsp.get_log_path())

vim.cmd([[source ~/.vimrc]])

-- [ loaders ] ------------------------------------------------------------- {{{
mega.load("preflight")
mega.load("settings")
mega.load("autocmds")
mega.load("mappings")
mega.load("lsp")
vim.schedule(
  function()
    mega.load("ftplugin").setup()
  end
)
vim.schedule(
  function()
    mega.load("ftplugin").trigger_ft()
  end
)
-- }}}
