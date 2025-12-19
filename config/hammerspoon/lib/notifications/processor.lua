-- Notification Rule Processing
-- Business logic for handling notification routing, priority, and focus mode checks
--
local M = {}
local fmt = string.format

---Processes a notification according to rule configuration
---Handles pattern matching, focus mode checks, priority logic, and rendering
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
function M.process(rule, title, subtitle, message, axStackingID, bundleID, notificationID, notificationType, subrole, matchedCriteria)
  local notify = require("lib.notifications.notifier")
  local db = require("lib.notifications.db")
  local menubar = require("lib.notifications.menubar")
  local timestamp = os.time()
  
  -- Determine action (default: redirect for backward compat)
  local action = rule.action or "redirect"

  -- Determine priority based on pattern matching
  local effectivePriority = "normal" -- default

  if rule.patterns and message then
    -- Check each priority level for matching patterns
    -- Iterate in priority order: high -> normal -> low
    for _, priority in ipairs({ "high", "normal", "low" }) do
      local patternList = rule.patterns[priority]
      if patternList then
        for _, pattern in ipairs(patternList) do
          if message:find(pattern) then
            effectivePriority = priority
            goto priority_determined -- exit both loops
          end
        end
      end
    end
    ::priority_determined::
  end

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
      priority = effectivePriority,
      focus_mode = currentFocus,
      shown = false,
    })
    -- Update menubar indicator
    menubar.update()
    return
  end

  -- Check priority-based app focus rules (only for high priority)
  if effectivePriority == "high" then
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
        priority = effectivePriority,
        focus_mode = currentFocus,
        shown = false,
      })
      -- Update menubar indicator
      menubar.update()
      return
    end
  end

  -- Determine notification config based on priority
  local duration = rule.duration or (effectivePriority == "high" and 15 or effectivePriority == "low" and 3 or 10)
  local notifConfig = {}

  -- Fallback chain for icon: appImageID → bundleID → rule.appBundleID
  local iconBundleID = rule.appImageID or bundleID or rule.appBundleID

  -- Fallback chain for launching: bundleID → rule.appBundleID
  local launchBundleID = bundleID or rule.appBundleID

  if effectivePriority == "high" then
    notifConfig = {
      anchor = "window",
      position = "C",
      dimBackground = true,
      dimAlpha = 0.6,
      includeProgram = false,
      appImageID = iconBundleID,
      appBundleID = launchBundleID,
      priority = "high",
    }
  else
    notifConfig = {
      anchor = "screen",
      position = "SW",
      dimBackground = false,
      includeProgram = false,
      appImageID = iconBundleID,
      appBundleID = launchBundleID,
      priority = effectivePriority,
    }
  end

  -- Determine action (default: redirect for backward compat)
  local action = rule.action or "redirect"
  
  -- Handle different actions
  if action == "dismiss" then
    -- Dismiss: log but don't show
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
      action = "dismiss",
      action_detail = "dismissed_by_rule",
      priority = effectivePriority,
      focus_mode = currentFocus,
      shown = false,
    })
    menubar.update()
    return
  elseif action == "ignore" then
    -- Ignore: don't log, don't show (silent drop)
    return
  elseif action == "redirect" then
    -- Redirect: show via canvas (original behavior)
    notify.sendCanvasNotification(title, subtitle, message, duration, notifConfig)
    
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
      action_detail = effectivePriority == "high" and "shown_center_dimmed" or "shown_bottom_left",
      priority = effectivePriority,
      focus_mode = currentFocus,
      shown = true,
    })
  else
    -- Unknown action, log warning and fall back to redirect
    U.log.wf("Unknown action '%s' in rule '%s', falling back to redirect", action, rule.name)
    notify.sendCanvasNotification(title, subtitle, message, duration, notifConfig)
    
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
      action_detail = "unknown_action_fallback",
      priority = effectivePriority,
      focus_mode = currentFocus,
      shown = true,
    })
  end
end

return M
