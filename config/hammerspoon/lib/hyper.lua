local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "hyper"
obj.modal = nil
obj.hyperBind = nil

local pressed = function()
  warn("hyper: entering")
  obj.modal:enter()
end

local released = function()
  warn("hyper: exiting")
  obj.modal:exit()
end

function obj:bind(mod, key, pressedFn, releasedFn)
  local msg = "[hyper]"
  P("hyper:bind(mod: %s, key: %s, msg: %s, pressedFn: %s, releasedFn: %s)", I(mod), key, msg, pressedFn, releasedFn)

  -- NOTE:
  -- can omit mod; but it breaks if no mod and no pressedFn; so we shift arg assignments;
  -- FIXME: find a safer/better way!
  if not pressedFn and not releasedFn then
    mod = {}
    key = mod
    pressedFn = key
    releasedFn = pressedFn
  end

  -- call the original modal bind
  obj.modal:bind(mod, key, nil, function()
    if pressedFn ~= nil and type(pressedFn) == "function" then pressedFn() end
  end, function()
    if releasedFn ~= nil and type(releasedFn) == "function" then releasedFn() end
  end, function()
    -- if repeatedFn ~= nil and type(repeatedFn) == "function" then repeatedFn() end
  end)
end

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

  local hyper = Settings.get("_mega_config").keys.hyper

  -- sets up our config'd hyper key as the "trigger" for hyper key things; likely F19
  obj.hyperBind = hs.hotkey.bind({}, hyper, pressed, released)

  return self
end

function obj:start()
  -- gives us a hotkey modal to bind to
  obj.modal = hs.hotkey.modal.new({}, nil)

  return self
end

function obj:stop()
  if obj.hyperBind ~= nil then obj.hyperBind:delete() end
  if obj.modal ~= nil then obj.modal:delete() end

  return self
end

return obj
