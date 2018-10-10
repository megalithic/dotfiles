local config = require('config')
local utils = require('utils')
local eventsWatcher = hs.uielement.watcher
local watchers = {}
local globalAppWatcher = nil
local screenCount = #hs.screen.allScreens()

events = {}

target_display = function(display_int)
  -- detect the current number of monitors
  displays = hs.screen.allScreens()
  if displays[display_int] ~= nil then
    return displays[display_int]
  else
    return hs.screen.primaryScreen()
  end
end

-- FIXME: simply must DRY up setLayoutForAll
setLayoutForAll = function()
  log.i('[auto-layout] setLayoutForAll - beginning layout for all apps')

  for _, appConfig in pairs(config.applications) do
    -- if we have a preferred display
    if appConfig.preferredDisplay ~= nil then
      application = hs.application.find(appConfig.name)

      if application ~= nil and application:mainWindow() ~= nil then
        local windows = application:visibleWindows()
        -- we are always positioning ALL the windows, we need a single window positioner method at some point..
        -- TODO: add a single window watcher and window handler, don't always handle all the windows.
        for _, window in pairs(windows) do
          if utils.canManageWindow(window) then
            log.df('[auto-layout] setLayoutForAll - grid layout applied for app: %s, window: %s, target_display: %s, position: %s', application:name(), window:title(), target_display(appConfig.preferredDisplay), appConfig.position)
            hs.grid.set(window, appConfig.position, target_display(appConfig.preferredDisplay))
          end
        end
      end
    end
  end
end

-- FIXME: simply must DRY up setLayoutForApp
setLayoutForApp = function(app) -- optionally, we should be able to take in a `window` to layout
  if app ~= nil and app:mainWindow() ~= nil then
    log.i('[auto-layout] setLayoutForApp - beginning layout for single app')

    local windows = app:visibleWindows()
    local appConfig = config.applications[app:name()]

    if appConfig ~= nil then
      -- we are always positioning ALL the windows, we need a single window positioner method at some point..
      -- TODO: add a single window watcher and window handler, don't always handle all the windows.
      for _, window in pairs(windows) do
        if utils.canManageWindow(window) then
          log.df('[auto-layout] setLayoutForApp - grid layout applied for app: %s, window: %s, target_display: %s, position: %s', app:name(), window:title(), target_display(appConfig.preferredDisplay), appConfig.position)
          hs.grid.set(window, appConfig.position, target_display(appConfig.preferredDisplay))
        end
      end
    else
      log.df('[auto-layout] setLayoutForApp - unable to find an app config for %s', app:name())
    end
  else
    -- default/general layout for apps not given a specific config
    local app = hs.application.frontmostApplication()
    local windows = app:visibleWindows()
    local appConfig = config.applications['default']

    for _, window in pairs(windows) do
      if utils.canManageWindow(window) then
        log.df('[auto-layout] setLayoutForApp (default) - grid layout applied for app: %s, window: %s, target_display: %s, position: %s', app:name(), window:title(), target_display(appConfig.preferredDisplay), appConfig.position)
        hs.grid.set(window, appConfig.position, target_display(appConfig.preferredDisplay))
      end
    end
  end
end

function handleGlobalAppEvent(name, eventType, app)
  if eventType == hs.application.watcher.launched then
    log.df('[auto-layout] handleGlobalAppEvent - global app event; launched %s', app:bundleID())
    if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
      watchApp(app)
    end
  elseif eventType == hs.application.watcher.terminated then
    -- Only the PID is set for terminated apps, so can't log bundleID.
    local pid = app:pid()
    log.df('[auto-layout] handleGlobalAppEvent - global app event; terminated PID %d', pid)
    unwatchApp(pid)
  end
end

function handleAppEvent(element, event)
  if event == eventsWatcher.windowCreated then
    if pcall(function()
      log.df('[auto-layout] handleAppEvent - app event; window %s created for %s', element:id(), element:application():bundleID())
    end) then
      watchWindow(element)
    else
      log.wf('[auto-layout] handleAppEvent - app event error; thrown trying to access element (%s) in handleAppEvent', element)
    end
  else
    log.wf('[auto-layout] handleAppEvent - app event error; unexpected app event (%d) received', event)
  end
end

function handleWindowEvent(window, event, watcher, info)
  log.df('[auto-layout] handleWindowEvent - window event; new window event (%s) for %s (%s)', event, window:application():bundleID(), info.id)

  if event == eventsWatcher.elementDestroyed then
    log.df('[auto-layout] handleWindowEvent - window event; %s destroyed for %s', info.id, window:application():bundleID())
    watcher:stop()
    watchers[info.pid].windows[info.id] = nil
  else
    log.wf('[auto-layout] handleWindowEvent - window error; unexpected window event (%d) received', event)
  end
end

function handleScreenEvent()
  -- Make sure that something noteworthy (display count) actually
  -- changed. We no longer check geometry because we were seeing spurious
  -- events.
  local screens = hs.screen.allScreens()

  log.df('[auto-layout] handleScreenEvent - screen event; new screens (%s), previous screens (%s)', #screens, screenCount)

  if #screens ~= screenCount then
    screenCount = #screens
    setLayoutForAll()
  end
end

function watchApp(app)
  local pid = app:pid()
  if watchers[pid] or app:bundleID() == 'org.hammerspoon.Hammerspoon' or app:bundleID() == 'com.contextsformac.Contexts' then
    log.wf('[auto-layout] watchApp - app warning; attempted watch for already-watched app PID %d', pid)
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

function unwatchApp(pid)
  local appWatcher = watchers[pid]
  if not appWatcher then
    log.wf('[auto-layout] unwatchApp - app warning; attempted unwatch for unknown app PID %d', pid)
    return
  end

  appWatcher.watcher:stop()
  for _, watcher in pairs(appWatcher.windows) do
    watcher:stop()
  end
  watchers[pid] = nil
end

function watchWindow(window)
  local app = window:application()
  local bundleID = app:bundleID()
  local pid = app:pid()
  local windows = watchers[pid].windows
  if utils.canManageWindow(window) then
    local bundleID = app:bundleID()
    local id = window:id()

    log.df('[auto-layout] watchWindow - window event; attempting to watch %s (app %s, window %s, ID %s, %s windows)', bundleID, app:name(), window:title(), id, utils.windowCount(app))

    -- layout specifics for given apps
    if config.applications[app:name()] then
      log.df('[auto-layout] watchWindow - window event; watching %s (window %s, ID %s, %s windows) and applying layout for window/app', bundleID, window:title(), id, utils.windowCount(app))
      setLayoutForApp(app)

      -- execute custom app fn() for given application
      if config.applications[app:name()].fn ~= nil then
        log.df('[auto-layout] watchWindow - window event; found custom function for %s (app %s, window %s, ID %s, %s windows)', bundleID, app:name(), window:title(), id, utils.windowCount(app))
        config.applications[app:name()].fn(window)
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
    log.df('[auto-layout] watchWindow - window event; unable to watch unmanageable %s (window %s, ID %s, %s windows)', bundleID, window:title(), id, utils.windowCount(app))
  end
end

return {
  init = (function()
    log.i('[auto-layout] init - creating screen/app/window watchers')

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
    log.i('[auto-layout] teardown - tearing down screen/app/window watchers')

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
