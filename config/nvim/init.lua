-- [ settings ] ----------------------------------------------------------------

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
  simplef = false, -- WIP: trialing flit/leap
  folds = true,
  tmux = false,
  env = false,
  winbar = false, -- FIXME: add more!
}

for plugin, _ in pairs(vim.g.enabled_plugin) do
  if not vim.tbl_contains({ "autocmds", "mappings", "quickfix" }, plugin) and vim.g.started_by_firenvim then
    plugin = false
  end
end

vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81"
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.notifier_enabled = true
vim.g.debug_enabled = true

-- [ globals ] -----------------------------------------------------------------

_G.mega = mega
  or {
    fn = {},
    dirs = {},
    mappings = {},
    term = {},
    lsp = {},
    colors = require("mega.lush_theme.colors"),
    icons = require("mega.icons"),
    notify = vim.notify, -- original vim.notify: REF: https://github.com/folke/dot/commit/b0f6a2db608cb090b969e2ef5c018b86d11fc4d6
  }

-- [ loaders ] -----------------------------------------------------------------

local reload_ok, reload = pcall(require, "plenary.reload")
RELOAD = reload_ok and reload.reload_module or function(...) return ... end
function R(name)
  RELOAD(name)
  return require(name)
end

R("mega.globals")
R("mega.options")
vim.schedule(function()
  mega.packer_deferred()
  R("mega.plugins")
end)
