local log = hs.logger.new("[watchables]", "debug")

local status = hs.watchable.new("status")

local cache = { status = status }
local M = { cache = cache }

local updateBattery = function()
  local burnRate = hs.battery.designCapacity() / math.abs(hs.battery.amperage())

  status.battery = {
    isCharged = hs.battery.isCharged(),
    percentage = hs.battery.percentage(),
    powerSource = hs.battery.powerSource(),
    amperage = hs.battery.amperage(),
    burnRate = burnRate,
  }
end

local updateScreen = function()
  status.connectedScreens = #hs.screen.allScreens()
  status.connectedScreenIds = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    return screen:id()
  end)
  status.is4kConnected = hs.screen.find(Config.displays.external) ~= nil
  status.isLaptopScreenConnected = hs.screen.find(Config.displays.laptop) ~= nil

  log.d("updated screens:", hs.inspect(status.connectedScreenIds))
end

local updateWiFi = function()
  status.currentNetwork = hs.wifi.currentNetwork()

  log.d("updated wifi:", status.currentNetwork)
end

local updateSleep = function(event) -- int
  status.sleepEvent = hs.caffeinate.watcher[event]

  log.d("updated sleep:", status.sleepEvent)
end

local updateUSB = function()
  status.docked = hs.fnutils.find(hs.usb.attachedDevices(), function(device)
    return device.productName == Config.docking.device.productName
  end) ~= nil

  status.connectedExternalKeyboard = hs.fnutils.find(hs.usb.attachedDevices(), function(device)
    return device.productName == Config.docking.keyboard.productName
  end) ~= nil

  status.isDocked = status.docked

  log.df("updated isDocked: %s", status.isDocked)
  log.df("updated connectedExternalKeyboard: %s", status.connectedExternalKeyboard)
end

M.start = function()
  -- start watchers
  cache.watchers = {
    battery = hs.battery.watcher.new(updateBattery):start(),
    screen = hs.screen.watcher.new(updateScreen):start(),
    sleep = hs.caffeinate.watcher.new(updateSleep):start(),
    usb = hs.usb.watcher.new(updateUSB):start(),
    wifi = hs.wifi.watcher.new(updateWiFi):start(),
  }

  -- setup on start
  updateBattery()
  updateScreen()
  updateSleep()
  updateUSB()
  updateWiFi()
end

M.stop = function()
  hs.fnutils.each(cache.watchers, function(watcher)
    watcher:stop()
  end)

  cache.configuration:stop()
end

return M
