local Application = require("hs.application")
local Window = require("hs.window")
local Settings = require("hs.settings")
local fnutils = require("hs.fnutils")
-- local contextsDir = utils.resourcePath("contexts/")

local obj = {}
local Snap = nil

obj.__index = obj
obj.name = "wm"
obj.settingsKey = "_mega_wm"
obj.layoutWatcher = nil
obj.debug = true

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

-- FIXME: deprecated; calling fns directly for each window
function obj.setLayout(appConfig)
  if appConfig == nil then return end

  local bundleID = appConfig["bundleID"]
  local appLayout = {}

  if appConfig.rules and #appConfig.rules > 0 then
    fnutils.map(appConfig.rules, function(rule)
      local title_pattern, screen, positionStr = table.unpack(rule)
      local position = Snap.grid[positionStr] or hs.layout.maximized
      title_pattern = (title_pattern and title_pattern ~= "") and title_pattern or nil

      dbg(
        fmt(
          "!! wm.setLayout: %s -> %s (%s) / %s (%s)",
          title_pattern or "no title",
          obj.targetDisplay(screen),
          screen,
          positionStr,
          position
        )
      )

      local layout = {
        hs.application.get(bundleID),
        title_pattern,
        obj.targetDisplay(screen),
        position,
        nil,
        nil,
      }

      table.insert(appLayout, layout)
    end)
  end

  return appLayout
end

function obj.applyLayout(appConfig)
  if appConfig == nil then return end

  local bundleID = appConfig["bundleID"]

  if appConfig.rules and #appConfig.rules > 0 then
    fnutils.each(appConfig.rules, function(rule)
      local winTitlePattern, screenNum, positionStr = table.unpack(rule)
      winTitlePattern = (winTitlePattern and winTitlePattern ~= "") and winTitlePattern or nil

      local app = Application.get(bundleID)
      local win = Window.find(winTitlePattern) or app:focusedWindow()
      local screen = obj.targetDisplay(screenNum)

      Snap.snapper(win, positionStr, screen)
    end)
  end
end

local function handleLayout(bundleID, appObj, event, fromWindowFilter)
  if event == Application.watcher.launched and bundleID then
    note(fmt("[LAUNCHED] %s", bundleID))
    local appConfig = obj.apps[bundleID]
    -- local appLayout = obj.setLayout(appConfig)
    obj.applyLayout(appConfig)
  end
end

local function handleContext(bundleID, appObj, event, fromWindowFilter)
  -- for key, value in pairs(appModals) do
  --   if key == bundleID then
  --     value:start(appObj)
  --   else
  --     value:stop()
  --   end
  -- end
end

local function generateAppFilters(apps)
  local filters = {}
  fnutils.map(apps, function(app) filters[app.name] = true end)
  return filters
end

function obj:init(opts)
  opts = opts or {}

  local config = Settings.get(CONFIG_KEY)
  obj.apps = config.bindings.apps

  Snap = L.load("lib.wm.snap"):start()
  obj.layoutWatcher = L.load("lib.contexts")

  return self
end

function obj:start(opts)
  opts = opts or {}

  -- app layouts
  obj.layoutWatcher:start(obj.apps, generateAppFilters(obj.apps), handleLayout)
  -- app-specific contexts
  -- obj.contextWatcher:start(obj.apps, handleContext)

  return self
end

function obj:stop()
  L.unload("lib.wm.snap")
  L.unload("lib.contexts")

  return self
end

return obj
