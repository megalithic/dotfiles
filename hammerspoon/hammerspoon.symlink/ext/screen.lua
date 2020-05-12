local module = {}

-- grabs screen with active window, unless it's Finder's desktop
-- then we use mouse position
module.activeScreen = function()
  local activeWindow = hs.window.focusedWindow()

  if activeWindow and activeWindow:role() ~= 'AXScrollArea' then
    return activeWindow:screen()
  else
    return hs.mouse.getCurrentScreen()
  end
end

-- focus screen quitely - with mouse in corner
module.quietFocusScreen = function(screen)
  screen = screen or hs.mouse.getCurrentScreen()

  local frame         = screen:frame()
  local mousePosition = hs.mouse.getAbsolutePosition()

  -- if mouse is already on the given screen we can safely return
  if hs.geometry(mousePosition):inside(frame) then return false end

  -- "hide" cursor in the lower right side of screen
  -- it's invisible while we are changing spaces
  local newMousePosition = {
    x = frame.x + frame.w - 1,
    y = frame.y + frame.h - 1
  }

  hs.mouse.setAbsolutePosition(newMousePosition)
  hs.timer.usleep(1000)
end

-- focus screen centering mouse
module.focusScreen = function(screen)
  screen = screen or hs.mouse.getCurrentScreen()

  local frame = screen:fullFrame()

  local mousePosition = {
    x = frame.x + frame.w / 2,
    y = frame.y + frame.h / 2
  }

  -- click center of the screen to bring focus to desktop
  hs.eventtap.leftClick(mousePosition)
end

return module
