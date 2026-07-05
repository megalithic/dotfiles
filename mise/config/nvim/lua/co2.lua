-- Coroutine utilities for async nvim callbacks.
-- Adapted from: https://github.com/madmaxieee/nvim-config/blob/main/lua/co2.lua

local M = {}

-- Example usage:
--
-- local co2 = require('co2')
--
-- co2.run(function(ctx)
--   vim.ui.input({prompt = 'New name:'}, ctx.resume)
--   local name = ctx.yield()
--
--   if name == nil then
--     vim.print('User canceled the operation')
--     return
--   end
--
--   vim.print('user finished typing')
--
--   local new_name = name:upper()
--   vim.print(new_name)
-- end)

local function pack_len(...)
  return { n = select("#", ...), ... }
end

---@class Co2Context
---@field resume fun(...): any
---@field yield fun(): any
---@field await fun(fn: function, ...): any

---Wrap a coroutine function so it can be used as a callback.
---Returns a function that, when called, runs the coroutine.
---@param coro_fn fun(ctx: Co2Context, ...): any
---@return fun(...)
function M.wrap(coro_fn)
  return function(...)
    M.run(coro_fn, ...)
  end
end

---@param coro_fn fun(ctx: Co2Context, ...): any
function M.run(coro_fn, ...)
  local t = coroutine.create(coro_fn)

  local function resume(...)
    if coroutine.status(t) ~= "suspended" then
      return
    end
    local ok, e = coroutine.resume(t, ...)
    if not ok then
      error(e)
    end
  end

  ---@type Co2Context
  local context = {
    resume = resume,

    yield = function()
      return coroutine.yield()
    end,

    await = function(fn, ...)
      local args = pack_len(...)
      local argc = args.n + 1
      args[argc] = resume
      fn(unpack(args, 1, argc))
      return coroutine.yield()
    end,
  }

  local ok, e = coroutine.resume(t, context, ...)
  if not ok then
    error(e)
  end
end

return M
