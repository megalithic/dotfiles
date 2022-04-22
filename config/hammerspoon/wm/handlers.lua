local log = hs.logger.new("[window-handlers]", "debug")
local running = require("wm.running")

local cache = { timers = {}, watchers = {} }
local M = { cache = cache }

local fn = require("hs.fnutils")

local split = function(str)
  local t = {}
  for token in string.gmatch(str, "[^%s]+") do
    table.insert(t, token)
  end
  return t
end

local function cmd_updater(args, use_prefix)
  if args ~= nil then
    local cmd
    local cmd_args = split(args)

    if use_prefix ~= nil and use_prefix then
      cmd = "/usr/local/bin/zsh"
      table.insert(cmd_args, 1, "-ic")
      log.df("using prefix: %s, %s", cmd, hs.inspect(cmd_args))
    else
      cmd = table.remove(cmd_args, 1)
      log.df("not using prefix: %s, %s", cmd, hs.inspect(cmd_args))
    end

    -- spews errors, BUT, it seems to work async! yay?
    local task = hs.task.new(cmd, function(stdTask, stdOut, stdErr)
      -- log.df("\nstdTask: %s\n stdOut: %s\n stdErr: %s\n", stdTask, stdOut, stdErr)
    end, cmd_args):start()
    -- log.df("running_task: %s", hs.inspect(task))

    return task

    -- NOTE: keep this in case hs.task fails again
    -- return hs.execute(args, true)
  end

  return nil
end

-- FIXME: need to be able to app-watch for the dndHandler too; not just for the context
-- onAppQuit(hs.application, function, number) :: nil
---@diagnostic disable-next-line: unused-local
M.onAppQuit = function(app, callback, providedInterval)
  -- local bundleID = app:bundleID()

  -- log.df("onAppQuit starting for %s; current app watchers: %s", bundleID, hs.inspect(cache.watchers))

  -- if cache.watchers[bundleID] ~= nil then
  --   log.df("found existing watcher for %s; killing it..", bundleID)
  --   -- kill the original watcher if there is one
  --   cache.watchers[bundleID] = nil
  -- end

  -- log.df("creating watcher for %s..", bundleID)
  -- cache.watchers[bundleID] = hs.application.watcher.new(function(appName, event, appObj)
  --   if event == hs.application.watcher.terminated then
  --     log.df("executing watcher callback for %s (%s)..", bundleID, appObj)
  --     callback(appName, event, appObj)

  --     if cache.watchers[bundleID] then
  --       log.df("stopping watcher for %s (%s)..", bundleID, appObj)

  --       cache.watchers[bundleID]:stop()
  --       cache.watchers[bundleID] = nil

  --       log.df("watcher stopped for %s: %s", bundleID, cache.watchers[bundleID])
  --     end
  --   end
  -- end):start()

  -- FIXME: old way .. don't really want this loop running forever while the app is open
  local interval = providedInterval or 2.0
  hs.timer.waitUntil(function()
    local success = app == nil or #app:allWindows() == 0
    return success
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
    -- FIXME: hs.task.new .. i hate you; i cannot get env variables and such in
    -- to my script. :/
    -- local slackCmd = os.getenv("HOME") .. "/.dotfiles/bin/slack"
    local dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"

    if event == running.events.created or event == running.events.launched then
      log.df("DND Handler: on/" .. mode)

      cmd_updater(dndCmd .. " on", false)
      -- cmd_updater(slackCmd .. " -sv " .. mode, false)

      M.onAppQuit(app, function()
        cmd_updater(dndCmd .. " off", false)
        -- cmd_updater(slackCmd .. " -sv back", false)
      end)
    elseif event == event == running.events.terminated then
      M.onAppQuit(app, function()
        cmd_updater(dndCmd .. " off", false)
        -- cmd_updater(slackCmd .. " -sv back", false)
      end)
    elseif type(event) == "table" and event.which ~= nil then
      cmd_updater(string.format("%s %s", dndCmd, event.which)) -- which: on | off
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
