local log = hs.logger.new('caffeinate|', 'debug')
local hubitat = require('hubitat')
local watcher = nil
local isDocked = false

local handleCaffeinateEvent = function(eventType) -- (int)
  log.df('Event triggered: event type %s(%s) | isDocked? %s', hs.caffeinate.watcher[eventType], eventType, isDocked)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    if (isDocked) then
      log.df('Attempting to turn OFF office lamp')
      hubitat.lampToggle("off")
    end

    hs.execute('slack away')
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    if (isDocked) then
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

    hs.execute('slack back')
  end
end

return {
  init = (function(is_docked)
    isDocked = is_docked or false
    log.df('Creating caffeinate watcher (isDocked? %s)', isDocked)
    watcher = hs.caffeinate.watcher.new(handleCaffeinateEvent):start()
  end),
  teardown = (function()
    log.i('Tearing down caffeinate watcher')
    watcher:stop()
  end),
}
