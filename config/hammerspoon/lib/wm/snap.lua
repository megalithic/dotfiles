--- === WindowManager ===
---
--- Moves and resizes windows.
--- Features:
---   * Every window can be resized to be a quarter, half or the whole of the screen.
---   * Every window can be positioned anywhere on the screen, WITHIN the constraints of a grid. The grids are 1x1, 2x2 and 4x4 for maximized, half-sized and quarter-sized windows, respectively.
---   * Any given window can be cycled through all sizes and locations with just 4 keys. For example: northwest quarter → northeast quarter → right half ↓ southeast quarter ↓ bottom half ↓ full-screen.
local Window = require("hs.window")
local Screen = require("hs.screen")
local Geometry = require("hs.geometry")
local Spoons = require("hs.spoons")
local Settings = require("hs.settings")
local alert = require("hs.alert")

local load = require("utils.loader").load
local Hyper = nil

local obj = {}

obj.__index = obj
obj.modal = {}
obj.alerts = {}

-- second window resize suggestion a-la Windows
-- TODO
-- obj.overlay = {
--   fill = Drawing.rectangle({0, 0, 0, 0}):setLevel(Drawing.windowLevels["_MaximumWindowLevelKey"]):setFill(true):setFillColor(
--     getSystemBlueColor()
--   ):setAlpha(0.2):setRoundedRectRadii(3, 3),
--   stroke = Drawing.rectangle({0, 0, 0, 0}):setLevel(Drawing.windowLevels["_MaximumWindowLevelKey"]):setFill(false):setStrokeWidth(
--     15
--   ):setStrokeColor(getSystemBlueColor()):setStroke(true):setRoundedRectRadii(3, 3),
--   show = function(dimensions)
--     for _, v in ipairs({obj.overlay.fill, obj.overlay.stroke}) do
--       if v and v.hide then
--         v:setFrame(dimensions):show(0.2)
--       end
--     end
--   end,
--   hide = function()
--     for _, v in ipairs({obj.overlay.fill, obj.overlay.stroke}) do
--       if v and v.hide then
--         v:setFrame({0, 0, 0, 0}):hide(0.2)
--       end
--     end
--   end
-- }
-- local function getSystemBlueColor()
--   return Drawing.color.lists()["System"]["systemBlueColor"]
-- end
-- hs.timer.doAfter(0.5, function() tabBind:disable() end)
-- end

-- local mainScreen = Screen.mainScreen()
-- local usableFrame = mainScreen:frame()
-- local menuBarHeight = mainScreen:fullFrame().h - usableFrame.h
-- local minX = 0
-- local midX = usableFrame.w / 2
-- local maxX = usableFrame.w
-- local minY = usableFrame.y -- not a simple zero because of the menu bar
-- local midY = usableFrame.h / 2
-- local maxY = usableFrame.h

-- local possibleCells = {
--   northWest = {
--     rect = Geometry.rect({ minX, minY, midX, midY }),
--     onLeft = "west",
--     onRight = "northEast",
--     onUp = "north",
--     onDown = "southWest",
--   },
--   northEast = {
--     rect = Geometry.rect({ midX, minY, midX, midY }),
--     onLeft = "northWest",
--     onRight = "east",
--     onUp = "north",
--     onDown = "southEast",
--   },
--   southWest = {
--     rect = Geometry.rect({ minX, midY, midX, midY + menuBarHeight }),
--     onLeft = "west",
--     onRight = "southEast",
--     onUp = "northWest",
--     onDown = "south",
--   },
--   southEast = {
--     rect = Geometry.rect({ midX, midY, midX, midY + menuBarHeight }),
--     onLeft = "southWest",
--     onRight = "east",
--     onUp = "northEast",
--     onDown = "south",
--   },
--   west = {
--     rect = Geometry.rect({ minX, minY, midX, maxY }),
--     onLeft = "fullScreen",
--     onRight = "east",
--     onUp = "northWest",
--     onDown = "southWest",
--   },
--   east = {
--     rect = Geometry.rect({ midX, minY, midX, maxY }),
--     onLeft = "west",
--     onRight = "fullScreen",
--     onUp = "northEast",
--     onDown = "southEast",
--   },
--   south = {
--     rect = Geometry.rect({ minX, midY, maxX, midY + menuBarHeight }),
--     onLeft = "southWest",
--     onRight = "southEast",
--     onUp = "north",
--     onDown = "fullScreen",
--   },
--   north = {
--     rect = Geometry.rect({ minX, minY, maxX, midY }),
--     onLeft = "northWest",
--     onRight = "northEast",
--     onUp = "fullScreen",
--     onDown = "south",
--   },
--   fullScreen = {
--     rect = Geometry.rect({ minX, minY, maxX, maxY }),
--     onLeft = "west",
--     onRight = "east",
--     onUp = "north",
--     onDown = "south",
--   },
-- }

-- local fallbacks = { Up = "north", Down = "south", Right = "east", Left = "west" }

-- local function pushToCell(direction)
--   local frontWindow = Window.frontmostWindow()
--   local frontWindowFrame = frontWindow:frame()
--   for _, cellProperties in pairs(possibleCells) do
--     if frontWindowFrame:equals(cellProperties.rect) then
--       local targetCellName = cellProperties["on" .. direction]
--       local targetCell = possibleCells[targetCellName].rect
--       frontWindow:setFrame(targetCell)
--       return
--     end
--   end
--   local targetCellName = fallbacks[direction]
--   frontWindow:setFrame(possibleCells[targetCellName].rect)
-- end

