_G["mega"] = require("mega.global")

vim.cmd [[packadd vimball]]

-- [ debugging ] ---------------------------------------------------------------

-- Can set this lower if needed (used in tandem with `mega.inspect`) ->
--  vim.lsp.set_log_level("debug")

-- To execute in :cmd ->
--  :lua <the_command>

-- LSP log location ->
--  `tail -n150 -f $HOME/.config/nvim/lsp.log`

do
  vim.cmd([[runtime .vimrc]])

  -- [ loaders ] ---------------------------------------------------------------

  mega.load("preflight", "mega.preflight")
  mega.load("packages", "mega.packages")
  mega.load("nova", "mega.colors.nova").load()
  -- mega.load("zephyr", "mega.colors.zephyr").load()
  -- mega.load("nova", "mega.colors.edge").load()
  -- mega.load("gruvbox_material", "mega.colors.gruvbox_material").load()
  mega.load("settings", "mega.settings")
  mega.load("lc", "mega.lc")
  mega.load("mappings", "mega.mappings")
  mega.load("autocmds", "mega.autocmds")
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
  mega.load("statusline", "mega.statusline")
end
