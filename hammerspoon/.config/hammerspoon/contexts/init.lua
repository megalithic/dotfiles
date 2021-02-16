local cache  = {}
local module = { cache = cache, }

-- load(string, hs.application, string, string) :: nil
module.load = function(event, app, context, level)
  local logger = string.format("[contexts.%s]", context)
  local log = hs.logger.new(logger, (level or 'info'))

  if app == nil then
    log.wf("no valid app given -> %s", app)
    return
  end

  local targetContext = require('contexts.' .. context)
  if targetContext ~= nil then
    log.df("applying target context::%s -> %s (%s)", event, app:name(), app:bundleID())
    targetContext.apply(event, app, log)
  end
end

return module
