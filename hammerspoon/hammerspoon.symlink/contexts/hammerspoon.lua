local log = hs.logger.new('[contexts.hammerspoon]', 'debug')

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')

local rules = {
  {title = 'Hammerspoon Console', action = 'snap', position = config.grid.rightHalf}
}

-- apply(string, hs.window)
module.apply = function(event, win)
  log.df("applying [contexts.hammerspoon] for %s..", event)

  local app = win:application()
  if app == nil then return end

  ----------------------------------------------------------------------
  -- handle window rules
  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil then return end

  if not hs.fnutils.contains({"windowDestroyed"}, event) then
    wh.applyRules(rules, win, appConfig)
  end
end

return module
