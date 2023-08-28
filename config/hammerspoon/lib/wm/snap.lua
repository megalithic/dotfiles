-- REF:
-- https://github.com/Hammerspoon/hammerspoon/issues/154
-- https://github.com/peterklijn/hammerspoon-shiftit/blob/master/init.lua
-- https://github.com/kevindiu/m1_config/blob/main/.hammerspoon/resizeWindow.lua
--
-- TODO: https://github.com/nitzan-shaked/hammerspoon-config/blob/master/kbd_win.lua
-- evaluate how we can use key repeat to cycle through layout positions, or to resize a window

local alert = require("utils.alert")
local obj = hs.hotkey.modal.new({}, nil)
local delayedExitTimer = nil
local Hyper

obj.__index = obj
obj.name = "snap"
obj.alerts = {}
obj.isOpen = false
obj.debug = false

local dbg = function(str, ...)
  if type(str) == "string" then
    str = fmt(":: [%s] %s", obj.name, str)
  else
    str = fmt(":: [%s] %s", obj.name, I(str))
  end

  if obj.debug then
    if ... == nil then
      return _G.dbg(str, false)
    else
      return _G.dbg(fmt(str, ...), false)
    end
  end
end

obj.grid = {
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

local latestMove = {
  windowId = -1,
  direction = "unknown",
  stepX = -1,
  stepY = -1,
}

-- WARN: deprecated
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

-- Thieved. Big up to peterklijn.
-- REF: https://github.com/peterklijn/hammerspoon-shiftit/blob/master/init.lua
function obj:move(unit) hs.window.focusedWindow():move(unit, nil, true, 0) end
function obj:resizeOut() self:resizeWindowInSteps(true) end
function obj:resizeIn() self:resizeWindowInSteps(false) end
function obj:resizeWindowInSteps(increment)
  local screen = hs.window.focusedWindow():screen():frame()
  local window = hs.window.focusedWindow():frame()
  local wStep = math.floor(screen.w / 12)
  local hStep = math.floor(screen.h / 12)
  local x, y, w, h = window.x, window.y, window.w, window.h

  if increment then
    local xu = math.max(screen.x, x - wStep)
    w = w + (x - xu)
    x = xu
    local yu = math.max(screen.y, y - hStep)
    h = h + (y - yu)
    y = yu
    w = math.min(screen.w - x + screen.x, w + wStep)
    h = math.min(screen.h - y + screen.y, h + hStep)
  else
    local noChange = true
    local notMinWidth = w > wStep * 3
    local notMinHeight = h > hStep * 3

    local snapLeft = x <= screen.x
    local snapTop = y <= screen.y
    -- add one pixel in case of odd number of pixels
    local snapRight = (x + w + 1) >= (screen.x + screen.w)
    local snapBottom = (y + h + 1) >= (screen.y + screen.h)

    local b2n = { [true] = 1, [false] = 0 }
    local totalSnaps = b2n[snapLeft] + b2n[snapRight] + b2n[snapTop] + b2n[snapBottom]

    if notMinWidth and (totalSnaps <= 1 or not snapLeft) then
      x = x + wStep
      w = w - wStep
      noChange = false
    end
    if notMinHeight and (totalSnaps <= 1 or not snapTop) then
      y = y + hStep
      h = h - hStep
      noChange = false
    end
    if notMinWidth and (totalSnaps <= 1 or not snapRight) then
      w = w - wStep
      noChange = false
    end
    if notMinHeight and (totalSnaps <= 1 or not snapBottom) then
      h = h - hStep
      noChange = false
    end
    if noChange then
      x = notMinWidth and x + wStep or x
      y = notMinHeight and y + hStep or y
      w = notMinWidth and w - wStep * 2 or w
      h = notMinHeight and h - hStep * 2 or h
    end
  end
  self:move({ x = x, y = y, w = w, h = h })
end

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
      local alt = hs.window.find(choice.id)
      if hs.eventtap.checkKeyboardModifiers()["shift"] then
        alert.show("  70 󱪳 30  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), obj.grid.left70, 0, 0 },
          { nil, alt, focused:screen(), obj.grid.right30, 0, 0 },
        })
      else
        alert.show("  50 󱪳 50  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), obj.grid.left50, 0, 0 },
          { nil, alt, focused:screen(), obj.grid.right50, 0, 0 },
        })
      end
      alt:raise()
    end
  end)

  chooser
    :placeholderText("Choose window for 50/50 split. Hold ⇧ for 70/30.")
    :searchSubText(true)
    :choices(windows)
    :show()
