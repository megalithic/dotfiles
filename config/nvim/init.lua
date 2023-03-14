-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  breadcrumb = false, -- lastplace
  mappings = true,
  autocmds = true,
  megaline = true,
  megacolumn = true,
  lsp = false,
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
  tmux = true,
  winbar = false,
}

-- disable certain plugins for firenvim
for plugin, _ in pairs(vim.g.enabled_plugin) do
  if not vim.tbl_contains({ "autocmds", "mappings", "quickfix" }, plugin) and vim.g.started_by_firenvim then
    plugin = false
  end
end

vim.g.colorscheme = "megaforest" -- alts: megaforest, everforest, palenightfall, rose-pine, forestbones, tokyonight-storm
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.notifier_enabled = true
vim.g.debug_enabled = false
vim.g.picker = "telescope" -- alts: fzf

-- [ globals ] -----------------------------------------------------------------

_G.mega = mega
  or {
    ui = {},
    fn = {},
    fzf = {},
    dirs = {},
    mappings = {},
    term = {},
    lsp = {},
    icons = require("mega.icons"),
    ts_ignored_langs = { "svg", "json", "heex", "jsonc" },
    -- original vim.notify: https://github.com/folke/dot/commit/b0f6a2db608cb090b969e2ef5c018b86d11fc4d6
    notify = vim.notify,
  }

-- [ loaders ] -----------------------------------------------------------------

require("mega.globals")
require("mega.debug")
require("mega.options")
require("mega.lazy").setup()

-- [ colorscheme ] -------------------------------------------------------------

mega.wrap_err("theme failed to load because", function(colorscheme)
  local theme = fmt("mega.lush_theme.%s", colorscheme)
  local ok, lush_theme = pcall(require, theme)
  if ok then
    vim.g.colors_name = colorscheme
    package.loaded[theme] = nil

    require("lush")(lush_theme)
  else
    vim.cmd.colorscheme(colorscheme)
  end

  -- NOTE: always make available my lushified-color palette
  mega.colors = require("mega.lush_theme.colors")
end, vim.g.colorscheme)
