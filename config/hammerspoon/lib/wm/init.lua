local Application = require("hs.application")
local Window = require("hs.window")
local fnutils = require("hs.fnutils")
local contextsDir = U.resourcePath("../contexts/")

local obj = {}
local Snap = nil

obj.__index = obj
obj.name = "wm"
obj.mode = "layout" -- "layout"|"snap"
obj.watcher = nil
obj.debug = false
obj.log = true
obj.contextModals = {}

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

local function info(...)
  if obj.log then return _G.info(...) end
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
-- TODO: pull layout info from launchers?
function obj.applyLayout(appConfig)
  if appConfig == nil then return end
  local bundleID = appConfig["bundleID"]
  local app = Application.get(bundleID)

  if appConfig.rules and #appConfig.rules > 0 then
    local layouts = {}

    fnutils.map(appConfig.rules, function(rule)
      local winTitlePattern, screenNum, positionStr = table.unpack(rule)
      winTitlePattern = (winTitlePattern ~= "") and winTitlePattern or nil

      local layout = {
        app, -- application name
        winTitlePattern, -- window title
        targetDisplay(screenNum), -- screen #
        Snap.grid[positionStr], -- layout/postion
        nil,
        nil,
      }
      dbg(fmt("layout: %s", I(layout)))
      table.insert(layouts, layout)
    end)
    hs.layout.apply(layouts, string.match)
    -- hs.timer.waitUntil(function() hs.layout.apply(layouts, string.match) end, 0.5)
  end
end

-- full-scale customization of an app; auto spins-up a context-based modal, binding defined actions to keys for that modal;
-- also allows for total customization of what should happen for certain app events (see below for supported watcher events).
function obj.applyContext(bundleID, appObj, event, fromWindowFilter)
  for key, context in pairs(obj.contextModals) do
    if key == bundleID then
      local appConfig = obj.layouts[bundleID]
      note(
        fmt(
          "[context_%s] (%s%s)",
          bundleID,
          U.eventName(event) or event,
          fromWindowFilter and "/fromWindowFilter" or ""
        )
      )

      if event == Application.watcher.activated or event == Application.watcher.launched then
        hs.timer.doAfter(0.1, function()
          context:start({
            bundleID = bundleID,
            appObj = appObj,
            event = event,
            appConfig = appConfig,
            appModal = context,
          })
          success(fmt(":: started %s context (%s)", bundleID, U.eventName(event)))
        end)
      elseif event == Application.watcher.deactivated or event == Application.watcher.terminated then
        context:stop({ event = event })
        info(fmt(":: stopped %s context (%s)", bundleID, U.eventName(event)))
      end
    end

    -- we want to always make sure the modal is inactive if we're not presently focused on our app
    if context.modal then context.modal:exit() end
  end
end

-- general handlers like quit-guard, delayed hiding or quitting/closing, etc.
function obj.applyHandlers(bundleID, appObj, event, fromWindowFilter)
  local appConfig = obj.layouts[bundleID]
  local lollygagger = L.load("lib.lollygagger", { id = bundleID, silent = true })

  if appConfig then
    if lollygagger then
      if appConfig.hideAfter then lollygagger.hideAfter(appObj, appConfig.hideAfter, event) end
      if appConfig.quitAfter then lollygagger.quitAfter(appObj, appConfig.quitAfter, event) end
    end
  end
end

local function handleWatcher(bundleID, appObj, event, fromWindowFilter)
  if event == Application.watcher.launched and bundleID ~= nil then
    note(fmt("[LAUNCHED] %s", bundleID))
    local appConfig = obj.layouts[bundleID]
    if appConfig then obj.applyLayout(appConfig) end
  elseif event == Application.watcher.terminated and bundleID ~= nil then
    note(fmt("[TERMINATED] %s", bundleID))
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

function obj.layoutRunningApps(apps)
  local runningApps = Application.runningApplications()

  fnutils.each(runningApps, function(app)
    local appConfig = apps[app:bundleID()]
    if appConfig ~= nil then
      dbg(fmt("running app to run: %s", appConfig.bundleID))
      obj.applyLayout(appConfig)
    end
  end)
end

function obj:init(opts)
  opts = opts or {}

  obj.layouts = C.layouts

  Snap = L.load("lib.wm.snap"):start()
  obj.watcher = L.load("lib.contexts", { id = "wm.watcher" })

  prepareContextScripts()

  return self
end

function obj:start(opts)
  opts = opts or {}

  local filters = generateAppFilters(obj.layouts)

  -- lib/contexts/init.lua instance; manually call :start() on it
  obj.watcher:start(obj.layouts, filters, handleWatcher)

  -- obj.layoutRunningApps(obj.layouts)

  note(fmt("[START] %s (%s)", obj.name, obj.mode))

  return self
end

function obj:stop()
  L.unload("lib.wm.snap")
  L.unload("lib.contexts")

  return self
end

return obj
