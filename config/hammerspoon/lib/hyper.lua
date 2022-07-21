local Settings = require("hs.settings")

local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "hyper"
obj.hyperBind = nil

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

function obj:init(opts)
  opts = opts or {}
  local hyperKey = opts["hyperKey"] or Settings.get(CONFIG_KEY).keys.hyper

  -- sets up our config'd hyper key as the "trigger" for hyper key things; likely F19
  obj.hyperBind = hs.hotkey.bind({}, hyperKey, function() obj:enter() end, function() obj:exit() end)

  return self
end

function obj:start() return self end

function obj:stop()
  obj:delete()
  obj.hyperBind:delete()

  return self
end

return obj
