local cache  = {}
local module = { cache = cache, }

-- load(string, hs.window, string, string) :: nil
module.load = function(event, win, context, level)
  local logger = string.format("[contexts.%s]", context)
  local log = hs.logger.new(logger, (level or 'info'))

  local app = win:application()
  if app == nil then return end

  local targetContext = require('contexts.' .. context)
  if targetContext ~= nil then
    log.df("applying::%s -> %s", event, win:title())
    targetContext.apply(event, win, log)
  end
end

return module
