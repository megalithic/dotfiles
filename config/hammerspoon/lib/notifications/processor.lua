-- Notification Rule Processing
-- Business logic for handling notification routing, urgency, and focus mode checks
--
local M = {}

---Processes a notification according to rule configuration
---Handles focus mode checks, urgency-based rendering, and phone delivery
---@param rule NotificationRule The notification rule configuration
---@param title string Notification title
---@param subtitle string Notification subtitle (may be empty)
---@param message string Notification message body
---@param axStackingID string Full AX stacking identifier from notification center
---@param bundleID string Parsed bundle ID from stacking identifier
---@param notificationID string|nil UUID from AXIdentifier
---@param notificationType string|nil "system" | "app"
---@param subrole string|nil AXSubrole value
---@param matchedCriteria string|nil JSON string of what matched (for logging)
---@param urgency string Resolved urgency level: "critical"|"high"|"normal"|"low"
function M.process(rule, title, subtitle, message, axStackingID, bundleID, notificationID, notificationType, subrole, matchedCriteria, urgency)
  local notify = require("lib.notifications.notifier")
  local db = require("lib.notifications.db")
  local menubar = require("lib.notifications.menubar")
  local timestamp = os.time()
  
  -- Urgency is now passed in from the watcher (resolved via rule.urgency config)
  urgency = urgency or "normal"

  -- Check focus mode
  -- When no focus mode is active → always show (default behavior)
  -- When focus mode IS active → only show if overrideFocusModes allows it
  local currentFocus = notify.getCurrentFocusMode and notify.getCurrentFocusMode() or nil
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

  if not focusAllowed then
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
      action_detail = "blocked_by_focus",
      priority = urgency,
      focus_mode = currentFocus,
      shown = false,
    })
    menubar.update()
    return
  end

  -- Check urgency-based app focus rules (only for high/critical urgency)
  if urgency == "high" or urgency == "critical" then
    local priorityCheck = notify.shouldShowHighPriority(bundleID, {
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
  local launchBundleID = bundleID
  
  local notifConfig = {
    includeProgram = false,
    appImageID = iconBundleID,
    appBundleID = launchBundleID,
    urgency = urgency,
  }
  
  if urgencyConfig.position == "center" then
    notifConfig.anchor = "window"
    notifConfig.position = "C"
    notifConfig.dimBackground = urgencyConfig.dim
    notifConfig.dimAlpha = 0.5
  else
    notifConfig.anchor = "screen"
    notifConfig.position = "SW"
    notifConfig.dimBackground = false
  end

  -- Show canvas notification
  notify.sendCanvasNotification(title, subtitle, message, duration, notifConfig)
  
  -- Handle phone delivery for critical urgency
  if urgencyConfig.phone then
    -- Send to phone via ntfy CLI
    local phoneTitle = title or "Notification"
    local phoneMessage = message or subtitle or ""
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
