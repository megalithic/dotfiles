-- Notification Rule Processing
-- Business logic for handling notification routing, urgency, and focus mode checks
--
local M = {}

-- Import dismiss utility for native notification dismissal
local dismiss = require("lib.notifications.dismiss")

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS (inlined from former notifier module)
--------------------------------------------------------------------------------

-- Focus mode cache (to avoid repeated subprocess calls)
local focusModeCache = {
  mode = nil,
  timestamp = 0,
  ttl = 5, -- Cache for 5 seconds
}

--- Check if source app is currently focused
---@param bundleID string|nil Bundle identifier
---@return boolean
local function isAppFocused(bundleID)
  if not bundleID then return false end
  local frontmost = hs.application.frontmostApplication()
  if not frontmost then return false end
  return frontmost:bundleID() == bundleID
end

--- Check if user is in terminal (Ghostty)
---@return boolean
local function isInTerminal()
  local frontmost = hs.application.frontmostApplication()
  if not frontmost then return false end
  return frontmost:bundleID() == TERMINAL or frontmost:name() == "Ghostty"
end

--- Determine if high priority notification should be shown
---@param bundleID string|nil Source app bundle ID
---@param opts {alwaysShowInTerminal?: boolean, showWhenAppFocused?: boolean}
---@return {shouldShow: boolean, reason: string}
local function shouldShowHighPriority(bundleID, opts)
  opts = opts or {}
  local alwaysShowInTerminal = opts.alwaysShowInTerminal ~= false
  local showWhenAppFocused = opts.showWhenAppFocused or false

  if alwaysShowInTerminal and isInTerminal() then
    return { shouldShow = true, reason = "in_terminal" }
  end

  local appIsFocused = isAppFocused(bundleID)
  if appIsFocused and not showWhenAppFocused then
    return { shouldShow = false, reason = "app_already_focused" }
  end

  return { shouldShow = true, reason = "app_not_focused" }
end

--- Get current Focus Mode (with 5-second cache)
---@return string|nil Focus mode name or nil if no focus active
local function getCurrentFocusMode()
  local now = os.time()

  -- Return cached value if still valid
  if focusModeCache.timestamp + focusModeCache.ttl > now then
    return focusModeCache.mode
  end

  -- Fetch fresh focus mode status via JXA script
  local output, status = hs.execute(os.getenv("HOME") .. "/.dotfiles/bin/get-focus-mode 2>/dev/null")

  if status then
    local mode = output and output:match("^%s*(.-)%s*$") or nil
    if mode == "" or mode == "No focus" then
      focusModeCache.mode = nil
    else
      focusModeCache.mode = mode
    end
  else
    focusModeCache.mode = nil
  end

  focusModeCache.timestamp = now
  return focusModeCache.mode
end

--------------------------------------------------------------------------------
-- NOTIFICATION PROCESSING
--------------------------------------------------------------------------------

---@class ProcessOpts
---@field title string Notification title
---@field subtitle? string Notification subtitle (default: "")
---@field message string Notification message body
---@field axStackingID? string Full AX stacking identifier from notification center
---@field bundleID? string Parsed bundle ID from stacking identifier
---@field notificationID? string UUID from AXIdentifier
---@field notificationType? string "system" | "app"
---@field subrole? string AXSubrole value
---@field matchedCriteria? string JSON string of what matched (for logging)
---@field urgency? string "critical"|"high"|"normal"|"low" (default: "normal")
---@field notificationElement? userdata AX element reference for dismissing native notification

