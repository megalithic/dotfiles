local Settings = require("hs.settings")
local Config = Settings.get(CONFIG_KEY)
local DockConfig = Config.dock
local DisplaysConfig = Config.displays

local obj = {}

obj.__index = obj
obj.name = "watcher.status"
obj.debug = true
obj.watchers = {
  status = {},
  usb = {},
  screen = {},
  app = {},
}

local function checkLeelooConnection()
  local connectedDevices = hs.battery.privateBluetoothBatteryInfo()
  local leeloo = hs.fnutils.find(connectedDevices, function(device) return device.name == "Leeloo" end)
  dbg(fmt(":: [status] leeloo: %s", I(leeloo)))
  return leeloo
end

local function usbHandler(device)
  dbg(fmt(":: [status] usb: %s", I(device)))
  if device.productName == DockConfig.target.productName then
    obj.watchers.status.dock = (device.eventType == "added")
    dbg(fmt(":: [status] usb: %s", I((device.eventType == "added"))))
    obj.watchers.status.leeloo = checkLeelooConnection()
  end
end

local function screenHandler() obj.watchers.status.display = hs.screen.find(DisplaysConfig.external) ~= nil end

local function applicationHandler(appName, appEvent, appObj)
  -- dbg(fmt(":: [status] app: %s/%s/%s", appName, appEvent, hs.inspect(appObj)))

  obj.watchers.status.app = {
    appName = appName,
    appEvent = appEvent,
    appObj = appObj,
  }
end

function obj:start()
  info("[status] watching for status, usb, screen, app updates")
  obj.watchers.status = hs.watchable.new("status", false) -- don't allow bi-directional status updates
  obj.watchers.usb = hs.usb.watcher.new(usbHandler):start()
  obj.watchers.screen = hs.screen.watcher.new(screenHandler):start()
  obj.watchers.app = hs.application.watcher.new(applicationHandler):start()

  return self
end

function obj:stop()
  if obj.watchers.status then obj.watchers.status = nil end
  if obj.watchers.usb then obj.watchers.usb:stop() end
  if obj.watchers.screen then obj.watchers.screen:stop() end
  if obj.watchers.app then obj.watchers.app:stop() end

  return self
end

return obj
