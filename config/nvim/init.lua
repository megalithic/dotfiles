if vim.loader then vim.loader.enable() end

-- [ settings ] ----------------------------------------------------------------

vim.g.enabled_plugin = {
  abbreviations = true,
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
  -- old_term = false,
  -- tmux = false,
  -- breadcrumb = false,
  -- megaterm = false,
  -- vscode = false,
  -- winbar = false,
}

for plugin, _ in pairs(vim.g.enabled_plugin) do
  if not vim.tbl_contains({ "autocmds", "mappings", "quickfix" }, plugin) and vim.g.started_by_firenvim then
    vim.g.enabled_plugin[plugin] = false
  end
end

vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81"
vim.g.notifier_enabled = true
vim.g.debug_enabled = false
vim.g.picker = "fzf_lua" -- alt: telescope, fzf_lua
vim.g.formatter = "conform" -- alt: null-ls/none-ls, conform
vim.g.tree = "neo-tree"
vim.g.explorer = "oil" -- alt: dirbuf, oil
vim.g.tester = "vim-test" -- alt: neotest, nvim-test, vim-test
vim.g.snipper = "vsnip" -- alt: vsnip, luasnip
vim.g.ts_ignored_langs = {} -- alt: { "svg", "json", "heex", "jsonc" }

-- REF: elixir LSPs: elixir-tools(ElixirLS, NextLS, credo), elixirls, nextls, lexical
vim.g.formatter_exclusions = { "ElixirLS", "NextLS", "nextls", "lexical" }
vim.g.diagnostic_exclusions = { "ElixirLS", "NextLS", "elixirls", "lexical" }
vim.g.enabled_elixir_ls = { "elixirls", "nextls" }
vim.g.disable_autolint = true
vim.g.disable_autoformat = false

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
