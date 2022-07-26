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
obj.layoutWatcher = nil
obj.contextWatcher = nil
obj.debug = true
obj.contextModals = {}

local function info(...)
  if obj.debug then
    return _G.info(...)
  else
    return print("")
  end
end
local function dbg(...)
  if obj.debug then
    return _G.dbg(...)
  else
    return print("")
  end
end
local function note(...)
  if obj.debug then
    return _G.note(...)
  else
    return print("")
  end
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

  local bundleID = appConfig["bundleID"]

  if appConfig.rules and #appConfig.rules > 0 then
    fnutils.each(appConfig.rules, function(rule)
      local winTitlePattern, screenNum, positionStr = table.unpack(rule)
      winTitlePattern = (winTitlePattern and winTitlePattern ~= "") and winTitlePattern or nil

      local app = Application.get(bundleID)

      local win = winTitlePattern
      if winTitlePattern ~= nil then
        win = Window.find(winTitlePattern)
      else
        win = app:mainWindow()
      end

      local screen = obj.targetDisplay(screenNum)
      Snap.snapper(win, positionStr, screen)
    end)
  end
end

local function handleLayout(bundleID, appObj, event, fromWindowFilter)
  if event == Application.watcher.launched and bundleID then
    note(fmt("[LAUNCHED] %s", bundleID))
    local appConfig = obj.apps[bundleID]
    obj.applyLayout(appConfig)
  else
    if event == Application.watcher.terminated and bundleID then note(fmt("[TERMINATED] %s", bundleID)) end
  end
end

-- presently only handles (de)activated events to enter/exit the context modal.
local function handleContext(bundleID, appObj, event, fromWindowFilter)
  for key, modal in pairs(obj.contextModals) do
    local appConfig = obj.apps[bundleID]
    if key == bundleID and event == Application.watcher.activated then
      modal:start({ bundleID = bundleID, appObj = appObj, event = event, appConfig = appConfig })
    elseif key == bundleID and event == Application.watcher.deactivated then
      modal:stop()
    end
  end
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
          note(fmt("[wm.prepareContextScripts] %s", basenameAndBundleID))
          if script.modal ~= nil and script.actions ~= nil then
            script.modal = hs.hotkey.modal.new()
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
  obj.layoutWatcher = L.load("lib.contexts", { id = "wm.layout" })
  obj.contextWatcher = L.load("lib.contexts", { id = "wm.context" })

  prepareContextScripts()

  return self
end

function obj:start(opts)
  opts = opts or {}

  local filters = generateAppFilters(obj.apps)

  -- app layouts
  obj.layoutWatcher:start(obj.apps, filters, handleLayout)

  -- app-specific contexts
  obj.contextWatcher:start(obj.apps, filters, handleContext)

  return self
end

function obj:stop()
  L.unload("lib.wm.snap")
  L.unload("lib.contexts")

  return self
end

return obj