end

-- TODO: or do we use something more simple:
--https://github.com/kevindiu/m1_config/blob/main/.hammerspoon/resizeWindow.lua
function obj.place(title, loc, win, screen)
  if title and not title == "" then alert.show(title) end
  win = win or obj.win()
  screen = screen or win:screen()

  if not loc then
    warn(fmt("[snap.place] no location provided for placing window %s..", win:title()))
    loc = obj.grid.maximized
  end

  return hs.layout.apply({
    { win:application(), win, screen, loc, 0, 0 },
  })
end

function obj.fullscreen(win, msg, screenAsUnit) obj.place(msg, obj.grid.maximized, win, screenAsUnit) end
obj.maximize = obj.fullscreen
function obj.centerSmall(win, msg, screenAsUnit) obj.place(msg, obj.grid.centeredSmall, win, screenAsUnit) end
function obj.centerMedium(win, msg, screenAsUnit) obj.place(msg, obj.grid.centeredMedium, win, screenAsUnit) end
function obj.centerLarge(win, msg, screenAsUnit) obj.place(msg, obj.grid.centeredLarge, win, screenAsUnit) end
function obj.left30(win, msg, screenAsUnit) obj.place(msg, obj.grid.left30, win, screenAsUnit) end
function obj.left50(win, msg, screenAsUnit) obj.place(msg, obj.grid.left50, win, screenAsUnit) end
function obj.left75(win, msg, screenAsUnit) obj.place(msg, obj.grid.left75, win, screenAsUnit) end
function obj.right30(win, msg, screenAsUnit) obj.place(msg, obj.grid.right30, win, screenAsUnit) end
function obj.right50(win, msg, screenAsUnit) obj.place(msg, obj.grid.right50, win, screenAsUnit) end
function obj.right75(win, msg, screenAsUnit) obj.place(msg, obj.grid.right75, win, screenAsUnit) end

-- WARN: deprecated
function obj.send_window_prev_monitor()
  local nextScreen = obj.win():screen():previous()
  obj.win():moveToScreen(nextScreen)
end

-- WARN: deprecated
function obj.send_window_next_monitor()
  local nextScreen = obj.win():screen():next()
  obj.win():moveToScreen(nextScreen)
end

function obj.toPrevScreen()
  local prev = obj.win():screen():previous()
  obj.win():moveToScreen(prev)
end

function obj.toNextScreen()
  local next = obj.win():screen():next()
  obj.win():moveToScreen(next)
end

-- return currently focused window
function obj.win() return hs.window.focusedWindow() end

function obj:toggle()
  if obj.isOpen then
    obj:exit()
  else
    obj:enter()
  end

  return self
end

function obj.debug_window()
  local win = obj.win()
  local app = win:application()
  local win_fullscreened = win:isFullScreen()
  local win_id = win:id()
  local win_frame = win:frame()
  local win_frame_string = "x: "
    .. win_frame.x
    .. " y: "
    .. win_frame.y
    .. " w: "
    .. win_frame.w
    .. " h: "
    .. win_frame.h
  local win_screen = win:screen():name()
  local win_screen_frame = win:screen():frame()
  local win_screen_frame_string = "x: "
    .. win_screen_frame.x
    .. " y: "
    .. win_screen_frame.y
    .. " w: "
    .. win_screen_frame.w
    .. " h: "
    .. win_screen_frame.h
  local debugLines = {
    "app name: " .. app:name(),
    "app bundleID: " .. app:bundleID(),
    "win title: " .. win:title(),
    "win id: " .. win_id,
    "frame: " .. win_frame_string,
    "screen: " .. win_screen,
    "screen frame: " .. win_screen_frame_string,
    "fullscreened? " .. I(win_fullscreened),
  }

  -- alert.show(fmt(" Window Debugger:\n%s", table.concat(debugLines, "\n")))
  local str = fmt(":: [%s] %s", obj.name, "\n" .. table.concat(debugLines, "\n"))
  _G.dbg(fmt(str), false)
