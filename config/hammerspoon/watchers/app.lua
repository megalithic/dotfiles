local enum = req("hs.fnutils")
local contexts = req("contexts")
local fmt = string.format

local M = {}

M.__index = M
M.name = "watcher.app"
-- Per-app uielement watchers are keyed by PID, not bundleID:
-- * terminated events only expose a usable PID (appName is nil, docs),
-- * a relaunched app gets a fresh PID, so it is re-watched, and
-- * hs.uielement's own global cleanup is keyed by PID too.
-- Each entry: { watcher = <uielement.watcher>, bundleID = <string> }
M.watchers = {
  global = nil,
  app = {},
  context = {},
}
M.lollygagger = req("lollygagger")

local function appPid(app)
  if not app then return nil end
  local ok, pid = pcall(function() return app:pid() end)
  if ok then return pid end
  return nil
end

local function appBundleID(app)
  if not app then return nil end
  local ok, bundleID = pcall(function() return app:bundleID() end)
  if ok then return bundleID end
  return nil
end

-- interface: (element, event, watcher, info)
function M.handleWatchedEvent(elementOrAppName, event, _watcher, app)
  if elementOrAppName == nil or app == nil then return end

  M.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
  M.runContextForAppBundleID(elementOrAppName, event, app)

  if M.lollygagger then M.lollygagger:run(elementOrAppName, event, app) end
end

-- Terminated events arrive with appName == nil and an app object that is only
-- useful for its PID, so they are routed here instead of handleWatchedEvent.
function M.handleTerminated(app)
  local pid = appPid(app)
  local entry = pid and M.watchers.app[pid]
  local bundleID = (entry and entry.bundleID) or appBundleID(app)

  if entry then
    pcall(function() entry.watcher:stop() end)
    M.watchers.app[pid] = nil
  end

  if not bundleID then return end

  M.runContextForAppBundleID(bundleID, hs.application.watcher.terminated, app, nil, bundleID)
  if M.lollygagger then M.lollygagger:run(bundleID, hs.application.watcher.terminated, app, bundleID) end
end

-- interface: (app, initializing)
function M.watchApp(app, _)
  local pid = appPid(app)
  if pid == nil or M.watchers.app[pid] then return end

  local bundleID = appBundleID(app)
  if bundleID == nil then return end

  local watcher = app:newWatcher(M.handleWatchedEvent, app)
  if watcher == nil then return end

  M.watchers.app[pid] = { watcher = watcher, bundleID = bundleID }

  watcher:start({
    hs.uielement.watcher.windowCreated,
    hs.uielement.watcher.focusedWindowChanged,
    hs.uielement.watcher.titleChanged,
    hs.uielement.watcher.elementDestroyed,
  })
end

function M.runLayoutRulesForAppBundleID(elementOrAppName, event, app)
  -- NOTE: only certain events are layout-runnable
  local layoutableEvents = {
    hs.application.watcher.launched,
    hs.uielement.watcher.windowCreated,
  }

  if app and enum.contains(layoutableEvents, event) then
    hs.timer.doAfter(0.2, function()
      -- The app may have quit during the delay; pcall guards dead objects.
      local ok, hasWindows = pcall(function() return #app:allWindows() > 0 and app:mainWindow() ~= nil end)
      if ok and hasWindows then require("wm").placeApp(event, app) end
    end)
  end
end

-- NOTE: all events are context-runnable
function M.runContextForAppBundleID(elementOrAppName, event, app, metadata, bundleIDHint)
  local bundleID = bundleIDHint or appBundleID(app)
  if bundleID == nil or not M.watchers.context or not M.watchers.context[bundleID] then return end

  contexts:run({
    context = M.watchers.context[bundleID],
    element = type(elementOrAppName) ~= "string" and elementOrAppName or nil,
    event = event,
    appObj = app,
    bundleID = bundleID,
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
      if appEvent == hs.application.watcher.terminated then
        M.handleTerminated(appObj)
        return
      end

      M.handleWatchedEvent(appName, appEvent, nil, appObj)
      M.watchApp(appObj)
    end)
    :start()

  -- for watching individual apps
  self.watchers.app = {}
  self.watchers.context = contexts:preload()

  if M.lollygagger then self.lollygagger:start() end

  U.log.i(fmt("started", self.name))

  return self
end

function M:stop()
  if self.watchers.global then
    self.watchers.global:stop()
    self.watchers.global = nil
  end

  if self.watchers.app then
    enum.each(self.watchers.app, function(entry)
      if entry and entry.watcher then
        U.log.f("stopping app/element watcher %s", entry.bundleID or "?")
        pcall(function() entry.watcher:stop() end)
      end
    end)
    self.watchers.app = nil
  end

  if self.watchers.context then
    enum.each(self.watchers.context, function(w)
      -- Exit still-entered modals: contexts.preload() is idempotent, so a
      -- restart resumes these same context objects. A modal left entered
      -- would keep capturing hotkeys while the watcher is stopped.
      if w and w.modal and w._modalActive then
        w._modalActive = false
        pcall(function() w.modal:exit() end)
      end
      if w and type(w["stop"]) == "function" then
        U.log.f("stopping %s", w.name)
        pcall(function() w:stop() end)
      end
    end)
    self.watchers.context = nil
  end

  -- Clean up lollygagger timers
  if M.lollygagger then M.lollygagger:stop() end

  U.log.i(fmt("stopped", self.name))

  return self
end

return M
