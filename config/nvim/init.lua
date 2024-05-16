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

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  local objects = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

function vim.pprint(...)
  local s, args = pcall(vim.deepcopy, { ... })
  if not s then args = { ... } end
  vim.schedule_wrap(vim.notify)(vim.inspect(#args > 1 and args or unpack(args)))
end

function vim.lg(...)
  if vim.in_fast_event() then return vim.schedule_wrap(vim.lg)(...) end
  local d = debug.getinfo(2)
  return vim.fn.writefile(
    vim.fn.split(":" .. d.short_src .. ":" .. d.currentline .. ":\n" .. vim.inspect(#{ ... } > 1 and { ... } or ...), "\n"),
    "/tmp/nlog",
    "a"
  )
end

function vim.lgclear() vim.fn.writefile({}, "/tmp/nlog") end

vim.g.mapleader = ","
vim.g.maplocalleader = " "

require("mega.settings").apply()
require("mega.lazy")
require("mega.autocmds").apply()
require("mega.mappings")
