if vim.loader then vim.loader.enable() end

vim.env.DYLD_LIBRARY_PATH = "$BREW_PREFIX/lib/"

vim.g.mapleader = ","
vim.g.maplocalleader = " "

_G.L = vim.log.levels
_G.I = vim.inspect

vim.noti = vim.notify

_G.mega = {
  ui = {},
  lsp = {
    on_attach = function(on_attach, name)
      -- `mega.lsp.on_attach` usage:
      --
      -- mega.lsp.on_attach(function(client, buffer)
      --   if client.name == "zk" then
      --     -- do a thing
      --   end
      -- end)
      return vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buffer = args.buf ---@type number
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and (not name or client.name == name) then return on_attach(client, buffer) end
        end,
      })
    end,
  },
  req = require("mega.req"),
  resize_windows = function() end, -- stubbed
  term = nil,
  notify = vim.noti,
}

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  local printables = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(printables, vim.inspect(v))
  end

  if pcall(require, "plenary") then
    local log = require("plenary.log").new({
      plugin = "notify",
      level = "debug",
      use_console = true,
      use_quickfix = false,
      use_file = false,
    })
    -- vim.schedule_wrap(log.info)(table.concat(printables, "\n"))
    vim.schedule_wrap(log.info)(vim.inspect(#printables > 1 and printables or unpack(printables)))
  else
    vim.schedule_wrap(print)(table.concat(printables, "\n"))
  end
  return ...
end
_G.dbg = _G.P

function vim.dbg(msg, level, _opts)
  if pcall(require, "plenary") then
    local log = require("plenary.log").new({
      plugin = "notify",
      level = level or "DEBUG",
      use_console = true,
      use_quickfix = false,
      use_file = false,
    })
    vim.schedule_wrap(log.info)(msg)
  else
    vim.schedule_wrap(P)(msg)
  end
end

function vim.pprint(...)
  local s, args = pcall(vim.deepcopy, { ... })
  if not s then args = { ... } end
  if pcall(require, "plenary") then
    local log = require("plenary.log").new({
      plugin = "notify",
      level = "debug",
      use_console = true,
      use_quickfix = false,
      use_file = false,
    })
    vim.schedule_wrap(log.info)(vim.inspect(#args > 1 and args or unpack(args)))
  else
    vim.schedule_wrap(vim.notify)(vim.inspect(#args > 1 and args or unpack(args)))
  end
end

function vim.wlog(...)
  if vim.in_fast_event() then return vim.schedule_wrap(vim.wlog)(...) end
  local d = debug.getinfo(2)
  return vim.fn.writefile(
    vim.fn.split(":" .. d.short_src .. ":" .. d.currentline .. ":\n" .. vim.inspect(#{ ... } > 1 and { ... } or ...), "\n"),
    "/tmp/nlog",
    "a"
  )
end

function vim.wlogclear() vim.fn.writefile({}, "/tmp/nlog") end

require("mega.settings").apply()
require("mega.lazy")
require("mega.autocmds").apply()
require("mega.mappings")
