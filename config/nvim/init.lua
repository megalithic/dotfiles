_G.mega = _G.mega
  or {
    p = {}, -- plugin-specific tables
    t = {}, -- theme
    u = {}, -- utils
    ui = { icons = require("icons") },
  }

vim.g.mapleader = ","
vim.g.maplocalleader = " "

require("settings")
require("utils")
require("keymaps")
require("options")
require("bootstrap")

require("langs").setup()
require("lsp").setup()
