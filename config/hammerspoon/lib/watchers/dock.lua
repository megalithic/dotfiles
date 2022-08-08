local Settings = require("hs.settings")
local DockConfig = Settings.get(CONFIG_KEY).dock
local DisplaysConfig = Settings.get(CONFIG_KEY).displays

local obj = {}

obj.__index = obj
obj.name = "watcher.dock"
obj.debug = true
obj.statusMonitor = {}
obj.usbWatcher = {}
obj.screenWatcher = {}
obj.hasExternal = false

local function usbHandler(device)
  dbg(fmt(":: usb device: %s", I(device)))

  if device.eventType == "added" then
    if device.productName == DockConfig.target.productName then
      success(fmt(":: dock device connected: %s", I(device)))
      hs.notify
        .new({ title = device.productName, subTitle = fmt("%s %s Connected", device.productName, "🔌") })
        :send()
    end
  elseif device.eventType == "removed" then
    if device.productName == DockConfig.target.productName then
      warn(fmt(":: dock device disconnected: %s", I(device)))
      hs.notify
        .new({ title = device.productName, subTitle = fmt("%s %s Disconnected", device.productName, "") })
        :send()
    end
  end
end

local function screenHandler()
  obj.hasExternal = hs.screen.find(DisplaysConfig.external) ~= nil
  dbg(fmt(":: external screen connected: %s", obj.hasExternal))
  if obj.hasExternal then
    hs.notify
      .new({ title = DisplaysConfig.external, subTitle = fmt("%s %s Connected", DisplaysConfig.external, "🖥") })
      :send()
  end
end

function obj:start()
  -- obj.statusMonitor = hs.watchable.new("status")
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
