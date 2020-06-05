local log = hs.logger.new('[wm]', 'warning') -- debug == 4, warning == 2

local cache  = {}
local module = { cache = cache }

local canLayoutWindow = require('ext.window').canLayoutWindow
local getManageableWindows = require('ext.window').getManageableWindows

local appHandler = require('utils.wm.window-handlers').appHandler
local dndHandler = require('utils.wm.window-handlers').dndHandler
local hideAfterHandler = require('utils.wm.window-handlers').hideAfterHandler
local quitAfterHandler = require('utils.wm.window-handlers').quitAfterHandler
local doQuitWin = require('utils.wm.window-handlers').doQuitWin

local display = function(screen)
  local allDisplays = hs.screen.allScreens()

  if allDisplays[screen] ~= nil then
    return allDisplays[screen]
  else
    return hs.screen.primaryScreen()
  end
end

local windowLogger = function(event, win, appName)
  log.df('%s: %s (%s)', event, appName, win:title())
end

local snap = function(win, position, screen)
  -- handle ignoredWindows from our current appConfig; don't snap anything
  local appConfig = config.getAppConfigForWin(win)
  if win== nil or (appConfig.ignoredWindows ~= nil and hs.fnutils.contains(appConfig.ignoredWindows, win:title())) then return end

  log.df('window snap (%s) on screen %s: %s (%s)', hs.inspect(position), screen, win:title(), hs.inspect(win:application():name()))

  hs.grid.set(win, position or hs.grid.get(win), display(screen))
end

