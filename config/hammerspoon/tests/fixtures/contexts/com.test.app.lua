-- Test fixture context used by tests/run.lua (never loaded by Hammerspoon:
-- contexts/init.lua only scans its own directory).
local obj = {}

obj.name = "context.test"
obj.activated = 0
obj.deactivated = 0

obj.actions = {
  noop = {
    hotkey = { {}, "j" },
    action = function() end,
  },
}

function obj:onActivate(_opts) obj.activated = obj.activated + 1 end

function obj:onDeactivate(_opts) obj.deactivated = obj.deactivated + 1 end

return obj
