--- An enchanced app watcher: a `hs.application.watcher` bolstered by a `hs.window.filter` to catch activations of "transient" apps, such as Spotlight.

local Application = require("hs.application")
local Window = require("hs.window")
local fnutils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.name = "contexts"
obj.debug = false

local appWatcher
local windowFilter
local frontAppBundleID
local callback

function obj.eventName(evtId)
  -- REF: https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/application/libapplication_watcher.m#L29
  local events = {
    [0] = "launching",
    [1] = "launched",
    [2] = "terminated",
    [3] = "hidden",
    [4] = "unhidden",
    [5] = "activated",
    [6] = "deactivated",
  }
  local event = events[0]

  for i, value in ipairs(events) do
    if evtId == i then
      event = value
      break
    end
  end

  return event
end

-- _ -> appName
local function appWatcherCallback(_, event, appObj)
  local newBundleID = appObj:bundleID()
  if event == Application.watcher.activated or event == "FROM_WINDOW_WATCHER" then
    if newBundleID == frontAppBundleID then return end
    frontAppBundleID = newBundleID

    -- info(fmt("[%s] appWatcherCallback %s executed for %s", string.upper(eventName(event)), frontAppBundleID, I(appObj)))

    callback(frontAppBundleID, appObj, event, event == "FROM_WINDOW_WATCHER")
  else
    -- info(fmt("[%s] appWatcherCallback %s executed for %s", string.upper(eventName(event)), newBundleID, I(appObj)))
    callback(newBundleID, appObj, event, event == "FROM_WINDOW_WATCHER")
  end
end

local function windowFilterCallback(hsWindow, appName, event)
  info(fmt("windowFilterCallback(%s) executed for %s", appName, event))
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

  windowFilter = Window.filter.new(false)
  -- info(fmt("contexts.init (%s)", I(opts)))
  appWatcher = Application.watcher.new(appWatcherCallback)

  return self
end

function obj:start(apps, _callback)
  callback = _callback or function() end

  local allowedWindowFilterEvents = {
    Window.filter.windowCreated,
    Window.filter.windowDestroyed,
    Window.filter.windowFocused,
  }

  -- on reload, enter modal (if any) for the front app (saves an redundant cmd+tab)
  local frontApp = Application.frontmostApplication()
  if frontApp then
    -- info(fmt("contexts.start frontApp (%s): %s", Application.watcher.activated, frontApp))
    appWatcherCallback(nil, Application.watcher.activated, frontApp)
  end
  appWatcher:start()
  -- windowFilter:setFilters(apps or {})
  windowFilter:subscribe(allowedWindowFilterEvents, windowFilterCallback)

  return self
end

function obj:stop()
  windowFilter:unsubscribeAll()
  appWatcher:stop()

  return self
end

return obj
