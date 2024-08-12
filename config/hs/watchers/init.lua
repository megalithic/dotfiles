local enum = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.name = "watchers"
obj.watched = {}

function obj:init() return self end

function obj:start(watchers)
  if watchers == nil then return self end

  function karabinerCallback(eventName, params)
    print("karabiner_event: " .. eventName)
    print(hs.inspect(params))
  end

  hs.urlevent.bind("karabiner", karabinerCallback)

  enum.each(watchers, function(modTarget)
    local modPath = "watchers." .. modTarget
    local mod = require(modPath):start()

    self.watched[modPath] = mod
  end)

  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop()
  if self.watched == nil then return end

  enum.each(self.watched, function(mod) require(mod):stop() end)
  self.watched = {}

  info(fmt("[STOP] %s", self.name))
  return self
end

return obj
