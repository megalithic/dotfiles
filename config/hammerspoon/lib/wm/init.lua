local Window = require("hs.window")
local Screen = require("hs.screen")
local Geometry = require("hs.geometry")
local Settings = require("hs.settings")
local load = require("utils.loader").load
local unload = require("utils.loader").unload
local utils = require("utils")
local contextsDir = utils.resourcePath("contexts/")

local obj = {}
local appModals = {}
local Snap = nil

obj.__index = obj
obj.name = "wm"
obj.settingsKey = "_mega_wm"
obj.watcher = nil

obj.grid = Settings.get(CONFIG_KEY).grid

-- local function enterAppContext(appObj, bundleID)
--   for key, value in pairs(appModals) do
--     if key == bundleID then
--       value:start(appObj)
--     else
--       value:stop()
--     end
--   end
-- end

function obj:init(opts)
  opts = opts or {}

  Snap = load("lib.wm.snap"):start()
  obj.watcher = load("lib.contexts")

  return self
end

function obj:start(opts)
  opts = opts or {}

  obj.watcher:start(
    -- transientApps,
    -- function(bundleId, appObj, isWinFilterEvent) enterAppEnvironment(appObj, bundleId) end
  )

  return self
end

function obj:stop()
  unload("lib.wm.snap")
  unload("lib.contexts")

  return self
end

return obj
