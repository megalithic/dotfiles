local Application = require("hs.application")
local Settings = require("hs.settings")
local fnutils = require("hs.fnutils")
-- local contextsDir = utils.resourcePath("contexts/")

local obj = {}
local Snap = nil

obj.__index = obj
obj.name = "wm"
obj.settingsKey = "_mega_wm"
obj.layoutWatcher = nil

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

function obj.setLayout(appConfig)
  if appConfig == nil then return end

  local bundleID = appConfig["bundleID"]
  local appLayout = {}

  if appConfig.rules and #appConfig.rules > 0 then
    fnutils.map(appConfig.rules, function(rule)
      local title_pattern, screen, positionStr = table.unpack(rule)
      local position = Snap.grid[positionStr] or hs.layout.maximized
      title_pattern = (title_pattern and title_pattern ~= "") and title_pattern or nil

      dbg(fmt("!! wm.setLayout: %s (%s) -> %s (%s)", title_pattern or "no title", screen, positionStr, position))

      local layout = {
        hs.application.get(bundleID), -- application name
        title_pattern, -- window title
        obj.targetDisplay(screen), -- screen #
        position, -- layout/postion
        nil,
        nil,
      }

      table.insert(appLayout, layout)
    end)
  end

  return appLayout
end

function obj.applyLayout(appLayout)
  if appLayout then hs.layout.apply(appLayout, string.match) end
end

local function handleLayout(bundleID, appObj, event, fromWindowFilter)
  -- info(fmt(
  --   ":: wm - %s (%s)",
  --   -- "wm.handleLayoutContext: %s(%s/%s) -- %s",
  --   bundleID,
  --   obj.layoutWatcher.eventName(event),
  --   fromWindowFilter,
  --   appObj
  -- ))

  if event == Application.watcher.launched and bundleID then
    note(fmt("[LAUNCHED] %s", bundleID))
    local appConfig = obj.apps[bundleID]
    local appLayout = obj.setLayout(appConfig)
    obj.applyLayout(appLayout)
  end

  -- for key, value in pairs(appModals) do
  --   if key == bundleID then
  --     value:start(appObj)
  --   else
  --     value:stop()
  --   end
  -- end
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
  obj.layoutWatcher:start(obj.apps, handleLayout)
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
