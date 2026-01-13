-- Notification Watcher - Intercepts macOS Notification Center notifications
-- Uses accessibility API (AXUIElement) to monitor notification banners/alerts
-- Based on proven approach: https://stackoverflow.com/questions/45593529
--
local fmt = string.format
local M = {}

M.observer = nil
M.processedNotificationIDs = {}
M.cleanupTimer = nil
M.processWatcher = nil
M.persistentScanTimer = nil  -- Timer for periodic persistent notification scanning
M.currentPID = nil

-- Track first-seen times for notifications pending delayed dismissal
-- { [notificationID] = { firstSeen = timestamp, rule = matchedRule } }
M.pendingDismissals = {}

-- Maximum number of stored notification IDs before cleanup
local MAX_PROCESSED_IDS = 100

-- Notification subroles we care about
local notificationSubroles = {
  AXNotificationCenterAlert = true,
  AXNotificationCenterBanner = true,
}

-- Detect notification type based on stackingID format
-- Returns: "system" if no bundleIdentifier, "app" otherwise
local function detectNotificationType(stackingID)
  if not stackingID or stackingID == "unknown" then return "unknown" end
  
  -- System notifications have UUID-only stackingIDs (no bundleIdentifier= prefix)
  if not stackingID:match("bundleIdentifier=") then
    return "system"
  end
  
  return "app"
end

