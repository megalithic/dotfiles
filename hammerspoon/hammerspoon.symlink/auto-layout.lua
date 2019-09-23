local config = require('config')
local utils = require('utils')
local log = hs.logger.new('[layout]', 'debug')
local eventsWatcher = hs.uielement.watcher
local watchers = {}
local globalAppWatcher = nil
local screenCount = #hs.screen.allScreens()
local screenWatcher = nil
local isDocked = false

local target_display = function(display_int)
  -- detect the current number of monitors
  local displays = hs.screen.allScreens()
  if displays[display_int] ~= nil then
    return displays[display_int]
  else
    return hs.screen.primaryScreen()
  end
end

local getManageableWindows = function(windows)
  return hs.fnutils.filter(windows, (function(window)
    return utils.canManageWindow(window)
  end))
end

local isIgnoredWindow = function(window, appConfig)
  local foundIgnoredWindow = false
  if appConfig.ignoredWindows ~= nil then
    log.df(' ignoredWindows - checking for ignored window (window: %s) for app %s', window:title(),
      string.upper(appConfig.hint))
    if hs.fnutils.contains(appConfig.ignoredWindows, window:title()) then
      log.df(' ignoredWindows - found ignored window for custom layout, %s in app, %s', window:title(),
        string.upper(appConfig.hint))
      foundIgnoredWindow = true
      return true
    end
  end

  return foundIgnoredWindow
end


local dndHandler = function(windows, dnd, event)
  if dnd == nil then return end
  log.df('found dnd handler for %s..', win:application():bundleID())

  local enabled = dnd.enabled
  local mode = dnd.mode

  if (enabled) then
    if (event == "created") then
      log.df('dnd handler: toggling ON slack status (%s) and dnd mode', mode)
      hs.execute("slack " .. mode, true)
      hs.execute("dnd on", true)
    elseif (event == "destroyed") then
      -- log.df('dnd handler: toggling OFF slack status and dnd mode')
      -- hs.execute("slack back", true)
      -- hs.execute("dnd off", true)
    end
  end
end

local setLayoutForSingleWindow = function(window, appConfig)
  log.df(' setLayoutForApp (single window) - grid layout applied for app: %s, window: %s, target_display: %s, position: %s', string.upper(appConfig.hint), window:title(), target_display(appConfig.preferredDisplay), appConfig.position)

  if window ~= nil then
    if not isIgnoredWindow(window, appConfig) then
      hs.grid.set(window, appConfig.position, target_display(appConfig.preferredDisplay))
    end
  end
end

