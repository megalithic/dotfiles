if vim.loader then vim.loader.enable() end
if vim.fn.has("nvim-0.12") == 1 then require("vim._extui").enable({}) end

_G.mega = {}

vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.noti = vim.notify

_G.mega = {
  colors = {},
  enabled_plugins = {
    "abbreviations",
    "megaline",
    "megacolumn",
    "term",
    "lsp",
    "repls",
    "cursorline",
    "colorcolumn",
    "windows",
    "numbers",
    "clipboard",
    "folds",
    "env",
    "notes",
    "filetypes",
  },
  ui = { statusline = {}, statuscolumn = {} },
  term = nil,
  notify = vim.noti,
}

-- local global_mods = {}
---Loads global modules under our `mega` namespace and the actual global `_G` namespace
---@param mod table
---@return table?
function _G.Load_macros(mod)
  -- local saved_mod = {}
  -- local debug_info = debug.getinfo(2)
  -- local mod_name = vim.fn.fnamemodify(debug_info.short_src, ":t:r")
  -- local mod_line = debug_info.currentline

  -- saved_mod[mod_name] = { mod, mod_line }
  -- table.insert(global_mods, saved_mod)

  -- bind these functions to our global `mega` table
  _G.mega = vim.tbl_extend("force", mega, mod)

  -- bind these functions to _the_ global `_G` as a
  -- capitalized function to denote global scope
  vim.iter(mod):each(function(k, v) _G[k:gsub("^%l", string.upper)] = v end)

  return mod
end

---Determines if a given plugin is loaded
---@param plugin string
---@return boolean
-- TODO: derive plugin name automatically
function _G.Plugin_enabled(plugin)
  local debug_info = debug.getinfo(2)
  plugin = plugin ~= nil and plugin or vim.fn.fnamemodify(debug_info.short_src, ":t:r")

  return vim.tbl_contains(mega.enabled_plugins, plugin)
end

require("mega.macros")
require("mega.settings").apply()
require("mega.lazy")
require("mega.commands")
require("mega.autocmds").apply()
require("mega.mappings")