-- Helper to count table keys (Hammerspoon doesn't have vim.tbl_count)
local function tableCount(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- Match a single field value against a pattern or array of patterns
-- bundleID uses exact matching; other fields use Lua pattern matching
local function matchField(fieldName, value, pattern)
  if not pattern then return true end -- No pattern = wildcard match
  if not value then return false end -- No value to match against
  
  -- Pattern is an array = OR logic (match any)
  if type(pattern) == "table" then
    for _, p in ipairs(pattern) do
      if matchField(fieldName, value, p) then return true end
    end
    return false
  end
  
  -- bundleID uses exact string matching (not pattern matching)
  if fieldName == "bundleID" then
    return value == pattern
  end
  
  -- Other fields use Lua pattern matching
  return value:match(pattern) ~= nil
end

-- Match notification against rule's match criteria
-- Returns: true if matches, false otherwise
-- match = { title = "...", message = "...", bundleID = {...}, etc }
-- Multiple fields = AND, array values = OR within field
local function matchesRule(notifData, matchCriteria)
  if not matchCriteria then return false end
  
  -- Check each field in match criteria (all must match = AND)
  for field, pattern in pairs(matchCriteria) do
    local value = notifData[field]
    if not matchField(field, value, pattern) then
      return false -- Field didn't match, rule fails
    end
  end
  
  return true -- All fields matched
end

-- Resolve urgency from rule + notification content
-- urgency can be: string ("normal") or table ({ default = "normal", high = {...}, ... })
local function resolveUrgency(rule, notifData)
  local urgency = rule.urgency or "normal"
  
  -- Simple string = static urgency
  if type(urgency) == "string" then return urgency end
  
  -- Table form: check patterns in priority order (critical → high → normal → low)
  local content = ((notifData.message or "") .. " " .. (notifData.subtitle or "")):lower()
  
  for _, level in ipairs({ "critical", "high", "normal", "low" }) do
    local patterns = urgency[level]
    if patterns then
      for _, pattern in ipairs(patterns) do
        if content:match(pattern:lower()) then return level end
      end
    end
  end
  
  return urgency.default or "normal"
end

-- Sort rules by priority (higher first), then by specificity (more match conditions first)
local function sortRulesByPriority(rules)
  table.sort(rules, function(a, b)
    local aPriority = a.priority or 50
    local bPriority = b.priority or 50
    if aPriority ~= bPriority then return aPriority > bPriority end
    
    -- Tie-breaker: more specific rules first
    local aConditions = a.match and tableCount(a.match) or 0
    local bConditions = b.match and tableCount(b.match) or 0
    return aConditions > bConditions
  end)
  return rules
end

-- Dismiss a notification by performing Close action or clicking close button
-- @param notificationElement: AX element of the notification
-- @param title: Notification title (for logging)
-- @return boolean: true if dismissed successfully, false otherwise
local function dismissNotification(notificationElement, title)
  if not notificationElement then
    U.log.wf("Cannot dismiss notification - no element reference: %s", title or "unknown")
    return false
  end
  
  -- First, try to find a "Close" action directly on the notification element
  -- macOS Sequoia exposes Close as a named action on AXNotificationCenterAlert
  local actions = notificationElement:actionNames() or {}
  for _, action in ipairs(actions) do
    if action:lower():match("close") then
      U.log.df("Dismissing notification via Close action: %s", title or "unknown")
      local success, err = pcall(function()
        notificationElement:performAction(action)
      end)
      if success then
        return true
      else
        U.log.wf("Close action failed: %s, trying button fallback", tostring(err))
      end
    end
  end
  
  -- Fallback: Recursively search for close button (older macOS style)
  local function findCloseButton(element, depth)
    depth = depth or 0
    if depth > 8 then return nil end -- Prevent infinite recursion
    
    -- Check if this element is a close button
    if element.AXRole == "AXButton" then
      local desc = element.AXDescription or ""
      local buttonTitle = element.AXTitle or ""
      
      -- Look for "Close" in description or title (case-insensitive)
      if desc:lower():match("close") or buttonTitle:lower():match("close") then
        return element
      end
    end
    
    -- Recurse into children
    local children = element:attributeValue("AXChildren") or {}
    for _, child in ipairs(children) do
      local found = findCloseButton(child, depth + 1)
      if found then return found end
    end
    
    return nil
  end
  
  local closeButton = findCloseButton(notificationElement)
  
  if closeButton then
    U.log.df("Dismissing notification via close button: %s", title or "unknown")
    
    local success, err = pcall(function()
      closeButton:performAction("AXPress")
    end)
    
    if success then
      return true
    else
      U.log.ef("Failed to perform AXPress on close button: %s", tostring(err))
      return false
    end
  end
  
  U.log.wf("Could not find close action or button for notification: %s", title or "unknown")
  return false
end

-- Find nested notification element in macOS Sequoia's new structure
-- Sequoia wraps notifications in AXSystemDialog > AXHostingView > ... > AXNotificationCenterAlert
local function findNotificationElement(element, depth)
  depth = depth or 0
  if depth > 6 then return nil end -- Prevent infinite recursion

  local subrole = element.AXSubrole
  if notificationSubroles[subrole] then
    return element
  end

  -- Recurse into children
  local children = element:attributeValue("AXChildren") or {}
  for _, child in ipairs(children) do
    local found = findNotificationElement(child, depth + 1)
    if found then return found end
  end

  return nil
end

-- Process a notification that appeared in Notification Center
local function handleNotification(element)
  -- Skip if notification drawer is open (user is already looking at notifications)
  local ncApp = hs.application.find("com.apple.notificationcenterui")
  if ncApp then
    local notificationCenter = hs.axuielement.applicationElement(ncApp)
    if notificationCenter and notificationCenter:asHSApplication():focusedWindow() then return end
  end

  -- macOS Sequoia (15+) changed notification structure:
  -- Events fire with AXSystemDialog at the top level, but the actual
  -- AXNotificationCenterAlert/Banner is nested inside. We need to traverse.
  local notificationElement = element
  if element.AXSubrole == "AXSystemDialog" then
    notificationElement = findNotificationElement(element)
    if not notificationElement then return end -- No notification found in tree
  end

  -- Get notification ID
  local notificationID = notificationElement.AXIdentifier or hs.host.uuid()
  if not notificationSubroles[notificationElement.AXSubrole] then return end
  
  -- Check if this notification has a pending delayed dismissal
  if M.pendingDismissals[notificationID] then
    local tracked = M.pendingDismissals[notificationID]
    local age = os.time() - tracked.firstSeen
    local dismissDelay = tracked.rule and tracked.rule.delay or 0
    
    if age >= dismissDelay then
      -- Delay elapsed, dismiss now
      U.log.df("Delay elapsed (%ds >= %ds), dismissing: %s", age, dismissDelay, tracked.title or "untitled")
      local success = dismissNotification(notificationElement, tracked.title)
      M.pendingDismissals[notificationID] = nil
      
      -- Log dismissal to database
      local db = require("lib.db").notifications
      db.log({
        timestamp = os.time(),
        notification_id = notificationID,
        rule_name = tracked.rule and tracked.rule.name or "unknown",
        app_id = notificationElement.AXStackingIdentifier or "unknown",
        notification_type = "system",
        subrole = notificationElement.AXSubrole or "unknown",
        match_criteria = nil,
        title = tracked.title,
        sender = tracked.title,
        subtitle = nil,
        message = nil,
        action = "dismiss",
        action_detail = success and "dismissed_after_delay" or "dismiss_failed",
        priority = "low",
        focus_mode = nil,
        shown = false,
      })
      
      require("lib.notifications.menubar").update()
    end
    return -- Already being tracked, don't re-process
  end
  
  -- Skip if already processed (and not pending dismissal)
  if M.processedNotificationIDs[notificationID] then return end
  M.processedNotificationIDs[notificationID] = true

  -- Get the AX stacking identifier to determine which app sent the notification
  -- Use notificationElement (the actual alert/banner), not the outer container
  -- Format: bundleIdentifier=com.example.app,threadIdentifier=...
  local axStackingID = notificationElement.AXStackingIdentifier or "unknown"
  local subrole = notificationElement.AXSubrole or "unknown"

  -- Extract bundle ID from AX stacking identifier
  -- Try to extract bundleIdentifier value first, fallback to simple extraction
  local bundleID = axStackingID:match("bundleIdentifier=([^,;%s]+)") or axStackingID:match("^([^;%s]+)") or axStackingID
  
  -- Detect notification type (system vs app)
  local notificationType = detectNotificationType(axStackingID)

  -- Extract notification text elements from the actual notification element
  local staticTexts = hs.fnutils.imap(
    hs.fnutils.ifilter(notificationElement, function(value) return value.AXRole == "AXStaticText" end),
    function(value) return value.AXValue end
  )

  local title, subtitle, message = nil, nil, nil
  if #staticTexts == 2 then
    title, message = table.unpack(staticTexts)
  elseif #staticTexts == 3 then
    title, subtitle, message = table.unpack(staticTexts)
  elseif #staticTexts >= 4 then
    -- Fantastical (and possibly other apps) send 4+ texts:
    -- [1] = alert type ("TIME SENSITIVE" or app name)
    -- [2] = event title
    -- [3] = time
    -- [4] = location/URL
    title = staticTexts[1]
    subtitle = staticTexts[2]
    message = staticTexts[3] .. (staticTexts[4] and (" • " .. staticTexts[4]) or "")
  end

  -- Build notification data object for matching
  local notifData = {
    title = title,
    subtitle = subtitle,
    message = message,
    bundleID = bundleID,
    axStackingID = axStackingID,
    notificationType = notificationType,
    subrole = subrole,
    notificationID = notificationID,
  }

  -- Process routing rules (sorted by priority, first match wins)
  local rules = sortRulesByPriority(C.notifier.rules or {})

  for _, rule in ipairs(rules) do
    local matched = false
    local matchedCriteria = nil
    
    -- Match against rule's match criteria
    if rule.match then
      matched = matchesRule(notifData, rule.match)
      if matched then
        matchedCriteria = hs.json.encode(rule.match)
      end
    end

    if matched then
      -- Resolve urgency based on rule config and notification content
      local resolvedUrgency = resolveUrgency(rule, notifData)
      
      -- Rule matched! Log match details (use print for guaranteed visibility)
      local action = rule.action or "redirect"
      print(string.format("[notification] %s: %s -> urgency=%s, action=%s", 
        rule.name, title or bundleID, resolvedUrgency, action))
      U.log.nf("%s: %s [ID=%s, type=%s, urgency=%s, action=%s]", 
        rule.name, title or bundleID, 
        tostring(notificationID or "nil"), 
        tostring(notificationType or "nil"), 
        resolvedUrgency,
        action)

      local timestamp = os.time()
      
      -- Handle different actions
      if action == "dismiss" then
        -- DISMISS: Find and click close button
        -- Check if rule specifies a delay before dismissing
        local dismissDelay = rule.delay or 0
        
        if dismissDelay > 0 then
          -- Track for delayed dismissal
          if not M.pendingDismissals[notificationID] then
            M.pendingDismissals[notificationID] = {
              firstSeen = timestamp,
              rule = rule,
              title = title,
              element = notificationElement,
            }
            U.log.df("Tracking notification for delayed dismiss (%ds): %s", dismissDelay, title or "untitled")
          else
            -- Already tracking - check if delay has elapsed
            local tracked = M.pendingDismissals[notificationID]
            local age = timestamp - tracked.firstSeen
            
            if age >= dismissDelay then
              -- Delay elapsed, dismiss now
              U.log.df("Delay elapsed (%ds >= %ds), dismissing: %s", age, dismissDelay, title or "untitled")
              local success = dismissNotification(notificationElement, title)
              M.pendingDismissals[notificationID] = nil
              
              -- Log dismissal to database
              local db = require("lib.db").notifications
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
                action_detail = success and "dismissed_after_delay" or "dismiss_failed",
                priority = "normal",
                focus_mode = nil,
                shown = false,
              })
              
              require("lib.notifications.menubar").update()
            else
              U.log.df("Waiting to dismiss (%ds / %ds): %s", age, dismissDelay, title or "untitled")
            end
          end
        else
          -- No delay - dismiss immediately
          local success = dismissNotification(notificationElement, title)
          
          -- Log dismissal to database
          local db = require("lib.db").notifications
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
            action_detail = success and "dismissed_via_close_button" or "dismiss_failed",
            priority = "normal",
            focus_mode = nil,
            shown = false,
          })
          
          require("lib.notifications.menubar").update()
        end
        
      elseif action == "ignore" then
        -- IGNORE: Silent drop (no logging, no display)
        U.log.df("Ignoring notification per rule: %s", rule.name)
        
      else
        -- REDIRECT (default): Delegate to processor for canvas display
        local ok, err = pcall(N.process, rule, {
          title = title,
          subtitle = subtitle,
          message = message,
          axStackingID = axStackingID,
          bundleID = bundleID,
          notificationID = notificationID,
          notificationType = notificationType,
          subrole = subrole,
          matchedCriteria = matchedCriteria,
          urgency = resolvedUrgency,
        })

        if not ok then U.log.ef("Error processing rule '%s': %s", rule.name, tostring(err)) end
      end

      -- First match wins - stop processing rules
      return
    end
  end
