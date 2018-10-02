-- TODO: extract events and device things to config.lua if possible

handleCaffeinateEvent = function(eventType) -- (int)
  log.df('[home-assistant] - event triggered: event type %s(%s)', hs.caffeinate.watcher[eventType], eventType)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    -- turn off office lamp
    log.df('[home-assistant] - attempting to turn off office lamp')
    hs.execute('~/.dotfiles/bin/hs-to-ha script.hs_office_lamp_off', true)
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    -- turn on office lamp
    local isNight = hs.execute('~/.dotfiles/bin/is-night', true)

    if (isNight) then
      log.df('[home-assistant] - night time; turning on office lamp, regardless of weather conditions')
      hs.execute('~/.dotfiles/bin/hs-to-ha script.hs_office_lamp_on', true)
    else
      log.df('[home-assistant] - day time; turning on office lamp based on weather conditions')
      hs.execute('~/.dotfiles/bin/hs-to-ha script.hs_office_lamp_on_conditioned', true)
    end
  end
end

return {
  init = (function()
    log.i('[home-assistant] - Creating home-assistant related watchers')
    caffeinateWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent):start()
  end),
  teardown = (function()
    log.i('[home-assistant] - Tearing down home-assistant related watchers')
    caffeinateWatcher:stop()
    caffeinateWatcher = nil
  end)
}
