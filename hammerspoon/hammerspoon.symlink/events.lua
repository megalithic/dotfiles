local events = {}

-- :: imports/requires
local config = require 'config'
local utils = require 'utils'
local wf = hs.window.filter
local eventsWatcher = hs.uielement.watcher

-- :: globals
local watchers = {}
local globalAppWatcher = nil
local screenCount = #hs.screen.allScreens()


target_display = function(display_int)
  -- detect the current number of monitors
  displays = hs.screen.allScreens()
  if displays[display_int] ~= nil then
    return displays[display_int]
  else
    return hs.screen.primaryScreen()
  end
end


setLayoutForAll = function()
  utils.log.df('[auto-layout] - beginning layout for all apps')

  for _, app_config in pairs(config.applications) do
    -- if we have a preferred display
    if app_config.preferred_display ~= nil then
      application = hs.application.find(app_config.name)

      -- if application ~= nil and application:mainWindow() ~= nil then
      --   application
      --   :mainWindow()
      --   :moveToScreen(target_display(app_config.preferred_display), false, true, 0)
      --   :moveToUnit(hs.layout.maximized)
      -- end

      if application ~= nil and application:mainWindow() ~= nil then
        local windows = application:visibleWindows()
        -- we are always positioning ALL the windows, we need a single window positioner method at some point..
        -- TODO: add a single window watcher and window handler, don't always handle all the windows.
        for _, window in pairs(windows) do
          if utils.canManageWindow(window) then
            utils.log.df('[auto-layout] - grid layout applied for app: %s, window: %s, target_display: %s, position: %s', application:name(), window:title(), target_display(app_config.preferred_display), app_config.position)
            hs.grid.set(window, app_config.position, target_display(app_config.preferred_display))
          end
        end
      end
    end
  end
end



-- event handlers
----------------------------------------------------------------------------
function handleGlobalAppEvent(name, eventType, app)
  if eventType == hs.application.watcher.launched then
    utils.log.df('[global] app event; launched %s', app:bundleID())
    if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
      watchApp(app)
    end
  elseif eventType == hs.application.watcher.terminated then
    -- Only the PID is set for terminated apps, so can't log bundleID.
    local pid = app:pid()
    utils.log.df('[global] app event; terminated PID %d', pid)
    unwatchApp(pid)
  end
end

function handleAppEvent(element, event)
  if event == eventsWatcher.windowCreated then
    if pcall(function()
      utils.log.df('[app] event; window %s created for %s', element:id(), element:application():bundleID())
    end) then
      watchWindow(element)
    else
      utils.log.wf('[error] app error; thrown trying to access element (%s) in handleAppEvent', element)
    end
  else
    utils.log.wf('[error] app error; unexpected app event (%d) received', event)
  end
end

function handleWindowEvent(window, event, watcher, info)
  utils.log.df('[window] event; new window event (%s) for %s (%s)', event, window:application():bundleID(), info.id)

  if event == eventsWatcher.elementDestroyed then
    utils.log.df('[window] event; %s destroyed for %s', info.id, window:application():bundleID())
    watcher:stop()
    watchers[info.pid].windows[info.id] = nil
  else
    utils.log.wf('[error] window error; unexpected window event (%d) received', event)
  end
end

function handleScreenEvent()
  -- Make sure that something noteworthy (display count) actually
  -- changed. We no longer check geometry because we were seeing spurious
  -- events.
  local screens = hs.screen.allScreens()

  utils.log.df('[screen] event; new screens (%s), previous screens (%s)', #screens, screenCount)

  if #screens ~= screenCount then
    screenCount = #screens
    setLayoutForAll()
  end
end

function watchApp(app)
  local pid = app:pid()
  if watchers[pid] or app:bundleID() == 'org.hammerspoon.Hammerspoon' or app:bundleID() == 'com.contextsformac.Contexts' then
    utils.log.wf('[warning] app warning; attempted watch for already-watched app PID %d', pid)
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
    utils.log.wf('[warning] app warning; attempted unwatch for unknown app PID %d', pid)
    return
  end

  appWatcher.watcher:stop()
  for _, watcher in pairs(appWatcher.windows) do
    watcher:stop()
  end
  watchers[pid] = nil
end

function watchWindow(window)
  local application = window:application()
  local bundleID = application:bundleID()
  local pid = application:pid()
  local windows = watchers[pid].windows
  if utils.canManageWindow(window) then

    -- Do initial layout-handling.
    local bundleID = application:bundleID()
    local id = window:id()

    if config.applications[application:name()] then
      utils.log.df('[window] event; watching %s (window %s, ID %s, %s windows) and applying layout for window/app', bundleID, window:title(), id, utils.windowCount(application))
      config.applications[application:name()](window)
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
    utils.log.df('[window] event; unable to watch unmanageable %s (window %s, ID %s, %s windows)', bundleID, window:title(), id, utils.windowCount(application))
  end
end

-- INIT ALL THE EVENTS
function events.initEventHandling ()
  utils.log.df('[init] event; initializing watchers')

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

  setLayoutForAll()
end

-- TEAR DOWN ALL THE EVENTS
function events.tearDownEventHandling ()
  utils.log.df('[teardown] event; tearing down watchers')

  globalAppWatcher:stop()
  globalAppWatcher = nil

  for pid, _ in pairs(watchers) do
    unwatchApp(pid)
  end

  screenWatcher:stop()
  screenWatcher = nil
end

return events
