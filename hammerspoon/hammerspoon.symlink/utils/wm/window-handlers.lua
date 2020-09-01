local log = hs.logger.new('[window-handlers]', 'info')
local cache = { timers = {} }
local module = { cache = cache }

local function dnd_command_updater(cmd, cb, args)
  if cmd ~= nil then
    local task = hs.task.new(cmd, cb, args)
    task:start()
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

module.dndHandler = function(win, dndConfig, event)
  if dndConfig == nil then return end

  local mode = dndConfig.mode

  if (dndConfig.enabled) then
    -- local slackCmd = os.getenv("HOME") ..  "/.dotfiles/bin/slack"
    local dndCmd = os.getenv("HOME") ..  "/.dotfiles/bin/dnd"

    if (event == "windowCreated") then
      log.df("DND Handler: on/".. mode)

      dnd_command_updater(dndCmd, nil, {"on"})

      module.onAppQuit(win, function()
        log.df("DND Handler: off/back")
        dnd_command_updater(dndCmd, nil, {"off"})
      end)
    elseif (event == "windowDestroyed") then
      module.onAppQuit(win, function()
        log.df("DND Handler: off/back")
        dnd_command_updater(dndCmd, nil, {"off"})
      end)
    end
  end
end

module.quitAfterHandler = function(win, interval, event)
  if interval ~= nil then
    local app = win:application()
    local appName = app:name()

    if (app:isRunning()) then
      if cache.timers[appName] ~= nil then
        log.df("stopping quit timer on ".. win:title())

        cache.timers[appName]:stop()
      end

      if hs.fnutils.contains({"windowUnfocused", "windowHidden", "windowMinimized", "windowNotVisible", "windowNotOnScreen"}, event) then
        log.df("starting quit timer on ".. win:title())

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
        log.df("stopping hide timer on ".. win:title())

        cache.timers[appName]:stop()
      end

      if hs.fnutils.contains({"windowUnfocused", "windowHidden", "windowMinimized", "windowNotVisible", "windowNotOnScreen"}, event) then
        log.df("starting hide timer on ".. win:title())

        cache.timers[appName] = hs.timer.doAfter((interval*60), function() app:hide() end)
      end
    end
  else
    return
  end
end

-- onAppQuit(hs.window, function) :: nil
-- evaluates and returns valid/usable windows for an app
module.onAppQuit = function(win, callback, providedInterval)
  local interval = providedInterval or 0.2
  local app = win:application()

  hs.timer.waitUntil(function()
    return app == nil or (not app:isRunning() and not hs.application.find(app:name()) and #app:allWindows() == 0)
  end,
  callback,
  interval)
end

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

-- ignoredWindowTitles(table) :: {string}
-- gathers the window titles from the given app config's rules
module.ignoredWindowTitles = function(appConfig)
  if appConfig == nil or appConfig.rules == nil then return {} end

  local ignoredWindowTitles = {}

  for _, rule in pairs(appConfig.rules) do
    if rule ~= nil then
      table.insert(ignoredWindowTitles, rule.title)
    end
  end

  log.df("ignoredWindowTitles::%s[%s]", appConfig.bundleID, #ignoredWindowTitles)

  return ignoredWindowTitles
end

-- validWindows(hs.application) :: {hs.window}
-- optional: hs.application
-- evaluates and returns valid/usable windows for an app
module.validWindows = function(app)
  local windowProvider = (app and app:allWindows()) or hs.window.filter.default:getWindows()

  local windows = hs.fnutils.filter(windowProvider, (function(win)
    return win ~= nil and win:title() ~= "" and win:isStandard() and win:isVisible() and not win:isFullScreen()
  end))

  log.df("validWindows::%s[%s]", (app and app:bundleID()) or "no-app", #windows)

  return windows
end

-- managedWindows(hs.application, {hs.window}, {string}) :: {hs.window}
-- evaluates and returns valid/usable/managed windows for an app
module.managedWindows = function(app, validWindows, ignoredWindowTitles)
  local windows = hs.fnutils.filter(validWindows, (function(win)
    return not hs.fnutils.contains(ignoredWindowTitles, win:title())
  end))

  log.df("managedWindows::%s[%s]", app:bundleID(), #windows)

  return windows
end

-- snap(hs.window, string, int) :: nil
-- does the actual hs.grid `set` for positioning a given window in our grid
module.snap = function(win, position, preferredDisplay)
  if win == nil then return end

  log.df("snap -> %s", win:title())
  hs.grid.set(win, position or hs.grid.get(win), module.targetDisplay(preferredDisplay))
end

-- snapRelated(hs.application, table, {hs.window}) :: nil
-- handles positioning of related windows for an app
module.snapRelated = function(_, appConfig, windows)
  if appConfig == nil then return end

  if #windows == 1 then
    module.snap(windows[1], appConfig.position, appConfig.preferredDisplay)

    return
  end

  for index, win in pairs(windows) do
    if win == nil then return end

    if (index % 2 == 0) then -- even index/number
      module.snap(win, config.grid.rightHalf, appConfig.preferredDisplay)
    else -- odd index/number
      module.snap(win, config.grid.leftHalf, appConfig.preferredDisplay)
    end
  end
end

-- applyRules(table, hs.window, table) :: nil
-- handles positioning of related windows for an app
module.applyRules = function(rules, win, appConfig)
  for _, rule in pairs(rules) do
    if win:title() == rule.title then
      if rule.action == "snap" then
        module.snap(win, rule.position or appConfig.position, appConfig.preferredDisplay)
      elseif rule.action == "quit" then
        module.killWindow(win)
      elseif rule.action == "hide" then
        -- FIXME: do we just do another window kill here, instead?
        -- module.killWindow(win)
        -- or --
        -- win:application():hide()
      elseif rule.action == "ignore" then
        log.wf("applyRules -> ignoring window [%s]", win:title())

        return
      end
    -- else
    --   log.wf("applyRules::%s -> no matching window titles [%s]", appConfig.bundleID, win:title())
    end
  end
end

return module