---Processes a notification according to rule configuration
---Handles focus mode checks, urgency-based rendering, and phone delivery
---@param rule NotificationRule The notification rule configuration
---@param opts ProcessOpts Notification content and metadata
function M.process(rule, opts)
  local db = require("lib.db").notifications
  local menubar = require("lib.notifications.menubar")
  local timestamp = os.time()

  -- Apply defaults
  opts = U.defaults(opts, {
    title = "",
    subtitle = "",
    message = "",
    urgency = "normal",
  })

  -- Local aliases for readability
  local title = opts.title
  local subtitle = opts.subtitle
  local message = opts.message
  local axStackingID = opts.axStackingID
  local bundleID = opts.bundleID
  local notificationID = opts.notificationID
  local notificationType = opts.notificationType
  local subrole = opts.subrole
  local matchedCriteria = opts.matchedCriteria
  local urgency = opts.urgency

  -- Check focus mode
  -- When no focus mode is active → always show (default behavior)
  -- When focus mode IS active → only show if overrideFocusModes allows it
  -- excludeFocusModes takes precedence (block even if overrideFocusModes would allow)
  local currentFocus = getCurrentFocusMode()
  local focusAllowed = false

  if currentFocus == nil then
    -- No focus mode active - always allow
    focusAllowed = true
  elseif rule.overrideFocusModes == true then
    -- Override ALL focus modes
    focusAllowed = true
  elseif type(rule.overrideFocusModes) == "table" then
    -- Check if current focus mode is in the override list
    for _, mode in ipairs(rule.overrideFocusModes) do
      if mode == currentFocus then
        focusAllowed = true
        break
      end
    end
  else
    -- Focus mode is active and no overrides defined - block
    focusAllowed = false
  end

  -- Check exclusion list (takes precedence over overrideFocusModes)
  if focusAllowed and currentFocus and type(rule.excludeFocusModes) == "table" then
    for _, mode in ipairs(rule.excludeFocusModes) do
      if mode == currentFocus then
        focusAllowed = false
        break
      end
    end
  end

  if not focusAllowed then
    -- Dismiss native notification if configured (rule-level or global default)
    local shouldDismissInFocus = rule.dismissInFocusModes
    if shouldDismissInFocus == nil then
      shouldDismissInFocus = C.notifier.dismissInFocusModes or false
    end

    local dismissedNative = false
    if shouldDismissInFocus and opts.notificationElement then
      dismissedNative = dismiss.dismiss(opts.notificationElement, title)
      if dismissedNative then
        U.log.df("Dismissed native notification (focus mode %s): %s", currentFocus, title or "untitled")
      end
    end

    db.log({
      timestamp = timestamp,
      notification_id = notificationID,
      rule_name = rule.name,
      app_id = axStackingID,
      notification_type = notificationType,
      subrole = subrole,
      match_criteria = matchedCriteria,
      title = title,
      sender = title,
      subtitle = subtitle,
      message = message,
      action = "blocked",
      action_detail = dismissedNative and "blocked_by_focus_dismissed" or "blocked_by_focus",
      priority = urgency,
      focus_mode = currentFocus,
      shown = false,
    })
    menubar.update()
    return
  end

  -- Check urgency-based app focus rules (only for high/critical urgency)
  if urgency == "high" or urgency == "critical" then
    local priorityCheck = shouldShowHighPriority(bundleID, {
      alwaysShowInTerminal = rule.alwaysShowInTerminal,
      showWhenAppFocused = rule.showWhenAppFocused,
    })

    if not priorityCheck.shouldShow then
      db.log({
        timestamp = timestamp,
        notification_id = notificationID,
        rule_name = rule.name,
        app_id = axStackingID,
        notification_type = notificationType,
        subrole = subrole,
        match_criteria = matchedCriteria,
        title = title,
        sender = title,
        subtitle = subtitle,
        message = message,
        action = "blocked",
        action_detail = "blocked_" .. priorityCheck.reason,
        priority = urgency,
        focus_mode = currentFocus,
        shown = false,
      })
      menubar.update()
      return
    end
  end

  -- Get urgency display settings from config
  local urgencyConfig = C.notifier.urgencyDisplay[urgency] or C.notifier.urgencyDisplay.normal

  -- Calculate duration with urgency multiplier
  local baseDuration = rule.duration or C.notifier.defaultDuration or 5
  local duration = baseDuration * (urgencyConfig.durationMultiplier or 1.0)

  -- Build notification config based on urgency
  local iconBundleID = rule.appImageID or bundleID

  -- Determine if notification content will be redacted (redaction logic)
  -- Redaction occurs in DND or Work focus modes to hide sensitive content
  local shouldRedact = currentFocus == "Do Not Disturb" or currentFocus == "Work"

  -- Redact message content if in focus mode
  local displayMessage = message
  if shouldRedact and message then
    local redacted = ""
    for i = 1, #message do
      local c = message:sub(i, i)
      if c == " " or c == "\n" or c == "\r" then
        redacted = redacted .. c
      else
        redacted = redacted .. "•"
      end
    end
    displayMessage = redacted
  end

  -- Map position: center for critical/high, bottom-left for normal/low
  local hudPosition = urgencyConfig.position == "center" and "center" or "bottom-left"

  -- Show HUD toast notification
  HUD.toast({
    title = title,
    subtitle = subtitle,
    message = displayMessage,
    appBundleID = iconBundleID,
    duration = duration,
    position = hudPosition,
    dim = urgencyConfig.dim or false,
    dimAlpha = 0.5,
  })

  -- Determine if we should dismiss the native macOS notification
  -- Priority: rule.dismissNative > global dismissNativeOnRedirect > false
  -- Also force dismiss when content is redacted (to prevent showing unredacted content in Notification Center)
  local shouldDismissNative = shouldRedact -- Always dismiss when redacting
  if not shouldDismissNative then
    -- Check rule-level override first, then global default
    if rule.dismissNative ~= nil then
      shouldDismissNative = rule.dismissNative
    else
      shouldDismissNative = C.notifier.dismissNativeOnRedirect or false
    end
  end

  -- Dismiss native notification if configured
  if shouldDismissNative and opts.notificationElement then
    local dismissSuccess = dismiss.dismiss(opts.notificationElement, title)
    local reason = shouldRedact and "redaction" or "redirect"
    if dismissSuccess then
      U.log.df("Dismissed native notification (%s): %s", reason, title or "untitled")
    else
      U.log.wf("Failed to dismiss native notification (%s): %s", reason, title or "untitled")
    end
  end

  -- Handle phone delivery for critical urgency
  if urgencyConfig.phone then
    -- Send to phone via ntfy CLI
    local phoneTitle = title ~= "" and title or "Notification"
    local phoneMessage = message ~= "" and message or subtitle
    local cmd = string.format(
      '~/bin/ntfy send -t "%s" -m "%s" -u critical -p',
      phoneTitle:gsub('"', '\\"'),
      phoneMessage:gsub('"', '\\"')
    )
    hs.execute(cmd, true)
    U.log.nf("Critical urgency: sent to phone - %s", phoneTitle)
  end

  -- Determine action_detail for logging
  local actionDetail = "shown_bottom_left"
  if urgencyConfig.position == "center" then
    actionDetail = urgencyConfig.phone and "shown_center_dimmed_phone" or "shown_center_dimmed"
  end
  -- Add suffix for redaction or native dismissal
  if shouldRedact then
    actionDetail = actionDetail .. "_redacted"
  elseif shouldDismissNative then
    actionDetail = actionDetail .. "_native_dismissed"
  end

  db.log({
    timestamp = timestamp,
    notification_id = notificationID,
    rule_name = rule.name,
    app_id = axStackingID,
    notification_type = notificationType,
    subrole = subrole,
    match_criteria = matchedCriteria,
    title = title,
    sender = title,
    subtitle = subtitle,
    message = message,
    action = "redirect",
    action_detail = actionDetail,
    priority = urgency,
    focus_mode = currentFocus,
    shown = true,
  })

  menubar.update()
end

return M
