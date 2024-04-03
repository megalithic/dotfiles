---Require one or more modules
---@example
--- p.require("foo").setup({})
--- p.require("foo", "bar", function(foo, bar)
---   foo.setup({arg = bar})
--- end)
return function(...)
  local args = { ... }
  local mods = {}
  local first_mod
  for _, arg in ipairs(args) do
    if type(arg) == "function" then
      arg(unpack(mods))
      break
    end
    local ok, mod = pcall(require, arg)
    if ok then
      if not first_mod then first_mod = mod end
      table.insert(mods, mod)
    else
      vim.notify_once(string.format("Missing module: %s", arg), vim.log.levels.WARN)
      -- Return a dummy item that returns functions, so we can do things like
      -- p.require("module").setup()
      local dummy = {}
      setmetatable(dummy, {
        __call = function() return dummy end,
        __index = function() return dummy end,
      })
      return dummy
    end
  end
  return first_mod
end
