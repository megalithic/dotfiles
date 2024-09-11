local obj = {}

obj.__index = obj
-- REF:
-- discussion around hs.watchable for a lot of stuff: https://github.com/Hammerspoon/hammerspoon/discussions/3437#discussioncomment-5398491
-- fixes for hs.watchable module: https://github.com/Hammerspoon/hammerspoon/pull/3440#issuecomment-1480308900
obj.name = "watcher.status"
obj.debug = false
obj.watchers = {
  status = {
    leeloo = false,
  },
  usb = {},
  screen = {},
  app = {},
}

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

local function leelooBluetoothConnected()
  local connectedDevices = hs.battery.privateBluetoothBatteryInfo()
  local connected = hs.fnutils.find(connectedDevices, function(device) return device.name == "Leeloo" end) ~= nil
  dbg("leeloo (bt): %s", connected)
  return connected
end

local function usbHandler(device)
  if device.productID == C.dock.keyboard.productID then
    if device.eventType == "added" then
      obj.watchers.status.leeloo = true
    elseif device.eventType == "removed" then
      obj.watchers.status.leeloo = false
    end
  end

  if device.productID == C.dock.target.productID then
    if device.eventType == "added" then
      obj.watchers.status.dock = true
    elseif device.eventType == "removed" then
      obj.watchers.status.dock = false
    end
  end
end

local function screenHandler() obj.watchers.status.display = hs.screen.find(C.displays.external) ~= nil end
--
local function applicationHandler(appName, appEvent, appObj)
  dbg("app: %s/%s/%s", appName, appEvent, appObj:bundleID())

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
