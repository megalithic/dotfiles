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

-- local appHandler = function(appName, event, appObj, windowTitle)
--   info(fmt("appHandler: %s/%s/%s (%s)", appName, event, appObj:bundleID(), windowTitle))
--   if event == hs.uielement.watcher.windowCreated then
--     if appName:find("Google Chrome") then
--       if windowTitle:find("(Private)", 1, true) then
--         if hs.application.find("OpenVPN Connect") then print("Created private window created while on VPN") end
--       end
--     end
--   elseif event == hs.uielement.watcher.titleChanged then
--     -- print("title changed")
--   elseif event == hs.uielement.watcher.elementDestroyed then
--     -- print("destroyed")
--   elseif event == hs.uielement.watcher.focusedWindowChanged then
--     if appName:find("Google Chrome") then
--       if windowTitle:find("(Private)", 1, true) then
--         if hs.application.find("OpenVPN Connect") then print("Switched to private window created while on VPN") end
--       end
--     end
--   end
-- end

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
    -- hs.application.watcher.activated,
    hs.application.watcher.launched,
    hs.uielement.watcher.windowCreated,
    -- hs.uielement.watcher.applicationActivated,
    -- hs.application.watcher.deactivated,
    hs.application.watcher.terminated,
    -- hs.uielement.watcher.applicationDeactivated,
  }

  local function targetDisplay(num)
    local displays = hs.screen.allScreens() or {}
    if displays[num] ~= nil then
      return displays[num]
    else
      return hs.screen.primaryScreen()
    end
  end

  if appObj and appObj:focusedWindow() and enum.contains(layoutableEvents, event) then
    local appLayout = LAYOUTS[appObj:bundleID()]
    if appLayout ~= nil then
      if appLayout.rules and #appLayout.rules > 0 then
        enum.each(appLayout.rules, function(rule)
          local winTitlePattern, screenNum, position = table.unpack(rule)

          winTitlePattern = (winTitlePattern ~= "") and winTitlePattern or nil
          local win = winTitlePattern == nil and appObj:mainWindow() or hs.window.find(winTitlePattern)

          -- if win == nil then win = appObj:focusedWindow() end

          if win ~= nil then
            note(
              fmt(
                "[LAYOUT] layouts/%s (%s): %s",
                appObj:bundleID(),
                utils.eventEnums(event),
                appObj:focusedWindow():title()
              )
            )

            dbg(
              fmt(
                "[RULES] %s (%s): %s",
                type(elementOrAppName) == "string" and elementOrAppName or I(elementOrAppName),
                win:title(),
                I(appLayout.rules)
              ),
              obj.debug
            )

            hs.grid.set(win, position, targetDisplay(screenNum))
          end
        end)
      end
    end
  end
end

function obj.runContextForAppBundleID(elementOrAppName, event, appObj)
  if not obj.watchers.context[appObj:bundleID()] then return end

  -- slight delay
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
