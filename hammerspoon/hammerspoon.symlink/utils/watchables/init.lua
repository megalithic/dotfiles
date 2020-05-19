local status = hs.watchable.new('status')
local log    = hs.logger.new('[utils.watchables]', 'debug')

local cache  = { status = status }
local module = { cache = cache }

-- local VPN_CONFIG_KEY  = "State:/Network/Global/Proxies"
-- local NETWORK_SHARING = "com.apple.NetworkSharing"

local updateBattery = function()
  local burnRate = hs.battery.designCapacity() / math.abs(hs.battery.amperage())

  status.battery = {
    isCharged     = hs.battery.isCharged(),
    percentage    = hs.battery.percentage(),
    powerSource   = hs.battery.powerSource(),
    amperage      = hs.battery.amperage(),
    burnRate      = burnRate,
  }
end

local updateScreen = function()
  status.connectedScreens        = #hs.screen.allScreens()
  status.connectedScreenIds      = hs.fnutils.map(hs.screen.allScreens(), function(screen) return screen:id() end)
  status.is4kConnected           = hs.screen.findByName(config.displays.external) ~= nil
  status.isLaptopScreenConnected = hs.screen.findByName(config.displays.laptop) ~= nil

  log.d('updated screens:', hs.inspect(status.connectedScreenIds))
end

-- local updateNetwork = function()
--   status.networkSharing   = cache.configuration:contents(NETWORK_SHARING)[NETWORK_SHARING]
--   status.vpnConfiguration = cache.configuration:contents(VPN_CONFIG_KEY)[VPN_CONFIG_KEY]

--   log.d('updated network config')
-- end

local updateWiFi = function()
  status.currentNetwork = hs.wifi.currentNetwork()

  log.d('updated wifi:', status.currentNetwork)
end

local updateSleep = function(event) -- int
  status.sleepEvent = hs.caffeinate.watcher[event]

  log.d('updated sleep:', status.sleepEvent)
end

local updateUSB = function()
  status.isDZ60Attached = hs.fnutils.find(hs.usb.attachedDevices(), function(device)
    return device.productName == 'DZ60'
  end) ~= nil
  status.isDocked = status.isDZ60Attached

  log.d('updated docked (dz60):', status.isDocked)
end

module.start = function()
  -- open network config for vpn watching
  cache.configuration = hs.network.configuration.open()

  -- start watchers
  cache.watchers = {
    battery = hs.battery.watcher.new(updateBattery):start(),
    screen  = hs.screen.watcher.new(updateScreen):start(),
    sleep   = hs.caffeinate.watcher.new(updateSleep):start(),
    usb     = hs.usb.watcher.new(updateUSB):start(),
    wifi    = hs.wifi.watcher.new(updateWiFi):start(),
    -- network = cache.configuration:monitorKeys({ VPN_CONFIG_KEY, NETWORK_SHARING }):setCallback(updateNetwork):start(),
  }

  -- setup on start
  updateBattery()
  updateScreen()
  updateSleep()
  updateUSB()
  updateWiFi()
  -- updateNetwork()
end

module.stop = function()
  hs.fnutils.each(cache.watchers, function(watcher)
    watcher:stop()
  end)

  cache.configuration:stop()
end

return module
