local module = {}

module.targetDisplay = function(displayInt)
  -- detect the current number of monitors
  displays = hs.screen.allScreens()
  if displays[displayInt] ~= nil then
    return displays[displayInt]
  else
    return hs.screen.primaryScreen()
  end
end

-- FIXME: simply must DRY up setLayoutForAll
module.setLayoutForAll = function()
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
            log.df('[auto-layout] setLayoutForAll - grid layout applied for app: %s, window: %s, targetDisplay: %s, position: %s', application:name(), window:title(), module.targetDisplay(appConfig.preferredDisplay), appConfig.position)
            hs.grid.set(window, appConfig.position, module.targetDisplay(appConfig.preferredDisplay))
          end
        end
      end
    end
  end
end

-- FIXME: simply must DRY up setLayoutForApp
module.setLayoutForApp = function(app) -- optionally, we should be able to take in a `window` to layout
  if app ~= nil and app:mainWindow() ~= nil then
    log.i('[auto-layout] setLayoutForApp - beginning layout for single app')

    local windows = app:visibleWindows()
    local appConfig = config.applications[app:name()]

    if appConfig ~= nil then
      -- we are always positioning ALL the windows, we need a single window positioner method at some point..
      -- TODO: add a single window watcher and window handler, don't always handle all the windows.
      for _, window in pairs(windows) do
        if utils.canManageWindow(window) then
          log.df('[auto-layout] setLayoutForApp - grid layout applied for app: %s, window: %s, targetDisplay: %s, position: %s', app:name(), window:title(), module.targetDisplay(appConfig.preferredDisplay), appConfig.position)
          hs.grid.set(window, appConfig.position, module.targetDisplay(appConfig.preferredDisplay))
        end
      end
    else
      log.df('[auto-layout] setLayoutForApp - unable to find an app config for %s', app:name())
    end
  -- else
  --   -- default/general layout for apps not given a specific config
  --   local app = hs.application.frontmostApplication()

  --   -- only if we're not ignoring
  --   if (not utils.isIgnoredApp(app:name())) then
  --     local windows = app:visibleWindows()
  --     local appConfig = config.applications['default']

  --     for _, window in pairs(windows) do
  --       if utils.canManageWindow(window) then
  --         log.df('[auto-layout] setLayoutForApp (default) - grid layout applied for app: %s, window: %s, targetDisplay: %s, position: %s', app:name(), window:title(), module.targetDisplay(appConfig.preferredDisplay), appConfig.position)
  --         hs.grid.set(window, appConfig.position, module.targetDisplay(appConfig.preferredDisplay))
  --       end
  --     end
  --   end
  end
end

return module
