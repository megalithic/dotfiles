local log = hs.logger.new('[ext.window-handlers]', 'warning')
local cache = { timers = {} }
local module = { cache = cache }

-- use this callback for debugging dnd tasks
local function dndCommandCb(exit_code, std_out, std_err)
  log.wf("DND command callback: { exit_code = %s, std_out = %s, std_err = %s }", exit_code, std_out, std_err)

  return
end

local function dnd_command_updater(cmd, cb, args)
  if cmd ~= nil then
    task = hs.task.new(cmd, cb, args)
    task:start()
  end
end

module.dndHandler = function(win, dndConfig, event)
  if dndConfig == nil then return end

  log.df('dndHandler for %s found: %s..', win:application():name(), hs.inspect(dndConfig))

  local mode = dndConfig.mode

  if (dndConfig.enabled) then
    if (event == "windowCreated") then
      log.df('DND handler: toggling ON dnd and slack status mode to %s', mode)

      dnd_command_updater(os.getenv("HOME") ..  "/.dotfiles/bin/slack", nil, {mode})
      dnd_command_updater(os.getenv("HOME") ..  "/.dotfiles/bin/dnd", nil, {"on"})
    elseif (event == "windowDestroyed") then
      log.df('DND handler: toggling OFF dnd and slack mode to back')

      dnd_command_updater(os.getenv("HOME") ..  "/.dotfiles/bin/slack", nil, {"back"})
      dnd_command_updater(os.getenv("HOME") ..  "/.dotfiles/bin/dnd", nil, {"off"})
    end
  end
end

module.appHandler = function(win, handler, event)
  if handler == nil then return end
  local app = win:application()

  log.df('found app handler for %s (%s)..', app:name(), app:bundleID())

  if event == "windowCreated" then
    handler(win)
  end
end


module.doQuitApp = function(win)
  if win == nil then return end
  local app = win:application()

  app:kill()
end

module.doQuitWin = function(win)
  if win == nil then return end
  log.df('doQuitWin - %s', hs.inspect(win))

  win:close()
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

      if event == "windowUnfocused" or event == "windowHidden" or event == "windowMinimized" or event == "windowNotVisible" or event == "windowNotOnScreen" then
        log.df('quitAfterHandler - starting timer (%sm) on %s (%s), for event %s', interval, win:title(), appName, event)

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() doAppQuit(win) end)
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

      log.df('hideAfterHandler: %s', event)

      if event == "windowUnfocused" or event == "windowHidden" or event == "windowMinimized" or event == "windowNotVisible" or event == "windowNotOnScreen" then
        log.df('hideAfterHandler - starting timer (%sm) on %s (%s), for event %s', interval, win:title(), appName, event)

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() app:hide() end)
      end
    end
  else
    return
  end
end

return module