local setLayoutForMultiWindows = function(windows, appConfig)
  for index, window in pairs(windows) do
    log.df(' setLayoutForApp (multiple windows) - grid layout applied for app: %s, window: %s, # of windows: %s, target_display: %s, position: %s', string.upper(appConfig.hint), window:title(), #windows, target_display(appConfig.preferredDisplay), appConfig.position)

    if window ~= nil then
      if not isIgnoredWindow(window, appConfig) then
        if (index % 2 == 0) then -- even index/number
          hs.grid.set(window, config.grid.rightHalf, target_display(appConfig.preferredDisplay))
        else -- odd index/number
          hs.grid.set(window, config.grid.leftHalf, target_display(appConfig.preferredDisplay))
        end
      end
    end
  end
end

local setLayoutForApp = function(app, appConfig)
  if app ~= nil and app:mainWindow() ~= nil then
    log.df(' setLayoutForApp - beginning layout for single app: %s', string.upper(app:name()))

    local windows = getManageableWindows(app:visibleWindows())
    appConfig = appConfig or config.apps[app:name()]

    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      if (#windows == 1) then
        -- getting first (and should be) only window from the table of windows for this app
        setLayoutForSingleWindow(windows[1], appConfig)
      elseif (#windows > 1) then
        setLayoutForMultiWindows(windows, appConfig)
      else
        log.df(' setLayoutForApp (no manageable windows found) - grid layout NOT applied for app: %s, #windows: %s, target_display: %s, position: %s', string.upper(app:name()), #windows, target_display(appConfig.preferredDisplay), appConfig.position)
      end

      -- dndHandler(windoows, appConfig.dnd)
    else
      log.df(' setLayoutForApp - unable to find an app config for %s', string.upper(app:name()))
    end
  end
end

local setLayoutForAll = function()
  log.i(' setLayoutForAll - beginning layout for all apps')

  for _, appConfig in pairs(config.apps) do
    -- we have an appConfig and a preferredDisplay defined
    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      -- FIXME: bug showing up here: `attempt to index a nil value in hs.application.find`
      local app = hs.application.find(appConfig.hint)
      setLayoutForApp(app, appConfig)
    end
  end
end

local handleWindowEvent = function(window, event, watcher, info)
  log.df(' handleWindowEvent - window event; new window event (%s) for %s (%s)', event,
    window:application():bundleID(), info.id)

  if event == eventsWatcher.elementDestroyed then
    log.df(' handleWindowEvent - window event; %s destroyed for %s', info.id,
      window:application():bundleID())
    watcher:stop()
    watchers[info.pid].windows[info.id] = nil
    setLayoutForApp(window:application())
  else
    log.wf(' handleWindowEvent - window error; unexpected window event (%d) received', event)
  end
end

local watchWindow = function(window)
  local app = window:application()
  local bundleID = app:bundleID()
  local pid = app:pid()
  local windows = watchers[pid].windows

  if utils.canManageWindow(window) then
    local id = window:id()

    log.df(' watchWindow - window event; attempting to watch %s (app %s, window %s, ID %s, %s windows)',
      bundleID, string.upper(app:name()), window:title(), id, utils.windowCount(app))

    -- layout specifics for given apps
    if config.apps[app:name()] then
      log.df(' watchWindow - window event; watching %s (window %s, ID %s, %s windows) and applying layout for window/app', bundleID, window:title(), id, utils.windowCount(app))
      setLayoutForApp(app)

      -- execute custom app handler() for given application
      if config.apps[app:name()].handler ~= nil then
        log.df(' watchWindow - window event; found custom function for %s (app %s, window %s, ID %s, %s windows)', bundleID, string.upper(app:name()), window:title(), id, utils.windowCount(app))
        config.apps[app:name()].handler(window)
      end
    else
      -- otherwise just always do a default thing for unhandled apps
      setLayoutForApp()
    end

    -- Watch for window-closed events.
    if id then
      if not windows[id] then
        local watcher = window:newWatcher(handleWindowEvent, {
          id = id,
          pid = pid,
        })
        windows[id] = watcher
        watcher:start({eventsWatcher.elementDestroyed})
      end
    end
  else
    log.df(' watchWindow - window event; unable to watch unmanageable %s (window %s, ID %s, %s windows)',
      bundleID, window:title(), id, utils.windowCount(app))
  end
end

local handleAppEvent = function(element, event)
  if event == eventsWatcher.windowCreated then
    if pcall(function()
      log.df(' handleAppEvent - app event; window %s created for %s', element:id(),
        element:application():bundleID())
    end) then
      watchWindow(element)
    else
      log.wf(' handleAppEvent - app event error; thrown trying to access element (%s) in handleAppEvent',
        element)
    end
  else
    log.wf(' handleAppEvent - app event error; unexpected app event (%s) received', event)
  end
end

local watchApp = function(app)
  local pid = app:pid()
  if watchers[pid] or app:bundleID() == 'org.hammerspoon.Hammerspoon' or
    app:bundleID() == 'com.contextsformac.Contexts' then
    log.wf(' watchApp - app warning; attempted watch for already-watched app PID %d', pid)
    return
  end

  -- Watch for new windows.
  local watcher = app:newWatcher(handleAppEvent)
  watchers[pid] = {
    watcher = watcher,
    windows = {},
  }
  watcher:start({eventsWatcher.windowCreated})

  -- Watch already-existing windows.
  for _, window in pairs(app:allWindows()) do
    watchWindow(window)
  end
end

local unwatchApp = function(pid)
  local appWatcher = watchers[pid]
  if not appWatcher then
    log.wf(' unwatchApp - app warning; attempted unwatch for unknown app PID %d', pid)
    return
  end

  appWatcher.watcher:stop()
  for _, watcher in pairs(appWatcher.windows) do
    watcher:stop()
  end
  watchers[pid] = nil
  -- setLayoutForAll()
end

local handleGlobalAppEvent = function(name, eventType, app)
  if eventType == hs.application.watcher.launched then
    log.df(' handleGlobalAppEvent - global app event; launched %s', app:bundleID())
    if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
      watchApp(app)
    end
  elseif eventType == hs.application.watcher.terminated then
    -- Only the PID is set for terminated apps, so can't log bundleID.
    local pid = app:pid()
    log.df(' handleGlobalAppEvent - global app event; terminated PID %d', pid)
    unwatchApp(pid)
  end
end

local handleScreenEvent = function()
  -- Make sure that something noteworthy (display count) actually
  -- changed. We no longer check geometry because we were seeing spurious
  -- events.
  local screens = hs.screen.allScreens()

  log.df(' handleScreenEvent - screen event; new screens (%s), previous screens (%s)',
    #screens, screenCount)

  if #screens ~= screenCount then
    screenCount = #screens
    setLayoutForAll()
  end
end

return {
  init = (function(is_docked)
    isDocked = is_docked or false
    log.df('init window auto-layouts (docked: %s)', isDocked)

    -- Watch for screen changes
    screenWatcher = hs.screen.watcher.new(handleScreenEvent)
    screenWatcher:start()

    -- Watch for application-level events
    globalAppWatcher = hs.application.watcher.new(handleGlobalAppEvent)
    globalAppWatcher:start()

    -- Watch already-running applications
    local apps = hs.application.runningApplications()
    for _, app in pairs(apps) do
      if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
        watchApp(app)
      end
    end
  end),
  teardown = (function()
    log.df('teardown window auto-layouts')

    globalAppWatcher:stop()
    globalAppWatcher = nil

    for pid, _ in pairs(watchers) do
      unwatchApp(pid)
    end
    screenWatcher:stop()
    screenWatcher = nil
  end),
  snapAll = (function()
    setLayoutForAll()
  end),
  snapApp = (function(app)
    setLayoutForApp(app)
  end)
}