end

function obj.delayedExit(delay)
  delay = delay or 1

  if delayedExitTimer ~= nil then
    delayedExitTimer:stop()
    delayedExitTimer = nil
  end

  delayedExitTimer = hs.timer.doAfter(delay, function()
    dbg("delaying exit..")
    obj:exit()
    delayedExitTimer = nil
  end)
end

-- function obj.selectWindow(index)
--   local app = obj.win():application()
--   local mainWindow = app:mainWindow()
--
--   local foundWin = mainWindow:otherWindowsAllScreens()[index]
--
--   if index < 1 or not foundWin then
--     warn(fmt("window not found for index %d", index))
--     return
--   end
--
--   app:getWindow(foundWin:title()):focus()
-- end

function obj:entered()
  obj.isOpen = true
  hs.window.highlight.start()

  obj.alerts = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    local win = hs.window.focusedWindow()

    if win ~= nil then
      if screen == hs.screen.mainScreen() then
        local app_title = win:application():title()
        local image = hs.image.imageFromAppBundle(win:application():bundleID())
        local prompt = fmt("◱ : %s", app_title)
        if image ~= nil then prompt = fmt(": %s", app_title) end
        alert.showOnly({ text = prompt, image = image, screen = screen })
        obj.delayedExit(1)
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
  dbg("exited modal")
end

function obj:init(opts)
  opts = opts or {}
  Hyper = L.load("lib.hyper", { id = obj.name }):start()

  hs.window.animationDuration = 0
  hs.window.highlight.ui.overlay = true

  return self
end

function obj:start()
  local keys = C.keys
  Hyper:bind(keys.mods.casc, "l", function() obj:toggle() end)

  obj
    :bind(keys.mods.casc, "escape", function() obj:exit() end)
    :bind(keys.mods.casc, "return", function() obj.fullscreen() end, function() obj.delayedExit(0.1) end)
    :bind(keys.mods.caSc, "return", function()
      obj.toNextScreen()
      obj.fullscreen()
    end, function() obj:exit() end)
    :bind(keys.mods.casc, "l", function() obj.right50() end, function() obj.delayedExit(0.1) end)
    :bind(keys.mods.caSc, "l", function()
      obj.toNextScreen()
      obj.right50()
    end, function() obj:exit() end)
    :bind(keys.mods.casc, "h", function() obj.left50() end, function() obj.delayedExit(0.1) end)
    :bind(keys.mods.caSc, "h", function()
      obj.toNextScreen()
      obj.left50()
    end, function() obj:exit() end)
    :bind(keys.mods.casc, "j", function() obj.toNextScreen() end, function() obj.delayedExit(0.1) end)
    :bind(keys.mods.casc, "k", function() obj.centerLarge() end, function() obj.delayedExit(0.1) end)
    :bind(keys.mods.casc, "v", function()
      obj.tile()
      obj:exit()
    end)
    :bind(keys.mods.casc, "s", function()
      local browser = L.load("lib.browser")
      browser.splitTab()
      obj:exit()
    end)
    :bind(keys.mods.caSc, "s", function()
      local browser = L.load("lib.browser")
      browser.splitTab(true) -- Split tab out and send to new window
      obj:exit()
    end)
    :bind(keys.mods.casc, "i", function()
      obj.debug_window()
      obj:exit()
    end)
    :bind(keys.mods.casc, "d", function()
      obj.debug_window()
      obj:exit()
    end)
    :bind(keys.mods.casc, "f", function()
      local focused = hs.window.focusedWindow()
      hs.fnutils.map(focused:otherWindowsAllScreens(), function(win) win:application():hide() end)
      obj:exit()
    end)
    :bind(keys.mods.casc, "left", function()
      obj:resizeIn()
      obj.delayedExit()
    end, function() obj.delayedExit() end, function() obj:resizeIn() end)
    :bind(keys.mods.casc, "right", function()
      obj:resizeOut()
      obj.delayedExit()
    end, function() obj.delayedExit() end, function() obj:resizeOut() end)

  return self
end

function obj:stop()
  obj:delete()
  obj.alerts = {}
  L.unload("lib.hyper", obj.name)

  return self
end

return obj
