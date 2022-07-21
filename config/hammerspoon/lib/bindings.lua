local Settings = require("hs.settings")
local Hyper

local obj = {}

obj.__index = obj
obj.name = "bindings"

function obj:init(opts)
  opts = opts or {}
  Hyper = L.load("lib.hyper", { id = obj.name }):start()

  return self
end

function obj:start()
  -- [ app bindings ] ----------------------------------------------------------
  local apps = Settings.get(CONFIG_KEY).apps
  hs.fnutils.each(apps, function(appConfig)
    if appConfig.key then
      Hyper:bind({}, appConfig.key, function() hs.application.launchOrFocusByBundleID(appConfig.bundleID) end)
    end
    if appConfig.localBindings and #appConfig.localBindings > 0 then
      hs.fnutils.each(appConfig.localBindings, function(key) Hyper:bindPassThrough(key, appConfig.bundleID) end)
    end
  end)

  -- [ utility bindings ] ----------------------------------------------------------

  return self
end

function obj:stop()
  L.unload("lib.hyper")

  return self
end

return obj
