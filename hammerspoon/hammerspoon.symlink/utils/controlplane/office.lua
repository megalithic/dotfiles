local log = hs.logger.new('[controlplane.office]', 'debug')

local cache = {}
local module = {
  cache = cache,
  isConnectedToHome = false
}

local homeNetworkPingResult = function(object, message, seqnum, error)
  if message == "didFinish" then
    avg = tonumber(string.match(object:summary(), '/(%d+.%d+)/'))

    if avg == 0.0 then
      -- hs.alert.show("No network")
      module.isConnectedToHome = false
    elseif avg < 200.0 then
      -- hs.alert.show("Network good (" .. avg .. "ms)")
      module.isConnectedToHome = true
    elseif avg < 500.0 then
      -- hs.alert.show("Network poor(" .. avg .. "ms)")
      module.isConnectedToHome = true
    else
      -- hs.alert.show("Network bad(" .. avg .. "ms)")
      module.isConnectedToHome = false
    end
  end

  return module.isConnectedToHome
end

local sleepWatcher = function(_, _, _, _, event)
  local isTurningOff = event == hs.caffeinate.watcher.screensDidSleep or hs.caffeinate.watcher.systemWillSleep or hs.caffeinate.watcher.systemWillPowerOff
  local isTurningOn = event == hs.caffeinate.watcher.screensDidWake or hs.caffeinate.watcher.screensDidUnlock or hs.caffeinate.watcher.systemDidWake

  -- local isEthernet   = hs.network.interfaceName == "Thunderbolt Ethernet Slot  1" and hs.network.interfaceDetails()['Link']['Active'] == true
  -- local isAtHome     = hs.wifi.currentNetwork() == config.network.home

  -- confirm we can connect to home
  -- hs.network.ping.ping("amplifi", 1, 0.01, 1.0, "any", homeNetworkPingResult)


  if isDocked then
    if isTurningOff then
      log.df('Attempting to turn OFF the office lights..')
      --       -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/hubitat", (function() return end), (function() return true end), {"off", "171"}):start()
      --       -- hubitat.lampToggle("off")
    else
      log.df('Attempting to turn ON the office lights..')
      --       -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/hubitat", (function() return end), (function() return true end), {"on", "171"}):start()
      --       -- hubitat.lampToggle("on")
    end
  end

  -- if isTurningOff and isAtHome and not hs.itunes.isPlaying() then
  --   homebridge.set(config.homebridge.studioSpeakers, 0)
  -- end
end

module.start = function()
  log.i('Starting office control, isDocked?', isDocked)
  cache.watcherSleep = hs.watchable.watch('status.sleepEvent', sleepWatcher)
end

module.stop = function()
  -- cache.watcherSleep:release()
  log.i('Stopping office control')
end

return module
