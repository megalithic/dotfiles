local config = require('config')
local utils = require('utils')
local log = hs.logger.new('[layout]', 'debug')
local eventsWatcher = hs.uielement.watcher
local watchedApps = {}
local appWatcher = nil
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


local canManageWindow = function (window)
  local bundleID = window:application():bundleID()

  return window:title() ~= "" and window:isStandard() and not window:isMinimized() or
    bundleID == 'com.googlecode.iterm2' or bundleID == 'net.kovidgoyal.kitty'
end

local getManageableWindows = function(windows)
  return hs.fnutils.filter(windows, (function(window)
    return canManageWindow(window)
  end))
end

local isIgnoredWindow = function(window, appConfig)
  local foundIgnoredWindow = false
  if appConfig.ignoredWindows ~= nil then
    log.df('(ignoredWindows) checking for ignored window (window: %s) for app %s', window:title(),
      string.upper(appConfig.hint))
    if hs.fnutils.contains(appConfig.ignoredWindows, window:title()) then
      log.df('(ignoredWindows) found ignored window for custom layout, %s in app, %s', window:title(),
        string.upper(appConfig.hint))
      foundIgnoredWindow = true
      return foundIgnoredWindow
    end
  end

  return foundIgnoredWindow
end


local dndHandler = function(win, dnd, event)
  if win == nil or dnd == nil or event == nil then return end
  log.df('(dndHandler) found DND handler for %s..', win:application():bundleID())

  local enabled = dnd.enabled
  local mode = dnd.mode

  if (enabled) then
    if (event == "created") then
      log.df('(dndHander) toggling ON slack status (%s) and DND mode', mode)
      hs.execute("slack " .. mode, true)
      hs.execute("dnd on", true)
    elseif (event == "destroyed") then
      -- FIXME: this only works for app watchers it seems; nothing to do with dead windows :(
      log.df('(dndHander) would be toggling OFF slack status and DND mode')
      -- hs.execute("slack back", true)
      -- hs.execute("dnd off", true)
    end
  end
end

local appHandler = function(win, handler)
  if win == nil or handler == nil then return end
  log.df('(appHandler) found custom app handler for %s..', win:application():bundleID())

  handler(win)
end

local snap = function(win, position, screen)
  if win == nil then return end
  log.df('(window snap to %s): %s', position, win:title())

  -- local wf = hs.window.filter
  -- local appBundleID = win:application():bundleID()
  -- local appName = win:application():name()
  -- local allWindows = win:application():visibleWindows()
  -- local relatedWindowsFilter = wf.new{[appName]={allowTitles=1}}
  -- local relatedWindowsFilter = wf.new{appName}:setAppFilter(appName, {allowTitles=1})

  -- print('allWindows: - ', hs.inspect(relatedWindowsFilter))
  -- print('allWindows: - ', hs.inspect(allWindows[1]))
  -- print('allWindows:isStandard(): - ', hs.inspect(allWindows[1]:isStandard()))

  -- if (#allWindows > 1) then
  --   snapRelatedWindows(appBundleID, allWindows, screen)
  -- else
  --   snap(win, position or hs.grid.get(win), screen)
  -- end

  hs.grid.set(win, position or hs.grid.get(win), screen)
end

local setLayoutForSingleWindow = function(window, appConfig)
  log.df('(setLayoutForSingleWindow) grid layout applied for app: %s, window: %s, target_display: %s, position: %s', string.upper(appConfig.hint), window:title(), target_display(appConfig.preferredDisplay), appConfig.position)

  if window ~= nil then
    if not isIgnoredWindow(window, appConfig) then
      snap(window, appConfig.position, target_display(appConfig.preferredDisplay))
    end
  end
end

local setLayoutForMultiWindows = function(windows, appConfig)
  for index, window in pairs(windows) do
    log.df('(setLayoutForMultiWindows) grid layout applied for app: %s, window: %s, # of windows: %s, target_display: %s, position: %s', string.upper(appConfig.hint), window:title(), #windows, target_display(appConfig.preferredDisplay), appConfig.position)

    if window ~= nil then
      if not isIgnoredWindow(window, appConfig) then
        if (index % 2 == 0) then -- even index/number
          snap(window, config.grid.rightHalf, target_display(appConfig.preferredDisplay))
        else -- odd index/number
          snap(window, config.grid.leftHalf, target_display(appConfig.preferredDisplay))
        end
      end
    end
  end
end

local setLayoutForApp = function(app, appConfig)
  if app ~= nil and app:mainWindow() ~= nil then
    log.df('(setLayoutForApp) starting layout for single app: %s', string.upper(app:name()))

    local windows = getManageableWindows(app:visibleWindows())
    appConfig = appConfig or config.apps[app:name()]

    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      if (#windows == 1) then
        -- getting first (and should be) only window from the table of windows for this app
        setLayoutForSingleWindow(windows[1], appConfig)
      elseif (#windows > 1) then
        setLayoutForMultiWindows(windows, appConfig)
      else
        log.df('(setLayoutForApp) grid layout NOT applied for app (no windows found for app): %s, #windows: %s, target_display: %s, position: %s', string.upper(app:name()), #windows, target_display(appConfig.preferredDisplay), appConfig.position)
      end
    else
      log.df('(setLayoutForApp) unable to find an app config for %s', string.upper(app:name()))
    end
  end
end

local setLayoutForAll = function()
  log.i('(setLayoutForAll) starting layout for all apps')

  for app, appConfig in pairs(config.apps) do
    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      setLayoutForApp(app, appConfig)
    end
  end
end

local handleWindowEvent = function(window, event, watcher, info)
  log.df('(handleWindowEvent) new window event (%s) for %s (%s)', event,
    window:application():bundleID(), info.id)

  if event == eventsWatcher.elementDestroyed then
    log.df('(handleWindowEvent) %s destroyed for %s', info.id,
      window:application():bundleID())
    watcher:stop()
    watchedApps[info.pid].windows[info.id] = nil
    setLayoutForApp(window:application())
  else
    log.wf('(handleWindowEvent) unexpected window event (%d) received', event)
  end
end

local watchWindow = function(window)
  local app = window:application()
  local bundleID = app:bundleID()
  local pid = app:pid()
  local windows = watchedApps[pid].windows
  local appConfig = config.apps[bundleID]
  local id = window:id()

  if canManageWindow(window) then
    log.df('(watchWindow) attempting to watch window %s (app %s, window %s, ID %s, %s windows)',
      bundleID, string.upper(app:name()), window:title(), id, utils.windowCount(app))

    -- layout specifics for given apps
    if config.apps[app:name()] then
      log.df('(watchWindow) applying layout for window/app: %s (window %s, ID %s, %s windows)', bundleID, window:title(), id, utils.windowCount(app))

      setLayoutForApp(app)
      dndHandler(window, appConfig.dnd)
      appHandler(window, appConfig.handler)
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
    log.df('(watchWindow) unable to watch unmanageable window %s (window %s, ID %s, %s windows)',
      bundleID, window:title(), id, utils.windowCount(app))
  end
end

local handleElementEvent = function(element, event)
  if event == eventsWatcher.windowCreated then
    if pcall(function()
      log.df('(handleElementEvent) window %s created for %s', element:id(),
        element:application():bundleID())
    end) then
      watchWindow(element)
    else
      log.wf('(handleElementEvent) error thrown trying to access element (%s)',
        element)
    end
  else
    log.wf('(handleElementEvent) unexpected app event (%s) received', event)
  end
end

local watchApp = function(app)
  local pid = app:pid()
  local appBundleID = app:bundleID()

  if watchedApps[pid] or appBundleID == 'org.hammerspoon.Hammerspoon' or
    appBundleID == 'com.contextsformac.Contexts' then

    log.wf('(watchApp) app (%s) already watched (%d)', appBundleID, pid)
    return
  end

  -- Watch for new UI element (window?).
  local elementWatcher = app:newWatcher(handleElementEvent)

  watchedApps[pid] = {
    watcher = elementWatcher,
    windows = {},
  }
  elementWatcher:start({eventsWatcher.windowCreated})

  -- Watch already-existing windows.
  for _, window in pairs(app:allWindows()) do
    watchWindow(window)
  end
end

local unwatchApp = function(pid)
  log.df('(unwatchApp) attempting to unwatching app for PID (%d)', pid)

  local watchedApp = watchedApps[pid]

  if not watchedApp then
    log.wf('(unwatchApp) app PID (%d) not found in previously watched apps list', pid)
    return
  end

  log.df('(unwatchApp) unwatched app (%d) %s', pid, hs.inspect(watchedApp))
  watchedApp.watcher:stop()
  for _, watchedWindow in pairs(watchedApp.windows) do
    log.df('(unwatchApp) unwatched window %s', hs.inspect(watchedWindow))
    watchedWindow:stop()
  end
  watchedApps[pid] = nil

  -- setLayoutForAll()
end

local handleAppEvent = function(name, eventType, app)
  log.df('(handleAppEvent) app (%s) event (%s): %s', name, eventType, hs.application.watcher[eventType])

  if eventType == hs.application.watcher.launched then
    log.df('(handleAppEvent) watching launched %s (%s)', name, app:bundleID())
    if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
      watchApp(app)
    end
  elseif eventType == hs.application.watcher.terminated then
    -- Only the PID is set for terminated apps, so can't log bundleID.
    local pid = app:pid()
    log.df('(handleAppEvent) unwatching terminated app for PID %d', pid)
    unwatchApp(pid)
  end
end

local handleScreenEvent = function(eventType)
  log.df('(handleScreenEvent) screen event (%s): %s', eventType, hs.caffeinate.watcher[eventType])

  setLayoutForAll()
end

return {
  init = (function(is_docked)
    isDocked = is_docked or false
    log.df('init auto-layout (docked: %s)', isDocked)

    -- Watch for screen changes
    screenWatcher = hs.screen.watcher.new(handleScreenEvent)
    screenWatcher:start()

    -- Watch for application-level events
    appWatcher = hs.application.watcher.new(handleAppEvent)
    appWatcher:start()

    -- Watch already-running applications
    local runningApps = hs.application.runningApplications()
    for _, app in pairs(runningApps) do
      if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
        watchApp(app)
      end
    end
  end),

  teardown = (function()
    log.df('teardown auto-layout')

    appWatcher:stop()
    appWatcher = nil

    for pid, _ in pairs(watchedApps) do
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