local snapRelatedWindows = function(appBundleID, windows, screen)
  for index, win in pairs(windows) do
    log.df('window snapping multiple windows (%s) at win (%s) for %s; index: %s', #windows, hs.inspect(win), appBundleID, index)

    if win ~= nil then
      if (index % 2 == 0) then -- even index/number
        snap(win, config.grid.rightHalf, screen)
      else -- odd index/number
        snap(win, config.grid.leftHalf, screen)
      end
    end
  end
end

local layoutManagedWindows = function(appConfig, managedWindows)
  log.df('attempting to layout managed windows for app: %s (%s), #win: %s', appConfig.name, appConfig.bundleID, #managedWindows)

  if #managedWindows == 0 then
    log.df('UNABLE to apply a layout for the configured app (no managed windows found for app): %s, #win: %s, pos: %s', appConfig.name, #managedWindows, appConfig.position)
    -- get more verbose output when we're in debug (4) mode:
    if log:getLogLevel() == 4 then
      dumpWindows(hs.application.get(appConfig.bundleID))
    end

    return
  end

  if (#managedWindows == 1) then
    -- snap the first (and possibly only) window
    snap(managedWindows[1], appConfig.position, appConfig.preferredDisplay)
  elseif (#managedWindows > 1) then
    -- or, we'll try and snap multiple windows for the same app, tiled (hard-coded to this)
    snapRelatedWindows(appConfig.hint, managedWindows, appConfig.preferredDisplay)
  end
end

local handleWindowRules = function(appConfig, allWindows)
  if config.rulesExistForAppConfig(appConfig) then
    log.df('attempting to layout all windows for app (and rules): %s (%s), #win: %s, rules: %s', appConfig.name, appConfig.bundleID, #allWindows, hs.inspect(appConfig.rules))

    if #allWindows == 0 then
      log.df('UNABLE to apply window-specific rules to any of the windows for app: %s, rules: %s', appConfig.name, hs.inspect(appConfig.rules))

      return
    elseif #allWindows > 1 then
      -- apply window rules
      hs.fnutils.each(allWindows, function(win)
        if config.ruleExistsForWin(win, 'snap') then
          -- handle hide rules
          log.df('trying to rule-based snap window %s', hs.inspect(win))

          local rule = config.ruleForWin(win, 'snap')
          snap(win, rule.position or appConfig.position, appConfig.preferredDisplay)
        elseif config.ruleExistsForWin(win, 'hide') then
        -- handle hide rules
          log.df('trying to rule-based hide window %s', hs.inspect(win))

          return
        elseif config.ruleExistsForWin(win, 'quit') then
          -- handle quit rules
          log.df('trying to rule-based quit window %s', hs.inspect(win))

          doQuitWin(win)
        elseif config.ruleExistsForWin(win, 'ignore') then
          -- handle ignore rules
          log.df('trying to rule-based ignore window %s', hs.inspect(win))

          return
        end
      end)
    end
  end
end

local doWindowHandlers = function(win, appConfig, event)
  if appConfig == nil then return end
  log.df("doWindowHandlers: {win: %s, event: %s}", win:title(), event)

  -- NOTE: window events are dealt with in each handler, instead of from here.
  quitAfterHandler(win, appConfig.quitAfter, event)
  hideAfterHandler(win, appConfig.hideAfter, event)
  appHandler(win, appConfig.handler, event)
  dndHandler(win, appConfig.dnd, event)
end

local setLayoutForApp = function(app, appConfig)
  if type(app) == "string" then
    app = hs.application.get(app)
  end

  -- FIXME: determine what mainWindow() targets; bug?
  if app ~= nil and app:mainWindow() ~= nil then
    log.df('beginning layout of app: %s (%s)', app:name(), app:bundleID())

    -- handle all windows that have no window-based rules from our app config
    local allWindows = app:allWindows()
    local visibleWindows = app:visibleWindows()
    local managedWindows = getManageableWindows(visibleWindows)
    local appConfig = appConfig or config.apps[app:bundleID()]

    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      -- TODO: fix these timers
      hs.timer.doAfter(1, function() handleWindowRules(appConfig, allWindows) end)
      hs.timer.doAfter(1, function() layoutManagedWindows(appConfig, managedWindows) end)
    else
      log.wf('UNABLE to find an app config for %s', app:name())
    end
  end
end

local setLayoutForAll = function()
  log.i('starting layout of all apps..')

  for app, appConfig in pairs(config.apps) do
    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      setLayoutForApp(app, appConfig)
    end
  end
end

local handleWindowLayout = function(win, appName, event)
  setLayoutForApp(win:application())

  local appConfig = config.getAppConfigForWin(win)
  doWindowHandlers(win, appConfig, event)
end

local getFiltersFromAppConfig = function()
  local filters = {}

  for app, app_config in pairs(config.apps) do
    if app_config ~= nil and app ~= "_" then
      table.insert(filters, app_config.name)
    end
  end

  log.df("Preparing to filter the following apps: \r\n%s", hs.inspect(filters))
  return filters
end

module.start = (function()
  log.df("Starting [utils.wm]..")

  -- FIXME: i have too many events subscribed; please figure out what's REALLY
  -- needed for my various use cases/handlers..
  --
  -- window event order:
  --  - created
  --  - (snap)
  --  - unfocused
  --  - focused
  --

  cache.filter = hs.window.filter.new(getFiltersFromAppConfig())
    :subscribe(hs.window.filter.windowCreated, function(win, appName, event)
      local appConfig = config.getAppConfigForWin(win)

      windowLogger(event, win, appName)
      handleWindowLayout(win, appName, event)
      if appConfig ~= nil then
        handleWindowRules(appConfig, win:application():allWindows())
      end
      end, true)
    :subscribe(hs.window.filter.windowDestroyed, function(win, appName, event)
      windowLogger(event, win, appName)
      handleWindowLayout(win, appName, event)
      end, true)
    :subscribe(hs.window.filter.windowFocused, function(win, appName, event)
      local appConfig = config.getAppConfigForWin(win)
      windowLogger(event, win, appName)
      if appConfig ~= nil then
        doWindowHandlers(win, appConfig, event)
      end
      end, true)
    :subscribe(hs.window.filter.windowUnfocused, function(win, appName, event)
      local appConfig = config.getAppConfigForWin(win)
      windowLogger(event, win, appName)
      if appConfig ~= nil then
        doWindowHandlers(win, appConfig, event)
      end
      end, true)
    :subscribe(hs.window.filter.windowHidden, function(win, appName, event)
      windowLogger(event, win, appName)
      end, true)
    :subscribe(hs.window.filter.windowMinimized, function(win, appName, event)
      windowLogger(event, win, appName)
      end, true)
    :subscribe(hs.window.filter.windowNotOnScreen, function(win, appName, event)
      windowLogger(event, win, appName)
      end, true)
end)

module.setLayoutForAll = (function()
  log.df('setLayoutForAll')

  setLayoutForAll()
end)

module.setLayoutForApp = (function(app)
  log.df('setLayoutForApp: %s', hs.inspect(app))

  setLayoutForApp(app)
end)

module.stop = (function()
  log.df("Stopping [utils.wm]..")

  cache.filter:unsubscribeAll()
end)

return module
