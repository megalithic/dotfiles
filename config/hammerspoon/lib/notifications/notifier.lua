local M = {}
M.__index = M
M.name = "notifier"

local config = C.notifier

-- Smart truncate text at word boundary with remaining character count
-- @param text string: text to truncate
-- @param maxLen number: maximum length before truncation
-- @return string: truncated text with "(+N)..." suffix if truncated
local function smartTruncate(text, maxLen)
  if not text or #text <= maxLen then return text end

  -- Find last word boundary before maxLen
  local truncateAt = maxLen

  -- Look backwards from maxLen for a space (up to 30 chars back)
  for i = maxLen, math.max(1, maxLen - 30), -1 do
    if text:sub(i, i):match("%s") then
      truncateAt = i - 1
      break
    end
  end

  local truncated = text:sub(1, truncateAt)
  local remaining = #text - truncateAt

  return truncated .. " (+" .. remaining .. ")..."
end

-- Global references to active notification canvas and timer
_G.activeNotificationCanvas = nil
_G.activeNotificationTimer = nil
_G.activeNotificationAnimTimer = nil
_G.notificationOverlay = nil -- Reusable dimming overlay
_G.activeNotificationBundleID = nil -- Track source app for auto-dismiss
_G.notificationAppWatcher = nil -- Application watcher for auto-dismiss

-- Focus mode cache (to avoid repeated subprocess calls)
local focusModeCache = {
  mode = nil, -- Current focus mode name or nil
  timestamp = 0, -- When cached
  ttl = 5, -- Cache for 5 seconds
}

-- Get active program name from Ghostty window title
-- Parses tmux title format: "◫ session:window ◦ command"
function M.getActiveProgram()
  local ghostty = hs.application.get(TERMINAL)
  if not ghostty then return nil end

  local win = ghostty:focusedWindow()
  if not win then return nil end

  local title = win:title()
  if not title then return nil end

  -- Parse tmux title format to extract command
  local command = title:match("◦%s*(.+)$")
  if command then
    -- Clean up command name (remove arguments)
    command = command:match("^(%S+)") or command
    -- Extract basename (handles /nix/store/.../bin/node -> node)
    command = command:match("[^/]+$") or command
    return command
  end

  return nil
end

-- Calculate optimal vertical offset based on active program and config
function M.calculateOffset(opts)
  opts = opts or {}
  local mode = opts.positionMode or config.positionMode or "auto"

  -- Fixed mode: use provided offset directly
  if mode == "fixed" then return opts.verticalOffset or config.minOffset or 100 end

  -- Auto mode: detect program and use configured offset
  if mode == "auto" then
    local program = M.getActiveProgram()
    local offsets = config.offsets or {}
    local offset = offsets.default or 350

    if program then
      -- Look up program-specific offset
      offset = offsets[program] or offsets.default or 350
    end

    -- Add any additional offset from options
    if opts.verticalOffset then offset = offset + opts.verticalOffset end

    -- Respect minimum offset
    local minOffset = config.minOffset or 100
    return math.max(offset, minOffset)
  end

  -- Above-prompt mode: estimate based on prompt lines
  if mode == "above-prompt" then
    local promptLines = opts.estimatedPromptLines or 2
    local lineHeight = 20 -- approximate px per line
    local offset = promptLines * lineHeight + 40 -- extra padding
    return offset + (opts.verticalOffset or 0)
  end

  -- Fallback
  return opts.verticalOffset or config.minOffset or 100
end

-- Check if source app is currently focused
-- Returns: true if app is frontmost, false otherwise
function M.isAppFocused(bundleID)
  if not bundleID then return false end

  local frontmost = hs.application.frontmostApplication()
  if not frontmost then return false end

  return frontmost:bundleID() == bundleID
end

-- Check if user is in terminal (Ghostty)
-- Returns: true if Ghostty is frontmost
function M.isInTerminal()
  local frontmost = hs.application.frontmostApplication()
  if not frontmost then return false end

  return frontmost:bundleID() == TERMINAL or frontmost:name() == "Ghostty"
end

-- Get the focused window title for a given application bundle ID
-- Returns: window title string or nil
function M.getFocusedWindowTitle(bundleID)
  if not bundleID then return nil end

  local app = hs.application.get(bundleID)
  if not app then return nil end

  local window = app:focusedWindow()
  if not window then return nil end

  return window:title()
