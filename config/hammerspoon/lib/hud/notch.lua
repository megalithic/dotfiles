-- Notch HUD Container
-- A generic HUD container positioned at the notch area
--
-- This is just the container/shape - content is set by the caller.
-- Use lib.hud.elements for drawing primitives and lib.hud.animator for animations.
--
local M = {}

local animator = require("lib.hud.animator")

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

---@class NotchGeometry
---@field width number Approximate notch width in points
---@field menuBarHeight number Standard menu bar height
---@field notchDepth number How far notch extends below screen top

---@class DropGeometry
---@field topOverlap number How much the drop overlaps with notch area
---@field cornerRadius number Bottom corner radius
---@field taper number How much narrower at bottom vs top
---@field widthReduction number How much narrower than requested width

-- Notch geometry (MacBook Pro 14"/16" 2021+)
M.NOTCH = {
  width = 200,           -- Approximate notch width in points
  menuBarHeight = 24,    -- Standard menu bar height
  notchDepth = 38,       -- How far notch extends below screen top
}

-- HUD drop geometry
M.DROP = {
  topOverlap = 10,       -- How much the drop overlaps with notch area
  cornerRadius = 28,     -- Bottom corner radius
  taper = 6,             -- How much narrower at bottom vs top
  widthReduction = 40,   -- How much narrower than requested width
}

--------------------------------------------------------------------------------
-- SCREEN DETECTION
--------------------------------------------------------------------------------

---Check if a screen has a notch (MacBook Pro built-in display)
---@param screen hs.screen|nil Screen to check (default: mainScreen)
---@return boolean hasNotch True if screen has a notch
function M.hasNotch(screen)
  screen = screen or hs.screen.mainScreen()
  local frame = screen:frame()
  local fullFrame = screen:fullFrame()
  
  -- Notch displays have ~38-44pt inset vs ~24-25pt for menu bar only
  local topInset = frame.y - fullFrame.y
  local isBuiltIn = screen:name():match("Built%-in") ~= nil
  
  return topInset > 30 and isBuiltIn
end

---Get the target screen and whether to use notch style
---@return hs.screen screen Target screen
---@return boolean useNotchStyle Whether to use notch-drop style
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
  
  return hs.screen.mainScreen(), false
end

---Get notch center position on a screen
---@param screen hs.screen Screen with notch
---@return number x Center X coordinate of notch
---@return number y Top Y coordinate (screen top)
function M.getNotchCenter(screen)
  local fullFrame = screen:fullFrame()
  local centerX = fullFrame.x + fullFrame.w / 2
  return centerX, fullFrame.y
end

--------------------------------------------------------------------------------
-- DROP SHAPE RENDERING
--------------------------------------------------------------------------------

---@class CreateDropOpts
---@field width? number Requested width (default: 160)
---@field height? number Content height (default: 65)

---@class CreateDropResult
---@field canvas hs.canvas The canvas object
---@field frame table Canvas frame {x, y, w, h}
---@field useNotchStyle boolean Whether notch style is used
---@field contentWidth number Actual content area width
---@field contentHeight number Actual content area height

---Create the notch-drop canvas shape
---@param opts CreateDropOpts Options for the drop
---@return hs.canvas|nil canvas The canvas object (nil on failure)
---@return table|nil frame Canvas frame
---@return boolean|nil useNotchStyle Whether notch style is used
---@return number|nil contentWidth Actual canvas width
---@return number|nil contentHeight Actual canvas height
function M.createDrop(opts)
  opts = opts or {}
  
  local screen, useNotchStyle = M.getTargetScreen()
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
  
  -- Draw tapered shape with rounded bottom:
  -- - Top edge at full width
  -- - Sides taper inward slightly going down
  -- - Large rounded corners at bottom
  
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
  
  -- Set canvas properties
  canvas:level("overlay")
  canvas:behavior({ "canJoinAllSpaces", "stationary" })
  
  return canvas, canvasFrame, useNotchStyle, w, h
