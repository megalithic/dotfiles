--- An enchanced app watcher: a `hs.application.watcher` bolstered by a `hs.window.filter` to catch activations of "transient" apps, such as Spotlight.

local Application = require("hs.application")
local Window = require("hs.window")

local appWatcher
local windowFilter
local frontAppBundleID
local callback

local obj = {}
obj.__index = obj
obj.name = "appwatcher"

local function appWatcherCallback(_, event, appObj)
  local newBundleID = appObj:bundleID()
  if event == Application.watcher.activated or event == "FROM_WINDOW_WATCHER" then
    if newBundleID == frontAppBundleID then return end
    frontAppBundleID = newBundleID
    callback(frontAppBundleID, appObj, event == "FROM_WINDOW_WATCHER")
  end
end

local function windowFilterCallback(hsWindow, appName, event)
  print(fmt("windowFilterCallback(%s) executed.", appName))
  local appObj = hsWindow:application()
  if not appObj then return end
  local bundleID = appObj:bundleID()
  if event == "windowFocused" or event == "windowCreated" then
    if bundleID == frontAppBundleID then return end
    appWatcherCallback(nil, "FROM_WINDOW_WATCHER", appObj)
  elseif event == "windowDestroyed" then
    appWatcherCallback(nil, Application.watcher.activated, Application.frontmostApplication())
  end
end

function obj:init(opts)
  opts = opts or {}
  P(fmt("app_watcher:init(%s) loaded.", hs.inspect(opts)))

  windowFilter = Window.filter.new(false)
  appWatcher = Application.watcher.new(appWatcherCallback)

  return self
end

function obj:start(apps, transientApps, _callback)
  P(fmt("app_watcher:start() executed."))

  callback = _callback or function() end

  local allowedWindowFilterEvents = {
    Window.filter.windowCreated,
    Window.filter.windowDestroyed,
    Window.filter.windowFocused,
  }

  -- on reload, enter modal (if any) for the front app (saves an redundant cmd+tab)
  local frontApp = Application.frontmostApplication()
  if frontApp then appWatcherCallback(nil, Application.watcher.activated, frontApp) end
  appWatcher:start()
  windowFilter:setFilters(transientApps or {})
  windowFilter:subscribe(allowedWindowFilterEvents, windowFilterCallback)

  return self
end

function obj:stop()
  P(fmt("app_watcher:stop() executed."))
  windowFilter:unsubscribeAll()
  appWatcher:stop()

  return self
end

return obj
