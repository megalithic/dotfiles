local enum = req("hs.fnutils")
local utils = req("utils")
local contexts = req("contexts")

local obj = {}

obj.__index = obj
obj.name = "watcher.app"
obj.debug = false
obj.watchers = {
  global = nil,
  app = {},
  context = {},
}
obj.lollygagger = req("lollygagger")

-- interface: (element, event, watcher, info)
function obj.handleWatchedEvent(elementOrAppName, event, _watcher, app)
  if elementOrAppName ~= nil then
    obj.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
    obj.runContextForAppBundleID(elementOrAppName, event, app)
    obj.lollygagger:run(elementOrAppName, event, app)
  end
end

-- interface: (app, initializing)
function obj.watchApp(app, _)
  if app == nil then return end
  if obj.watchers.app[app:pid()] then return end

  local watcher = app:newWatcher(obj.handleWatchedEvent, app)
  obj.watchers.app[app:pid()] = {
    watcher = watcher,
  }

  if watcher == nil then return end

  watcher:start({
    hs.uielement.watcher.windowCreated,
    hs.uielement.watcher.mainWindowChanged,
    hs.uielement.watcher.focusedWindowChanged,
    hs.uielement.watcher.titleChanged,
    hs.uielement.watcher.elementDestroyed,
  })
end

function obj.attachExistingApps()
  enum.each(hs.application.runningApplications(), function(app)
    if app:title() ~= "Hammerspoon" then obj.watchApp(app, true) end
  end)
end

function obj.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
  -- NOTE: only certain events are layout-runnable
  local layoutableEvents = {
    hs.application.watcher.launched,
    hs.application.watcher.terminated,
    -- hs.uielement.watcher.windowCreated,
    -- hs.application.watcher.activated,
    -- hs.application.watcher.deactivated,
    -- hs.uielement.watcher.applicationActivated,
    -- hs.uielement.watcher.applicationDeactivated,
  }

  if app and enum.contains(layoutableEvents, event) then
    hs.timer.waitUntil(
      function() return #app:allWindows() > 0 and app:mainWindow() ~= nil end,
      function() req("wm").placeApp(elementOrAppName, event, app) end
    )
  end
end

-- NOTE: all events are context-runnable
function obj.runContextForAppBundleID(elementOrAppName, event, app, metadata)
  if not obj.watchers.context[app:bundleID()] then return end

  contexts:run({
    context = obj.watchers.context[app:bundleID()],
    element = type(elementOrAppName) ~= "string" and elementOrAppName or nil,
    event = event,
    appObj = app,
    bundleID = app:bundleID(),
    metadata = metadata,
  })
end

function obj:start()
  self.watchers.app = {}
  self.watchers.context = contexts:start()
  self.watchers.global = hs.application.watcher
    .new(function(appName, event, app) obj.handleWatchedEvent(appName, event, nil, app) end)
    :start()
  -- NOTE: this slows it ALL down
  -- self.attachExistingApps()
  self.lollygagger:start()

  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop()
  if self.watchers.global then
    -- self.watchers.global:stop()
    self.watchers.global = nil
  end

  if self.watchers.app then
    enum.each(self.watchers.app, function(w)
      w:stop()
      w = nil
    end)
    self.watchers.app = nil
  end

  if self.watchers.contexts then
    enum.each(self.watchers.contexts, function(w)
      w:stop()
      w = nil
    end)
    self.watchers.contexts = nil
  end

  info(fmt("[STOP] %s", self.name))

  return self
end

return obj
