if vim.loader then vim.loader.enable() end

vim.env.DYLD_LIBRARY_PATH = "$BREW_PREFIX/lib/"

vim.g.mapleader = ","
vim.g.maplocalleader = " "

require("mega.globals")
require("mega.settings").apply()
require("mega.lazy")
require("mega.commands")
require("mega.autocmds").apply()
require("mega.mappings")
