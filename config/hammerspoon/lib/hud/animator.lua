-- HUD Animator Module
-- Animation primitives for slide, fade, and combined effects
--
-- Time units:
--   - Duration parameters are in MILLISECONDS for precision
--   - Convert to seconds internally for hs.timer
--
-- All animation functions return timer references for cleanup.
-- Timers self-clear their predicates when complete.
--

---@alias EasingFunction fun(t: number): number

---@class AnimationOpts
---@field duration? number Duration in milliseconds
---@field easing? EasingFunction Easing function
---@field onComplete? function Callback when animation completes

---@class HudAnimatorModule
---@field DEFAULTS table Default animation durations
---@field easeOutCubic EasingFunction Ease out cubic
---@field easeInOutCubic EasingFunction Ease in/out cubic
---@field easeOutBack EasingFunction Ease out with overshoot
---@field easeOutBounce EasingFunction Ease out bounce
---@field animate fun(duration: number, callback: fun(progress: number), opts?: AnimationOpts): hs.timer
---@field slideIn fun(canvas: hs.canvas, fromY: number, toY: number, opts?: AnimationOpts): hs.timer
---@field slideOut fun(canvas: hs.canvas, fromY: number, toY: number, opts?: AnimationOpts): hs.timer
---@field fadeIn fun(canvas: hs.canvas, opts?: AnimationOpts): hs.timer
---@field fadeOut fun(canvas: hs.canvas, opts?: AnimationOpts): hs.timer
---@field stop fun(timer: hs.timer|nil) Safely stop a timer

local M = {}

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

-- Default animation durations (milliseconds)
M.DEFAULTS = {
  slideIn = 250,
  slideOut = 300,
  fadeIn = 200,
  fadeOut = 200,
  bounce = 300,  -- For bouncy slide effect
}

-- Animation frame rate
M.FPS = 60

--------------------------------------------------------------------------------
-- EASING FUNCTIONS
--------------------------------------------------------------------------------

--- Ease-out cubic (smooth deceleration)
---@param t number Progress 0-1
---@return number Eased value 0-1
function M.easeOutCubic(t)
  return 1 - math.pow(1 - t, 3)
end

--- Ease-in cubic (smooth acceleration)
---@param t number Progress 0-1
---@return number Eased value 0-1
function M.easeInCubic(t)
  return math.pow(t, 3)
end

--- Ease-out back (slight overshoot/bounce)
---@param t number Progress 0-1
---@return number Eased value 0-1
function M.easeOutBack(t)
  local c1 = 1.70158
  local c3 = c1 + 1
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

--- Ease-in-out cubic
---@param t number Progress 0-1
---@return number Eased value 0-1
function M.easeInOutCubic(t)
  if t < 0.5 then
    return 4 * t * t * t
  else
    return 1 - math.pow(-2 * t + 2, 3) / 2
  end
end

--- Linear (no easing)
---@param t number Progress 0-1
---@return number Same value
function M.linear(t)
  return t
end

--- Ease-out elastic (springy bounce)
---@param t number Progress 0-1
---@return number Eased value with overshoot
function M.easeOutElastic(t)
  if t == 0 then return 0 end
  if t == 1 then return 1 end
  local p = 0.4  -- Period
  local a = 1    -- Amplitude
  local s = p / 4
  return a * math.pow(2, -10 * t) * math.sin((t - s) * (2 * math.pi) / p) + 1
end

--------------------------------------------------------------------------------
-- CORE ANIMATION
--------------------------------------------------------------------------------

--- Create an animation timer
---@param durationMs number Duration in milliseconds
---@param onFrame function(progress: number) Called each frame with progress 0-1
---@param opts? table { easing?, onComplete? }
---@return hs.timer Timer reference (caller should store for cleanup)
function M.animate(durationMs, onFrame, opts)
  opts = opts or {}
  local easing = opts.easing or M.easeOutCubic
  local onComplete = opts.onComplete

  local durationSec = durationMs / 1000
  local totalFrames = math.max(1, math.floor(durationSec * M.FPS))
  local currentFrame = 0

  -- Store timer reference for self-clearing
  local timerRef = { timer = nil }

  timerRef.timer = hs.timer.doUntil(function()
    local done = currentFrame >= totalFrames
    if done then
      timerRef.timer = nil
      if onComplete then onComplete() end
    end
    return done
  end, function()
    currentFrame = currentFrame + 1
    local progress = currentFrame / totalFrames
    local eased = easing(progress)
    onFrame(eased)
  end, 1 / M.FPS)

  return timerRef.timer
