local cache  = {}
local module = { cache = cache }

local IMAGE_PATH = os.getenv('HOME') .. '/.hammerspoon/assets/airport.png'

local notifyWifi = function(_, _, _, prevNetwork, network)
  local subTitle = network and 'Network: ' .. network or 'Disconnected'

  if prevNetwork ~= network then
    hs.notify.new({
      title        = 'Wi-Fi Status',
      subTitle     = subTitle,
      contentImage = IMAGE_PATH
    }):send()
  end
end

module.start = function()
  cache.watcher = hs.watchable.watch('status.currentNetwork', notifyWifi)
end

module.stop = function()
  cache.watcher:release()
end

return module
