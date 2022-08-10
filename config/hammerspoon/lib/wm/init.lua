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
obj.mode = "layout" -- "layout"|"snap"
obj.watcher = nil
obj.debug = false
obj.log = true
obj.contextModals = {}
obj.layoutComplete = true

local function info(...)
  if obj.log then return _G.info(...) end
end
local function dbg(...)
  if obj.debug then return _G.dbg(...) end
end
local function note(...)
  if obj.log then return _G.note(...) end
end
local function success(...)
  if obj.log then return _G.success(...) end
end

local function getWindow(winTitlePattern, bundleID)
  local win = winTitlePattern

  local app = Application.get(bundleID)
  if winTitlePattern ~= nil then
    win = Window.find(winTitlePattern)
  else
    -- app is nil here sometimes
    win = app:mainWindow()
  end

  return win
end

local function targetDisplay(num)
  local displays = hs.screen.allScreens() or {}
  if displays[num] ~= nil then
    return displays[num]
  else
    return hs.screen.primaryScreen()
  end
end

-- handles auto-layout of launched apps; using lib.snap
function obj.applyLayout(appConfig)
  if appConfig == nil then return end
  local bundleID = appConfig["bundleID"]

  if appConfig.rules and #appConfig.rules > 0 then
    obj.layoutComplete = false

    if obj.mode == "snap" then
      fnutils.each(appConfig.rules, function(rule)
        local winTitlePattern, screenNum, positionStr = table.unpack(rule)
        winTitlePattern = (winTitlePattern and winTitlePattern ~= "") and winTitlePattern or nil

        hs.timer.waitUntil(function() return getWindow(winTitlePattern, appConfig.bundleID) ~= nil end, function()
          Snap.snapper(getWindow(winTitlePattern, appConfig.bundleID), positionStr, targetDisplay(screenNum))
          obj.layoutComplete = true
        end)
      end)
    elseif obj.mode == "layout" then
      local layouts = {}

      fnutils.map(appConfig.rules, function(rule)
        local winTitlePattern, screenNum, positionStr = table.unpack(rule)

        table.insert(layouts, {
          hs.application.get(bundleID), -- application name
          winTitlePattern, -- window title
          targetDisplay(screenNum), -- screen #
          Snap.grid[positionStr], -- layout/postion
          nil,
          nil,
        })
      end)

      hs.layout.apply(layouts, string.match)
      obj.layoutComplete = true
    end
  end
end

-- full-scale customization of an app; auto spins up a context-based modal, binding defined actions to keys for that modal;
-- also allows for total customization of what should happen for certain app events (see below for supported watcher events).
function obj.applyContext(bundleID, appObj, event, fromWindowFilter)
  for key, modal in pairs(obj.contextModals) do
    -- note(fmt(":: MATCHING CONTEXT? %s, %s", key, bundleID))
    if key == bundleID then
      dbg(fmt(":: MATCHING CONTEXT? %s == %s", key, bundleID))
      local appConfig = obj.apps[bundleID]
      note(
        fmt(
          "[context_%s] (%s%s)",
          bundleID,
          U.eventName(event) or event,
          fromWindowFilter and "/fromWindowFilter" or ""
        )
      )
      if appConfig then
        if event == Application.watcher.activated or event == Application.watcher.launched then
          -- hs.timer.waitUntil(function() return obj.layoutComplete end, function()
          modal:start({
            bundleID = bundleID,
            appObj = appObj,
            event = event,
            appConfig = appConfig,
            appModal = modal,
          })
          success(fmt(":: started %s context (%s)", bundleID, U.eventName(event)))
          -- end)
        elseif event == Application.watcher.deactivated or event == Application.watcher.terminated then
          modal:stop({ event = event })
          success(fmt(":: stopped %s context (%s)", bundleID, U.eventName(event)))
        end
      end
    end
  end
end

-- general handlers like quit-guard, delayed hiding or quitting/closing, etc.
function obj.applyHandlers(bundleID, appObj, event, fromWindowFilter)
  local appConfig = obj.apps[bundleID]
  local lollygagger = L.load("lib.lollygagger", { id = bundleID, silent = true })

  if appConfig then
    if lollygagger then
      if appConfig.hideAfter then lollygagger.hideAfter(appObj, appConfig.hideAfter, event) end
      if appConfig.quitAfter then lollygagger.quitAfter(appObj, appConfig.quitAfter, event) end
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
  obj.applyHandlers(bundleID, appObj, event, fromWindowFilter)
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

          -- FIXME: for some reason context applying fails on deactivate/activate
          -- so we don't exit the modal for other apps
          --
          -- if script.actions ~= nil then
          --   for _, value in pairs(script.actions) do
          --     local hotkey = value.hotkey
          --     if hotkey then
          --       local mods, key = table.unpack(hotkey)
          --       script.modal:bind(mods, key, value.action)
          --     end
          --   end
          -- end
          obj.contextModals[basenameAndBundleID] = script
        end
      end
    end
  end
end

function obj.layoutRunningApps(apps)
  local runningApps = Application.runningApplications()

  fnutils.each(runningApps, function(app)
    local appConfig = apps[app:bundleID()]
    if appConfig then obj.applyLayout(appConfig) end
  end)
end

function obj:init(opts)
  opts = opts or {}

  obj.apps = Settings.get(CONFIG_KEY).bindings.apps

  Snap = L.load("lib.wm.snap"):start()
  obj.watcher = L.load("lib.contexts", { id = "wm.watcher" })

  prepareContextScripts()

  return self
end

function obj:start(opts)
  opts = opts or {}

  local filters = generateAppFilters(obj.apps)

  obj.watcher:start(obj.apps, filters, handleWatcher)

  obj.layoutRunningApps(obj.apps)

  note(fmt("[START] %s (%s)", obj.name, obj.mode))

  return self
end

function obj:stop()
  L.unload("lib.wm.snap")
  L.unload("lib.contexts")

  return self
end

return obj
