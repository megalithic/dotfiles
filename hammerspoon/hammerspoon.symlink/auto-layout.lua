require 'utils'

local screenWatcher
local appWatcher

target_display = function(display_int)
  -- detect the current number of monitors
  displays = hs.screen.allScreens()
  if displays[display_int] ~= nil then
    return displays[display_int]
  else
    return hs.screen.primaryScreen()
  end
end

autoLayout = function(app)
  if app ~= nil then
    setLayoutForApp(app)
  else
    setLayoutForAll()
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

setLayoutForApp = function(app) -- optionally, take in a `window` to layout
  if app ~= nil and app:mainWindow() ~= nil then
    utils.log.df('[auto-layout] - beginning layout for single app')

    local windows = app:visibleWindows()
    local app_config = utils.getConfigForApp(app:name())

    if app_config ~= nil then
      -- we are always positioning ALL the windows, we need a single window positioner method at some point..
      -- TODO: add a single window watcher and window handler, don't always handle all the windows.
      for _, window in pairs(windows) do
        if utils.canManageWindow(window) then
          utils.log.df('[auto-layout] - grid layout applied for app: %s, window: %s, target_display: %s, position: %s', app:name(), window:title(), target_display(app_config.preferred_display), app_config.position)
          hs.grid.set(window, app_config.position, target_display(app_config.preferred_display))
        end
      end
    else
      utils.log.df('[auto-layout] - unable to find an app config for %s', app:name())
    end

  end
end

watchScreen = function()
  autoLayout()
end

watchApp = function(app)
  -- watch new windows for app
  local watcher = app:newWatcher(autoLayout)
  watcher:start({hs.uielement.watcher.windowCreated})

  -- watch existing windows for app
  for _, window in pairs(app:allWindows()) do
    watchWindow(window)
  end
end


watchWindow = function(window)
  local application = window:application()
  local bundleID = application:bundleID()
  if utils.canManageWindow(window) then
    -- Do initial layout-handling.
    local id = window:id()

    utils.log.df('[window] event; watching %s (%s) (window %s, ID %s, %s windows) and applying layout for window/app', application:name(), bundleID, window:title(), id, utils.windowCount(application))
    setLayoutForApp(application)
  else
    utils.log.df('[window] event; unable to watch unmanageable window %s (%s) (window %s, ID %s, %s windows)', application:name(), bundleID, window:title(), id, utils.windowCount(application))
  end
end

return {
  init = (function()
    utils.log.df('[auto-layout] - creating auto-layout watchers')

    screenWatcher = hs.screen.watcher.new(watchScreen):start()
    appWatcher = hs.application.watcher.new(watchApp):start()
  end),
  teardown = (function()
    utils.log.df('[auto-layout] - tearing down auto-layout watchers')

    screenWatcher:stop()
    screenWatcher = nil

    appWatcher:stop()
    appWatcher = nil
  end)
}
