local log = hs.logger.new('[utils.wm]', 'debug')

local cache  = {}
local module = { cache = cache }

local display = function(screen)
  local allDisplays = hs.screen.allScreens()

  if allDisplays[screen] ~= nil then
    return allDisplays[screen]
  else
    return hs.screen.primaryScreen()
  end
end

local snap = function(win, position, screen)
  if win == nil then return end
  log.df('window snap (%s) on screen %s: %s (%s)', hs.inspect(position), screen, win:title(), hs.inspect(win:application():name()))

  hs.grid.set(win, position or hs.grid.get(win), display(screen))
end

local windowLayouts = config.apps

local canLayoutWindow = function(win)
  local bundleID = win:application():bundleID()

  return win:title() ~= "" and win:isStandard() and not win:isMinimized() and not win:isFullScreen() or
    bundleID == 'com.googlecode.iterm2' or bundleID == 'net.kovidgoyal.kitty'
end

local getManageableWindows = function(windows)
  if windows == nil then return end
  return hs.fnutils.filter(windows, (function(win)
    if win == nil then return end
    return canLayoutWindow(win)
  end))
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

local dndHandler = function(win, dnd, event)
  if dnd == nil then return end
  log.df('found dnd handler for %s..', win:application():bundleID())

  local enabled = dnd.enabled
  local mode = dnd.mode

  if (enabled) then
    if (event == "created") then
      log.df('dnd handler: toggling ON slack status (%s) and dnd mode', mode)
      hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/slack", (function() end), (function() end), {mode}):start()
      hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/dnd", (function() end), (function() end), {"on"}):start()
    elseif (event == "destroyed") then
      -- FIXME: this only works for app watchers it seems; nothing to do with dead windows :(
      -- log.df('dnd handler: toggling OFF slack status and dnd mode')
      -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/slack", (function() end) , (function() end), {"back"}):start()
      -- hs.execute("slack back", true)
      -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/dnd", (function() end), (function() end), {"off"}):start()
      -- hs.execute("dnd off", true)
    end
  end
end

local appHandler = function(win, handler)
  if handler == nil then return end
  log.df('found app handler for %s..', win:application():bundleID())

  handler(win)
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
        -- getting first (and should be) only window from the table of windows for this app
        snap(windows[1], appConfig.position, appConfig.preferredDisplay)
      elseif (#windows > 1) then
        snapRelatedWindows(appConfig.hint, windows, appConfig.preferredDisplay)
      else
        log.df('grid layout NOT applied for app (no windows found for app): \r\n%s, #windows: %s, position: %s', string.upper(app:name()), #windows, appConfig.position)
      end
    else
      log.df('unable to find an app config for %s', string.upper(app:name()))
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

local highlightFocused = function()
  local rect = hs.drawing.rectangle(hs.window.focusedWindow():frame())
  rect:setStrokeColor({["red"]=1,  ["blue"]=0, ["green"]=0, ["alpha"]=0.75})
  rect:setStrokeWidth(2)
  rect:setFill(false)
  rect:show()
  hs.timer.doAfter(0.3, function() rect:delete() end)
end

local highlight = function()
  hs.timer.doAfter(0.05, highlightFocused)
end

local windowLogger = function(event, win, appName)
  log.df('window %s: %s (%s)', event, appName, win:title())
end

local handleWindowLayout = function(win, appName, event)
  if not canLayoutWindow(win) and event ~= "destroyed" then return end

  local appBundleId = win:application():bundleID()
  local appConfig = windowLayouts[appBundleId] or windowLayouts['_']

  -- log.df('found app config for %s..', appBundleId or "<no app found>")

  dndHandler(win, appConfig.dnd, event)
  appHandler(win, appConfig.handler)

  if event ~= "focused" then
    snap(win, appConfig.position, appConfig.preferredDisplay)
  end
end

local handleWindowCreated = function(win, appName)
  local event = "created"
  windowLogger(event, win, appName)

  handleWindowLayout(win, appName, event)
end

local handleWindowDestroyed = function(win, appName)
  local event = "destroyed"
  windowLogger(event, win, appName)

  if win ~= nil and appName ~= "zoom.us" then
    setLayoutForApp(win:application())
  end

  -- handleWindowLayout(win, appName, event)
end

local handleWindowFocused = function(win, appName)
  local event = "focused"
  windowLogger(event, win, appName)

  handleWindowLayout(win, appName, event)
  -- highlight()
end

local handleWindowUnfocused = function(win, appName)
  local event = "unfocused"
  windowLogger(event, win, appName)

  -- handleWindowLayout(win, appName, event)
  -- highlight()
end

local handleWindowMoved = function(win, appName)
  if win == nil then return end

  local event = "moved"
  windowLogger(event, win, appName)

  -- handleWindowLayout(win, appName, event)
end

local handleWindowFullscreened = function(win, appName)
  local event = "fullscreened"
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

  cache.filter = hs.window.filter.new(app_filters)
    :subscribe(hs.window.filter.windowCreated, handleWindowCreated, true)
    :subscribe(hs.window.filter.windowFocused, handleWindowFocused, true)
    :subscribe(hs.window.filter.windowUnfocused, handleWindowUnfocused, true)
    :subscribe(hs.window.filter.windowVisible, handleWindowFocused, true)
    -- :subscribe(hs.window.filter.windowMoved, handleWindowMoved, true)
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
