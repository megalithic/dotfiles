local Settings = require("hs.settings")

local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "hyper"
obj.hyperBind = nil

-- --- Hyper:bindHotKeys(table) -> hs.hotkey.modal
-- --- Method
-- --- Expects a config table in the form of {"hyperKey" = {mods, key}}.
-- ---
-- --- Returns:
-- ---  * self
-- function obj:bindHotKeys(mapping)
--   local mods, key = table.unpack(mapping["hyperKey"])
--   hs.hotkey.bind(mods, key, function() m:enter() end, function() m:exit() end)

--   return self
-- end

--- Hyper:bindPassThrough(key, bundleId) -> hs.hotkey.modal
--- Method
--- Ensures the bundleId's application is running, then sends the "hyper-chord"
--- (⌘+⌥+⌃+⇧) plus whatever you set as `key`.
---
--- Returns:
---  * self
function obj:bindPassThrough(key, app)
  obj:bind({}, key, nil, function()
    if hs.application.get(app) then
      hs.eventtap.keyStroke({ "cmd", "alt", "shift", "ctrl" }, key)
    else
      hs.application.launchOrFocusByBundleID(app)
      hs.timer.waitWhile(
        function() return not hs.application.get(app):isFrontmost() end,
        function() hs.eventtap.keyStroke({ "cmd", "alt", "shift", "ctrl" }, key) end
      )
    end
  end)

  return self
end

-- TODO: optionally take in the hyper key?
function obj:init(opts)
  opts = opts or {}

  -- sets up our config'd hyper key as the "trigger" for hyper key things; likely F19
  hs.hotkey.bind({}, Settings.get("_mega_config").keys.hyper, function() obj:enter() end, function() obj:exit() end)

  return self
end

function obj:start() return self end

function obj:stop()
  -- if obj.hyperBind ~= nil then obj.hyperBind:delete() end
  obj:delete()

  return self
end

return obj
