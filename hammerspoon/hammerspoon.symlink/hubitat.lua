-- TODO: extract events and device things to config.lua if possible
local log = hs.logger.new('[hubitat]', 'debug')
local caffeinateWatcher = nil
local office_device_id = 163
local weather_device_id = 32

local lampToggle = function(command)
  hs.execute("hubitat " .. command .. " " .. lamp_device_id, true)
end

local isCloudy = function()
  return hs.task.new(
    "/Users/replicant/.dotfiles/bin/hubitat",
    function(...)
      print("exit", hs.inspect(table.pack(...)))
    end,
    function(...)
      print("stream", hs.inspect(table.pack(...)))
      return true
    end,
    {"status", weather_device_id, '.attributes[] | select(.name == "cloud").currentValue | tonumber >= 75'}
  ):start()
  -- return hs.execute("hubitat status " .. weather_device_id .. " '.attributes[] | select(.name == \"cloud\").currentValue | tonumber >= 75'")
end

local isNight = function()
  return hs.task.new("/Users/replicant/.dotfiles/bin/hubitat", nil, {"status", weather_device_id, '.attributes[] | select(.name == "is_day").currentValue | tonumber == 0'}):start()
  -- return hs.execute("hubitat status " .. weather_device_id .. " '.attributes[] | select(.name == \"is_day\").currentValue | tonumber == 0'")
end

local handleCaffeinateEvent = function(eventType) -- (int)
  log.df('Event triggered: event type %s(%s)', hs.caffeinate.watcher[eventType], eventType)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    log.df('Attempting to turn OFF office lamp')
    lampToggle("off")
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    log.df('Attempting to turn ON office lamp')
    lampToggle("on")

    -- log.df("isNight?")
    -- log.df(isNight())

    log.df("isCloudy?")
    log.df(isCloudy())

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
