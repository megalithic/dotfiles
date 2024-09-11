local obj = {}
local _appObj = nil
obj.__index = obj
obj.name = "context.hammerspoon"
obj.debug = true

obj.modal = true
obj.actions = {
  reload = {
    action = function() hs.reload() end,
    hotkey = { { "cmd" }, "r" },
  },
}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]

  if obj.modal then obj.modal:enter() end

  return self
end

function obj:stop(opts)
  opts = opts or {}

  if obj.modal then obj.modal:exit() end

  return self
end

return obj
