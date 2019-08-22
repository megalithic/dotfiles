-- TODO: extract events and device things to config.lua if possible
local log = hs.logger.new('[ hubitat ]', 'debug')
local caffeinateWatcher = nil

local handleCaffeinateEvent = function(eventType) -- (int)
  log.df('Event triggered: event type %s(%s)', hs.caffeinate.watcher[eventType], eventType)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    -- turn off office lamp
    log.df('Attempting to turn off office lamp')
    hs.execute('hubitat off 6', true)
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    -- turn on office lamp
    -- local isNight = hs.execute("hubitat status 32 '.attributes[] | select(.name == \"cloud\").currentValue'", true)
    local isNight = hs.execute("hubitat status 32 '.attributes[] | select(.name == \"is_day\").currentValue | tonumber == 0'", true)
    local isCloudy = hs.execute("hubitat status 32 '.attributes[] | select(.name == \"cloud\").currentValue | tonumber >=75'", true)

    if (isNight == true or isNight == 'true') then
      log.df('night time; turning on office lamp, regardless of weather conditions')
      hs.execute('hubitat on 6', true)
    else
      log.df('day time; turning on office lamp based on weather conditions')
      if (isCloudy == true) then
        log.df('is presently cloudy, turning on')
        hs.execute('hubitat on 6', true)
      else
        log.df('is not cloudy, turning off')
        hs.execute('hubitat off 6', true)
      end
    end
  end
end

return {
  init = (function()
    log.i('Creating hubitat watcher')
    caffeinateWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent):start()
  end),
  teardown = (function()
    log.i('Tearing down hubitat watcher')
    caffeinateWatcher:stop()
    caffeinateWatcher = nil
  end)
}
