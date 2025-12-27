-- Canvas Utilities Library
-- Reusable animation and rendering helpers for hs.canvas
--
-- All animation functions return timer references that callers should store
-- for cleanup. Timers self-clear their predicates when complete.
--
local M = {}

--------------------------------------------------------------------------------
-- ANIMATION: Slide + Fade
--------------------------------------------------------------------------------

--- Animate a canvas sliding up with fade-in (entry animation)
--- Canvas should be created but not yet shown, or shown with alpha=0
---@param canvas hs.canvas Canvas to animate
---@param startY number Starting Y position (below final position)
---@param finalY number Final Y position
---@param opts? {duration?: number, onComplete?: function} Animation options
---@return hs.timer Timer reference (caller should store to cancel if needed)
function M.slideIn(canvas, startY, finalY, opts)
  opts = opts or {}
  local duration = opts.duration or 0.25
  local fps = 60
  local totalFrames = math.floor(duration * fps)
  local currentFrame = 0
  local x = canvas:topLeft().x
  local slideDistance = startY - finalY

  -- Start invisible at bottom position
  canvas:topLeft({ x = x, y = startY })
  canvas:alpha(0)
  canvas:show()

  -- Store timer reference for self-clearing in predicate
  local timerRef = { timer = nil }

  timerRef.timer = hs.timer.doUntil(function()
    local done = currentFrame >= totalFrames
    if done then
      timerRef.timer = nil -- Clear reference when animation completes
      if opts.onComplete then opts.onComplete() end
    end
    return done
  end, function()
    currentFrame = currentFrame + 1
    local progress = currentFrame / totalFrames
    -- Ease-out cubic for smooth deceleration
    local eased = 1 - math.pow(1 - progress, 3)

    -- Slide up
    local newY = startY - (slideDistance * eased)
    canvas:topLeft({ x = x, y = newY })

    -- Fade in
    canvas:alpha(eased)
  end, 1 / fps)

  return timerRef.timer
end

--- Animate a canvas sliding down with fade-out (exit animation)
--- Optionally deletes canvas after animation completes
---@param canvas hs.canvas Canvas to animate
---@param opts? {duration?: number, onComplete?: function, deleteAfter?: boolean} Animation options
---@return hs.timer Timer reference
function M.slideOut(canvas, opts)
  opts = opts or {}
  local duration = opts.duration or 0.3
  local deleteAfter = opts.deleteAfter ~= false -- default true
  local fps = 60
  local totalFrames = math.floor(duration * fps)
  local currentFrame = 0

  local currentPos = canvas:topLeft()
  local startX, startY = currentPos.x, currentPos.y
  local screen = hs.screen.mainScreen():frame()
  local canvasFrame = canvas:frame()

  -- Calculate slide distance to go off bottom of screen
  local slideDistance = (screen.y + screen.h) - startY + canvasFrame.h + 50

  -- Store timer reference for self-clearing in predicate
  local timerRef = { timer = nil }

  timerRef.timer = hs.timer.doUntil(function()
    local done = currentFrame >= totalFrames
    if done then
      timerRef.timer = nil -- Clear reference when animation completes
      -- Handle cleanup after animation ends
      if deleteAfter and canvas then
        canvas:delete(0)
      end
      if opts.onComplete then opts.onComplete() end
    end
    return done
  end, function()
    currentFrame = currentFrame + 1
    local progress = currentFrame / totalFrames
    -- Ease-in cubic for smooth acceleration
    local eased = math.pow(progress, 3)

    -- Slide down
    local newY = startY + (slideDistance * eased)
    canvas:topLeft({ x = startX, y = newY })

    -- Fade out
    canvas:alpha(1 - progress)
  end, 1 / fps)

  return timerRef.timer
end

--- Simple fade-in animation (no slide)
---@param canvas hs.canvas Canvas to animate
---@param opts? {duration?: number, onComplete?: function} Animation options
---@return hs.timer Timer reference
function M.fadeIn(canvas, opts)
  opts = opts or {}
  local duration = opts.duration or 0.2
  local fps = 60
  local totalFrames = math.floor(duration * fps)
  local currentFrame = 0

  canvas:alpha(0)
  canvas:show()

  -- Store timer reference for self-clearing in predicate
  local timerRef = { timer = nil }

  timerRef.timer = hs.timer.doUntil(function()
    local done = currentFrame >= totalFrames
    if done then
      timerRef.timer = nil -- Clear reference when animation completes
      if opts.onComplete then opts.onComplete() end
    end
    return done
  end, function()
    currentFrame = currentFrame + 1
    local progress = currentFrame / totalFrames
    canvas:alpha(progress)
  end, 1 / fps)

  return timerRef.timer
