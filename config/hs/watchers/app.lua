local enum = require("hs.fnutils")
local utils = require("utils")
local contexts = require("contexts")

local obj = {}

obj.__index = obj
obj.name = "watcher.app"
obj.debug = false
obj.watchers = {
  app = {},
  context = {},
}
obj.contextModals = {}
obj.contextsPath = utils.resourcePath("../contexts/")

local appHandler = function(appName, event, appObj, windowTitle)
  info(fmt("appHandler: %s/%s/%s (%s)", appName, event, appObj:bundleID(), windowTitle))
  if event == hs.uielement.watcher.windowCreated then
    if appName:find("Google Chrome") then
      if windowTitle:find("(Private)", 1, true) then
        if hs.application.find("OpenVPN Connect") then print("Created private window created while on VPN") end
      end
    end
  elseif event == hs.uielement.watcher.titleChanged then
    -- print("title changed")
  elseif event == hs.uielement.watcher.elementDestroyed then
    -- print("destroyed")
  elseif event == hs.uielement.watcher.focusedWindowChanged then
    if appName:find("Google Chrome") then
      if windowTitle:find("(Private)", 1, true) then
        if hs.application.find("OpenVPN Connect") then print("Switched to private window created while on VPN") end
      end
    end
  end
end

function obj.prepareContextScripts(contextsScriptsPath)
  contextsScriptsPath = contextsScriptsPath or obj.contextsPath
  local iterFn, dirObj = hs.fs.dir(contextsScriptsPath)
  if iterFn then
    for file in iterFn, dirObj do
      if string.sub(file, -3) == "lua" then
        local basenameAndBundleID = string.sub(file, 1, -5)
        local script = dofile(contextsScriptsPath .. file)
        if basenameAndBundleID ~= "init" then
          if script.modal then script.modal = hs.hotkey.modal.new() end

          if script.actions ~= nil then
            for _, value in pairs(script.actions) do
              local hotkey = value.hotkey
              if hotkey then
                local mods, key = table.unpack(hotkey)
                script.modal:bind(mods, key, value.action)
              end
            end
          end

          obj.watchers.context[basenameAndBundleID] = script
        end
      end
    end
  end
end

-- interface: (appName, eventType, appObject)
obj.handleGlobalAppEvent = function(appName, event, appObj)
  -- if event == hs.application.watcher.activated then print("activated " .. appName) end
  -- if event == hs.application.watcher.deactivated then print("deactivated " .. appName) end
  -- if event == hs.application.watcher.launched then print("launched " .. appName) end
  obj.runContextForAppBundleID(appName, event, appObj)
end

-- interface: (element, event, watcher, info)
obj.handleAppEvent = function(element, event, _watcher, appObj)
  if element ~= nil then obj.runContextForAppBundleID(element, event, appObj) end
end

-- interface: (app, initializing)
obj.watchApp = function(app, _)
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

obj.attachExistingApps = function()
  local apps = enum.filter(hs.application.runningApplications(), function(app) return app:title() ~= "Hammerspoon" end)
  enum.each(apps, function(app) obj.watchApp(app, true) end)
end

obj.runContextForAppBundleID = function(elementOrAppName, event, appObj)
  if not obj.watchers.context[appObj:bundleID()] then return end

  contexts:run({
    context = obj.watchers.context[appObj:bundleID()],
    element = type(elementOrAppName) ~= "string" and elementOrAppName or nil,
    event = event,
    appObj = appObj,
    bundleID = appObj:bundleID(),
  })
end

function obj:start()
  self.prepareContextScripts()
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
