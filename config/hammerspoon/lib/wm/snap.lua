-- local Window = require("hs.window")
-- local Screen = require("hs.screen")
-- local Geometry = require("hs.geometry")
-- local Spoons = require("hs.spoons")
-- local Settings = require("hs.settings")
local alert = require("hs.alert")

local load = require("utils.loader").load

local obj = {}

obj.__index = obj
obj.name = "snap"
obj.alerts = {}
obj.snapback_window_state = {}
local Hyper

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

function obj.send_window_left()
  local s = obj.screen()
  local ssp = obj.split_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Left", {
    x = s.x,
    y = s.y,
    w = (s.w * ssp.x) - obj.gutter().x,
    h = s.h,
  })
end

function obj.send_window_right()
  local s = obj.screen()
  local ssp = obj.split_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Right", {
    x = s.x + (s.w * ssp.x) + g.x,
    y = s.y,
    w = (s.w * (1 - ssp.x)) - g.x,
    h = s.h,
  })
end

function obj.send_window_up()
  local s = obj.screen()
  local ssp = obj.split_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Up", {
    x = s.x,
    y = s.y,
    w = s.w,
    h = (s.h * ssp.y) - g.y,
  })
end

function obj.send_window_down()
  local s = obj.screen()
  local ssp = obj.split_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Down", {
    x = s.x,
    y = s.y + (s.h * ssp.y) + g.y,
    w = s.w,
    h = (s.h * (1 - ssp.y)) - g.y,
  })
end

function obj.send_window_upper_left()
  local s = obj.screen()
  local qsp = obj.quarter_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Upper Left", {
    x = s.x,
    y = s.y,
    w = (s.w * qsp.x) - g.x,
    h = (s.h * qsp.y) - g.y,
  })
end

function obj.send_window_upper_right()
  local s = obj.screen()
  local qsp = obj.quarter_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Upper Right", {
    x = s.x + (s.w * qsp.x) + g.x,
    y = s.y,
    w = (s.w * (1 - qsp.x)) - g.x,
    h = (s.h * qsp.y) - g.y,
  })
end

function obj.send_window_lower_left()
  local s = obj.screen()
  local qsp = obj.quarter_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Lower Left", {
    x = s.x,
    y = s.y + (s.h * qsp.y) + g.y,
    w = (s.w * qsp.x) - g.x,
    h = (s.h * (1 - qsp.y)) - g.y,
  })
end
function obj.send_window_lower_right()
  local s = obj.screen()
  local qsp = obj.quarter_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Lower Right", {
    x = s.x + (s.w * qsp.x) + g.x,
    y = s.y + (s.h * qsp.y) + g.y,
    w = (s.w * (1 - qsp.x)) - g.x,
    h = (s.h * (1 - qsp.y)) - g.y,
  })
end

function obj.send_window_prev_monitor()
  hs.alert.show("Prev Monitor")
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():previous()
  win:moveToScreen(nextScreen)
end

function obj.send_window_next_monitor()
  hs.alert.show("Next Monitor")
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():next()
  win:moveToScreen(nextScreen)
end

-- snapback return the window to its last position. calling snapback twice returns the window to its original position.
-- snapback holds state for each window, and will remember previous state even when focus is changed to another window.
function obj.snapback()
  local win = obj.win()
  local id = win:id()
  local state = win:frame()
  local prev_state = obj.snapback_window_state[id]
  if prev_state then win:setFrame(prev_state) end
  obj.snapback_window_state[id] = state
end

function obj.maximize() obj.set_frame("Full Screen", obj.screen()) end

--- move_to_center_relative(size)
--- Method
--- Centers and resizes the window to the the fit on the given portion of the screen.
--- The argument is a size with each key being between 0.0 and 1.0.
--- Example: win:move_to_center_relative(w=0.5, h=0.5) -- window is now centered and is half the width and half the height of screen
function obj.move_to_center_relative(unit)
  local s = obj.screen()
  obj.set_frame("Center", {
    x = s.x + (s.w * ((1 - unit.w) / 2)),
    y = s.y + (s.h * ((1 - unit.h) / 2)),
    w = s.w * unit.w,
    h = s.h * unit.h,
  })
