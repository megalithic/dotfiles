local cache = {}
local module = { cache = cache }

module.start = function()
  hs.fnutils.each(Config.preferred.bindings, function(binding)
    cache[binding] = require("bindings." .. binding)
    cache[binding].start()
  end)
end

module.stop = function()
  hs.fnutils.each(cache, function(binding)
    binding.stop()
  end)
end

return module
