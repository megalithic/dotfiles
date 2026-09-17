-- Test fixture: context whose lifecycle hooks error. Used to verify that
-- contexts/init.lua isolates hook failures from the app watcher callback.
local obj = {}

obj.name = "context.err"

obj.actions = {
  noop = {
    hotkey = { {}, "k" },
    action = function() end,
  },
}

function obj:onActivate(_opts) error("boom-activate") end

function obj:onDeactivate(_opts) error("boom-deactivate") end

return obj
