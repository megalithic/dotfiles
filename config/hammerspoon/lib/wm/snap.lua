-- REF: https://github.com/Hammerspoon/hammerspoon/issues/154
--
-- TODO: https://github.com/nitzan-shaked/hammerspoon-config/blob/master/kbd_win.lua
-- evaluate how we can use key repeat to cycle through layout positions, or to resize a window

local alert = require("utils.alert")
local obj = hs.hotkey.modal.new({}, nil)
local Hyper

obj.__index = obj
obj.name = "snap"
obj.alerts = {}
obj.isOpen = false
obj.debug = true

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

function obj.place(title, loc, win, screen)
  if title and not title == "" then alert.show(title) end
  win = win and win or obj.win()
  screen = screen and screen or win:screen()

  if not loc then
    warn(fmt("[snap.place] no location provided for placing window %s..", win:title()))
    loc = obj.grid.maximized
  end

  return hs.layout.apply({
    { win:application(), win, screen, loc, 0, 0 },
  })
end

function obj.fullscreen(win, msg, screenAsUnit)
  msg = msg or "Fullscreen"
  obj.place(msg, obj.grid.maximized, win, screenAsUnit)
end
obj.maximize = obj.fullscreen
function obj.centerSmall(win, msg, screenAsUnit)
  msg = msg or "Center sm"
  obj.place(msg, obj.grid.centeredSmall, win, screenAsUnit)
end
function obj.centerMedium(win, msg, screenAsUnit)
  msg = msg or "Center md"
  obj.place(msg, obj.grid.centeredMedium, win, screenAsUnit)
end
function obj.centerLarge(win, msg, screenAsUnit)
  msg = msg or "Center lg"
  obj.place(msg, obj.grid.centeredLarge, win, screenAsUnit)
end
function obj.left30(win, msg, screenAsUnit)
  msg = msg or "Left 30%"
  obj.place(msg, obj.grid.left30, win, screenAsUnit)
end
function obj.left50(win, msg, screenAsUnit)
  msg = msg or "Left 50%"
  obj.place(msg, obj.grid.left50, win, screenAsUnit)
end
function obj.left75(win, msg, screenAsUnit)
  msg = msg or "Left 75%"
  obj.place(msg, obj.grid.left75, win, screenAsUnit)
end
function obj.right30(win, msg, screenAsUnit)
  msg = msg or "Right 30%"
  obj.place(msg, obj.grid.right30, win, screenAsUnit)
end
function obj.right50(win, msg, screenAsUnit)
  msg = msg or "Right 50%"
  obj.place(msg, obj.grid.right50, win, screenAsUnit)
end
function obj.right75(win, msg, screenAsUnit)
  msg = msg or "Right 75%"
  obj.place(msg, obj.grid.right75, win, screenAsUnit)
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

-- return currently focused window
function obj.win() return hs.window.focusedWindow() end

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

function obj.debug_window()
  local win = hs.window.focusedWindow()
  local app = win:application()
  local app_name = app:name()
  local win_title = win:title()
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
    "app: " .. app_name,
    "win title: " .. win_title,
    "win_id: " .. win_id,
    "frame: " .. win_frame_string,
    "screen: " .. win_screen,
    "screen frame: " .. win_screen_frame_string,
  }

  -- alert.show(fmt(" Window Debugger:\n%s", table.concat(debugLines, "\n")))
  local str = fmt(":: [%s] %s", obj.name, "\n" .. table.concat(debugLines, "\n"))
  _G.dbg(fmt(str), false)
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
  local browser = L.load("lib.browser")

  obj
    :bind(keys.mods.casc, "escape", function() obj:exit() end)
    :bind(keys.mods.casc, "return", function()
      obj.fullscreen()
      obj:exit()
    end)
    :bind(keys.mods.caSc, "return", function()
      obj.send_window_next_monitor()
      obj.fullscreen()
      obj:exit()
    end)
    :bind(keys.mods.casc, "l", function()
      obj.right50()
      obj:exit()
    end)
    :bind(keys.mods.caSc, "l", function()
      obj.send_window_next_monitor()
      obj.right50()
      obj:exit()
    end)
    :bind(keys.mods.casc, "h", function()
      obj.left50()
      obj:exit()
    end)
    :bind(keys.mods.caSc, "h", function()
      obj.send_window_prev_monitor()
      obj.left50()
      obj:exit()
    end)
    :bind(keys.mods.casc, "j", function()
      obj.centerMedium()
      obj:exit()
    end)
    :bind(keys.mods.casc, "k", function()
      obj.centerLarge()
      obj:exit()
    end)
    :bind(keys.mods.casc, "v", function()
      obj.tile()
      obj:exit()
    end)
    :bind(keys.mods.casc, "s", function()
      browser.splitTab()
      obj:exit()
    end)
    :bind(keys.mods.caSc, "s", function()
      browser.splitTab(true) -- Split tab out and send to new window
      obj:exit()
    end)
    :bind(keys.mods.casc, "i", function()
      obj.debug_window()
      obj:exit()
    end)

  return self
end

function obj:stop()
  obj:delete()
  obj.alerts = {}
  L.unload("lib.hyper", obj.name)

  return self
end

return obj
