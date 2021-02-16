local log = hs.logger.new("[window-handlers]", "warning")

local cache = {timers = {}}
local M = {cache = cache}

local fn = require("hs.fnutils")

local function dnd_command_updater(cmd, cb, args)
  if cmd ~= nil then
    local task = hs.task.new(cmd, cb, args)
    task:start()
  end
end

-- onAppQuit(hs.application, function) :: nil
-- evaluates and returns valid/usable windows for an app
M.onAppQuit = function(app, callback, providedInterval)
  local interval = providedInterval or 0.2

  hs.timer.waitUntil(
    function()
      return app == nil or #app:allWindows() == 0
      -- return app == nil or (not hs.application.get(app:name()) and #app:allWindows() == 0)
    end,
    callback,
    interval
  )
end

M.killApp = function(app)
  if app == nil then
    log.wf("no valid app given; unable to kill -> %s")
    return
  end

  app:kill()
end

M.killWindow = function(win)
  if win == nil then
    return
  end

  win:close()
end

M.dndHandler = function(app, dndConfig, event)
  if dndConfig == nil then
    return
  end

  local mode = dndConfig.mode

  if (dndConfig.enabled) then
    -- local slackCmd = os.getenv("HOME") ..  "/.dotfiles/bin/slack"
    local dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"

    if fn.contains({"windowCreated", hs.application.watcher.launched}, event) then
      log.df("DND Handler: on/" .. mode)

      dnd_command_updater(dndCmd, nil, {"on"})

      M.onAppQuit(
        app,
        function()
          log.df("DND Handler: off/back")
          dnd_command_updater(dndCmd, nil, {"off"})
        end
      )
    elseif fn.contains({"windowDestroyed", hs.application.watcher.terminated}, event) then
      M.onAppQuit(
        app,
        function()
          log.df("DND Handler: off/back")
          dnd_command_updater(dndCmd, nil, {"off"})
        end
      )
    end
  end
end

M.quitAfterHandler = function(app, interval, event)
  if interval ~= nil then
    local app_name = app:name()

    if (app:isRunning()) then
      if cache.timers[app_name] ~= nil then
        log.df("stopping quit timer on " .. app_name)

        cache.timers[app_name]:stop()
      end

      if
        fn.contains(
          {
            "windowUnfocused",
            "windowHidden",
            "windowMinimized",
            "windowNotVisible",
            "windowNotOnScreen",
            hs.application.watcher.deactivated,
            hs.application.watcher.hidden
          },
          event
        )
       then
        log.df("starting quit timer on " .. app_name)

        cache.timers[app_name] =
          hs.timer.doAfter(
          (interval * 60),
          function()
            M.killApp(app)
          end
        )
      end
    end
  else
    return
  end
end

M.hideAfterHandler = function(app, interval, event)
  if interval ~= nil then
    local app_name = app:name()

    if app:isRunning() and not app:isHidden() then
      if cache.timers[app_name] ~= nil then
        log.df("stopping hide timer on " .. app_name)

        cache.timers[app_name]:stop()
      end

      if
        fn.contains(
          {
            "windowUnfocused",
            "windowHidden",
            "windowMinimized",
            "windowNotVisible",
            "windowNotOnScreen",
            hs.application.watcher.deactivated,
            hs.application.watcher.hidden
          },
          event
        )
       then
        log.df("starting hide timer on " .. app_name)

        cache.timers[app_name] =
          hs.timer.doAfter(
          (interval * 60),
          function()
            app:hide()
          end
        )
      end
    end
  else
    return
  end
end

M.layoutFromGrid = function(gridCell, screenNum)
  local geometry = hs.grid.getCell(gridCell, M.targetDisplay(screenNum))
  local rect = hs.geometry(geometry)

  -- print("gridCell -> " .. gridCell)
  -- print("geometry -> " .. hs.inspect(geometry))
  -- print("rect -> " .. hs.inspect(rect))

  return rect
end

-- targetDisplay(int) :: hs.screen
-- detect the current number of monitors and return target screen
M.targetDisplay = function(num)
  local displays = hs.screen.allScreens()
  if displays[num] ~= nil then
    return displays[num]
  else
    return hs.screen.primaryScreen()
  end
end

-- ignoredWindowTitles(table) :: {string}
-- gathers the window titles from the given app config's rules
M.ignoredWindowTitles = function(app_config)
  if app_config == nil or app_config.rules == nil then
    return {}
  end

  local ignoredWindowTitles = {}

  for _, rule in pairs(app_config.rules) do
    if rule ~= nil then
      table.insert(ignoredWindowTitles, rule.title)
    end
  end

  log.df("ignoredWindowTitles::%s[%s]", app_config.bundleID, #ignoredWindowTitles)

  return ignoredWindowTitles
end

-- validWindows(hs.application) :: {hs.window}
-- optional: hs.application
-- evaluates and returns valid/usable windows for an app
M.validWindows = function(app)
  local windowProvider = (app and app:allWindows()) or hs.window.orderedWindows()

  local windows =
    fn.filter(
    windowProvider,
    (function(win)
      log.df("validWindow::%s | isVisible? -> %s", win:title(), win:isVisible())
      return win ~= nil and win:title() ~= "" and win:isStandard() and win:isVisible() and not win:isFullScreen()
    end)
  )

  log.df("validWindows::%s[%s]", (app and app:bundleID()) or "no-app", #windows)

  return windows
end

-- managedWindows(hs.application, {hs.window}, {string}) :: {hs.window}
-- evaluates and returns valid/usable/managed windows for an app
M.managedWindows = function(app, validWindows, ignoredWindowTitles)
  local windows =
    fn.filter(
    validWindows,
    (function(win)
      return not fn.contains(ignoredWindowTitles, win:title())
    end)
  )

  log.df("managedWindows::%s[%s]", app:bundleID(), #windows)

  return windows
end

-- snap(hs.window, string, int) :: nil
-- does the actual hs.grid `set` for positioning a given window in our grid
M.snap = function(win, position, preferredDisplay)
  if win == nil then
    return
  end

  log.df("snap -> %s", win:title())
  hs.grid.set(win, position or hs.grid.get(win), M.targetDisplay(preferredDisplay))
end

-- snapRelated(hs.application, table, {hs.window}) :: nil
-- handles positioning of related windows for an app
M.snapRelated = function(_, app_config, windows)
  if app_config == nil then
    return
  end

  if #windows == 1 then
    M.snap(windows[1], app_config.position, app_config.preferredDisplay)

    return
  end

  for index, win in pairs(windows) do
    if win == nil then
      return
    end

    if (index % 2 == 0) then -- even index/number
      M.snap(win, config.grid.rightHalf, app_config.preferredDisplay)
    else -- odd index/number
      M.snap(win, config.grid.leftHalf, app_config.preferredDisplay)
    end
  end
end

-- applyRules(table, hs.window, table) :: nil
-- handles positioning of related windows for an app
M.applyRules = function(rules, win, app_config)
  -- exit from this function for now.. need to figure out how to use hs.layout
  -- to do multi-window layout rules.
  -- return
  -- for _, rule in pairs(rules) do
  --   if win:title() == rule.title then
  --     if rule.action == "snap" then
  --       M.snap(win, rule.position or app_config.position, app_config.preferredDisplay)
  --     elseif rule.action == "quit" then
  --       M.killWindow(win)
  --     elseif rule.action == "hide" then
  --       -- FIXME: do we just do another window kill here, instead?
  --       -- M.killWindow(win)
  --       -- or --
  --       -- win:application():hide()
  --     elseif rule.action == "ignore" then
  --       log.wf("applyRules -> ignoring window [%s]", win:title())
  --       return
  --     end
  --   -- else
  --   --   log.wf("applyRules::%s -> no matching window titles [%s]", app_config.bundleID, win:title())
  --   end
  -- end
end

return M
