local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, _)
  local app = win:application()
  if app == nil then return end

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 1, event)

  ----------------------------------------------------------------------
  -- handle window rules
  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil or appConfig.rules == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
    wh.applyRules(appConfig.rules, win, appConfig)
  end
end

return module
