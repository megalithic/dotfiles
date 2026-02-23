local M = {}
local animator = require("lib.hud.animator")

---@class NotchGeometry
---@field width number
---@field menuBarHeight number
---@field notchDepth number

---@class DropGeometry
---@field topOverlap number
---@field cornerRadius number
---@field taper number
---@field widthReduction number

M.NOTCH = {
  width = 200,
  menuBarHeight = 24,
  notchDepth = 38,
}

M.DROP = {
  topOverlap = 10,
  cornerRadius = 28,
  taper = 6,
  widthReduction = 40,
}

---@param screen hs.screen?
---@return boolean
function M.hasNotch(screen)
  screen = screen or hs.screen.mainScreen()
  local frame = screen:frame()
  local fullFrame = screen:fullFrame()
  
  -- Notch displays have ~38-44pt inset vs ~24-25pt for menu bar only
  local topInset = frame.y - fullFrame.y
  local isBuiltIn = screen:name():match("Built%-in") ~= nil
  
  return topInset > 30 and isBuiltIn
end

---@return hs.screen, boolean
function M.getTargetScreen()
  local screens = hs.screen.allScreens()
  
  local builtIn = hs.fnutils.find(screens, function(s)
    return s:name():match("Built%-in") ~= nil
  end)
  
  local external = hs.fnutils.find(screens, function(s)
    return s:name():match("Built%-in") == nil
  end)
  
  if external then
    -- External connected: show there (standard position, no notch style)
    return external, false
  elseif builtIn then
    -- Internal only: show with notch style
    return builtIn, true
  end
  
  -- Fallback - mainScreen() can return nil during screen transitions
  local main = hs.screen.mainScreen()
  return main, false
end

---@param screen hs.screen
---@return number, number
function M.getNotchCenter(screen)
  local fullFrame = screen:fullFrame()
  return fullFrame.x + fullFrame.w / 2, fullFrame.y
end

---@class CreateDropOpts
---@field width? number
---@field height? number

---@param opts? CreateDropOpts
---@return hs.canvas?, table?, boolean?, number?, number?
function M.createDrop(opts)
  opts = opts or {}
  
  local screen, useNotchStyle = M.getTargetScreen()
  if not screen then
    -- Screen not available (can happen during screen transitions)
    return nil
  end
  local fullFrame = screen:fullFrame()
  local frame = screen:frame()
  
  -- Calculate dimensions using constants
  local requestedWidth = opts.width or 160
  local contentHeight = opts.height or 65
  local r = M.DROP.cornerRadius
  local taper = M.DROP.taper
  local k = 0.552  -- Bezier constant for circular arc approximation
  
  -- Actual canvas dimensions
  local w = requestedWidth - M.DROP.widthReduction
  local h = contentHeight + M.DROP.topOverlap
  
  -- Position: centered below notch (or top-center for non-notch)
  local centerX = fullFrame.x + fullFrame.w / 2
  local topY
  
  if useNotchStyle then
    -- Start from top of screen, overlapping with notch area
    topY = fullFrame.y
  else
    -- Non-notch: start below menu bar
    topY = frame.y
  end
  
  local canvasFrame = {
    x = centerX - w / 2,
    y = topY,
    w = w,
    h = h,
  }
  
  local canvas = hs.canvas.new(canvasFrame)
  if not canvas then return nil end
  
  canvas:appendElements({
    id = "background",
    type = "segments",
    action = "fill",
    fillColor = { red = 4/255, green = 9/255, blue = 15/255, alpha = 1 },  -- #04090f menubar color
    closed = true,
    coordinates = {
      -- Top left corner
      { x = 0, y = 0 },
      -- Top edge to top right
      { x = w, y = 0 },
      -- Right side tapers inward to bottom corner
      { x = w - taper, y = h - r },
      -- Bottom right rounded curve
      { x = w - taper - r, y = h,
        c1x = w - taper, c1y = h - r + r * k,
        c2x = w - taper - r + r * k, c2y = h },
      -- Bottom edge
      { x = taper + r, y = h },
      -- Bottom left rounded curve
      { x = taper, y = h - r,
        c1x = taper + r - r * k, c1y = h,
        c2x = taper, c2y = h - r + r * k },
      -- Left side tapers outward going up
      { x = 0, y = 0 },
    },
  })
  
  canvas:level("overlay")
  canvas:behavior({ "canJoinAllSpaces", "stationary" })
  
  return canvas, canvasFrame, useNotchStyle, w, h
end

