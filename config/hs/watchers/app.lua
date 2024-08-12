local enum = req("hs.fnutils")
local utils = req("utils")
local contexts = req("contexts")

local obj = {}

obj.__index = obj
obj.name = "watcher.app"
obj.debug = false
obj.watchers = {
  app = {},
  context = {},
}

-- interface: (appName, eventType, appObject)
function obj.handleGlobalAppEvent(appName, event, appObj)
  obj.runLayoutRulesForAppBundleID(appName, event, appObj)
  obj.runContextForAppBundleID(appName, event, appObj)
end

-- interface: (element, event, watcher, info)
function obj.handleAppEvent(element, event, _watcher, appObj)
  if element ~= nil then
    obj.runLayoutRulesForAppBundleID(element, event, appObj)
    obj.runContextForAppBundleID(element, event, appObj)
  end
end

-- interface: (app, initializing)
function obj.watchApp(app, _)
  if obj.watchers.app[app:pid()] then return end

  local watcher = app:newWatcher(obj.handleAppEvent, app)
  obj.watchers.app[app:pid()] = {
    watcher = watcher,
  }

  watcher:start({
    hs.uielement.watcher.mainWindowChanged,
    hs.uielement.watcher.focusedWindowChanged,
    hs.uielement.watcher.titleChanged,
    hs.uielement.watcher.elementDestroyed,
  })
end

function obj.attachExistingApps()
  local apps = enum.filter(hs.application.runningApplications(), function(app) return app:title() ~= "Hammerspoon" end)
  enum.each(apps, function(app) obj.watchApp(app, true) end)
end

function obj.runLayoutRulesForAppBundleID(elementOrAppName, event, appObj)
  local layoutableEvents = {
    hs.application.watcher.launched,
    hs.uielement.watcher.windowCreated,
    hs.application.watcher.terminated,
    -- hs.application.watcher.activated,
    -- hs.uielement.watcher.applicationActivated,
    -- hs.application.watcher.deactivated,
    -- hs.uielement.watcher.applicationDeactivated,
  }

  if appObj and appObj:focusedWindow() and enum.contains(layoutableEvents, event) then
    req("wm").placeApp(elementOrAppName, event, appObj)
  end
end

function obj.runContextForAppBundleID(elementOrAppName, event, appObj)
  if not obj.watchers.context[appObj:bundleID()] then return end

  -- seems to work best with a slight delay
  hs.timer.doAfter(
    0.1,
    function()
      contexts:run({
        context = obj.watchers.context[appObj:bundleID()],
        element = type(elementOrAppName) ~= "string" and elementOrAppName or nil,
        event = event,
        appObj = appObj,
        bundleID = appObj:bundleID(),
      })
    end
  )
end

function obj:start()
  self.watchers.context = contexts:init()
  self.watchers.app = {}
  self.globalWatcher = hs.application.watcher.new(self.handleGlobalAppEvent):start()
  self.attachExistingApps()

  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop()
  if self.watchers.app then
    enum.each(self.watchers.app, function(w) w:stop() end)
    self.watchers.app = nil
  end

  info(fmt("[STOP] %s", self.name))

  return self
end

return obj
