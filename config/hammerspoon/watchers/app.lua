local enum = req("hs.fnutils")
local contexts = req("contexts")
local fmt = string.format

local M = {}

M.__index = M
M.name = "watcher.app"
M.debug = false
M.watchers = {
  global = nil,
  app = {},
  context = {},
}
-- obj.lollygagger = req("lollygagger")

-- interface: (element, event, watcher, info)
function M.handleWatchedEvent(elementOrAppName, event, _watcher, app)
  if elementOrAppName ~= nil then
    -- M.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
    M.runContextForAppBundleID(elementOrAppName, event, app)

    -- if M.lollygagger then
    --   M.lollygagger:run(elementOrAppName, event, app)
    -- end
  end
end

-- interface: (app, initializing)
function M.watchApp(app, _)
  if app == nil or app:bundleID() == nil then return end
  if M.watchers.app[app:bundleID()] then return end

  local watcher = app:newWatcher(M.handleWatchedEvent, app)
  if watcher == nil then return end

  M.watchers.app[app:bundleID()] = watcher

  watcher:start({
    hs.uielement.watcher.windowCreated,
    hs.uielement.watcher.mainWindowChanged,
    hs.uielement.watcher.focusedWindowChanged,
    hs.uielement.watcher.titleChanged,
    hs.uielement.watcher.elementDestroyed,
  })
end

function M.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
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
function M.runContextForAppBundleID(elementOrAppName, event, app, metadata)
  if not M.watchers.context[app:bundleID()] then
    -- U.log.wf("%s context failed to run", app:bundleID())
    return
  end

  contexts:run({
    context = M.watchers.context[app:bundleID()],
    element = type(elementOrAppName) ~= "string" and elementOrAppName or nil,
    event = event,
    appObj = app,
    bundleID = app:bundleID(),
    metadata = metadata,
  })
end

function M:start()
  -- Stop existing watchers first to avoid duplicates
  if self.watchers.global then
    self.watchers.global:stop()
    self.watchers.global = nil
  end

  -- for watching all app events; the orchestrator, if you will
  self.watchers.global = hs.application.watcher
    .new(function(appName, appEvent, appObj)
      M.handleWatchedEvent(appName, appEvent, nil, appObj)
      M.watchApp(appObj)
    end)
    :start()

  -- for watching individual apps
  self.watchers.app = {}
  self.watchers.context = contexts:preload()

  -- if M.lollygagger then
  --   self.lollygagger:start()
  -- end

  U.log.i(fmt("started", self.name))

  return self
end

function M:stop()
  if self.watchers.global then
    self.watchers.global:stop()
    self.watchers.global = nil
  end

  if self.watchers.app then
    enum.each(self.watchers.app, function(w)
      if w and type(w["stop"]) == "function" then
        U.log.f("stopping app/element watcher %s", w:element())
        w:stop()
      end
      w = nil
    end)
    self.watchers.app = nil
  end

  if self.watchers.context then
    enum.each(self.watchers.context, function(w)
      if w and type(w["stop"]) == "function" then
        U.log.f("stopping %s", w.name)
        w:stop()
      end
      w = nil
    end)
    self.watchers.context = nil
  end

  U.log.i(fmt("stopped", self.name))

  return self
end

return M
