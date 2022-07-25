local Settings = require("hs.settings")
local load = require("utils.loader").load
local unload = require("utils.loader").unload
local utils = require("utils")
local fn = require("hs.fnutils")
-- local contextsDir = utils.resourcePath("contexts/")

local obj = {}
-- local appModals = {}
local Snap = nil

obj.__index = obj
obj.name = "wm"
obj.settingsKey = "_mega_wm"
obj.layoutWatcher = nil

-- targetDisplay(int) :: hs.screen
-- detect the current number of monitors and return target screen
function obj.targetDisplay(num)
  local displays = hs.screen.allScreens()
  if displays[num] ~= nil then
    return displays[num]
  else
    return hs.screen.primaryScreen()
  end
end

function obj._set_app_layout(cfg)
  if cfg == nil then return end

  local bundleID = cfg["bundleID"]
  local layouts = {}

  if cfg.rules and #cfg.rules > 0 then
    fn.map(cfg.rules, function(rule)
      local title_pattern, screen, position = rule[1], rule[2], rule[3]

      local layout = {
        hs.application.get(bundleID), -- application name
        title_pattern, -- window title
        -- hs.window.get(title_pattern), -- window title NOTE: this doesn't
        -- handle `nil` window title instances
        obj.targetDisplay(screen), -- screen #
        position, -- layout/postion
        nil,
        nil,
      }

      table.insert(layouts, layout)
    end)
  end

  return layouts
end

local function enterLayoutContext(appObj, bundleID)
  dbg(fmt("wm.enterLayoutContextCallback: %s %s", appObj, bundleID))

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

  obj.apps = Settings.get(CONFIG_KEY).apps
  Snap = load("lib.wm.snap"):start()
  obj.layoutWatcher = load("lib.contexts")

  return self
end

function obj:start(opts)
  opts = opts or {}

  -- app layouts
  obj.layoutWatcher:start(obj.apps, function(bundleId, appObj, isWinFilterEvent)
    -- dbg(fmt("wm.layoutWatcher: %s %s (%s)", bundleId, appObj, isWinFilterEvent))
    enterLayoutContext(appObj, bundleId)
  end)

  return self
end

function obj:stop()
  unload("lib.wm.snap")
  unload("lib.contexts")

  return self
end

return obj
