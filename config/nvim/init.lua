if vim.loader then vim.loader.enable() end
vim.env.DYLD_LIBRARY_PATH = "$BREW_PREFIX/lib/"

_G.L = vim.log.levels
_G.I = vim.inspect
_G.mega = {
  ui = {},
  lsp = {},
  req = require("mega.req"),
  term = nil,
  notify = vim.notify,
}

vim.g.mapleader = ","
vim.g.maplocalleader = " "

require("mega.settings").apply()
require("mega.lazy")
require("mega.autocmds").apply()
require("mega.mappings")

-- vim: ts=2 sts=2 sw=2 et
