-- Notification Rule Processing
-- Business logic for handling notification routing, urgency, and focus mode checks
--
local M = {}

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

---Processes a notification according to rule configuration
---Handles focus mode checks, urgency-based rendering, and phone delivery
---@param rule NotificationRule The notification rule configuration
---@param opts ProcessOpts Notification content and metadata
function M.process(rule, opts)
  local notify = require("lib.notifications.notifier")
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
    subtitle = subtitle,
    duration = duration,
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
  notify.sendCanvasNotification(title, message, notifConfig)

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
