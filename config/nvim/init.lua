-- NOTE: fix for initial flash of black
-- REF: follow along here: https://github.com/neovim/neovim/pull/26381
vim.o.termguicolors = false

if vim.loader then vim.loader.enable() end
vim.env.DYLD_LIBRARY_PATH = "$BREW_PREFIX/lib/"

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
  }

-- [ loaders ] -----------------------------------------------------------------

package.path = fmt("%s; %s/.luarocks/share/lua/5.1/?/init.lua;", package.path, vim.g.home)
package.path = fmt("%s; %s/.luarocks/share/lua/5.1/?.lua;", package.path, vim.g.home)

req("mega.globals")
req("mega.settings").apply()
req("mega.lazy").setup()
req("mega.autocmds")
req("mega.mappings")
