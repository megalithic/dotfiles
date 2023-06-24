if vim.loader then vim.loader.enable() end

-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  breadcrumb = true,
  mappings = true,
  autocmds = true,
  megaline = true,
  megacolumn = true,
  term = true,
  megaterm = false,
  lsp = true,
  repls = true,
  cursorline = true,
  colorcolumn = true,
  windows = true,
  numbers = true,
  quickfix = true,
  folds = true,
  env = true,
  tmux = false,
  dim = true,
  vscode = false,
  winbar = false,
}

-- disable certain plugins for firenvim
for plugin, _ in pairs(vim.g.enabled_plugin) do
  if not vim.tbl_contains({ "autocmds", "mappings", "quickfix" }, plugin) and vim.g.started_by_firenvim then
    vim.g.enabled_plugin[plugin] = false
  end
end

vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.notifier_enabled = true
vim.g.debug_enabled = false
vim.g.picker = "telescope" -- alt: telescope, fzf
vim.g.tree = "neo-tree"
vim.g.explorer = "oil" -- alt: dirbuf, oil
vim.g.tester = "vim-test" -- alt: neotest, vim-test
vim.g.snipper = "vsnip" -- alt: vsnip, luasnip

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
    notify = vim.notify,
  }

-- [ loaders ] -----------------------------------------------------------------

require("mega.globals")
require("mega.debug")
require("mega.options")
require("mega.lazy").setup()
require("mega.mappings")

-- [ colorscheme ] -------------------------------------------------------------

mega.pcall("theme failed to load because", function(colorscheme)
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
