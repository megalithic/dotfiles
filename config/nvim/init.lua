--==============================================================================
--
-- WARN: nvim must be pinned to 59d9f2413bde2046a09eb4a9edf856dcfa40eaf4 for now;
-- it looks like the next commit's dep updates of luajit are breaking my
-- colorscheme/lush.nvim
--
--==============================================================================

if vim.loader then vim.loader.enable() end

-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  filetypes = true,
  mappings = true,
  autocmds = true,
  megaline = true,
  megacolumn = true,
  term = true,
  lsp = true,
  repls = true,
  cursorline = true,
  colorcolumn = true,
  windows = true,
  numbers = true,
  folds = true,
  env = true,
  dim = true,
  tmux = false,
  breadcrumb = false,
  megaterm = false,
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
vim.g.picker = "fzf" -- alt: telescope, fzf
vim.g.formatter = "conform" -- alt: null-ls, conform
vim.g.tree = "neo-tree"
vim.g.explorer = "oil" -- alt: dirbuf, oil
vim.g.tester = "vim-test" -- alt: neotest, nvim-test, vim-test
vim.g.snipper = "vsnip" -- alt: vsnip, luasnip
vim.g.ts_ignored_langs = {} -- alt: { "svg", "json", "heex", "jsonc" }
vim.g.formatter_exclusions = { "ElixirLS", "NextLS", "nextls", "lexical" } -- alt: ElixirLS, NextLS, elixirls, nextls, lexical
vim.g.diagnostic_exclusions = { "ElixirLS", "NextLS", "elixirls", "nextls" } -- alt: ElixirLS, NextLS, elixirls, nextls, lexical
vim.g.enabled_elixir_ls = { "elixirls", "nextls" } -- alt: ElixirLS, NextLS, elixirls, nextls, lexical, credo

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
    notify = vim.notify,
  }

-- [ luarocks ] -----------------------------------------------------------------

package.path = string.format("%s; %s/.luarocks/share/lua/5.1/?/init.lua;", package.path, vim.fn.expand("$HOME"))
package.path = string.format("%s; %s/.luarocks/share/lua/5.1/?.lua;", package.path, vim.fn.expand("$HOME"))

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
