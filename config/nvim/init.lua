-- NOTE: fix for initial flash of black
-- REF: follow along here: https://github.com/neovim/neovim/pull/26381
vim.o.termguicolors = false

if vim.loader then vim.loader.enable() end
vim.env.DYLD_LIBRARY_PATH = "$BREW_PREFIX/lib/"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "git@github.com:folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- settings and autocmds must load before plugins,
-- but we can manually enable caching before both
-- of these for optimal performance
local lcc_ok, lazy_cache = pcall(require, "lazy.core.cache")
if lcc_ok then lazy_cache.enable() end

-- [ globals ] -----------------------------------------------------------------

local req = require("mega.req")

_G.I = vim.inspect
_G.fmt = string.format
_G.L = vim.log.levels

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  -- if not vim.g.debug_enabled then return end
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  if pcall(require, "plenary") then
    local p_logger = logger.new({ level = "debug" })
    p_logger.info(table.concat(objects, "\n"))
  else
    print(...)
  end

  return ...
end

-- NOTE: to use in one of our plugins:
-- `if not plugin_loaded("plugin_name") then return end`
function _G.plugin_loaded(plugin)
  if not mega then return false end
  local enabled_plugins = require("mega.settings").enabled_plugins

  if not enabled_plugins then return false end
  if not vim.tbl_contains(enabled_plugins, plugin) then return false end

  return true
end

_G.mega = mega
  or {
    ui = { foldtext = {}, statuscolumn = {} },
    fn = {},
    fzf = {},
    dirs = {},
    mappings = {},
    term = {},
    lsp = {},
    icons = require("mega.icons"),
    notify = vim.notify,
    req = req,
    blink_cursorline = function() end,
    resize_windows = function() end,
  }

-- [ loaders ] -----------------------------------------------------------------

package.path = fmt("%s; %s/.luarocks/share/lua/5.1/?/init.lua;", package.path, vim.g.home)
package.path = fmt("%s; %s/.luarocks/share/lua/5.1/?.lua;", package.path, vim.g.home)

req("mega.globals")
req("mega.settings").apply()
req("mega.lazy").setup()
req("mega.autocmds")
req("mega.mappings")