end

--------------------------------------------------------------------------------
-- SLIDE ANIMATIONS
--------------------------------------------------------------------------------

--- Animate a canvas sliding in with fade
---@param canvas hs.canvas Canvas to animate
---@param startY number Starting Y position
---@param finalY number Final Y position
---@param opts? table { duration?, easing?, onComplete? }
---@return hs.timer Timer reference
function M.slideIn(canvas, startY, finalY, opts)
  opts = opts or {}
  local durationMs = opts.duration or M.DEFAULTS.slideIn
  local easing = opts.easing or M.easeOutBack  -- Bouncy by default
  local x = canvas:topLeft().x
  local slideDistance = startY - finalY

  -- Start invisible at bottom position
  canvas:topLeft({ x = x, y = startY })
  canvas:alpha(0)
  canvas:show()

  return M.animate(durationMs, function(progress)
    -- Slide up
    local newY = startY - (slideDistance * progress)
    canvas:topLeft({ x = x, y = newY })
    -- Fade in
    canvas:alpha(progress)
  end, {
    easing = easing,
    onComplete = opts.onComplete,
  })
end

--- Animate a canvas sliding out with fade
---@param canvas hs.canvas Canvas to animate
---@param opts? table { duration?, easing?, deleteAfter?, onComplete? }
---@return hs.timer Timer reference
function M.slideOut(canvas, opts)
  opts = opts or {}
  local durationMs = opts.duration or M.DEFAULTS.slideOut
  local easing = opts.easing or M.easeInCubic
  local deleteAfter = opts.deleteAfter ~= false  -- Default true
  local onComplete = opts.onComplete

  local currentPos = canvas:topLeft()
  local startX, startY = currentPos.x, currentPos.y
  local screen = hs.screen.mainScreen():frame()
  local canvasFrame = canvas:frame()

  -- Calculate slide distance to go off bottom of screen
  local slideDistance = (screen.y + screen.h) - startY + canvasFrame.h + 50

  return M.animate(durationMs, function(progress)
    -- Slide down
    local newY = startY + (slideDistance * progress)
    canvas:topLeft({ x = startX, y = newY })
    -- Fade out
    canvas:alpha(1 - progress)
  end, {
    easing = easing,
    onComplete = function()
      if deleteAfter and canvas then
        canvas:delete(0)
      end
      if onComplete then onComplete() end
    end,
  })
end

--- Animate a canvas sliding down (for top-anchored HUDs like notch)
---@param canvas hs.canvas Canvas to animate
---@param startY number Starting Y position (above final, hidden behind menubar)
---@param finalY number Final Y position (visible)
---@param opts? table { duration?, easing?, onComplete? }
---@return hs.timer Timer reference
function M.slideDown(canvas, startY, finalY, opts)
  opts = opts or {}
  local durationMs = opts.duration or M.DEFAULTS.slideIn
  local easing = opts.easing or M.easeOutCubic  -- Smooth deceleration, no bounce
  local x = canvas:topLeft().x
  local slideDistance = finalY - startY

  canvas:topLeft({ x = x, y = startY })
  canvas:alpha(0)
  canvas:show()

  return M.animate(durationMs, function(progress)
    local newY = startY + (slideDistance * progress)
    canvas:topLeft({ x = x, y = newY })
    -- Fade in synced with slide (slightly faster)
    canvas:alpha(math.min(1, progress * 1.5))
  end, {
    easing = easing,
    onComplete = opts.onComplete,
  })
end

