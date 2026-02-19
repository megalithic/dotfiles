-- Notch HUD Renderer
-- Creates a HUD that "drops" from the MacBook notch
--
-- Design: Black background blends with notch, rounded bottom corners
-- Content area appears to extend from the notch downward
--
local M = {}

local theme = require("lib.hud.theme")
local animator = require("lib.hud.animator")

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

-- Notch geometry (MacBook Pro 14"/16" 2021+)
M.NOTCH = {
  width = 200,           -- Approximate notch width in points
  menuBarHeight = 24,    -- Standard menu bar height
  notchDepth = 38,       -- How far notch extends below screen top (44pt inset - some margin)
  cornerRadius = 10,     -- Bottom corner radius to match notch aesthetic
}

-- HUD drop geometry
M.DROP = {
  minWidth = 120,        -- Minimum drop width
  maxWidth = 300,        -- Maximum drop width
  padding = 16,          -- Content padding
  cornerRadius = 16,     -- Bottom corners of the drop
  topOverlap = 10,       -- How much the drop overlaps with notch area (seamless blend)
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

---Create the notch-drop canvas shape
---@param opts NotchDropOpts Options for the drop
---@return hs.canvas canvas The canvas object
function M.createDrop(opts)
  opts = opts or {}
  
  local screen, useNotchStyle = M.getTargetScreen()
  local fullFrame = screen:fullFrame()
  local frame = screen:frame()
  
  -- Calculate dimensions
  local dropWidth = opts.width or M.DROP.minWidth
  local dropHeight = opts.height or 80
  local cornerRadius = M.DROP.cornerRadius
  
  -- Position: centered below notch (or top-center for non-notch)
  local centerX = fullFrame.x + fullFrame.w / 2
  local topY = fullFrame.y
  
  if useNotchStyle then
    -- Start from top of screen, overlapping with notch area
    topY = fullFrame.y
  else
    -- Non-notch: start below menu bar
    topY = frame.y
  end
  
  -- Canvas frame
  local canvasFrame = {
    x = centerX - dropWidth / 2,
    y = topY,
    w = dropWidth,
    h = dropHeight + M.DROP.topOverlap,
  }
  
  local canvas = hs.canvas.new(canvasFrame)
  if not canvas then return nil end
  
  -- Build the drop shape: rounded rect + square rect on top
  -- This gives us rounded bottom corners only
  local w, h = dropWidth, dropHeight + M.DROP.topOverlap
  local r = cornerRadius
  
  -- Full rounded rect (all corners)
  canvas:appendElements({
    id = "background_rounded",
    type = "rectangle",
    action = "fill",
    fillColor = { black = 0, alpha = 1 },  -- Pure black to match notch
    roundedRectRadii = { xRadius = r, yRadius = r },
    frame = { x = 0, y = 0, w = w, h = h },
  })
  
  -- Square rect on top to cover rounded top corners
  canvas:appendElements({
    id = "background_top",
    type = "rectangle",
    action = "fill",
    fillColor = { black = 0, alpha = 1 },
    frame = { x = 0, y = 0, w = w, h = r + 2 },  -- Slightly overlap to ensure no gap
  })
  
  -- Set canvas properties
  canvas:level("overlay")
  canvas:behavior({ "canJoinAllSpaces", "stationary" })
  
  return canvas, canvasFrame, useNotchStyle
end

--------------------------------------------------------------------------------
-- CONTENT ELEMENTS
--------------------------------------------------------------------------------

---Add a centered circle (for recording indicator)
---@param canvas hs.canvas Canvas to add to
---@param opts {x: number, y: number, radius: number, color: table}
function M.addCircle(canvas, opts)
  canvas:appendElements({
    id = opts.id or "circle",
    type = "circle",
    action = "fill",
    fillColor = opts.color or { red = 1, green = 0.23, blue = 0.19, alpha = 1 },  -- #FF3B30
    center = { x = opts.x, y = opts.y },
    radius = opts.radius or 20,
  })
end

---Add waveform bars (animated equalizer style)
---@param canvas hs.canvas Canvas to add to
---@param opts {x: number, y: number, barCount: number, barWidth: number, maxHeight: number, spacing: number, color: table}
function M.addWaveformBars(canvas, opts)
  local barCount = opts.barCount or 5
  local barWidth = opts.barWidth or 4
  local maxHeight = opts.maxHeight or 20
  local spacing = opts.spacing or 3
  local totalWidth = barCount * barWidth + (barCount - 1) * spacing
  local startX = opts.x - totalWidth / 2
  
  for i = 1, barCount do
    local barX = startX + (i - 1) * (barWidth + spacing)
    -- Initial height (will be animated)
    local barHeight = maxHeight * 0.3
    
    canvas:appendElements({
      id = "waveform_bar_" .. i,
      type = "rectangle",
      action = "fill",
      fillColor = opts.color or { white = 1, alpha = 1 },
      roundedRectRadii = { xRadius = barWidth / 2, yRadius = barWidth / 2 },
      frame = {
        x = barX,
        y = opts.y - barHeight / 2,
        w = barWidth,
        h = barHeight,
      },
    })
  end
end

---Add text label
---@param canvas hs.canvas Canvas to add to
---@param opts {x: number, y: number, text: string, color: table, fontSize: number}
function M.addText(canvas, opts)
  canvas:appendElements({
    id = opts.id or "text",
    type = "text",
    text = opts.text,
    textColor = opts.color or { white = 1, alpha = 0.8 },
    textFont = ".AppleSystemUIFont",
    textSize = opts.fontSize or 12,
    textAlignment = "center",
    frame = {
      x = 0,
      y = opts.y,
      w = "100%",
      h = opts.fontSize or 12 + 4,
    },
  })
end

---Add SF Symbol icon
---@param canvas hs.canvas Canvas to add to
---@param opts {x: number, y: number, size: number, symbol: string, color: string}
function M.addSFSymbol(canvas, opts)
  local sfsymbol = require("lib.hud.sfsymbol")
  local size = opts.size or 32
  local symbol = opts.symbol or "checkmark"
  local color = opts.color or "34C759"  -- Green
  
  local image = sfsymbol.image(symbol, { size = size, color = color })
  if not image then return end
  
  canvas:appendElements({
    id = opts.id or "symbol",
    type = "image",
    image = image,
    imageAlignment = "center",
    imageScaling = "none",
    frame = {
      x = opts.x - size / 2,
      y = opts.y - size / 2,
      w = size,
      h = size,
    },
  })
end

--------------------------------------------------------------------------------
-- ANIMATION HELPERS
--------------------------------------------------------------------------------

---Animate waveform bars with random heights
---@param canvas hs.canvas Canvas containing waveform bars
---@param opts {barCount: number, maxHeight: number, baseY: number, interval: number}
---@return hs.timer Timer for the animation (caller should store to stop)
function M.animateWaveform(canvas, opts)
  local barCount = opts.barCount or 5
  local maxHeight = opts.maxHeight or 20
  local baseY = opts.baseY
  local barWidth = opts.barWidth or 4
  
  return hs.timer.doEvery(opts.interval or 0.05, function()
    for i = 1, barCount do
      local elementId = "waveform_bar_" .. i
      -- Random height between 30% and 100%
      local newHeight = maxHeight * (0.3 + math.random() * 0.7)
      
      local element = canvas[elementId]
      if element then
        canvas[elementId].frame = {
          x = element.frame.x,
          y = baseY - newHeight / 2,
          w = barWidth,
          h = newHeight,
        }
      end
    end
  end)
end

---Pulse a circle element
---@param canvas hs.canvas Canvas containing the circle
---@param opts {elementId: string, baseRadius: number, pulseAmount: number, interval: number, center: {x: number, y: number}}
---@return hs.timer Timer for the animation
function M.pulseCircle(canvas, opts)
  local baseRadius = opts.baseRadius or 20
  local pulseAmount = opts.pulseAmount or 5
  local phase = 0
  
  return hs.timer.doEvery(opts.interval or 0.033, function()  -- ~30fps
    phase = phase + 0.15
    local pulse = math.sin(phase) * pulseAmount
    local newRadius = baseRadius + pulse
    
    canvas[opts.elementId].radius = newRadius
  end)
end

--------------------------------------------------------------------------------
-- HIGH-LEVEL API
--------------------------------------------------------------------------------

---@class NotchHUD
---@field canvas hs.canvas The canvas object
---@field timers table Animation timers
---@field state string Current state
local NotchHUD = {}
NotchHUD.__index = NotchHUD

---Create a new notch HUD
---@param opts {width?: number, height?: number}
---@return NotchHUD
function M.new(opts)
  opts = opts or {}
  
  local self = setmetatable({}, NotchHUD)
  self.timers = {}
  self.state = "idle"
  self.opts = opts
  
  -- Create the drop canvas
  local width = opts.width or 160
  local height = opts.height or 100
  
  self.canvas, self.frame, self.useNotchStyle = M.createDrop({
    width = width,
    height = height,
  })
  
  if not self.canvas then
    return nil
  end
  
  -- Calculate content center
  self.contentCenterX = width / 2
  self.contentCenterY = M.DROP.topOverlap + (height - M.DROP.topOverlap) / 2
  
  return self
end

---Show the HUD
function NotchHUD:show()
  if self.canvas then
    self.canvas:show()
  end
end

---Hide the HUD
function NotchHUD:hide()
  self:stopAnimations()
  if self.canvas then
    self.canvas:hide()
  end
end

---Destroy the HUD
function NotchHUD:destroy()
  self:stopAnimations()
  if self.canvas then
    self.canvas:delete()
    self.canvas = nil
  end
end

---Stop all animations
function NotchHUD:stopAnimations()
  for name, timer in pairs(self.timers) do
    if timer then
      timer:stop()
    end
  end
  self.timers = {}
end

---Set state to "recording" (red pulsing circle with waveform)
function NotchHUD:setRecording()
  self:stopAnimations()
  self.state = "recording"
  
  -- Clear existing elements except background
  while self.canvas:elementCount() > 2 do
    self.canvas:removeElement(3)
  end
  
  local cx, cy = self.contentCenterX, self.contentCenterY - 10
  
  -- Add pulsing red circle
  M.addCircle(self.canvas, {
    id = "indicator",
    x = cx,
    y = cy,
    radius = 24,
    color = { red = 1, green = 0.23, blue = 0.19, alpha = 1 },
  })
  
  -- Add waveform inside circle
  M.addWaveformBars(self.canvas, {
    x = cx,
    y = cy,
    barCount = 5,
    barWidth = 3,
    maxHeight = 16,
    spacing = 2,
    color = { white = 1, alpha = 1 },
  })
  
  -- Add label
  M.addText(self.canvas, {
    y = self.contentCenterY + 25,
    text = "Recording...",
    fontSize = 11,
  })
  
  -- Start animations
  self.timers.pulse = M.pulseCircle(self.canvas, {
    elementId = "indicator",
    baseRadius = 24,
    pulseAmount = 4,
    center = { x = cx, y = cy },
  })
  
  self.timers.waveform = M.animateWaveform(self.canvas, {
    barCount = 5,
    maxHeight = 16,
    baseY = cy,
    barWidth = 3,
  })
end

---Set state to "processing" (black circle with orange waveform)
function NotchHUD:setProcessing()
  self:stopAnimations()
  self.state = "processing"
  
  -- Clear existing elements except background
  while self.canvas:elementCount() > 2 do
    self.canvas:removeElement(3)
  end
  
  local cx, cy = self.contentCenterX, self.contentCenterY - 10
  
  -- Add black circle
  M.addCircle(self.canvas, {
    id = "indicator",
    x = cx,
    y = cy,
    radius = 24,
    color = { black = 0, alpha = 1 },
  })
  
  -- Add orange waveform
  M.addWaveformBars(self.canvas, {
    x = cx,
    y = cy,
    barCount = 5,
    barWidth = 3,
    maxHeight = 16,
    spacing = 2,
    color = { red = 1, green = 0.58, blue = 0, alpha = 1 },  -- #FF9500
  })
  
  -- Add label
  M.addText(self.canvas, {
    y = self.contentCenterY + 25,
    text = "Transcribing...",
    fontSize = 11,
  })
  
  -- Animate waveform (slower, more "processing" feel)
  self.timers.waveform = M.animateWaveform(self.canvas, {
    barCount = 5,
    maxHeight = 16,
    baseY = cy,
    barWidth = 3,
    interval = 0.08,
  })
end

---Set state to "complete" (green checkmark)
function NotchHUD:setComplete()
  self:stopAnimations()
  self.state = "complete"
  
  -- Clear existing elements except background (2 elements now: rounded + top rect)
  while self.canvas:elementCount() > 2 do
    self.canvas:removeElement(3)
  end
  
  local cx, cy = self.contentCenterX, self.contentCenterY - 10
  
  -- Add green checkmark SF Symbol
  M.addSFSymbol(self.canvas, {
    x = cx,
    y = cy,
    size = 36,
    symbol = "checkmark.circle.fill",
    color = "34C759",
  })
  
  -- Add label
  M.addText(self.canvas, {
    y = self.contentCenterY + 25,
    text = "⌘V paste · ESC dismiss",
    fontSize = 10,
    color = { white = 1, alpha = 0.6 },
  })
end

---Set state to "ptt" (push-to-talk active - simple red indicator)
function NotchHUD:setPTT()
  self:stopAnimations()
  self.state = "ptt"
  
  -- Clear existing elements except background
  while self.canvas:elementCount() > 2 do
    self.canvas:removeElement(3)
  end
  
  local cx, cy = self.contentCenterX, self.contentCenterY - 5
  
  -- Add pulsing red circle (smaller, no waveform)
  M.addCircle(self.canvas, {
    id = "indicator",
    x = cx,
    y = cy,
    radius = 16,
    color = { red = 1, green = 0.23, blue = 0.19, alpha = 1 },
  })
  
  -- Add label
  M.addText(self.canvas, {
    y = self.contentCenterY + 20,
    text = "Mic Active",
    fontSize = 11,
  })
  
  -- Start pulse animation
  self.timers.pulse = M.pulseCircle(self.canvas, {
    elementId = "indicator",
    baseRadius = 16,
    pulseAmount = 3,
    center = { x = cx, y = cy },
  })
end

return M
