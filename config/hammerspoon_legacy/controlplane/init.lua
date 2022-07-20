local cache = {}
local module = { cache = cache }

module.start = function()
  hs.fnutils.each(Config.preferred.controlplane, function(controlName)
    cache[controlName] = require("controlplane." .. controlName)
    cache[controlName]:start()
  end)
end

module.stop = function()
  hs.fnutils.each(cache, function(control)
    control:stop()
  end)
end

return module
