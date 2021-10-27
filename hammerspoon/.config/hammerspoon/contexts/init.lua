local cache = {}
local module = { cache = cache }

-- load(string, hs.application, string, string) :: nil
module.load = function(app, win, event, context, level)
  local logger = string.format("[ctx.%s]", context)
  local log = hs.logger.new(logger, (level or "info"))

  if app == nil then
    log.wf("no valid app given -> %s", app)
    return
  end

  local targetContext = require("contexts." .. context)
  if targetContext ~= nil then
    log.f("> context:" .. app:name() .. " (" .. event .. ")")
    targetContext.apply(app, win, event, log)
  end
end

return module
