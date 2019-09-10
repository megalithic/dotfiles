local log = hs.logger.new('[caffeinate]', 'debug')
local hubitat = require('hubitat')
local caffeinateWatcher = hs.caffeinate.watcher
local isDocked = false

local handleCaffeinateEvent = function(eventType) -- (int)
  log.df('Event triggered: event type %s(%s) | isDocked? %s', hs.caffeinate.watcher[eventType], eventType, isDocked)

  if (isDocked) then
    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
      log.df('Attempting to turn OFF office lamp')
      hubitat.lampToggle("off")
    elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
      log.df('Attempting to turn ON office lamp')
      hubitat.lampToggle("on")

      -- if (isNight()) then
      --   log.df('night time; turning on office lamp, regardless of weather conditions')
      --   lampToggle("on")
      -- else
      --   log.df('day time; turning on office lamp based on weather conditions')
      --   if (isCloudy()) then
      --     log.df('is presently cloudy, turning on')
      --     lampToggle("on")
      --   else
      --     log.df('is not cloudy, turning off')
      --     lampToggle("off")
      --   end
      -- end
    end
  end
end

return {
  init = (function(is_docked)
    isDocked = is_docked
    log.df('Creating caffeinate watcher (isDocked? %s)', isDocked)
    caffeinateWatcher.new(handleCaffeinateEvent):start()
  end),
  teardown = (function()
    log.i('Tearing down caffeinate watcher')
    caffeinateWatcher:stop()
  end),
}
