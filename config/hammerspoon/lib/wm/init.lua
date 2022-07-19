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

obj.__index = obj
obj.name = "wm"
obj.settingsKey = "_mega_wm"
obj.watcher = nil

obj.grid = Settings.get("_mega_config").grid

-- return currently focused window
function obj.win() return hs.window.focusedWindow() end
-- display title, save state and move win to unit
function obj.set_frame(title, unit)
  hs.alert.show(title)
  local win = obj.win()
  obj.snapback_window_state[win:id()] = win:frame()
  return win:setFrame(unit)
end
-- screen is the available rect inside the screen edge margins
function obj.screen()
  local screen = obj.win():screen():frame()
  local sem = obj.screen_edge_margins
  return {
    x = screen.x + sem.left,
    y = screen.y + sem.top,
    w = screen.w - (sem.left + sem.right),
    h = screen.h - (sem.top + sem.bottom),
  }
end

-- snapback return the window to its last position. calling snapback twice returns the window to its original position.
-- snapback holds state for each window, and will remember previous state even when focus is changed to another window.
function obj.snapback()
  local win = obj.win()
  local id = win:id()
  local state = win:frame()
  local prev_state = obj.snapback_window_state[id]
  if prev_state then win:setFrame(prev_state) end
  if id ~= nil then obj.snapback_window_state[id] = state end
end

function obj.maximize() obj.set_frame("Full Screen", obj.screen()) end

-- gutter is the adjustment required to accomidate partition
-- margins between windows
function obj.gutter()
  local pm = obj.partition_margins
  return {
    x = pm.x / 2,
    y = pm.y / 2,
  }
end

local function enterAppContext(appObj, bundleID)
  for key, value in pairs(appModals) do
    if key == bundleID then
      value:start(appObj)
    else
      value:stop()
    end
  end
end

function obj:init(opts)
  opts = opts or {}

  load("lib.wm.snap")
  obj.watcher = load("lib.contexts", { opt = true })

  return self
end

function obj:start(opts)
  opts = opts or {}

  -- Watcher:start(transientApps, function(bundleId, appObj, isWinFilterEvent) enterAppEnvironment(appObj, bundleId) end)
  return self
end

function obj:stop()
  unload("lib.wm.snap")
  unload("lib.contexts")

  return self
end

return obj
