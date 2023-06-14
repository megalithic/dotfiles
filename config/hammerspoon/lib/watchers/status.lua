local obj = {}

obj.__index = obj
-- REF:
-- discussion around hs.watchable for a lot of stuff: https://github.com/Hammerspoon/hammerspoon/discussions/3437#discussioncomment-5398491
-- fixes for hs.watchable module: https://github.com/Hammerspoon/hammerspoon/pull/3440#issuecomment-1480308900
obj.name = "watcher.status"
obj.debug = true
obj.watchers = {
  status = {},
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
  local leeloo = hs.fnutils.find(connectedDevices, function(device) return device.name == "Leeloo" end)
  dbg("leeloo: %s", I(leeloo))
  return leeloo ~= nil
end

local function usbHandler(device)
  -- dbg("usb: %s", I(device))
  -- if device.productName == DockConfig.target.productName then
  --   dbg("usb (%s): %s", DockConfig.target.productName, I((device.eventType == "added")))
  --
  --   if device.eventType == "added" then
  --     obj.watchers.status.dock = true
  --   elseif device.eventType == "removed" then
  --     obj.watchers.status.dock = false
  --   end
  -- end
  --
  obj.watchers.status.leeloo = leelooBluetoothConnected()
    or (device.eventType == "added" and device.productID == C.dock.keyboard.productID)
end

local function screenHandler()
  obj.watchers.status.display = hs.screen.find(C.displays.external) ~= nil
  obj.watchers.status.dock = obj.watchers.status.display
end

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