end

--- Simple fade-out animation (no slide)
---@param canvas hs.canvas Canvas to animate
---@param opts? {duration?: number, onComplete?: function, deleteAfter?: boolean} Animation options
---@return hs.timer|nil Timer reference (nil if instant)
function M.fadeOut(canvas, opts)
  opts = opts or {}
  local duration = opts.duration or 0.2
  local deleteAfter = opts.deleteAfter ~= false

  if duration <= 0 then
    -- Instant
    if deleteAfter then
      canvas:delete(0)
    else
      canvas:hide()
    end
    if opts.onComplete then opts.onComplete() end
    return nil
  end

  local fps = 60
  local totalFrames = math.floor(duration * fps)
  local currentFrame = 0

  -- Store timer reference for self-clearing in predicate
  local timerRef = { timer = nil }

  timerRef.timer = hs.timer.doUntil(function()
    local done = currentFrame >= totalFrames
    if done then
      timerRef.timer = nil -- Clear reference when animation completes
      -- Handle cleanup after animation ends
      if deleteAfter then
        canvas:delete(0)
      else
        canvas:hide()
      end
      if opts.onComplete then opts.onComplete() end
    end
    return done
  end, function()
    currentFrame = currentFrame + 1
    local progress = currentFrame / totalFrames
    canvas:alpha(1 - progress)
  end, 1 / fps)

  return timerRef.timer
end

--------------------------------------------------------------------------------
-- POSITIONING HELPERS
--------------------------------------------------------------------------------

--- Calculate bottom-center position for a canvas
---@param width number Canvas width
---@param height number Canvas height
---@param opts? {screen?: hs.screen, margin?: number} Options
---@return {x: number, y: number, startY: number} Position with startY for animation
function M.bottomCenter(width, height, opts)
  opts = opts or {}
  local screen = opts.screen or hs.screen.mainScreen()
  local margin = opts.margin or 40
  local frame = screen:frame()

  local x = frame.x + (frame.w - width) / 2
  local finalY = frame.y + frame.h - height - margin
  local startY = finalY + 40 -- Start below final position for slide-up

  return { x = x, y = finalY, startY = startY }
end

--- Calculate bottom-left position for a canvas
---@param width number Canvas width
---@param height number Canvas height
---@param opts? {screen?: hs.screen, margin?: number, offset?: number} Options
---@return {x: number, y: number, startY: number} Position with startY for animation
function M.bottomLeft(width, height, opts)
  opts = opts or {}
  local screen = opts.screen or hs.screen.mainScreen()
  local margin = opts.margin or 20
  local offset = opts.offset or 0
  local frame = screen:frame()

  local x = frame.x + margin
  local finalY = frame.y + frame.h - height - margin - offset
  local startY = frame.y + frame.h - height -- Start at very bottom

  return { x = x, y = finalY, startY = startY }
end

--- Calculate bottom-right position for a canvas
---@param width number Canvas width
---@param height number Canvas height
---@param opts? {screen?: hs.screen, margin?: number, offset?: number} Options
---@return {x: number, y: number, startY: number} Position with startY for animation
function M.bottomRight(width, height, opts)
  opts = opts or {}
  local screen = opts.screen or hs.screen.mainScreen()
  local margin = opts.margin or 20
  local offset = opts.offset or 0
  local frame = screen:frame()

  local x = frame.x + frame.w - width - margin
  local finalY = frame.y + frame.h - height - margin - offset
  local startY = frame.y + frame.h - height

  return { x = x, y = finalY, startY = startY }
end

--------------------------------------------------------------------------------
-- COLOR HELPERS
--------------------------------------------------------------------------------

--- Get colors based on system dark/light mode
---@param darkColors table Colors for dark mode
---@param lightColors table Colors for light mode
---@return table Selected color scheme
function M.getSystemColors(darkColors, lightColors)
  local appearance = hs.host.interfaceStyle()
  if appearance == "Dark" then
    return darkColors
  else
    return lightColors
  end
end

return M
