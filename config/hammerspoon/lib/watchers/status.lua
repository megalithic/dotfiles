local Settings = require("hs.settings")
local DockConfig = Settings.get(CONFIG_KEY).dock
local DisplaysConfig = Settings.get(CONFIG_KEY).displays

local obj = {}

obj.__index = obj
obj.name = "watcher.status"
obj.debug = true
obj.statusMonitor = {}
obj.usbWatcher = {}
obj.screenWatcher = {}
obj.hasExternal = false

local function usbHandler(device)
  dbg(fmt(":: usb device: %s", I(device)))

  if device.eventType == "added" then
    if device.productName == DockConfig.target.productName then obj.statusMonitor.docked = true end
  elseif device.eventType == "removed" then
    if device.productName == DockConfig.target.productName then obj.statusMonitor.docked = false end
  end
end

local function screenHandler()
  obj.statusMonitor.externalDisplay = hs.screen.find(DisplaysConfig.external) ~= nil
  info(fmt("[dock] external screen connected: %s", obj.hasExternal))
end

function obj:start()
  obj.statusMonitor = hs.watchable.new("status")
  obj.usbWatcher = hs.usb.watcher.new(usbHandler):start()
  obj.screenWatcher = hs.screen.watcher.new(screenHandler):start()

  return self
end

function obj:stop()
  if obj.usbWatcher then obj.usbWatcher:stop() end
  if obj.screenWatcher then obj.screenWatcher:stop() end

  return self
end

return obj
