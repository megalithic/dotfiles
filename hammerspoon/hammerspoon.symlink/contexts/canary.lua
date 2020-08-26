local log = hs.logger.new('[contexts.canary]', 'info')

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')

-- apply(string, hs.window) :: nil
module.apply = function(event, win)
  local app = win:application()
  if app == nil then return end

  log.f("applying [contexts.canary] for %s (%s)..", event, win:title())

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 5, event)

  ----------------------------------------------------------------------
  -- handle window rules
  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil or appConfig.rules == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
    wh.applyRules(appConfig.rules, win, appConfig)
  end
end

return module
