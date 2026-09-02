-- HUD Position Module
-- 9-point positioning with cursor tracking and display scaling
--
-- Anchor points:
--   top-left      top-center      top-right
--   left-center   center          right-center
--   bottom-left   bottom-center   bottom-right
--   cursor (follows mouse)
--

---@alias HudAnchor
---| "top-left"
---| "top-center"
---| "top-right"
---| "left-center"
---| "center"
---| "right-center"
---| "bottom-left"
---| "bottom-center"
---| "bottom-right"
---| "cursor"

---@class HudPosition
---@field x number X coordinate
---@field y number Y coordinate
---@field startY number Animation start Y position
---@field screen hs.screen Screen object

---@class HudPositionOpts
---@field screen? hs.screen Target screen
---@field window? hs.window Target window (for window-relative positioning)
---@field margin? number Edge margin in points
---@field offset? number Vertical offset in points

---@class HudPositionModule
---@field MARGIN number Default edge margin
---@field STACK_SPACING number Spacing between stacked HUDs
---@field BOTTOM_OFFSET number Default bottom offset
---@field ANCHORS string[] Valid anchor positions
---@field calculate fun(anchor: HudAnchor, width: number, height: number, opts?: HudPositionOpts): HudPosition
---@field isExternalDisplay fun(screen?: hs.screen): boolean
---@field getScaleFactor fun(screen?: hs.screen): number
---@field stackOffset fun(index: number, height: number, anchor: HudAnchor): number

local M = {}

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

-- Margin from screen edges (points)
M.MARGIN = 40

-- Spacing between stacked HUDs (points)
M.STACK_SPACING = 12

-- Default vertical offset for bottom positioning (clears terminal input areas)
M.BOTTOM_OFFSET = 100

-- Valid anchor positions
M.ANCHORS = {
  "top-left", "top-center", "top-right",
  "left-center", "center", "right-center",
  "bottom-left", "bottom-center", "bottom-right",
  "cursor",
}

--------------------------------------------------------------------------------
-- DISPLAY DETECTION
--------------------------------------------------------------------------------

--- Check if a screen is an external display (not built-in)
---@param screen hs.screen Screen to check
---@return boolean True if external display
function M.isExternalDisplay(screen)
  if not screen then return false end

  local name = screen:name() or ""
  -- Built-in displays are typically named "Built-in Retina Display" or similar
  -- Also check if it's the main laptop display
  local isBuiltIn = name:lower():find("built%-in") ~= nil
    or name:lower():find("color lcd") ~= nil
    or name:lower():find("internal") ~= nil

  return not isBuiltIn
end

--- Get display scale factor (1.0 for laptop, 1.5 for external)
--- Simple 2-tier approach as specified
---@param screen hs.screen|nil Screen to check (default: mainScreen)
---@return number Scale factor
function M.getScaleFactor(screen)
  screen = screen or hs.screen.mainScreen()
  return M.isExternalDisplay(screen) and 1.5 or 1.0
end

--- Get screen info for DPI detection
--- Useful for future enhancement / documentation
---@param screen hs.screen|nil Screen to analyze
---@return table Info about the display
function M.getDisplayInfo(screen)
  screen = screen or hs.screen.mainScreen()
  local mode = screen:currentMode()

  return {
    name = screen:name(),
    isExternal = M.isExternalDisplay(screen),
    scaleFactor = M.getScaleFactor(screen),
    -- Raw DPI info for future use
    width = mode.w,
    height = mode.h,
    scale = mode.scale or 1,
    -- Frame info
    frame = screen:frame(),
    fullFrame = screen:fullFrame(),
  }
end

--------------------------------------------------------------------------------
-- POSITION CALCULATION
--------------------------------------------------------------------------------

