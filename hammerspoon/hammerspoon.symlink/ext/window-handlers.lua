local log = hs.logger.new('[ext.window-handlers]', 'warning')

local cache = { timers = {} }

local module = { cache = cache }


module.dndHandler = function(win, dndConfig, event)
  if dndConfig == nil then return end

  if event == "windowCreated" then
    log.df('dndHandler for %s found..', win:application():name())
  end

--   local enabled = dndConfig.enabled
--   local mode = dndConfig.mode

--   if (enabled) then
--     if (event == "windowCreated") then
--       log.df('dnd handler: toggling ON slack status (%s) and dnd mode', mode)
--       hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/slack", (function() end), (function() end), {mode}):start()
--       hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/dnd", (function() end), (function() end), {"on"}):start()
--     elseif (event == "windowDestroyed") then
--       -- FIXME: this only works for app watchers it seems; nothing to do with dead windows :(
--       -- log.df('dnd handler: toggling OFF slack status and dnd mode')
--       -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/slack", (function() end) , (function() end), {"back"}):start()
--       -- hs.execute("slack back", true)
--       -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/dnd", (function() end), (function() end), {"off"}):start()
--       -- hs.execute("dnd off", true)
--     end
--   end
end

module.appHandler = function(win, handler, event)
  if handler == nil then return end
  local app = win:application()

  log.df('found app handler for %s (%s)..', app:name(), app:bundleID())

  if event == "windowCreated" then
    handler(win)
  end
end

module.quitAfterHandler = function(win, interval, event)
  if interval ~= nil then
    local app = win:application()
    local appName = app:name()

    if (app:isRunning()) then
      if cache.timers[appName] ~= nil then
        log.df('quitAfterHandler - stopping existing timer for %s (%s)', hs.inspect(cache.timers[appName]), event)

        cache.timers[appName]:stop()
      end

      if event == "windowUnfocused" or event == "windowHidden" then
        log.df('quitAfterHandler - starting timer (%sm) on %s (%s), for event %s', interval, win:title(), appName, event)

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() app:kill() end)
      end
    end
  else
    return
  end
end

module.hideAfterHandler = function(win, interval, event)
  if interval ~= nil then
    local app = win:application()
    local appName = app:name()

    if app:isRunning() and not app:isHidden() then
      if cache.timers[appName] ~= nil then
        log.df('hideAfterHandler - stopping existing timer for %s (%s)', hs.inspect(cache.timers[appName]), event)

        cache.timers[appName]:stop()
      end

      if event == "windowUnfocused" or event == "windowHidden" then
        log.df('hideAfterHandler - starting timer (%sm) on %s (%s), for event %s', interval, win:title(), appName, event)

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() app:hide() end)
      end
    end
  else
    return
  end
end

return module