end

-- Helper to start/restart the AX observer
local function startObserver()
  local ncApp = hs.application.find("com.apple.notificationcenterui")
  if not ncApp then
    U.log.e("Unable to find Notification Center application")
    return false
  end

  local notificationCenter = hs.axuielement.applicationElement(ncApp)
  if not notificationCenter then
    U.log.e("Unable to get Notification Center AX element")
    return false
  end

  local ncPID = notificationCenter:pid()

  -- Check if we're already watching this PID
  if M.currentPID == ncPID and M.observer then return true end

  -- Stop old observer if it exists
  if M.observer then
    U.log.wf("NC PID changed: %d → %d, recreating observer", M.currentPID or 0, ncPID)
    pcall(function() M.observer:stop() end)
    M.observer = nil
  end

  M.currentPID = ncPID

  -- Create observer for layout changes
  -- NOTE: Using both AXLayoutChanged and AXCreated for maximum compatibility
  -- AXCreated was mentioned as more reliable in some cases
  M.observer = hs.axuielement.observer
    .new(ncPID)
    :callback(function(_, element) handleNotification(element) end)
    :addWatcher(notificationCenter, "AXLayoutChanged")
    :addWatcher(notificationCenter, "AXCreated")
    :start()
  return true
end

-- Extract text content from notification element
local function extractNotificationText(notificationElement)
  local staticTexts = {}
  local children = notificationElement:attributeValue("AXChildren") or {}
  
  for _, child in ipairs(children) do
    if child.AXRole == "AXStaticText" and child.AXValue then
      table.insert(staticTexts, child.AXValue)
    end
  end
  
  local title = staticTexts[1] or ""
  local message = table.concat(staticTexts, " ", 2) or ""
  
  return title, message
