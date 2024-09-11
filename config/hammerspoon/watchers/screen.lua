local obj = {}

obj.__index = obj
obj.name = "watcher.screen"
obj.debug = false
obj.watchers = {
  screen = {},
}

local function displayHandler(_watcher, _path, _key, _oldValue, isConnected)
  if isConnected then
    success("[watcher.screen] external display connected")
    hs.screen.find(DISPLAYS.external):setPrimary()
  else
    warn("[watcher.screen] external display disconnected")
    local internal = hs.screen.find(DISPLAYS.internal)
    if internal ~= nil then internal:setPrimary() end
  end
end

local function screenHandler()
  local externalScreenConnected = hs.screen.find(DISPLAYS.external) ~= nil

  displayHandler(nil, nil, nil, nil, externalScreenConnected)
end

function obj:start()
  self.watchers.screen = hs.screen.watcher.new(screenHandler):start()

  info(fmt("[START] %s", self.name))
  return self
end

function obj:stop()
  if self.watchers.screen then self.watchers.screen:stop() end

  info(fmt("[STOP] %s", self.name))
  return self
end

return obj