-- local function maximize()
--   P("in snap.lua maximize")
--   local frontWindow = Window.frontmostWindow()
--   local frontWindowFrame = frontWindow:frame()
--   if frontWindowFrame:equals(possibleCells.fullScreen.rect) then
--     frontWindow:setFrame(possibleCells.northWest.rect)
--     frontWindow:centerOnScreen()
--   else
--     frontWindow:setFrame(possibleCells.fullScreen.rect)
--   end
-- end

-- local function center() Window.frontmostWindow():centerOnScreen() end

function obj.modal:entered()
  obj.alerts = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    local win = hs.window.focusedWindow()

    if win ~= nil then
      if screen == hs.screen.mainScreen() then
        local app_title = win:application():title()
        local image = hs.image.imageFromAppBundle(win:application():bundleID())
        local prompt = string.format("◱ : %s", app_title)
        if image ~= nil then prompt = string.format(": %s", app_title) end
        alert.showOnly({ text = prompt, image = image, screen = screen })
      end
    else
      -- unable to move a specific window. ¯\_(ツ)_/¯
      obj.modal:exit()
    end

    return nil
  end)
end

function obj.modal:exited()
  hs.fnutils.ieach(obj.alerts, function(id) alert.closeSpecific(id) end)

  alert.close()
end

-- obj.tile = function()
--   local windows = hs.fnutils.map(hs.window.filter.new():getWindows(), function(win)
--     if win ~= hs.window.focusedWindow() then
--       return {
--         text = win:title(),
--         subText = win:application():title(),
--         image = hs.image.imageFromAppBundle(win:application():bundleID()),
--         id = win:id(),
--       }
--     end
--   end)

--   local chooser = hs.chooser.new(function(choice)
--     if choice ~= nil then
--       local focused = hs.window.focusedWindow()
--       local toRead = hs.window.find(choice.id)
--       if hs.eventtap.checkKeyboardModifiers()["alt"] then
--         hs.layout.apply({
--           { nil, focused, focused:screen(), hs.layout.left70, 0, 0 },
--           { nil, toRead, focused:screen(), hs.layout.right30, 0, 0 },
--         })
--       else
--         hs.layout.apply({
--           { nil, focused, focused:screen(), hs.layout.left50, 0, 0 },
--           { nil, toRead, focused:screen(), hs.layout.right50, 0, 0 },
--         })
--       end
--       toRead:raise()
--     end
--   end)

--   chooser
--     :placeholderText("Choose window for 50/50 split. Hold ⎇ for 70/30.")
--     :searchSubText(true)
--     :choices(windows)
--     :show()
-- end

-- Margins --
obj.screen_edge_margins = {
  top = 32, -- px
  left = 0,
  right = 0,
  bottom = 0,
}
obj.partition_margins = {
  x = 0, -- px
  y = 0,
}

-- Partitions --
obj.split_screen_partitions = {
  x = 0.5, -- %
  y = 0.5,
}
obj.quarter_screen_partitions = {
  x = 0.5, -- %
  y = 0.5,
}

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

function obj.maximize() obj.set_frame("Full Screen", obj.screen()) end

function obj:init(opts)
  opts = opts or {}
  P(fmt("snap:init(%s) loaded.", hs.inspect(opts)))

  -- FIXME: why is Hyper calling start twice?
  Hyper = load("lib.hyper"):start()
  P(fmt("Hyper: %s", I(Hyper)))
  obj.modal = Hyper.modal
  P(fmt("obj.modal: %s", I(obj.modal)))

  return self
end

function obj:start()
  P(fmt("snap:start() executed."))

  P(fmt("Hyper: %s", I(Hyper)))
  Hyper:bind({}, "l", nil, function() obj.modal:enter() end)

  -- :: window-manipulation (manual window snapping)
  obj.modal:bind("", "return", function()
    P("-- should be binding here")
    obj.maximize()
    -- require("ext.window").chain(c.locations)(string.format("shortcut: %s", c.shortcut))
    obj.modal:exit()
  end)
  -- for _, c in pairs(Config.snap) do
  --   obj.modal:bind("", c.shortcut, function()
  --     P("-- should be binding here")
  --     -- require("ext.window").chain(c.locations)(string.format("shortcut: %s", c.shortcut))
  --     obj.modal:exit()
  --   end)
  -- end

  -- obj.modal
  --   :bind("", "v", function()
  --     M.windowSplitter()
  --     obj.modal:exit()
  --   end)
  --   :bind("ctrl", "[", function() obj.modal:exit() end)
  --   :bind("", "s", function()
  --     if hs.window.focusedWindow():application():name() == Config.preferred.browsers[1] then
  --       require("bindings.browser").split()
  --     end
  --     obj.modal:exit()
  --   end)
  --   :bind("", "escape", function() obj.modal:exit() end)
  --   :bind("shift", "h", function()
  --     hs.window.focusedWindow():moveOneScreenWest()
  --     obj.modal:exit()
  --   end)
  --   :bind("shift", "l", function()
  --     hs.window.focusedWindow():moveOneScreenEast()
  --     obj.modal:exit()
  --   end)
  --   :bind("", "tab", function()
  --     hs.window.focusedWindow():centerOnScreen()
  --     obj.modal:exit()
  --   end)

  return self
end

function obj:stop()
  P(fmt("snap:stop() executed."))
  obj.modal:exit()
  obj.alerts = nil
  return self
end

return obj
