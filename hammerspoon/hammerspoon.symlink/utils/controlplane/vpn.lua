local log = hs.logger.new('[vpn]', 'debug')

local cache = {}
local module = { cache = cache }
local toggle = require('ext.application').toggle

local toggleVpn = function(currentNetwork)
  local appName      = config.preferred.vpn[1]
  local appInstance  = hs.application.get(appName)
  local isRunning    = appInstance and appInstance:isRunning()

  if currentNetwork ~= nil then
    hs.application.launchOrFocus(appName)
  else
    if isRunning then
      appInstance:kill()
    end
  end
end

local wifiWatcher = function(_, _, _, _, currentNetwork)
  toggleVpn(currentNetwork)
end

module.start = function()
  cache.watcher = hs.watchable.watch('status.currentNetwork', wifiWatcher)
end

module.stop = function()
  cache.watcher:release()
end

return module
