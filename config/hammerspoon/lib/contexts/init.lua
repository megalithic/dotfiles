--- An enhanced app watcher: a `hs.application.watcher` bolstered by a
-- `hs.window.filter` to catch activations of "transient" apps, such as Spotlight.
--- TODO: deal with non-transient apps to see if we want to act on window filter events.

local Application = require("hs.application")
local Window = require("hs.window")

local obj = {}
local frontAppBundleID

obj.__index = obj
obj.name = "contexts"
obj.debug = true
obj.appWatcher = nil
obj.windowFilter = nil
obj.callback = nil

-- local function info(...)
--   if obj.debug then return _G.info(...) end
-- end
-- local function dbg(...)
--   if obj.debug then return _G.dbg(...) end
-- end
-- local function note(...)
--   if obj.debug then return _G.note(...) end
-- end
-- local function success(...)
--   if obj.debug then return _G.success(...) end
-- end

-- _ -> appName
local function appWatcherCallback(_, event, appObj)
  local newBundleID = appObj:bundleID()
  if event == Application.watcher.activated or event == "FROM_WINDOW_WATCHER" then
    if newBundleID == frontAppBundleID then return end
    frontAppBundleID = newBundleID
    obj.callback(frontAppBundleID, appObj, event, event == "FROM_WINDOW_WATCHER")
  else
    obj.callback(newBundleID, appObj, event, event == "FROM_WINDOW_WATCHER")
  end
end

local function windowFilterCallback(hsWindow, _appName, event)
  local appObj = hsWindow:application()
  if not appObj then return end
  local bundleID = appObj:bundleID()
  if event == "windowFocused" or event == "windowCreated" then
    -- info(fmt("windowFilterCallback(%s) executed for given: %s/front: %s", event, bundleID, frontAppBundleID))
    if bundleID == frontAppBundleID then return end
    appWatcherCallback(nil, "FROM_WINDOW_WATCHER", appObj)
  elseif event == "windowDestroyed" then
    appWatcherCallback(nil, Application.watcher.activated, Application.frontmostApplication())
  end
end

function obj:init(opts)
  opts = opts or {}

  obj.windowFilter = Window.filter.new(false)
  obj.appWatcher = hs.watchable.watch(
    "status.app",
    function(_watcher, _path, _key, _old, new) appWatcherCallback(new.appName, new.appEvent, new.appObj) end
  )

  return self
end

function obj:start(_apps, appFilters, callback)
  obj.callback = callback or function() end

  local allowedWindowFilterEvents = {
    Window.filter.windowCreated,
    Window.filter.windowDestroyed,
    Window.filter.windowFocused,
  }

  -- on reload, enter modal (if any) for the front app (saves an redundant cmd+tab)
  local frontApp = Application.frontmostApplication()
  if frontApp then appWatcherCallback(nil, Application.watcher.activated, frontApp) end
  obj.windowFilter:setFilters(appFilters or {})
  obj.windowFilter:subscribe(allowedWindowFilterEvents, windowFilterCallback)

  return self
end

function obj:stop()
  obj.windowFilter:unsubscribeAll()
  obj.appWatcher:release()

  return self
end

return obj