--- Calculate position for a HUD based on anchor point
---@param anchor string Anchor position (e.g., "bottom-center", "cursor")
---@param width number HUD width in pixels
---@param height number HUD height in pixels
---@param opts? table Options: { screen?, margin?, offset? }
---@return table { x, y, startY, screen } Position with animation start position
function M.calculate(anchor, width, height, opts)
  opts = opts or {}
  -- Default to screen with focused window (mainScreen), not mouse position
  -- This ensures notifications appear where the user is working
  local screen = opts.screen or hs.screen.mainScreen() or hs.mouse.getCurrentScreen()
  local window = opts.window
  local margin = opts.margin or M.MARGIN
  local offset = opts.offset or 0  -- Additional offset (e.g., for terminal prompts)

  -- Use window frame if provided, otherwise screen frame
  local frame
  if window then
    frame = window:frame()
    -- Smaller margin for window-relative positioning
    margin = opts.margin or 12
  else
    frame = screen:frame()
  end

  local x, y

  -- Handle cursor-relative positioning
  if anchor == "cursor" then
    local mouse = hs.mouse.absolutePosition()
    -- Position above and to the right of cursor
    x = mouse.x + 16
    y = mouse.y - height - 8

    -- Ensure it stays on screen
    if x + width > frame.x + frame.w then
      x = frame.x + frame.w - width - margin
    end
    if y < frame.y + margin then
      y = frame.y + margin
    end

    return {
      x = x,
      y = y,
      startY = y + 20,  -- Slide up from slightly below
      screen = screen,
    }
  end

  -- Parse anchor into components
  local vPos, hPos = anchor:match("^([^-]+)-?(.*)$")
  if not hPos or hPos == "" then
    -- Single word like "center"
    if vPos == "center" then
      vPos, hPos = "center", "center"
    else
      -- Assume it's a vertical position with center horizontal
      hPos = "center"
    end
  end

  -- Horizontal positioning
  if hPos == "left" then
    x = frame.x + margin
  elseif hPos == "right" then
    x = frame.x + frame.w - width - margin
  else  -- center
    x = frame.x + (frame.w - width) / 2
  end

  -- Vertical positioning
  local slideDirection = 1  -- 1 = slide up, -1 = slide down
  if vPos == "top" then
    y = frame.y + margin
    slideDirection = -1  -- Slide down from above
  elseif vPos == "bottom" then
    y = frame.y + frame.h - height - margin - offset
  elseif vPos == "left" or vPos == "right" then
    -- "left-center" or "right-center"
    y = frame.y + (frame.h - height) / 2
  else  -- center
    y = frame.y + (frame.h - height) / 2
  end

  -- Calculate animation start position
  local slideDistance = 40
  local startY = y + (slideDirection * slideDistance)

  return {
    x = x,
    y = y,
    startY = startY,
    screen = screen,
  }
end

--- Calculate position for bottom-center (convenience function)
---@param width number HUD width
---@param height number HUD height
---@param opts? table Options
---@return table Position info
function M.bottomCenter(width, height, opts)
  return M.calculate("bottom-center", width, height, opts)
end

--- Calculate position for bottom-left (convenience function)
---@param width number HUD width
---@param height number HUD height
---@param opts? table Options
---@return table Position info
function M.bottomLeft(width, height, opts)
  return M.calculate("bottom-left", width, height, opts)
end

--- Calculate position for bottom-right (convenience function)
---@param width number HUD width
---@param height number HUD height
---@param opts? table Options
---@return table Position info
function M.bottomRight(width, height, opts)
  return M.calculate("bottom-right", width, height, opts)
end

--- Calculate position for top-right (convenience function)
---@param width number HUD width
---@param height number HUD height
---@param opts? table Options
---@return table Position info
function M.topRight(width, height, opts)
  return M.calculate("top-right", width, height, opts)
end

--- Calculate position for center (convenience function)
---@param width number HUD width
---@param height number HUD height
---@param opts? table Options
---@return table Position info
function M.center(width, height, opts)
  return M.calculate("center", width, height, opts)
end

--- Calculate position at cursor (convenience function)
---@param width number HUD width
---@param height number HUD height
---@param opts? table Options
---@return table Position info
function M.cursor(width, height, opts)
  return M.calculate("cursor", width, height, opts)
end

--------------------------------------------------------------------------------
-- STACKING
--------------------------------------------------------------------------------

--- Calculate position for stacked HUDs at the same anchor
--- Returns offset to add to base Y position
---@param stackIndex number 0-based index in stack (0 = bottom/newest)
---@param hudHeight number Height of this HUD
---@param anchor string Anchor position
---@return number Vertical offset (negative for bottom anchors, positive for top)
function M.stackOffset(stackIndex, hudHeight, anchor)
  if stackIndex <= 0 then return 0 end

  local totalOffset = stackIndex * (hudHeight + M.STACK_SPACING)

  -- For bottom anchors, stack upwards (negative Y)
  -- For top anchors, stack downwards (positive Y)
  if anchor:find("bottom") or anchor == "center" then
    return -totalOffset
  else
    return totalOffset
  end
end

return M