end

-- Find matching dismiss rule for a notification
local function findDismissRule(title, message, bundleID, notificationType, subrole)
  local notifData = {
    title = title,
    message = message,
    bundleID = bundleID,
    notificationType = notificationType,
    subrole = subrole,
  }
  
  local rules = sortRulesByPriority(C.notifier.rules or {})
  
  for _, rule in ipairs(rules) do
    if rule.action == "dismiss" and rule.match then
      if matchesRule(notifData, rule.match) then
        return rule
      end
    end
  end
  
  return nil
end

-- Scan for existing persistent notifications and handle delayed dismissals
-- This catches system notifications that were already present before Hammerspoon loaded
-- and processes delayed dismissals in a self-contained loop
local function scanExistingNotifications()
  local ncApp = hs.application.find("com.apple.notificationcenterui")
  if not ncApp then return end
  
  local notificationCenter = hs.axuielement.applicationElement(ncApp)
  if not notificationCenter then return end
  
  local windows = notificationCenter:attributeValue("AXWindows") or {}
  if #windows == 0 then return end
  
  local now = os.time()
  local seenIDs = {}
  local processedCount = 0
  local dismissedCount = 0
  
  -- Recursively find all notification elements
  local function processNotificationElement(element, depth)
    depth = depth or 0
    if depth > 8 then return end
    
    local subrole = element.AXSubrole or ""
    
    if subrole == "AXNotificationCenterAlert" or subrole == "AXNotificationCenterBanner" then
      local notifID = element.AXIdentifier
      if not notifID then return end
      
      seenIDs[notifID] = true
      
      -- Extract notification content
      local title, message = extractNotificationText(element)
      local axStackingID = element.AXStackingIdentifier or "unknown"
      local bundleID = axStackingID:match("bundleIdentifier=([^,;%s]+)") or axStackingID:match("^([^;%s]+)") or axStackingID
      local notificationType = detectNotificationType(axStackingID)
      
      -- Check if this notification has a pending delayed dismissal
      if M.pendingDismissals[notifID] then
        local tracked = M.pendingDismissals[notifID]
        local age = now - tracked.firstSeen
        local dismissDelay = tracked.rule and tracked.rule.delay or 0
        
        if age >= dismissDelay then
          -- Delay elapsed, dismiss now via close button
          U.log.nf("Dismissing after %ds: %s", age, title)
          
          local success = dismissNotification(element, title)
          
          if success then
            dismissedCount = dismissedCount + 1
            
            -- Log to database
            local db = require("lib.db").notifications
            db.log({
              timestamp = now,
              notification_id = notifID,
              rule_name = tracked.rule and tracked.rule.name or "unknown",
              app_id = axStackingID,
              notification_type = notificationType,
              subrole = subrole,
              match_criteria = nil,
              title = title,
              sender = title,
              subtitle = nil,
              message = message,
              action = "dismiss",
              action_detail = "dismissed_after_delay",
              priority = "low",
              focus_mode = nil,
              shown = false,
            })
            
            require("lib.notifications.menubar").update()
          end
          
          M.pendingDismissals[notifID] = nil
        end
        return -- Already being tracked
      end
      
      -- Skip if already processed for non-dismiss actions
      if M.processedNotificationIDs[notifID] then return end
      
      -- Check if this matches a dismiss rule
      local dismissRule = findDismissRule(title, message, bundleID, notificationType, subrole)
      
      if dismissRule then
        local dismissDelay = dismissRule.delay or 0
        
        if dismissDelay > 0 then
          -- Track for delayed dismissal
          M.pendingDismissals[notifID] = {
            firstSeen = now,
            rule = dismissRule,
            title = title,
          }
          U.log.df("Tracking for delayed dismiss (%ds): %s", dismissDelay, title)
        else
          -- Dismiss immediately via close button
          U.log.nf("Dismissing immediately: %s", title)
          
          local success = dismissNotification(element, title)
          
          if success then
            dismissedCount = dismissedCount + 1
            
            local db = require("lib.db").notifications
            db.log({
              timestamp = now,
              notification_id = notifID,
              rule_name = dismissRule.name,
              app_id = axStackingID,
              notification_type = notificationType,
              subrole = subrole,
              match_criteria = hs.json.encode(dismissRule.match),
              title = title,
              sender = title,
              subtitle = nil,
              message = message,
              action = "dismiss",
              action_detail = "dismissed_via_axpress",
              priority = "low",
              focus_mode = nil,
              shown = false,
            })
            
            require("lib.notifications.menubar").update()
          end
        end
        
        M.processedNotificationIDs[notifID] = true
      else
        -- Not a dismiss rule - process normally via handleNotification
        pcall(function()
          handleNotification(element)
        end)
      end
      
      processedCount = processedCount + 1
      return -- Don't recurse into notification children
    end
    
    -- Recurse into children
    for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
      processNotificationElement(child, depth + 1)
    end
  end
  
  for _, window in ipairs(windows) do
    processNotificationElement(window, 0)
  end
  
  -- Cleanup stale pending dismissals (notification no longer present)
  for notifID, tracked in pairs(M.pendingDismissals) do
    if not seenIDs[notifID] then
      U.log.df("Notification gone, removing from tracking: %s", tracked.title)
      M.pendingDismissals[notifID] = nil
    end
  end
  
  if dismissedCount > 0 then
    U.log.nf("Dismissed %d notification(s)", dismissedCount)
  end
