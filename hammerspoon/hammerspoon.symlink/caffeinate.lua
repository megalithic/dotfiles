local log = hs.logger.new('[caffeine]', 'debug')
-- local hubitat = require('hubitat')
local watcher = nil
local isDocked = false

local isCurrentlyDocked = function()
  return require('dock').isDocked()
end

local handleCaffeinateEvent = function(eventType) -- (int)
  isDocked = isCurrentlyDocked()

  log.df('Event triggered: event type %s(%s) | isDocked? %s', hs.inspect(hs.caffeinate.watcher[eventType]), eventType, isDocked)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    if (isDocked) then
      log.df('Attempting to turn OFF office lamp')
      -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/hubitat", (function() return end), (function() return true end), {"off", "171"}):start()
      -- hubitat.lampToggle("off")
    end

    -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/slack", (function() end), (function() end), {"away"}):start()
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    if (isDocked) then
      log.df('Attempting to turn ON office lamp')
      -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/hubitat", (function() return end), (function() return true end), {"on", "171"}):start()
      -- hubitat.lampToggle("on")
    end

    -- hubitat.handleEnvironmentBasedOfficeAutomations()

    -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/slack", (function() end), (function() end), {"back"}):start()
  end
end

return {
  init = (function(is_docked)
    isDocked = is_docked or isCurrentlyDocked() or false
    log.df('Creating caffeinate watcher (isDocked? %s)', isDocked)
    watcher = hs.caffeinate.watcher.new(handleCaffeinateEvent):start()
  end),
  teardown = (function()
    log.i('Tearing down caffeinate watcher')
    watcher:stop()
  end),
}