---@class NotchHUD
---@field canvas hs.canvas
---@field frame table
---@field timers table<string, hs.timer>
---@field contentCenterX number
---@field contentCenterY number
---@field useNotchStyle boolean
local NotchHUD = {}
NotchHUD.__index = NotchHUD

---@class NotchHUDOpts
---@field width? number
---@field height? number

---@param opts? NotchHUDOpts
---@return NotchHUD?
function M.new(opts)
  opts = opts or {}
  
  local self = setmetatable({}, NotchHUD)
  self.timers = {}
  
  -- Store requested dimensions for repositioning
  self.requestedWidth = opts.width or 160
  self.requestedHeight = opts.height or 65
  
  -- Create the drop canvas
  local canvas, frame, useNotchStyle, canvasW, canvasH = M.createDrop({
    width = self.requestedWidth,
    height = self.requestedHeight,
  })
  
  if not canvas then
    return nil
  end
  
  self.canvas = canvas
  self.frame = frame
  self.useNotchStyle = useNotchStyle
  
  self.contentCenterX = canvasW / 2
  self.contentCenterY = canvasH / 2
  
  return self
end

---@param opts? {animate?: boolean, duration?: number}
function NotchHUD:show(opts)
  opts = opts or {}
  local animate = opts.animate ~= false
  
  if not self.canvas then return end
  
  if self.timers.showHide then
    animator.stop(self.timers.showHide)
    self.timers.showHide = nil
  end
  
  if animate then
    local finalY = self.frame.y
    local startY = finalY - self.frame.h - 10
    self.timers.showHide = animator.slideDown(self.canvas, startY, finalY, {
      duration = opts.duration or 350,
      onComplete = function()
        self.timers.showHide = nil
      end,
    })
  else
    self.canvas:show()
  end
end

---@param opts? {animate?: boolean, duration?: number}
function NotchHUD:hide(opts)
  opts = opts or {}
  local animate = opts.animate ~= false
  self:stopAnimations()
  if not self.canvas then return end
  
  if animate then
    self.timers.showHide = animator.slideUp(self.canvas, {
      duration = opts.duration or 250,
      hideAfter = true,
      onComplete = function()
        self.timers.showHide = nil
      end,
    })
  else
    self.canvas:hide()
  end
end

function NotchHUD:destroy()
  self:stopAnimations()
  if self.canvas then
    self.canvas:delete()
    self.canvas = nil
  end
end

function NotchHUD:stopAnimations()
  for _, timer in pairs(self.timers) do
    if timer then
      pcall(function() timer:stop() end)
    end
  end
  self.timers = {}
end

function NotchHUD:clearContent()
  self:stopAnimations()
  while self.canvas and self.canvas:elementCount() > 1 do
    self.canvas:removeElement(2)
  end
end

---@param builder fun(canvas: hs.canvas, cx: number, cy: number)
function NotchHUD:setContent(builder)
  self:clearContent()
  if builder then
    builder(self.canvas, self.contentCenterX, self.contentCenterY)
  end
end

---@param name string
---@param timer hs.timer
function NotchHUD:addTimer(name, timer)
  self.timers[name] = timer
end

---@return number, number
function NotchHUD:getCenter()
  return self.contentCenterX, self.contentCenterY
end

---@return hs.canvas
function NotchHUD:getCanvas()
  return self.canvas
end

---Reposition the notch when screen configuration changes
function NotchHUD:reposition()
  if not self.canvas then return end
  
  -- Get current visibility state
  local wasVisible = self.canvas:isShowing()
  
  -- Store current content elements (skip background at index 1)
  local contentElements = {}
  local elementCount = self.canvas:elementCount()
  for i = 2, elementCount do
    table.insert(contentElements, self.canvas[i])
  end
  
  -- Recreate canvas for new screen configuration
  local canvas, frame, useNotchStyle, canvasW, canvasH = M.createDrop({
    width = self.requestedWidth,
    height = self.requestedHeight,
  })
  
  if not canvas then return end
  
  -- Destroy old canvas
  self.canvas:delete()
  
  -- Update with new canvas
  self.canvas = canvas
  self.frame = frame
  self.useNotchStyle = useNotchStyle
  self.contentCenterX = canvasW / 2
  self.contentCenterY = canvasH / 2
  
  -- Restore content elements
  for _, element in ipairs(contentElements) do
    self.canvas:insertElement(element)
  end
  
  -- Restore visibility
  if wasVisible then
    self.canvas:show()
  end
end

return M