end

function M:start()
  -- Start the observer
  if not startObserver() then
    U.log.e("Failed to start notification observer")
    return
  end
  
  -- Scan for existing notifications after a short delay (let system settle)
  hs.timer.doAfter(2, function()
    scanExistingNotifications()
  end)

  -- Optional: Periodic scanning for persistent notifications
  -- Useful for catching system alerts that don't trigger AX events
  local persistentConfig = C.notifier.persistentScanner or {}
  if persistentConfig.enabled then
    local scanInterval = persistentConfig.scanInterval or 10
    M.persistentScanTimer = hs.timer.doEvery(scanInterval, function()
      scanExistingNotifications()
    end)
    U.log.df("Periodic persistent notification scanning enabled (every %ds)", scanInterval)
  end

  -- Monitor Notification Center process for restarts
  -- Check every 30 seconds if NC has restarted (PID changed)
  M.processWatcher = hs.timer.doEvery(30, function()
    -- Must get hs.application object first, then pass to applicationElement
    -- Passing bundle ID string directly is unreliable in timer callbacks
    local ncApp = hs.application.find("com.apple.notificationcenterui")
    if not ncApp then
      U.log.w("Notification Center not found during health check")
      return
    end

    local nc = hs.axuielement.applicationElement(ncApp)
    if nc then
      local currentPID = nc:pid()
      if currentPID ~= M.currentPID then
        U.log.wf("Notification Center restarted (PID %d → %d), recreating observer", M.currentPID or 0, currentPID)
        startObserver()
      end
    else
      U.log.w("Failed to get AX element for Notification Center")
    end
  end)

  -- Periodic cleanup of notification ID cache (every 5 minutes)
  M.cleanupTimer = hs.timer.doEvery(300, function()
    local count = 0
    for _ in pairs(M.processedNotificationIDs) do
      count = count + 1
    end

    if count > MAX_PROCESSED_IDS then M.processedNotificationIDs = {} end
  end)

  U.log.i("started")
end

function M:stop()
  if M.observer then
    pcall(function() M.observer:stop() end)
    M.observer = nil
  end

  if M.processWatcher then
    M.processWatcher:stop()
    M.processWatcher = nil
  end

  if M.cleanupTimer then
    M.cleanupTimer:stop()
    M.cleanupTimer = nil
  end

  if M.persistentScanTimer then
    M.persistentScanTimer:stop()
    M.persistentScanTimer = nil
  end

  M.currentPID = nil
  M.pendingDismissals = {}
  M.processedNotificationIDs = {}
  U.log.i("stopped")
end

return M
