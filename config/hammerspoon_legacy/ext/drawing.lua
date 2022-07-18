local cache  = { borderDrawings = {}, borderDrawingFadeOuts = {} }
local module = { cache = cache }

-- returns 'graphite' or 'aqua'
local getOSXAppearance = function()
  local _, res = hs.applescript.applescript([[
    tell application "System Events"
      tell appearance preferences
        return appearance as string
      end tell
    end tell
  ]])

  return res
end

-- get appearance on start
cache.osxApperance = getOSXAppearance()

module.getHighlightWindowColor = function()
  local blueColor = { red = 50 / 255, green = 138 / 255, blue = 215 / 255, alpha = 1.0 }
  local grayColor = { red = 143 / 255, green = 143 / 255, blue = 143 / 255, alpha = 1.0 }

  return cache.osxApperance == 'graphite' and grayColor or blueColor
end

module.drawBorder = function()
  local focusedWindow = hs.window.focusedWindow()

  if not focusedWindow or focusedWindow:role() ~= "AXWindow" then
    if cache.borderCanvas then
      cache.borderCanvas:hide(0.5)
    end

    return
  end

  local alpha       = 0.6
  local borderWidth = 2
  local distance    = 6
  local roundRadius = 12

  local isFullScreen = focusedWindow:isFullScreen()
  local frame        = focusedWindow:frame()

  if not cache.borderCanvas then
    cache.borderCanvas = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 })
      :level(hs.canvas.windowLevels.overlay)
      :behavior({ hs.canvas.windowBehaviors.transient, hs.canvas.windowBehaviors.moveToActiveSpace })
      :alpha(alpha)
  end

  if isFullScreen then
    cache.borderCanvas:frame(frame)
  else
    cache.borderCanvas:frame({
        x = frame.x - distance / 2,
        y = frame.y - distance / 2,
        w = frame.w + distance,
        h = frame.h + distance
      })
  end

  cache.borderCanvas[1] = {
    type             = 'rectangle',
    action           = 'stroke',
    strokeColor      = module.getHighlightWindowColor(),
    strokeWidth      = borderWidth,
    roundedRectRadii = { xRadius = roundRadius, yRadius = roundRadius }
  }

  cache.borderCanvas:show()
end

module.highlightWindow = function(win)
  if config.window.highlightBorder then
    module.drawBorder(0.5)
  end

  if config.window.highlightMouse then
    local focusedWindow = win or hs.window.focusedWindow()
    if not focusedWindow or focusedWindow:role() ~= "AXWindow" then return end

    local frameCenter = hs.geometry.getcenter(focusedWindow:frame())

    hs.mouse.setAbsolutePosition(frameCenter)
  end
end

return module