end

-- Determine if high priority notification should be shown
-- Based on app focus state and terminal exception
-- Returns: {shouldShow: boolean, reason: string}
function M.shouldShowHighPriority(bundleID, opts)
  opts = opts or {}
  local alwaysShowInTerminal = opts.alwaysShowInTerminal ~= false -- default true
  local showWhenAppFocused = opts.showWhenAppFocused or false -- default false

  -- Check if we're in terminal (always show high priority in terminal)
  if alwaysShowInTerminal and M.isInTerminal() then return { shouldShow = true, reason = "in_terminal" } end

  -- Check if source app is focused
  local appIsFocused = M.isAppFocused(bundleID)

  if appIsFocused and not showWhenAppFocused then return { shouldShow = false, reason = "app_already_focused" } end

  return { shouldShow = true, reason = "app_not_focused" }
end

-- Get current Focus Mode (with 5-second cache)
-- Returns: focus mode name (string) or nil if no focus active
function M.getCurrentFocusMode()
  local now = os.time()

  -- Return cached value if still valid
  if focusModeCache.timestamp + focusModeCache.ttl > now then return focusModeCache.mode end

  -- Fetch fresh focus mode status
  -- Uses fast JXA script: bin/get-focus-mode
  local output, status = hs.execute(os.getenv("HOME") .. "/.dotfiles/bin/get-focus-mode 2>/dev/null")

  if status then
    local mode = output and output:match("^%s*(.-)%s*$") or nil
    -- Normalize "No focus" or empty string to nil
    if mode == "" or mode == "No focus" then
      focusModeCache.mode = nil
    else
      focusModeCache.mode = mode
    end
  else
    -- If script fails, cache nil
    focusModeCache.mode = nil
  end

  focusModeCache.timestamp = now
  return focusModeCache.mode
end

-- Show dimming overlay (reuses single global canvas for efficiency)
function M.showOverlay(alpha)
  alpha = alpha or 0.6

  -- Reuse existing overlay if present
  if _G.notificationOverlay then
    _G.notificationOverlay:alpha(alpha)
    _G.notificationOverlay:show()
    return
  end

  -- Create overlay canvas first time
  local screen = hs.screen.mainScreen()
  local frame = screen:fullFrame() -- Includes menu bar

  _G.notificationOverlay = hs
    .canvas
    .new(frame)
    :appendElements({
      type = "rectangle",
      action = "fill",
      fillColor = { red = 0.0, green = 0.0, blue = 0.0, alpha = alpha },
      frame = { x = 0, y = 0, h = "100%", w = "100%" },
    })
    :level("overlay") -- Above windows, below notification canvas
    :alpha(alpha)

  -- Add click-to-dismiss if enabled in config
  local clickDismiss = config.clickDismiss
  if clickDismiss then
    _G.notificationOverlay:canvasMouseEvents(true, true)
    _G.notificationOverlay:mouseCallback(function(canvas, event, id, x, y)
      if event == "mouseDown" and _G.activeNotificationCanvas then
        M.dismissNotification()
      end
    end)
  end

  _G.notificationOverlay:show()
end

-- Hide dimming overlay (keeps canvas for reuse)
function M.hideOverlay()
  if _G.notificationOverlay then _G.notificationOverlay:hide() end
end

-- Dismiss active notification (helper function)
function M.dismissNotification(fadeTime)
  fadeTime = fadeTime or 0.3

  if _G.activeNotificationCanvas then
    _G.activeNotificationCanvas:delete(fadeTime)
    _G.activeNotificationCanvas = nil
  end

  if _G.activeNotificationTimer then
    _G.activeNotificationTimer:stop()
    _G.activeNotificationTimer = nil
  end

  if _G.activeNotificationAnimTimer then
    _G.activeNotificationAnimTimer:stop()
    _G.activeNotificationAnimTimer = nil
  end

  if _G.notificationOverlay then hs.timer.doAfter(fadeTime, function() M.hideOverlay() end) end

  _G.activeNotificationBundleID = nil
end

