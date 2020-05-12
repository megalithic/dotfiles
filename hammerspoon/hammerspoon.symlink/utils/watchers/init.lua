local cache  = {}
local module = { cache = cache }

module.start = function()
  hs.fnutils.each(watchers.enabled, function(watchName)
    cache[watchName] = require('utils.watchers.' .. watchName)
    cache[watchName]:start()
  end)
end

module.stop = function()
  hs.fnutils.each(cache, function(watcher)
    watcher:stop()
  end)
end

return module
