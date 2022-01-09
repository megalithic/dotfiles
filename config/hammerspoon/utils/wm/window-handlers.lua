local log = hs.logger.new("[window-handlers]", "warning")
local running = require("utils.wm.running")

local cache = { timers = {} }
local M = { cache = cache }

local fn = require("hs.fnutils")

local function cmd_updater(cmd)
  if cmd ~= nil then
    return hs.execute(cmd, true)
  end

  return nil
end

-- onAppQuit(hs.application, function) :: nil
-- evaluates and returns valid/usable windows for an app
M.onAppQuit = function(app, callback, providedInterval)
  log.df("onAppQuit -> %s", app:name())

  local interval = providedInterval or 0.2

  hs.timer.waitUntil(function()
    local success = app == nil or #app:allWindows() == 0
    -- log.wf("success for onAppQuit -> %s", success)

    return success
    -- return app == nil or (not hs.application.get(app:name()) and #app:allWindows() == 0)
  end, callback, interval)
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

  if dndConfig.enabled then
    local slackCmd = os.getenv("HOME") .. "/.dotfiles/bin/slack"
    local dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"

    if event == running.events.created or event == running.events.launched then
      log.df("DND Handler: on/" .. mode)

      cmd_updater(dndCmd .. " on")
      cmd_updater(slackCmd .. " " .. mode)

      M.onAppQuit(app, function()
        cmd_updater(dndCmd .. " off")
        local out, status, type, rc = cmd_updater(slackCmd .. " -s back")
        log.df(
          "DND Handler (slack): off/back/silent; %s,%s,%s,%s",
          hs.inspect(out),
          hs.inspect(status),
          hs.inspect(type),
          hs.inspect(rc)
        )
      end)
    elseif event == running.events.closed or event == running.events.terminated then
      M.onAppQuit(app, function()
        cmd_updater(dndCmd .. " off")
        local out, status, type, rc = cmd_updater(slackCmd .. " gs back")
        log.df(
          "DND Handler (slack): off/back/silent; %s,%s,%s,%s",
          hs.inspect(out),
          hs.inspect(status),
          hs.inspect(type),
          hs.inspect(rc)
        )
      end)
    end
  end
end

M.quitAfterHandler = function(app, interval, event)
  if interval ~= nil then
    local app_name = app:name()

    if app:isRunning() then
      if cache.timers[app_name] ~= nil then
        log.df("stopping quit timer on " .. app_name)

        cache.timers[app_name]:stop()
      end

      if event == running.events.hidden then
        log.df("starting quit timer on " .. app_name)

        cache.timers[app_name] = hs.timer.doAfter((interval * 60), function()
          M.killApp(app)
        end)
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

      if event == running.events.hidden then
        log.df("starting hide timer on " .. app_name)

        cache.timers[app_name] = hs.timer.doAfter((interval * 60), function()
          app:hide()
        end)
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

  local windows = fn.filter(windowProvider, function(win)
    log.df("validWindow::%s | isVisible? -> %s", win:title(), win:isVisible())
    return win ~= nil and win:title() ~= "" and win:isStandard() and win:isVisible() and not win:isFullScreen()
  end)

  log.df("validWindows::%s[%s]", (app and app:bundleID()) or "no-app", #windows)

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

    if index % 2 == 0 then -- even index/number
      M.snap(win, config.grid.rightHalf, app_config.preferredDisplay)
    else -- odd index/number
      M.snap(win, config.grid.leftHalf, app_config.preferredDisplay)
    end
  end
end

return M