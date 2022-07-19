-- === sizeup ===
-- SizeUp emulation for hammerspoon
--
-- To use, you can tweak the key bindings and the margins
-- REF: https://github.com/Hammerspoon/hammerspoon/issues/154

local Settings = require("hs.settings")
local load = require("utils.loader").load
local Hyper = load("lib/hyper"):start()

local obj = {}
obj.modal = nil

--------------
-- Bindings --
--------------

--- Split Screen Actions ---
-- Send Window Left
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "Left", function() obj.send_window_left() end)
-- Send Window Right
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "Right", function() obj.send_window_right() end)
-- Send Window Up
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "Up", function() obj.send_window_up() end)
-- Send Window Down
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "Down", function() obj.send_window_down() end)

--- Quarter Screen Actions ---
-- Send Window Upper Left
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "Left", function() obj.send_window_upper_left() end)
-- Send Window Upper Right
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "Up", function() obj.send_window_upper_right() end)
-- Send Window Lower Left
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "Down", function() obj.send_window_lower_left() end)
-- Send Window Lower Right
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "Right", function() obj.send_window_lower_right() end)

--- Multiple Monitor Actions ---
-- Send Window Prev Monitor
hs.hotkey.bind({ "ctrl", "alt" }, "Left", function() obj.send_window_prev_monitor() end)
-- Send Window Next Monitor
hs.hotkey.bind({ "ctrl", "alt" }, "Right", function() obj.send_window_next_monitor() end)

--- Spaces Actions ---

-- Apple no longer provides any reliable API access to spaces.
-- As such, this feature no longer works in SizeUp on Yosemite and
-- Hammerspoon currently has no solution that isn't a complete hack.
-- If you have any ideas, please visit the ticket

--- Snapback Action ---
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "Z", function() obj.snapback() end)
--- Other Actions ---
-- Make Window Full Screen
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function() obj.maximize() end)
-- Send Window Center
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "J", function()
  obj.move_to_center_absolute({ w = 800, h = 600 })
  -- sizeup.move_to_center_relative({w=0.75, h=0.75})
end)

-------------------
-- Configuration --
-------------------

-- Margins --
obj.screen_edge_margins = {
  top = 0, -- px
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

----------------
-- Public API --
----------------

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

------------------
-- Internal API --
------------------

-- SizeUp uses no animations
hs.window.animation_duration = 0.0
-- Initialize Snapback state
obj.snapback_window_state = {}
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

function obj:init(opts)
  opts = opts or {}
  print(string.format("sizeup:init(opts: %s) loaded.", hs.inspect(opts)))

  return self
end

function obj:start()
  print(string.format("sizeup:start() executed."))
  -- local hyper = Settings.get("_mega_config").keys.hyper

  return self
end

function obj:stop()
  print(string.format("sizeup:stop() executed."))
  obj.hyperBind.delete()
  obj.modal.delete()
  return self
end