--- Animate a canvas sliding up (for top-anchored HUDs like notch)
---@param canvas hs.canvas Canvas to animate
---@param opts? table { duration?, easing?, hideAfter?, onComplete? }
---@return hs.timer Timer reference
function M.slideUp(canvas, opts)
  opts = opts or {}
  local durationMs = opts.duration or M.DEFAULTS.slideOut
  local easing = opts.easing or M.easeInCubic
  local hideAfter = opts.hideAfter ~= false  -- Default true
  local onComplete = opts.onComplete

  local currentPos = canvas:topLeft()
  local startX, startY = currentPos.x, currentPos.y
  local canvasFrame = canvas:frame()

  -- Slide up behind menubar (negative Y to hide above screen)
  local targetY = startY - canvasFrame.h - 20

  return M.animate(durationMs, function(progress)
    local newY = startY + (targetY - startY) * progress
    canvas:topLeft({ x = startX, y = newY })
    -- Fade out in last 50% of animation
    if progress > 0.5 then
      canvas:alpha(1 - (progress - 0.5) * 2)
    end
  end, {
    easing = easing,
    onComplete = function()
      if hideAfter and canvas then
        canvas:hide()
        -- Reset position for next show
        canvas:topLeft({ x = startX, y = startY })
        canvas:alpha(1)
      end
      if onComplete then onComplete() end
    end,
  })
end

--------------------------------------------------------------------------------
-- FADE ANIMATIONS
--------------------------------------------------------------------------------

--- Fade in a canvas (no slide)
---@param canvas hs.canvas Canvas to animate
---@param opts? table { duration?, onComplete? }
---@return hs.timer Timer reference
function M.fadeIn(canvas, opts)
  opts = opts or {}
  local durationMs = opts.duration or M.DEFAULTS.fadeIn

  canvas:alpha(0)
  canvas:show()

  return M.animate(durationMs, function(progress)
    canvas:alpha(progress)
  end, {
    easing = M.linear,
    onComplete = opts.onComplete,
  })
end

--- Fade out a canvas
---@param canvas hs.canvas Canvas to animate
---@param opts? table { duration?, deleteAfter?, onComplete? }
---@return hs.timer|nil Timer reference (nil if instant)
function M.fadeOut(canvas, opts)
  opts = opts or {}
  local durationMs = opts.duration or M.DEFAULTS.fadeOut
  local deleteAfter = opts.deleteAfter ~= false
  local onComplete = opts.onComplete

  if durationMs <= 0 then
    if deleteAfter then
      canvas:delete(0)
    else
      canvas:hide()
    end
    if onComplete then onComplete() end
    return nil
  end

  return M.animate(durationMs, function(progress)
    canvas:alpha(1 - progress)
  end, {
    easing = M.linear,
    onComplete = function()
      if deleteAfter then
        canvas:delete(0)
      else
        canvas:hide()
      end
      if onComplete then onComplete() end
    end,
  })
end

--------------------------------------------------------------------------------
-- SCALE ANIMATIONS (for hover-to-zoom)
--------------------------------------------------------------------------------

--- Animate a canvas scaling up
---@param canvas hs.canvas Canvas to scale
---@param targetScale number Target scale (e.g., 2.0 for 2x)
---@param opts? table { duration?, onComplete? }
---@return hs.timer Timer reference
function M.scaleUp(canvas, targetScale, opts)
  opts = opts or {}
  local durationMs = opts.duration or 200

  local startFrame = canvas:frame()
  local startW, startH = startFrame.w, startFrame.h
  local startX, startY = startFrame.x, startFrame.y

  local endW = startW * targetScale
  local endH = startH * targetScale
  -- Keep centered
  local endX = startX - (endW - startW) / 2
  local endY = startY - (endH - startH) / 2

  return M.animate(durationMs, function(progress)
    local w = startW + (endW - startW) * progress
    local h = startH + (endH - startH) * progress
    local x = startX - (w - startW) / 2
    local y = startY - (h - startH) / 2
    canvas:frame({ x = x, y = y, w = w, h = h })
  end, {
    easing = M.easeOutCubic,
    onComplete = opts.onComplete,
  })
end

--- Animate a canvas scaling down (reverse of scaleUp)
---@param canvas hs.canvas Canvas to scale
---@param originalFrame table Original frame {x, y, w, h}
---@param opts? table { duration?, onComplete? }
---@return hs.timer Timer reference
function M.scaleDown(canvas, originalFrame, opts)
  opts = opts or {}
  local durationMs = opts.duration or 200

  local currentFrame = canvas:frame()
  local startW, startH = currentFrame.w, currentFrame.h
  local startX, startY = currentFrame.x, currentFrame.y

  local endW, endH = originalFrame.w, originalFrame.h
  local endX, endY = originalFrame.x, originalFrame.y

  return M.animate(durationMs, function(progress)
    local w = startW + (endW - startW) * progress
    local h = startH + (endH - startH) * progress
    local x = startX + (endX - startX) * progress
    local y = startY + (endY - startY) * progress
    canvas:frame({ x = x, y = y, w = w, h = h })
  end, {
    easing = M.easeOutCubic,
    onComplete = opts.onComplete,
  })
