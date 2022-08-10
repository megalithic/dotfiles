local Settings = require("hs.settings")
local Config = Settings.get(CONFIG_KEY)
local DockConfig = Config.dock
local DisplaysConfig = Config.displays

local obj = {}

obj.__index = obj
obj.name = "watcher.status"
obj.debug = true
obj.statusMonitor = {}
obj.usbWatcher = {}
obj.screenWatcher = {}

local function checkLeelooConnection()
  local connectedDevices = hs.battery.privateBluetoothBatteryInfo()
  local leeloo = hs.fnutils.find(connectedDevices, function(device) return device.name == "Leeloo" end)
  dbg(fmt(":: [status] leeloo: %s", I(leeloo)))
  return leeloo
end

local function usbHandler(device)
  if device.productName == DockConfig.target.productName then
    obj.statusMonitor.dock = (device.eventType == "added")
    obj.statusMonitor.leeloo = checkLeelooConnection()
  end
end

local function screenHandler() obj.statusMonitor.display = hs.screen.find(DisplaysConfig.external) ~= nil end

function obj:start()
  obj.statusMonitor = hs.watchable.new("status", false) -- don't allow bi-directional status updates
  obj.usbWatcher = hs.usb.watcher.new(usbHandler):start()
  obj.screenWatcher = hs.screen.watcher.new(screenHandler):start()

  return self
end

function obj:stop()
  if obj.statusMonitor then obj.statusMonitor = nil end
  if obj.usbWatcher then obj.usbWatcher:stop() end
  if obj.screenWatcher then obj.screenWatcher:stop() end

  return self
end

return obj
