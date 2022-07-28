local Application = require("hs.application")
local Window = require("hs.window")
local Settings = require("hs.settings")
local fnutils = require("hs.fnutils")
local contextsDir = U.resourcePath("../contexts/")

local obj = {}
local Snap = nil

obj.__index = obj
obj.name = "wm"
obj.settingsKey = "_mega_wm"
obj.watcher = nil
obj.debug = false
obj.contextModals = {}
obj.layoutComplete = true

local function info(...)
  if obj.debug then return _G.info(...) end
end
local function dbg(...)
  if obj.debug then return _G.dbg(...) end
end
local function note(...)
  if obj.debug then return _G.note(...) end
end
local function success(...)
  if obj.debug then return _G.success(...) end
end

-- targetDisplay(int) :: hs.screen
-- detect the current number of monitors and return target screen
function obj.targetDisplay(num)
  local displays = hs.screen.allScreens() or {}
  if displays[num] ~= nil then
    return displays[num]
  else
    return hs.screen.primaryScreen()
  end
end

function obj.applyLayout(appConfig)
  if appConfig == nil then return end

  local function getWindow(winTitlePattern, bundleID)
    local win = winTitlePattern

    local app = Application.get(bundleID)
    if winTitlePattern ~= nil then
      win = Window.find(winTitlePattern)
    else
      win = app:mainWindow()
    end

    return win
  end

  local bundleID = appConfig["bundleID"]

  if appConfig.rules and #appConfig.rules > 0 then
    obj.layoutComplete = false

    fnutils.each(appConfig.rules, function(rule)
      local winTitlePattern, screenNum, positionStr = table.unpack(rule)
      winTitlePattern = (winTitlePattern and winTitlePattern ~= "") and winTitlePattern or nil

      hs.timer.waitUntil(function() return getWindow(winTitlePattern, bundleID) ~= nil end, function()
        Snap.snapper(getWindow(winTitlePattern, bundleID), positionStr, obj.targetDisplay(screenNum))
        obj.layoutComplete = true
      end)
    end)
  end
end

-- presently only handles (de)activated events to enter/exit the context modal.
function obj.applyContext(bundleID, appObj, event, fromWindowFilter)
  for key, modal in pairs(obj.contextModals) do
    if key == bundleID then
      local appConfig = obj.apps[bundleID]
      note(
        fmt(
          "[context_%s] (%s%s)",
          bundleID,
          U.eventName(event) or event,
          fromWindowFilter and "/fromWindowFilter" or ""
        )
      )
      if event == Application.watcher.activated or event == Application.watcher.launched then
        hs.timer.waitUntil(
          function() return obj.layoutComplete end,
          function() modal:start({ bundleID = bundleID, appObj = appObj, event = event, appConfig = appConfig }) end
        )
      elseif event == Application.watcher.deactivated or event == Application.watcher.terminated then
        modal:stop({ event = event })
      end
    end
  end
end

local function handleWatcher(bundleID, appObj, event, fromWindowFilter)
  -- auto-layout events: [launched]
  if event == Application.watcher.launched and bundleID then
    note(fmt("[LAUNCHED] %s", bundleID))
    local appConfig = obj.apps[bundleID]
    obj.applyLayout(appConfig)
  else
    if event == Application.watcher.terminated and bundleID then note(fmt("[TERMINATED] %s", bundleID)) end
  end

  obj.applyContext(bundleID, appObj, event, fromWindowFilter)
end

local function generateAppFilters(apps)
  local filters = {}
  fnutils.map(apps, function(app) filters[app.name] = true end)
  return filters
end

local function prepareContextScripts()
  local iterFn, dirObj = hs.fs.dir(contextsDir)
  if iterFn then
    for file in iterFn, dirObj do
      if string.sub(file, -3) == "lua" then
        local basenameAndBundleID = string.sub(file, 1, -5)
        local script = dofile(contextsDir .. file)
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
          obj.contextModals[basenameAndBundleID] = script
        end
      end
    end
  end
end

function obj:init(opts)
  opts = opts or {}

  local config = Settings.get(CONFIG_KEY)
  obj.apps = config.bindings.apps

  Snap = L.load("lib.wm.snap"):start()
  obj.watcher = L.load("lib.contexts", { id = "wm.watcher" })

  prepareContextScripts()

  return self
end

function obj:start(opts)
  opts = opts or {}

  local filters = generateAppFilters(obj.apps)

  obj.watcher:start(obj.apps, filters, handleWatcher)

  return self
end

function obj:stop()
  L.unload("lib.wm.snap")
  L.unload("lib.contexts")

  return self
end

return obj
