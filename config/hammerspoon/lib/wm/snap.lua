-- REF: https://github.com/Hammerspoon/hammerspoon/issues/154

local alert = require("utils.alert")

local Settings = require("hs.settings")
local Hyper

local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "snap"
obj.alerts = {}
obj.snapback_window_state = {}
obj.isOpen = false
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

obj.grid = {
  screen_edge_margins = {
    top = 0,
    left = 0,
    right = 0,
    bottom = 0,
  },
  partition_margins = {
    x = 0, -- px
    y = 0,
  },
  -- Partitions --
  split_screen_partitions = {
    x = 0.5, -- %
    y = 0.5,
  },
  quarter_screen_partitions = {
    x = 0.5, -- %
    y = 0.5,
  },
  maximized = hs.layout.maximized,
  left70 = hs.layout.left70,
  left50 = hs.layout.left50,
  left30 = hs.layout.left30,
  right70 = hs.layout.right70,
  right50 = hs.layout.right50,
  right30 = hs.layout.right30,
  centeredLarge = { x = 0.10, y = 0.10, w = 0.80, h = 0.80 },
  centeredMedium = { x = 0.25, y = 0.25, w = 0.50, h = 0.50 },
  centeredSmall = { x = 0.35, y = 0.35, w = 0.30, h = 0.30 },
}

obj.tile = function()
  local windows = hs.fnutils.map(hs.window.filter.new():getWindows(), function(win)
    if win ~= hs.window.focusedWindow() then
      return {
        text = win:title(),
        subText = win:application():title(),
        image = hs.image.imageFromAppBundle(win:application():bundleID()),
        id = win:id(),
      }
    end
  end)

  local chooser = hs.chooser.new(function(choice)
    if choice ~= nil then
      local focused = hs.window.focusedWindow()
      local toRead = hs.window.find(choice.id)
      if hs.eventtap.checkKeyboardModifiers()["shift"] then
        alert.show("  70 ◱ 30  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), obj.grid.left70, 0, 0 },
          { nil, toRead, focused:screen(), obj.grid.right30, 0, 0 },
        })
      else
        -- obj.send_window_left(focused, fmt("", focused:title()))
        -- obj.send_window_right(toRead, fmt("", toRead:title()))
        alert.show("  50 ◱ 50  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), obj.grid.left50, 0, 0 },
          { nil, toRead, focused:screen(), obj.grid.right50, 0, 0 },
        })
      end
      toRead:raise()
    end
  end)

  chooser
    :placeholderText("Choose window for 50/50 split. Hold ⇧ for 70/30.")
    :searchSubText(true)
    :choices(windows)
    :show()
end

function obj.send_window_left(win, msg, screenAsUnit)
  msg = msg or "Left"
  local s = screenAsUnit or obj.screen()
  local ssp = obj.grid.split_screen_partitions
  local g = obj.gutter()
  local geom = {
    x = s.x,
    y = s.y,
    w = (s.w * ssp.x) - g.x,
    h = s.h,
  }
  obj.set_frame(msg, geom, win)
end

function obj.send_window_right(win, msg, screenAsUnit)
  msg = msg or "Right"
  local s = screenAsUnit or obj.screen()
  local ssp = obj.grid.split_screen_partitions
  local g = obj.gutter()
  local geom = {
    x = s.x + (s.w * ssp.x) + g.x,
    y = s.y,
    w = (s.w * (1 - ssp.x)) - g.x,
    h = s.h,
  }
  obj.set_frame(msg, geom, win)
end

function obj.send_window_up()
  local s = obj.screen()
  local ssp = obj.grid.split_screen_partitions
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
  local ssp = obj.grid.split_screen_partitions
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
  local qsp = obj.grid.quarter_screen_partitions
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
  local qsp = obj.grid.quarter_screen_partitions
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
  local qsp = obj.grid.quarter_screen_partitions
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
  local qsp = obj.grid.quarter_screen_partitions
  local g = obj.gutter()
  obj.set_frame("Lower Right", {
    x = s.x + (s.w * qsp.x) + g.x,
    y = s.y + (s.h * qsp.y) + g.y,
    w = (s.w * (1 - qsp.x)) - g.x,
    h = (s.h * (1 - qsp.y)) - g.y,
  })
end

function obj.send_window_prev_monitor()
  alert.show("Prev Monitor")
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():previous()
  win:moveToScreen(nextScreen)
end

