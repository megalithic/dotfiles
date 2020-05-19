local log = hs.logger.new('[utils.wm]', 'warning')

local cache  = {}
local module = { cache = cache }

local canLayoutWindow = require('ext.window').canLayoutWindow
local getManageableWindows = require('ext.window').getManageableWindows

local appHandler = require('ext.window-handlers').appHandler
local dndHandler = require('ext.window-handlers').dndHandler
local hideAfterHandler = require('ext.window-handlers').hideAfterHandler
local quitAfterHandler = require('ext.window-handlers').quitAfterHandler

local display = function(screen)
  local allDisplays = hs.screen.allScreens()

  if allDisplays[screen] ~= nil then
    return allDisplays[screen]
  else
    return hs.screen.primaryScreen()
  end
end

local windowLogger = function(event, win, appName)
  log.df('window %s: %s (%s)', event, appName, win:title())
end

local doWindowHandlers = function(win, appConfig, event)
  log.df("doWindowHandlers: {win: %s, event: %s}", win:title(), event)

  -- NOTE: events are dealt with in each handler, instead of from here.
  quitAfterHandler(win, appConfig.quitAfter, event)
  hideAfterHandler(win, appConfig.hideAfter, event)
  appHandler(win, appConfig.handler, event)
  dndHandler(win, appConfig.dnd, event)
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

local setLayoutForApp = function(app, appConfig)
  if type(app) == "string" then
    -- log.df('app to layout (%s) is a string, getting app object..', hs.inspect(app))
    app = hs.application.get(app)
  end

  if app ~= nil and app:mainWindow() ~= nil then
    log.df('beginning layout of app: %s / %s', string.upper(app:name()), app:bundleID())

    local windows = getManageableWindows(app:visibleWindows())
    appConfig = appConfig or config.apps[app:bundleID()]

    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      if (#windows == 1) then
        -- snap the first (and possibly) only window
        snap(windows[1], appConfig.position, appConfig.preferredDisplay)
      elseif (#windows > 1) then
        -- otherwise we'll try and snap multiple windows for the same app, tiled
        snapRelatedWindows(appConfig.hint, windows, appConfig.preferredDisplay)
      else
        log.wf('grid layout NOT applied for app (no windows found for app): %s, #win: %s, pos: %s', string.upper(app:name()), #windows, appConfig.position)
      end
    else
      log.wf('unable to find an app config for %s', string.upper(app:name()))
    end
  end
end

local setLayoutForAll = function()
  log.i('starting layout of all apps')

  for app, appConfig in pairs(config.apps) do
    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      setLayoutForApp(app, appConfig)
    end
  end
end

local handleWindowLayout = function(win, appName, event)
  if not canLayoutWindow(win) or event ~= "windowDestroyed" then return end

  appConfig = config.getAppConfigForWin(win)

  doWindowHandlers(win, appConfig, event)

  if event ~= "windowFocused" then
    snap(win, appConfig.position, appConfig.preferredDisplay)
  end
end

local handleWindowCreated = function(win, appName, event)
  windowLogger(event, win, appName)

  handleWindowLayout(win, appName, event)
end

local handleWindowDestroyed = function(win, appName, event)
  windowLogger(event, win, appName)

  if win ~= nil and appName ~= "zoom.us" then
    setLayoutForApp(win:application())
  end
end

local handleWindowFocused = function(win, appName, event)
  windowLogger(event, win, appName)

  handleWindowLayout(win, appName, event)
end

local handleWindowUnfocused = function(win, appName, event)
  windowLogger(event, win, appName)

  doWindowHandlers(win, config.getAppConfigForWin(win), event)
end

local handleWindowMoved = function(win, appName, event)
  if win == nil then return end

  windowLogger(event, win, appName)
end

local handleWindowFullscreened = function(win, appName, event)
  windowLogger(event, win, appName)

  win:setFullscreen(false)
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

  local app_filters = getFiltersFromAppConfig()

  -- window event order:
  --  - created
  --  - (snap)
  --  - unfocused
  --  - focused

  cache.filter = hs.window.filter.new(app_filters)
    :subscribe(hs.window.filter.windowCreated, handleWindowCreated, true)
    :subscribe(hs.window.filter.windowFocused, handleWindowFocused, true)
    :subscribe(hs.window.filter.windowUnfocused, handleWindowUnfocused, true)
    :subscribe(hs.window.filter.windowVisible, handleWindowFocused, true)
    :subscribe(hs.window.filter.windowHidden, handleWindowUnfocused, true)
    :subscribe(hs.window.filter.windowMoved, handleWindowMoved, true)
    :subscribe(hs.window.filter.windowDestroyed, handleWindowDestroyed, true)
    :subscribe(hs.window.filter.windowFullscreened, handleWindowFullscreened, true)
end)

module.setLayoutForAll = (function()
  setLayoutForAll()
end)

module.setLayoutForApp = (function(app)
  setLayoutForApp(app)
end)

module.stop = (function()
  log.df("Stopping [utils.wm]..")

  cache.filter:unsubscribeAll()
end)

return module