-- Set up application watcher for auto-dismiss
-- Called once when module is loaded
function M.setupAppWatcher()
  if _G.notificationAppWatcher then return end -- Already set up

  _G.notificationAppWatcher = hs.application.watcher.new(function(appName, eventType, app)
    -- Only care about app activation events
    if eventType ~= hs.application.watcher.activated then return end

    -- Check if there's an active notification
    if not _G.activeNotificationCanvas or not _G.activeNotificationBundleID then return end

    -- Check if the activated app matches the notification source
    if app and app:bundleID() == _G.activeNotificationBundleID then
      M.dismissNotification(0.2) -- Quick fade
    end
  end)

  _G.notificationAppWatcher:start()
end

-- Initialize app watcher on module load
M.setupAppWatcher()

-- Calculate notification position based on anchor and position
-- @param anchor string: "screen", "window", or "app"
-- @param position string: "NW", "N", "NE", "W", "C", "E", "SW", "S", "SE"
-- @param width number: notification width in pixels
-- @param height number: notification height in pixels
-- @param offset number: optional additional vertical offset for fine-tuning
-- Returns: {x, y} table with pixel coordinates
function M.calculatePosition(anchor, position, width, height, offset)
  offset = offset or 0
  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()
  local frame = screenFrame

  -- Determine the reference frame based on anchor
  if anchor == "window" then
    local win = hs.window.focusedWindow()
    if win then
      frame = win:frame()
    else
      -- Fallback to screen if no window
      anchor = "screen"
      frame = screenFrame
    end
  elseif anchor == "app" then
    -- Get frontmost app's main window
    local app = hs.application.frontmostApplication()
    if app then
      local win = app:mainWindow()
      if win then
        frame = win:frame()
      else
        anchor = "screen"
        frame = screenFrame
      end
    else
      anchor = "screen"
      frame = screenFrame
    end
  end

  -- Calculate base coordinates for each cardinal direction
  local x, y

  -- Horizontal positioning
  if position:match("W") then -- West (left)
    x = frame.x + 20 -- 20px padding from left edge
  elseif position:match("E") then -- East (right)
    x = frame.x + frame.w - width - 20 -- 20px padding from right edge
  else -- Center or no horizontal indicator
    x = frame.x + (frame.w - width) / 2
  end

  -- Vertical positioning
  if position:match("N") and not position:match("NE") and not position:match("NW") then -- North (top center)
    y = frame.y + 20 -- 20px padding from top edge
  elseif position:match("S") and not position:match("SE") and not position:match("SW") then -- South (bottom center)
    y = frame.y + frame.h - height - 20 -- 20px padding from bottom edge
  elseif position:find("NW") or position:find("NE") then -- Northwest/Northeast (top corners)
    y = frame.y + 20
  elseif position:find("SW") or position:find("SE") then -- Southwest/Southeast (bottom corners)
    y = frame.y + frame.h - height - 20
  else -- Center or middle
    y = frame.y + (frame.h - height) / 2
  end

  -- Apply additional offset (typically for SW position with program detection)
  y = y - offset

  return { x = x, y = y }
end

-- Check if Ghostty is frontmost and display is awake
-- Returns: 'not_ghostty', 'display_asleep', or 'ghostty_active'
function M.checkAttention()
  local frontmost = hs.application.frontmostApplication()
  if not frontmost or frontmost:name() ~= "Ghostty" then return "not_ghostty" end

  local displayIdle = hs.caffeinate.get("displayIdle")
  if displayIdle then return "display_asleep" end

  return "ghostty_active"
end

-- Check if display is asleep, screen is locked, or user is logged out
-- Returns: 'display_asleep', 'screen_locked', 'logged_out', or 'awake'
function M.checkDisplayState()
  local displayIdle = hs.caffeinate.get("displayIdle")
  local sessionInfo = hs.caffeinate.sessionProperties()
  local screenLocked = sessionInfo and sessionInfo["CGSSessionScreenIsLocked"] or false
  local onConsole = sessionInfo and sessionInfo["kCGSSessionOnConsoleKey"] or false

  if displayIdle then
    return "display_asleep"
  elseif screenLocked then
    return "screen_locked"
  elseif not onConsole then
    return "logged_out"
  else
    return "awake"
  end
end

-- Detect if system is in dark mode
-- Returns: 'dark' or 'light'
function M.getSystemAppearance()
  local appearance = hs.host.interfaceStyle()
  if appearance == "Dark" then
    return "dark"
  else
    return "light"
  end
end