end

--------------------------------------------------------------------------------
-- HIGH-LEVEL API
--------------------------------------------------------------------------------

---@class NotchHUD
---@field canvas hs.canvas The canvas object
---@field frame table Canvas frame {x, y, w, h}
---@field timers table<string, hs.timer> Animation timers by name
---@field contentCenterX number Center X for content
---@field contentCenterY number Center Y for content
---@field useNotchStyle boolean Whether using notch style
local NotchHUD = {}
NotchHUD.__index = NotchHUD

---@class NotchHUDOpts
---@field width? number Requested width (default: 160)
---@field height? number Content height (default: 65)

---Create a new notch HUD
---@param opts? NotchHUDOpts
---@return NotchHUD|nil hud The HUD instance (nil on failure)
function M.new(opts)
  opts = opts or {}
  
  local self = setmetatable({}, NotchHUD)
  self.timers = {}
  
  -- Create the drop canvas
  local width = opts.width or 160
  local height = opts.height or 65
  
  local canvas, frame, useNotchStyle, canvasW, canvasH = M.createDrop({
    width = width,
    height = height,
  })
  
  if not canvas then
    return nil
  end
  
  self.canvas = canvas
  self.frame = frame
  self.useNotchStyle = useNotchStyle
  
  -- Calculate content center from actual canvas dimensions
  self.contentCenterX = canvasW / 2
  self.contentCenterY = canvasH / 2
  
  return self
end

---Show the HUD with slide-down animation
---@param opts? {animate?: boolean, duration?: number}
function NotchHUD:show(opts)
  opts = opts or {}
  local animate = opts.animate ~= false  -- Default true
  
  if not self.canvas then return end
  
  -- Stop any existing show/hide animation
  if self.timers.showHide then
    animator.stop(self.timers.showHide)
    self.timers.showHide = nil
  end
  
  if animate then
    -- Start hidden above the frame (behind menubar)
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

---Hide the HUD with slide-up animation
---@param opts? {animate?: boolean, duration?: number}
function NotchHUD:hide(opts)
  opts = opts or {}
  local animate = opts.animate ~= false  -- Default true
  
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

---Destroy the HUD (immediate, no animation)
function NotchHUD:destroy()
  -- Stop all timers including show/hide
  if self.timers.showHide then
    animator.stop(self.timers.showHide)
    self.timers.showHide = nil
  end
  self:stopAnimations()
  if self.canvas then
    self.canvas:delete()
    self.canvas = nil
  end
end

---Stop all animations
function NotchHUD:stopAnimations()
  for _, timer in pairs(self.timers) do
    if timer then
      pcall(function() timer:stop() end)
    end
  end
  self.timers = {}
end

---Clear all content (keeps background)
function NotchHUD:clearContent()
  self:stopAnimations()
  while self.canvas:elementCount() > 1 do
    self.canvas:removeElement(2)
  end
end

---Set content using a builder function
---@param builder fun(canvas: hs.canvas, cx: number, cy: number) Builder function
---
---Example:
---```lua
---local elements = require("lib.hud.elements")
---hud:setContent(function(canvas, cx, cy)
---  elements.circle(canvas, {x = cx, y = cy, radius = 20, color = {red = 1}})
---end)
---```
function NotchHUD:setContent(builder)
  self:clearContent()
  if builder then
    builder(self.canvas, self.contentCenterX, self.contentCenterY)
  end
end

---Add a timer/animation (will be stopped on clearContent)
---@param name string Timer name (for later reference/removal)
---@param timer hs.timer The timer to track
function NotchHUD:addTimer(name, timer)
  self.timers[name] = timer
end

---Get content center coordinates
---@return number cx Center X
---@return number cy Center Y
function NotchHUD:getCenter()
  return self.contentCenterX, self.contentCenterY
end

---Get the canvas for direct manipulation
---@return hs.canvas canvas The canvas object
function NotchHUD:getCanvas()
  return self.canvas
end

return M
