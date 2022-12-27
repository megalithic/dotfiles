-- [ settings ] ----------------------------------------------------------------
-- vim.go.loadplugins = true
vim.g.enabled_plugin = {
  mappings = true,
  autocmds = true,
  megaline = true,
  lsp = true,
  term = true,
  repls = true,
  cursorline = true,
  colorcolumn = true,
  windows = true,
  numbers = true,
  quickfix = true,
  folds = true,
  env = true,
  vscode = false,
  tmux = false,
  winbar = false, -- FIXME: add more!
}
-- vim.cmd([[
--   :luafile ~/.config/nvim/lua/lazyinit.lua
-- ]])

-- disable certain plugins for firenvim
for plugin, _ in pairs(vim.g.enabled_plugin) do
  if not vim.tbl_contains({ "autocmds", "mappings", "quickfix" }, plugin) and vim.g.started_by_firenvim then
    plugin = false
  end
end

vim.g.colorscheme = "rose-pine" -- alts: rose-pine, forestbones, tokyonight-storm
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.notifier_enabled = true
vim.g.debug_enabled = false

-- [ globals ] -----------------------------------------------------------------

_G.mega = {
  fn = {},
  dirs = {},
  mappings = {},
  term = {},
  lsp = {},
  icons = require("mega.icons"),
  ts_ignored_langs = { "svg", "json", "heex", "jsonc" },
  -- original vim.notify: REF: https://github.com/folke/dot/commit/b0f6a2db608cb090b969e2ef5c018b86d11fc4d6
  notify = vim.notify,
}

-- [ loaders ] -----------------------------------------------------------------

require("mega.globals")
require("mega.debug")
require("mega.options")
require("mega.lazy").setup()
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function() mega.colors = require("mega.lush_theme.colors") end,
})