-- Get color scheme based on system appearance
-- Returns: table of colors from config
function M.getColorScheme()
  local appearance = M.getSystemAppearance()
  return config.colors[appearance] or config.colors.light
end

-- Send macOS notification via hs.notify
function M.sendMacOSNotification(title, subtitle, body) hs.notify.show(title, subtitle or "", body or "") end

-- Send iMessage to phone number
function M.sendPhoneNotification(phoneNumber, message)
  if not phoneNumber or phoneNumber == "" then return false end
  hs.messages.iMessage(phoneNumber, message)
  return true
end

-- Send Hammerspoon alert (short overlay message)
function M.sendAlert(message, duration)
  duration = duration or 5
  hs.alert.show(message, duration)
end

-- Send custom canvas notification at bottom-left with macOS Sequoia styling
-- Options: {
--   positionMode = "auto" | "fixed" | "above-prompt",
--   verticalOffset = number,  -- additional px offset
--   estimatedPromptLines = number,  -- for "above-prompt" mode
--   includeProgram = boolean,  -- whether to prepend program name to title (default: true)
-- }
function M.sendCanvasNotification(title, subtitle, message, duration, opts)
  duration = duration or config.defaultDuration or 5
  opts = opts or {}

  -- Guard against nil values (some notifications have empty fields)
  title = title or ""
  subtitle = subtitle or ""
  message = message or ""

  -- Optionally prepend program name to title
  if opts.includeProgram ~= false then -- default to true
    local program = M.getActiveProgram()
    if program then title = "[" .. program .. "] " .. title end
  end

  -- Check if we should redact notification content based on focus mode
  local currentFocus = M.getCurrentFocusMode and M.getCurrentFocusMode() or nil
  local shouldRedact = currentFocus == "Do Not Disturb" or currentFocus == "Work"

  if shouldRedact then
    -- Redact message content character-by-character (preserve spaces)
    message = message:gsub(".", function(c)
      return c == " " and " " or "•"
    end)
  end

  -- Close any existing notification before showing new one
  if _G.activeNotificationCanvas then
    M.dismissNotification(0) -- Instant dismiss
  end

  -- Show dimming overlay if requested
  if opts.dimBackground then M.showOverlay(opts.dimAlpha or 0.6) end

  -- Process message: truncate to fit visible area (~90 chars for 3 lines)
  local maxTotalChars = 90
  local originalLength = #message

  -- Replace newlines with spaces for consistent display
  message = message:gsub("\n", " ")

  -- Apply smart truncation if message exceeds limit
  if originalLength > maxTotalChars then
    message = smartTruncate(message, maxTotalChars)
  end

  -- Count lines for height calculation (let canvas wordWrap handle wrapping)
  local estimatedLines = math.ceil(#message / 30)
  local lineCount = math.min(estimatedLines, 3)

  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()

  -- Calculate dynamic height based on content
  local baseHeight = 70
  local lineHeight = 20
  local height = baseHeight + (lineCount * lineHeight)

  -- Minimum and maximum heights
  if height < 100 then height = 100 end
  if height > 200 then height = 200 end

  local padding = 20
  local width = 420

  -- Get anchor and position from opts (with defaults)
  local anchor = opts.anchor or "screen"
  local position = opts.position or "SW"

  -- Calculate intelligent offset for SW position in terminal
  local offset = 0
  if position == "SW" then
    local _, tmuxRunning = hs.execute("pgrep -x tmux")
    local frontmost = hs.application.frontmostApplication()
    local inTerminal = frontmost and (frontmost:bundleID() == TERMINAL or frontmost:name() == "Ghostty")

    -- Only apply offset if in terminal (with or without tmux, depending on config)
    if inTerminal then
      local shouldApplyOffset = true
      if config.tmuxShiftEnabled == false then
        -- If tmuxShiftEnabled is explicitly false, only apply when NOT in tmux
        shouldApplyOffset = not tmuxRunning
      end
      -- If tmuxShiftEnabled is true or nil (default), always apply offset in terminal

      if shouldApplyOffset then
        offset = M.calculateOffset(opts)
      end
    end
  end

  -- Calculate position using new anchor + position system
  local pos = M.calculatePosition(anchor, position, width, height, offset)
  local x = pos.x
  local y = pos.y

  -- Store final position for animation
  local finalY = y

  -- Check if animation is enabled and adjust starting position
  local animConfig = config.animation or {}
  local animEnabled = animConfig.enabled ~= false -- default to true

  if animEnabled then
    -- Start from the bottom of the focused window (or screen if no window)
    local focusedWin = hs.window.focusedWindow()
    if focusedWin then
      local winFrame = focusedWin:frame()
      y = winFrame.y + winFrame.h - height
    else
      y = screenFrame.h - height
    end
  end

  -- Create canvas
  local canvas = hs.canvas.new({ x = x, y = y, h = height, w = width })

  -- IMPORTANT: Prevent clicking on canvas from activating/raising Hammerspoon
  -- This keeps notifications unobtrusive and prevents the console from coming to front
  canvas:clickActivating(false)

  -- Get color scheme based on system appearance
  local colors = M.getColorScheme()

  -- Shadow layer
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = colors.shadow,
    roundedRectRadii = { xRadius = 14, yRadius = 14 },
    frame = { x = "0.5%", y = "1%", h = "99%", w = "99%" },
    shadow = {
      blurRadius = 25,
      color = { red = 0.0, green = 0.0, blue = 0.0, alpha = 0.5 },
      offset = { h = 6, w = 0 },
    },
  })

  -- Main background
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = colors.background,
    roundedRectRadii = { xRadius = 12, yRadius = 12 },
    frame = { x = "0%", y = "0%", h = "100%", w = "100%" },
    id = "background",
    trackMouseDown = true,
  })

  -- Subtle border
  canvas:appendElements({
    type = "rectangle",
    action = "stroke",
    strokeColor = colors.border,
    strokeWidth = 1.5,
    roundedRectRadii = { xRadius = 12, yRadius = 12 },
    frame = { x = 0, y = 0, h = height, w = width },
  })

  -- Layout constants for consistent spacing
  local iconSize = 48
  local leftPadding = 16
  local iconSpacing = 12
  local topPadding = 16
  local rightPadding = 16
  local bottomPadding = 16
  local titleHeight = 22
  local subtitleHeight = 20
  local titleToSubtitleSpacing = 2
  local subtitleToMessageSpacing = 4
  local timestampHeight = 20

  -- All vertical positioning uses topPadding as the base reference
  local contentY = topPadding -- Single reference point for top alignment
  local textLeftMargin = leftPadding -- Default if no icon

  if opts.appImageID then
    local appIcon

    -- Handle special icon markers
    if opts.appImageID == "hal9000" then
      local iconPath = hs.configdir .. "/assets/hal9000.png"
      appIcon = hs.image.imageFromPath(iconPath)
    else
      appIcon = hs.image.imageFromAppBundle(opts.appImageID)
    end

    if appIcon then
      canvas:appendElements({
        type = "image",
        image = appIcon,
        frame = { x = leftPadding, y = contentY, h = iconSize, w = iconSize },
        imageScaling = "scaleProportionally",
        imageAlignment = "center",
        id = "appIcon",
        trackMouseDown = true,
        trackMouseEnterExit = true,
      })
      -- Adjust text position to make room for icon
      textLeftMargin = leftPadding + iconSize + iconSpacing
    end
  end

  -- Title text (aligned with icon top)
  canvas:appendElements({
    type = "text",
    text = title,
    textColor = colors.title,
    textSize = 16,
    textFont = ".AppleSystemUIFontBold",
    frame = { x = textLeftMargin, y = contentY, h = titleHeight, w = width - textLeftMargin - rightPadding - 50 },
    textAlignment = "left",
    textLineBreak = "truncateTail",
    id = "title",
    trackMouseDown = true,
  })

  -- Subtitle text (positioned directly below title, medium emphasis)
  local subtitleY = contentY + titleHeight + titleToSubtitleSpacing
  if subtitle ~= "" then
    canvas:appendElements({
      type = "text",
      text = subtitle,
      textColor = colors.title, -- Same as title for emphasis
      textSize = 15,
      textFont = ".AppleSystemUIFont", -- Regular weight, not bold
      frame = { x = textLeftMargin, y = subtitleY, h = subtitleHeight, w = width - textLeftMargin - rightPadding - 50 },
      textAlignment = "left",
      textLineBreak = "truncateTail",
      id = "subtitle",
      trackMouseDown = true,
    })
  end

  -- Message text (positioned below subtitle if present, otherwise below title)
  local messageY = subtitle ~= ""
    and (subtitleY + subtitleHeight + subtitleToMessageSpacing)
    or (contentY + titleHeight + subtitleToMessageSpacing)
  local messageBottomSpace = timestampHeight + bottomPadding + 4 -- Base spacing
  canvas:appendElements({
    type = "text",
    text = message,
    textColor = colors.message,
    textSize = 14,
    textFont = ".AppleSystemUIFont",
    frame = {
      x = textLeftMargin,
      y = messageY,
      h = height - messageY - messageBottomSpace,
      w = width - textLeftMargin - rightPadding,
    },
    textAlignment = "left",
    textLineBreak = "wordWrap",
    id = "message",
    trackMouseDown = true,
  })

  -- Timestamp (bottom-right corner, subtle)
  -- Moved up slightly to create more space above it without cutting off message text
  local timestamp = os.date("%b %d, %I:%M %p") -- e.g., "Nov 06, 02:30 PM"
  local timestampWidth = 120
  local timestampExtraSpacing = 8 -- Additional space above timestamp
  canvas:appendElements({
    type = "text",
    text = timestamp,
    textColor = colors.timestamp,
    textSize = 11,
    textFont = ".AppleSystemUIFont",
    frame = {
      x = width - timestampWidth - rightPadding,
      y = height - timestampHeight - bottomPadding + timestampExtraSpacing,
      h = timestampHeight,
      w = timestampWidth,
    },
    textAlignment = "right",
    id = "timestamp",
    trackMouseDown = true,
  })

  -- Handle mouse events - dismiss on any click except app icon
  canvas:mouseCallback(function(obj, message, id, x, y)
    if message == "mouseDown" then
      if id == "appIcon" then
        -- Click on app icon - activate/focus the app
        if opts.appBundleID then hs.application.launchOrFocusByBundleID(opts.appBundleID) end
        return true
      else
        -- Click anywhere else - dismiss notification
        M.dismissNotification(0.3)
        return true
      end
    end
  end)

  -- Enable mouse events on entire canvas (including areas not covered by elements)
  canvas:canvasMouseEvents(true, false, false, false)

  -- Show canvas with higher level
  canvas:level("overlay")
  canvas:show()

  -- Store canvas reference globally
  _G.activeNotificationCanvas = canvas

  -- Store source app bundle ID for auto-dismiss
  _G.activeNotificationBundleID = opts.appBundleID or nil

  -- Animate slide-up if enabled
  if animEnabled then
    local animDuration = animConfig.duration or 0.3
    local fps = 60 -- frames per second
    local totalFrames = math.floor(animDuration * fps)
    local currentFrame = 0
    local startY = y
    local slideDistance = startY - finalY

    _G.activeNotificationAnimTimer = hs.timer.doUntil(function() return currentFrame >= totalFrames end, function()
      currentFrame = currentFrame + 1
      -- Ease-out cubic for smooth deceleration
      local progress = currentFrame / totalFrames
      local eased = 1 - math.pow(1 - progress, 3)
      local newY = startY - (slideDistance * eased)

      canvas:topLeft({ x = x, y = newY })
    end, 1 / fps)
  end

  -- Auto-hide after duration with fade
  _G.activeNotificationTimer = hs.timer.doAfter(duration, function()
    if canvas then
      canvas:delete(0.5)
      _G.activeNotificationCanvas = nil
      _G.activeNotificationTimer = nil
      if _G.activeNotificationAnimTimer then
        _G.activeNotificationAnimTimer:stop()
        _G.activeNotificationAnimTimer = nil
      end

      -- Hide overlay with slight delay for smooth fadeout
      if opts.dimBackground then hs.timer.doAfter(0.5, function() M.hideOverlay() end) end
    end
  end)
end

-- Send smart alert (short messages use alert, long messages use canvas)
function M.sendSmartAlert(message, duration)
  duration = duration or 5

  -- If message is longer than 25 characters, use canvas notification
  if #message > 25 then
    -- Extract title (up to first colon or first 25 chars)
    local title = message:match("^([^:]+)")
    if not title or title == message then title = message:sub(1, 25) end

    -- Rest is the body
    local body = message:match("^[^:]+:%s*(.+)")
    if not body or body == message then body = message:sub(26) end

    M.sendCanvasNotification(title, body, duration)
  else
    M.sendAlert(message, duration)
  end
end

return M