end

--- Animate canvas resize while keeping a specified edge fixed
---@param canvas hs.canvas Canvas to resize
---@param targetWidth number Target width
---@param targetHeight number Target height
---@param opts? { edge?: "bottom", duration?: number, onComplete?: function }
---@return hs.timer|nil Timer reference
function M.resizeFromEdge(canvas, targetWidth, targetHeight, opts)
  opts = opts or {}
  local edge = opts.edge or "bottom"
  local durationMs = opts.duration or 150

  local oldFrame = canvas:frame()

  -- No animation needed if size hasn't changed
  if math.abs(oldFrame.h - targetHeight) < 1 and math.abs(oldFrame.w - targetWidth) < 1 then
    return nil
  end

  -- Currently only "bottom" edge is supported
  -- TODO: Add top, left, right when needed
  local anchorBottom = oldFrame.y + oldFrame.h

  return M.animate(durationMs, function(progress)
    local currentW = oldFrame.w + (targetWidth - oldFrame.w) * progress
    local currentH = oldFrame.h + (targetHeight - oldFrame.h) * progress
    local currentY = anchorBottom - currentH

    canvas:frame({ x = oldFrame.x, y = currentY, w = currentW, h = currentH })
  end, {
    easing = M.easeOutCubic,
    onComplete = opts.onComplete,
  })
end

--------------------------------------------------------------------------------
-- ELEMENT ANIMATIONS
--------------------------------------------------------------------------------

---@class WaveformAnimOpts
---@field barCount number Number of bars
---@field maxHeight number Maximum bar height
---@field baseY number Center Y coordinate for bars
---@field barWidth? number Width of each bar (default: 4)
---@field interval? number Animation interval in seconds (default: 0.05)
---@field idPrefix? string ID prefix for bars (default: "waveform_bar_")

---Animate waveform bars with random heights
---@param canvas hs.canvas Canvas containing waveform bars
---@param opts WaveformAnimOpts
---@return hs.timer timer Timer for the animation (caller must stop)
function M.waveform(canvas, opts)
  assert(opts.barCount, "waveform requires opts.barCount")
  assert(opts.maxHeight, "waveform requires opts.maxHeight")
  assert(opts.baseY, "waveform requires opts.baseY")
  
  local barCount = opts.barCount
  local maxHeight = opts.maxHeight
  local baseY = opts.baseY
  local barWidth = opts.barWidth or 4
  local idPrefix = opts.idPrefix or "waveform_bar_"
  
  return hs.timer.doEvery(opts.interval or 0.05, function()
    for i = 1, barCount do
      local elementId = idPrefix .. i
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

---@class PulseAnimOpts
---@field elementId string Canvas element ID to pulse
---@field baseRadius number Base radius of the circle
---@field pulseAmount? number How much to grow/shrink (default: 5)
---@field interval? number Animation interval in seconds (default: 0.033 ~30fps)

---Pulse a circle element (grow/shrink)
---@param canvas hs.canvas Canvas containing the circle
---@param opts PulseAnimOpts
---@return hs.timer timer Timer for the animation (caller must stop)
function M.pulse(canvas, opts)
  assert(opts.elementId, "pulse requires opts.elementId")
  assert(opts.baseRadius, "pulse requires opts.baseRadius")
  
  local baseRadius = opts.baseRadius
  local pulseAmount = opts.pulseAmount or 5
  local phase = 0
  
  return hs.timer.doEvery(opts.interval or 0.033, function()  -- ~30fps
    phase = phase + 0.15
    local pulse = math.sin(phase) * pulseAmount
    local newRadius = baseRadius + pulse
    
    if canvas[opts.elementId] then
      canvas[opts.elementId].radius = newRadius
    end
  end)
end

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

--- Stop a timer safely
---@param timer hs.timer|nil Timer to stop
function M.stop(timer)
  if timer then
    pcall(function() timer:stop() end)
  end
end

return M
