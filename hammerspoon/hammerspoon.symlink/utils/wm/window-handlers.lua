local log = hs.logger.new('[window-handlers]', 'info')
local cache = { timers = {} }
local module = { cache = cache }

local function dnd_command_updater(cmd, cb, args)
  if cmd ~= nil then
    local task = hs.task.new(cmd, cb, args)
    task:start()
  end
end

module.dndHandler = function(win, dndConfig, event)
  if dndConfig == nil then return end

  local mode = dndConfig.mode

  if (dndConfig.enabled) then
    local slackCmd = os.getenv("HOME") ..  "/.dotfiles/bin/slack"
    local dndCmd = os.getenv("HOME") ..  "/.dotfiles/bin/dnd"

    if (event == "windowCreated") then
      log.df('DND handler: toggling ON dnd and slack status mode to %s', mode)

      dnd_command_updater(dndCmd, nil, {"on"})

      -- FIXME: for some reason i still have to verify it's not running and kill
      -- it; it for some reason shows up as being running and will turn DND to on
      -- if i close zoom in some weird way, for instance.
      hs.timer.waitUntil(function()
        return not win:application():isRunning()
      end,
      function()
        log.df('DND handler: toggling OFF dnd and slack mode to back; isRunning? %s', win:application():isRunning())

        dnd_command_updater(dndCmd, nil, {"off"})
      end,
      0.2)
    elseif (event == "windowDestroyed") then
      hs.timer.waitUntil(function()
        return not win:application():isRunning()
      end,
      function()
        log.df('DND handler: toggling OFF dnd and slack mode to back; isRunning? %s', win:application():isRunning())

        dnd_command_updater(dndCmd, nil, {"off"})
      end,
      0.2)
    end
  end
end

module.appHandler = function(win, handler, event)
  if handler == nil then return end
  local app = win:application()

  if event == "windowCreated" then
    log.df('found app handler for %s (%s)..', app:name(), app:bundleID())

    handler(win)
  end
end

module.killApp = function(win)
  if win == nil then return end
  local app = win:application()

  app:kill()
end

module.killWindow = function(win)
  if win == nil then return end

  win:close()
end

module.quitAfterHandler = function(win, interval, event)
  if interval ~= nil then
    local app = win:application()
    local appName = app:name()

    if (app:isRunning()) then
      if cache.timers[appName] ~= nil then
        log.df('quitAfterHandler - stopping existing timer on %s (%s), for event %s {timer = %s}', win:title(), appName, event, cache.timers[appName])

        cache.timers[appName]:stop()
      end

      log.df('quitAfterHandler event (%s) for app: %s', event, appName)

      if event == "windowUnfocused" or event == "windowHidden" or event == "windowMinimized" or event == "windowNotVisible" or event == "windowNotOnScreen" then
        log.df('quitAfterHandler - starting timer (%sm) on %s (%s), for event %s', interval, win:title(), appName, event)

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() module.killApp(win) end)
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
        log.df('hideAfterHandler - stopping existing timer on %s (%s), for event %s {timer = %s}', win:title(), appName, event, cache.timers[appName])

        cache.timers[appName]:stop()
      end

      log.df('hideAfterHandler event (%s) for app: %s', event, appName)

      if event == "windowUnfocused" or event == "windowHidden" or event == "windowMinimized" or event == "windowNotVisible" or event == "windowNotOnScreen" then
        log.df('hideAfterHandler - starting timer (%sm) on %s (%s), for event %s', interval, win:title(), appName, event)

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() app:hide() end)
      end
    end
  else
    return
  end
end

-- module.buildLayout = function()
--   local layout = {}
--   table.insert(
--     layout,
--     {
--       appConfig.bundleID,
--       window,
--       module.targetDisplay(appConfig.preferredDisplay),
--       appConfig.position, -- hs.layout.maximized,
--       nil,
--       nil
--     }
--   )
--   hs.layout.apply(layout)
-- end


-- targetDisplay(int) :: hs.screen
-- detect the current number of monitors and return target screen
module.targetDisplay = function(displayInt)
  local displays = hs.screen.allScreens()
  if displays[displayInt] ~= nil then
    return displays[displayInt]
  else
    return hs.screen.primaryScreen()
  end
end

-- validWindows(hs.application) :: {hs.window}
module.validWindows = function(app)
  local windows = hs.fnutils.filter(app:allWindows(), (function(win)
    return win ~= nil and win:title() ~= "" and win:isStandard() and not win:isMinimized() and not win:isFullScreen()
  end))

  return windows
end

-- snap(hs.window, string, int) :: nil
-- does the actual hs.grid activities for positioning a given window
module.snap = function(win, position, preferredDisplay)
  if win == nil then return end

  hs.grid.set(win, position or hs.grid.get(win), module.targetDisplay(preferredDisplay))
end

-- snapRelated(hs.application, table) :: nil
-- handles positioning of related windows for an app
module.snapRelated = function(app, appConfig)
  if appConfig == nil then return end
  local windows = module.validWindows(app)

  for index, win in pairs(windows) do
    if win == nil then return end

    if (index % 2 == 0) then -- even index/number
      module.snap(win, config.grid.rightHalf, appConfig.preferredDisplay)
    else -- odd index/number
      module.snap(win, config.grid.leftHalf, appConfig.preferredDisplay)
    end
  end
end

return module