function obj.send_window_next_monitor()
  alert.show("Next Monitor")
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
  if id ~= nil then obj.snapback_window_state[id] = state end
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
function obj.move_to_center_absolute(unit, win)
  local s = obj.screen()
  return obj.set_frame("Center", {
    x = (s.w - unit.w) / 2,
    y = (s.h - unit.h) / 2,
    w = unit.w,
    h = unit.h,
  }, win)
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

-- return currently focused window
function obj.win() return hs.window.focusedWindow() end

-- display title, save state and move win to unit
function obj.set_frame(title, unit, win)
  if title and not title == "" then alert.show(title) end
  win = win and win or obj.win()
  if win then
    obj.snapback_window_state[win:id()] = win:frame()
    return win:setFrame(unit)
  end

  return {}
end

-- screen is the available rect inside the screen edge margins
function obj.screen(screen, win)
  win = win or obj.win()
  screen = screen and screen:frame() or win:screen():frame()
  local sem = obj.grid.screen_edge_margins
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
  local pm = obj.grid.partition_margins
  return {
    x = pm.x / 2,
    y = pm.y / 2,
  }
end

-- PUBLIC API to for autolayout
function obj.maximized(win, screenAsUnit) obj.set_frame("Full Screen", screenAsUnit, win) end
function obj.left50(win, screenAsUnit) obj.send_window_left(win, nil, screenAsUnit) end
function obj.right50(win, screenAsUnit) obj.send_window_right(win, nil, screenAsUnit) end
function obj.centeredLarge(win, _) obj.move_to_center_absolute({ w = 3100, h = 1600 }, win) end
function obj.centeredMedium(win, _) obj.move_to_center_absolute({ w = 2160, h = 1200 }, win) end
function obj.snapper(win, position, screen)
  local fn = obj[position]

  screen = obj.screen(screen, win)

  if fn and type(fn) == "function" then fn(win, screen) end
end

function obj:entered()
  obj.isOpen = true
  hs.window.highlight.start()

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
      obj:exit()
    end

    return nil
  end)
end

function obj:exited()
  obj.isOpen = false
  hs.window.highlight.stop()

  hs.fnutils.ieach(obj.alerts, function(id) alert.closeSpecific(id) end)

  alert.close()
end

function obj:toggle()
  if obj.isOpen then
    obj:exit()
  else
    obj:enter()
  end

  return self
end

function obj:init(opts)
  opts = opts or {}
  Hyper = L.load("lib.hyper", { id = obj.name }):start()

  hs.window.highlight.ui.overlay = true

  return self
end

function obj:start()
local config = C
  local keys = config.keys
  local browsers = config.preferred.browsers

  Hyper:bind(keys.mods.casc, "l", function() obj:toggle() end)

  obj
    :bind(keys.mods.casc, "escape", function() obj:exit() end)
    :bind({}, "return", function()
      obj.maximize()
      obj:exit()
    end)
    :bind({ "shift" }, "return", function()
      obj.send_window_next_monitor()
      obj.maximize()
      obj:exit()
    end)
    :bind(keys.mods.casc, "l", function()
      obj.send_window_right()
      obj:exit()
    end)
    :bind(keys.mods.caSc, "l", function()
      obj.send_window_next_monitor()
      obj.send_window_right()
      obj:exit()
    end)
    :bind(keys.mods.casc, "h", function()
      obj.send_window_left()
      obj:exit()
    end)
    :bind({ "shift" }, "h", function()
      obj.send_window_prev_monitor()
      obj.send_window_left()
      obj:exit()
    end)
    :bind(keys.mods.casc, "k", function()
      obj.move_to_center_absolute({ w = 3100, h = 1600 })
      obj:exit()
    end)
    :bind({ "shift" }, "k", function()
      obj.send_window_next_monitor()
      obj.move_to_center_absolute({ w = 3100, h = 1600 })
      obj:exit()
    end)
    :bind(keys.mods.casc, "j", function()
      obj.move_to_center_absolute({ w = 2160, h = 1200 })
      obj:exit()
    end)
    :bind({ "shift" }, "j", function()
      obj.send_window_next_monitor()
      obj.move_to_center_absolute({ w = 2160, h = 1200 })
      obj:exit()
    end)
    :bind(keys.mods.casc, "space", function()
      obj:snapback()
      obj:exit()
    end)
    :bind(keys.mods.casc, "v", function()
      obj.tile()
      obj:exit()
    end)
    :bind(keys.mods.casc, "s", function()
      L.load("lib.browser").splitTab()
      obj:exit()
    end)

  return self
end

function obj:stop()
  obj:delete()
  obj.alerts = {}
  obj.snapback_window_state = {}
  L.unload("lib.hyper", obj.name)

  return self
end

return obj