end

--- move_to_center_absolute(size)
--- Method
--- Centers and resizes the window to the the fit on the given portion of the screen given in pixels.
--- Example: win:move_to_center_relative(w=800, h=600) -- window is now centered and is 800px wide and 600px high
function obj.move_to_center_absolute(unit)
  local s = obj.screen()
  obj.set_frame("Center", {
    x = (s.w - unit.w) / 2,
    y = (s.h - unit.h) / 2,
    w = unit.w,
    h = unit.h,
  })
end

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
-- gutter is the adjustment required to accomidate partition
-- margins between windows
function obj.gutter()
  local pm = obj.partition_margins
  return {
    x = pm.x / 2,
    y = pm.y / 2,
  }
end

--- hs.window:moveToScreen(screen)
--- Method
--- move window to the the given screen, keeping the relative proportion and position window to the original screen.
--- Example: win:moveToScreen(win:screen():next()) -- move window to next screen
function hs.window:moveToScreen(nextScreen)
  local currentFrame = self:frame()
  local screenFrame = self:screen():frame()
  local nextScreenFrame = nextScreen:frame()
  self:setFrame({
    x = ((((currentFrame.x - screenFrame.x) / screenFrame.w) * nextScreenFrame.w) + nextScreenFrame.x),
    y = ((((currentFrame.y - screenFrame.y) / screenFrame.h) * nextScreenFrame.h) + nextScreenFrame.y),
    h = ((currentFrame.h / screenFrame.h) * nextScreenFrame.h),
    w = ((currentFrame.w / screenFrame.w) * nextScreenFrame.w),
  })
end

local function setupEvents()
  function Hyper.modal:entered()
    info("snap:hyper: entered")

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
        Hyper:exit()
      end

      return nil
    end)
  end

  function Hyper.modal:exited()
    info("snap:hyper: exited")

    hs.fnutils.ieach(obj.alerts, function(id) alert.closeSpecific(id) end)

    alert.close()
  end
end

function obj:init(opts)
  opts = opts or {}
  Hyper = load("lib.hyper", { opt = true })

  return self
end

function obj:start()
  Hyper = load("lib.hyper"):start()

  setupEvents()

  dbg(fmt("snap:start -> %s", I(Hyper)))

  Hyper:bind({}, "l", nil, function()
    warn("snap: entering hyper modal")
    dbg(fmt("hyper:bind(l): %s", I(Hyper)))
    Hyper.modal:enter()
  end)

  -- :: window-manipulation (manual window snapping)
  Hyper:bind("", "return", function() obj.maximize() end)
  Hyper:bind("", "j", function() obj.move_to_center_absolute({ w = 1440, h = 900 }) end)
  -- for _, c in pairs(Config.snap) do
  --   Hyper.modal:bind("", c.shortcut, function()
  --     P("-- should be binding here")
  --     -- require("ext.window").chain(c.locations)(string.format("shortcut: %s", c.shortcut))
  --     Hyper.modal:exit()
  --   end)
  -- end

  -- Hyper.modal
  --   :bind("", "v", function()
  --     M.windowSplitter()
  --     Hyper.modal:exit()
  --   end)
  --   :bind("ctrl", "[", function() Hyper.modal:exit() end)
  --   :bind("", "s", function()
  --     if hs.window.focusedWindow():application():name() == Config.preferred.browsers[1] then
  --       require("bindings.browser").split()
  --     end
  --     Hyper.modal:exit()
  --   end)
  --   :bind("", "escape", function() Hyper.modal:exit() end)
  --   :bind("shift", "h", function()
  --     hs.window.focusedWindow():moveOneScreenWest()
  --     Hyper.modal:exit()
  --   end)
  --   :bind("shift", "l", function()
  --     hs.window.focusedWindow():moveOneScreenEast()
  --     Hyper.modal:exit()
  --   end)
  --   :bind("", "tab", function()
  --     hs.window.focusedWindow():centerOnScreen()
  --     Hyper.modal:exit()
  --   end)

  return self
end

function obj:stop()
  Hyper:stop()
  obj.alerts = {}
  obj.snapback_window_state = {}
  return self
end

return obj
