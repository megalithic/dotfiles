local config = require('config')
local log = hs.logger.new('[wflayout]', 'debug')

local appWatcher = nil
local screenWatcher = nil
local windowFilter = nil
local dwf = nil
local isDocked = false

local windowLayouts = config.apps or {
  -- FIXME: superfulous default?
  ['_'] = {
    position = config.grid.centeredMedium,
    handler = function(win) snap(win) end
  }
}

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

local snap = function(win, position, screen)
  if win == nil then return end
  log.df('window snap (%s): %s', hs.inspect(position), win:title())

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
  --   hs.grid.set(win, position or hs.grid.get(win), screen)
  -- end

  hs.grid.set(win, position or hs.grid.get(win), screen)
end

local snapRelatedWindows = function(appBundleID, windows, screen)
  for index, win in pairs(windows) do
    log.df('window snapping multiple windows (%s) for %s', #windows, appBundleID)

    if win ~= nil and win:title() ~= "" then
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
  if app ~= nil and app:mainWindow() ~= nil then
    log.df('starting layout of single app: %s', string.upper(app:name()))

    local windows = getManageableWindows(app:visibleWindows())
    appConfig = appConfig or config.apps[app:bundleID()]

    if appConfig ~= nil and appConfig.preferredDisplay ~= nil then
      if (#windows == 1) then
        -- getting first (and should be) only window from the table of windows for this app
        snap(windows[1], appConfig.position, appConfig.preferredDisplay)
      elseif (#windows > 1) then
        snapRelatedWindows(windows, appConfig)
      else
        log.df('grid layout NOT applied for app (no windows found for app): %s, #windows: %s, target_display: %s, position: %s', string.upper(app:name()), #windows, target_display(appConfig.preferredDisplay), appConfig.position)
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

local logWindowInfo = function(win, appName, event)
  log.df('--------------------------------------------------')
  log.df(':: %s (%s) - role: %s - subrole: %s - appName: %s', event, win:title(), win:role(), win:subrole(), appName)
  log.df('Window: - %s', hs.inspect(win))
  log.df('IsStandard: - %s', win:isStandard())
  log.df('Application: - %s', win:application())
end

local highlightFocused = function()
  local rect = hs.drawing.rectangle(hs.window.focusedWindow():frame())
  rect:setStrokeColor({["red"]=1,  ["blue"]=0, ["green"]=0, ["alpha"]=1})
  rect:setStrokeWidth(1)
  rect:setFill(false)
  rect:show()
  hs.timer.doAfter(0.3, function() rect:delete() end)
end

local handleWindowLayout = function(win, appName, event)
  if not canLayoutWindow(win) and event ~= "destroyed" then return end

  local appBundleId = win:application():bundleID()
  local appConfig = windowLayouts[appBundleId] or windowLayouts['_']

  log.df('found app config for %s..', appBundleId or "<no app found>")

  snap(win, appConfig.position, appConfig.preferredDisplay)
  dndHandler(win, appConfig.dnd, event)
  appHandler(win, appConfig.handler)
end

local handleWindowCreated = function(win, appName)
  log.df('window created: %s', win:title())
  -- logWindowInfo(win, appName, "created")

  handleWindowLayout(win, appName, "created")
end

local handleWindowDestroyed = function(win, appName)
  log.df('window destroyed: %s', hs.inspect(win))
  -- logWindowInfo(win, appName, "destroyed")

  -- handleWindowLayout(win, appName, "destroyed")
end

local handleWindowFocused = function(win, appName)
  log.df('window focused: %s', win:title())
  -- logWindowInfo(win, appName, "focused")

  -- handleWindowLayout(win, appName, "focused")
  hs.timer.doAfter(0.05, highlightFocused)
end

local handleWindowMoved = function(win, appName)
  if win == nil then return end
  log.df('window moved: %s', win or appName)

  -- handleWindowLayout(win, appName, "moved")
end

local handleWindowFullscreened = function(win, appName)
  log.df('window fullscreened: %s for %s', win:title(), appName)

  win:setFullscreen(false)
end

-- @param event: int
local handleScreenEvent = function(event)
  log.df('screen event (%s) occurred', event)
end

-- @param name: string
-- @param event: int
-- @param app: table
local handleAppEvent = function(name, event, app)
  log.df('app (%s) event (%s) occurred: %s', name, event, hs.inspect(app))
end

-- function activateLayout(forceScreenCount)
--   -- before hook
--   layoutConfig._before_()

--   -- apply layouts
--   for bundleID, callback in pairs(layoutConfig) do
--     local application = hs.application.get(bundleID)
--     if application then
--       local windows = application:visibleWindows()
--       for _, window in pairs(windows) do
--         if canManageWindow(window) then
--           callback(window, forceScreenCount)
--         end
--       end
--     end
--   end

--   -- after hook
--   layoutConfig._after_()
-- end

-- local handleWindowEvent = function(window)
--   if canManageWindow(window) then
--     local application = window:application()
--     local bundleID = application:bundleID()
--     if layoutConfig[bundleID] then
--       layoutConfig[bundleID](window)
--     end
--   end
-- end


-- local handleScreenEvent = function()
--   -- Make sure that something noteworthy (display count) actually
--   -- changed. We no longer check geometry because we were seeing spurious
--   -- events.
--   local screens = hs.screen.allScreens()
--   if not (#screens == screenCount) then
--     screenCount = #screens
--     activateLayout(screenCount)
--   end
-- end

return {
  init = (function(is_docked)
    isDocked = is_docked or false
    log.df('init window layouts (docked: %s)..', isDocked)

    -- Watch for screen changes
    screenWatcher = hs.screen.watcher.new(handleScreenEvent)
    screenWatcher:start()

    -- Watch for application-level events
    appWatcher = hs.application.watcher.new(handleAppEvent)
    appWatcher:start()

    -- windowFilter = hs.window.filter.new()
    -- windowFilter:subscribe(hs.window.filter.windowCreated, handleWindowEvent)

    -- FIXME: determine if we want to spin up a window.filter for each app?
    dwf = hs.window.filter.new()
    hs.window.filter.allowedWindowRoles = {
      AXStandardWindow=true,
      AXDialog=true,
      AXSystemDialog=true,
      -- AXUnknown=true
    }

    for _, name in ipairs(config.ignoredApps) do
      hs.window.filter.ignoreAlways[name] = true
    end

    dwf:subscribe(hs.window.filter.windowCreated, handleWindowCreated, true)
    dwf:subscribe(hs.window.filter.windowFocused, handleWindowFocused, true)
    dwf:subscribe(hs.window.filter.windowMoved, handleWindowMoved, true)
    dwf:subscribe(hs.window.filter.windowDestroyed, handleWindowDestroyed, true)
    dwf:subscribe(hs.window.filter.windowFullscreened, handleWindowFullscreened, true)
  end),

  setLayoutForAll = (function()
    setLayoutForAll()
  end),

  setLayoutForApp = (function(app)
    setLayoutForApp(app)
  end),

  teardown = (function()
    log.df('teardown window layouts..')

    dwf = nil
    screenWatcher:stop()
    screenWatcher = nil
    appWatcher = nil
  end)
}
