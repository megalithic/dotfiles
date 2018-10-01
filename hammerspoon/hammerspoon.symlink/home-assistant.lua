handleCaffeinateEvent = function(eventType)
  utils.log.df('[home-assistant] - event triggered: event type (%s)', eventType)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    -- turn off office lamp
    utils.log.df('[home-assistant] - attempting to turn off office lamp')
    hs.execute('~/.dotfiles/bin/hs-to-ha script.hammerspoon_office_lamp_off', true)
  elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
    -- turn on office lamp
    utils.log.df('[home-assistant] - attempting to turn on office lamp')
    hs.execute('~/.dotfiles/bin/hs-to-ha script.hammerspoon_office_lamp_on', true)
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
