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

-- interface: (element, event, watcher, info)
function obj.handleAppEvent(elementOrAppName, event, _watcher, app)
  -- dbg({ I(element), appObj:bundleID(), utils.eventEnums(event) }, true)
  if elementOrAppName ~= nil then
    obj.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
    obj.runContextForAppBundleID(elementOrAppName, event, app)
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
    hs.uielement.watcher.windowCreated,
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

function obj.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
  local layoutableEvents = {
    hs.application.watcher.launched,
    hs.application.watcher.terminated,
    -- hs.uielement.watcher.windowCreated,
    -- hs.application.watcher.activated,
    -- hs.application.watcher.deactivated,
    -- hs.uielement.watcher.applicationActivated,
    -- hs.uielement.watcher.applicationDeactivated,
  }

  -- hs.timer.doAfter(0.3, function()
  if app and enum.contains(layoutableEvents, event) then
    hs.timer.waitUntil(
      function() return #app:allWindows() > 0 and app:mainWindow() ~= nil end,
      function() req("wm").placeApp(elementOrAppName, event, app) end
    )
  end

  -- end)
end

function obj.runContextForAppBundleID(elementOrAppName, event, app)
  if not obj.watchers.context[app:bundleID()] then return end

  -- seems to work best with a slight delay
  -- hs.timer.doAfter(
  --   0.2,
  --   function()
  contexts:run({
    context = obj.watchers.context[app:bundleID()],
    element = type(elementOrAppName) ~= "string" and elementOrAppName or nil,
    event = event,
    appObj = app,
    bundleID = app:bundleID(),
  })
  --   end
  -- )
end

function obj:start()
  -- prepares all of our contexts scripts by initializing their potential hotkey modals and actions
  self.watchers.context = contexts:start()
  self.watchers.app = {}
  -- self.globalWatcher = hs.application.watcher.new(self.handleGlobalAppEvent):start()
  self.globalWatcher = hs.application.watcher
    .new(function(appName, event, app) obj.handleAppEvent(appName, event, nil, app) end)
    :start()
  self.attachExistingApps()

  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop()
  if self.watchers.app then
    enum.each(self.watchers.app, function(w) w:stop() end)
    self.watchers.app = nil
  end

  if self.watchers.contexts then
    enum.each(self.watchers.contexts, function(w) w:stop() end)
    self.watchers.contexts = nil
  end

  info(fmt("[STOP] %s", self.name))

  return self
end

return obj
