local log = hs.logger.new('[contexts.canary]', 'debug')

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')

local rules = {
  {title = 'Main Window', action = 'snap'},
  {title = 'Preferences', action = 'ignore'},
}

-- apply(string, hs.window)
module.apply = function(event, win)
  log.df("applying [contexts.canary] for %s (%s)..", event, win:title())

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 5, event)

  ----------------------------------------------------------------------
  -- handle window rules
  local app = win:application()
  if app == nil then return end

  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil then return end

  if not hs.fnutils.contains({"windowDestroyed"}, event) then
    wh.applyRules(rules, win, appConfig)
  end
end

return module
