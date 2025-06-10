if vim.loader then vim.loader.enable() end

_G.mega = {}
local global_mods = {}

vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.noti = vim.notify

_G.mega = {
  colors = {},
  enabled_plugins = {
    -- "abbreviations",
    "megaline",
    -- "megacolumn",
    -- "term",
    "lsp",
    -- "repls",
    "cursorline",
    "colorcolumn",
    -- "windows",
    -- "numbers",
    -- "folds",
    -- "env",
  },
  ui = { statusline = {}, statuscolumn = {} },
  term = nil,
  notify = vim.noti,
}

---Loads global modules under our `_` namespace and the actual global `_G` namespace
---@param mod table
---@return table?
function _G.Load_macros(mod)
  local saved_mod = {}
  local debug_info = debug.getinfo(2)
  local mod_name = vim.fn.fnamemodify(debug_info.short_src, ":t:r")
  local mod_line = debug_info.currentline

  saved_mod[mod_name] = { mod, mod_line }
  table.insert(global_mods, saved_mod)

  -- bind these functions to our global `_` table
  _G.mega = vim.tbl_extend("force", mega, mod)

  -- bind these functions to _the_ global `_G`
  vim.iter(mod):each(function(k, v)
    _G[k] = v
    _G[k:gsub("^%l", string.upper)] = v
  end)

  return global_mods
end

require("mega.macros")
require("mega.settings").apply()
require("mega.lazy")
require("mega.commands")
require("mega.autocmds").apply()
require("mega.mappings")

Echom(string.format("%d global modules loaded..", #global_mods), "Question")
