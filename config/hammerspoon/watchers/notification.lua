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
M.currentPID = nil

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

-- Match a single field value against a pattern or array of patterns
-- Supports: exact string, Lua pattern, or array of patterns (OR logic)
local function matchField(value, pattern)
  if not pattern then return true end -- No pattern = wildcard match
  if not value then return false end -- No value to match against
  
  -- Pattern is an array = OR logic (match any)
  if type(pattern) == "table" then
    for _, p in ipairs(pattern) do
      if matchField(value, p) then return true end
    end
    return false
  end
  
  -- Pattern is a string = Lua pattern match
  return value:match(pattern) ~= nil
end

-- Match notification against new-style match criteria
-- Returns: true if matches, false otherwise
-- match = { title = "...", message = "...", bundleID = {...}, etc }
-- Multiple fields = AND, array values = OR within field
local function matchesNewRule(notifData, matchCriteria)
  if not matchCriteria then return false end
  
  -- Check each field in match criteria (all must match = AND)
  for field, pattern in pairs(matchCriteria) do
    local value = notifData[field]
    if not matchField(value, pattern) then
      return false -- Field didn't match, rule fails
    end
  end
  
  return true -- All fields matched
end

-- Match notification against old-style rule (backward compatibility)
-- Returns: true if matches, false otherwise
local function matchesOldRule(notifData, rule)
  -- Old rules use appBundleID + optional senders
  if not rule.appBundleID then return false end
  
  -- Check if axStackingID contains appBundleID
  local axStackingID = notifData.axStackingID or ""
  if not axStackingID:find(rule.appBundleID, 1, true) then
    return false
  end
  
  -- Check senders if specified
  if rule.senders then
    local title = notifData.title or ""
    local senderMatch = false
    for _, sender in ipairs(rule.senders) do
      if title == sender then
        senderMatch = true
        break
      end
    end
    if not senderMatch then return false end
  end
  
  return true
end

-- Dismiss a notification by finding and clicking its close button
-- @param notificationElement: AX element of the notification
-- @param title: Notification title (for logging)
-- @return boolean: true if dismissed successfully, false otherwise
local function dismissNotification(notificationElement, title)
  if not notificationElement then
    U.log.wf("Cannot dismiss notification - no element reference: %s", title or "unknown")
    return false
  end
  
  -- Recursively search for close button
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
    
    -- Click the close button (NOT AXPress on notification itself!)
    local success, err = pcall(function()
      closeButton:performAction("AXPress")
    end)
    
    if success then
      return true
    else
      U.log.ef("Failed to perform AXPress on close button: %s", tostring(err))
      return false
    end
  else
    U.log.wf("Could not find close button for notification: %s", title or "unknown")
    return false
  end
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

  -- Process each notification only once
  local notificationID = notificationElement.AXIdentifier or hs.host.uuid()
  if not notificationSubroles[notificationElement.AXSubrole] or M.processedNotificationIDs[notificationID] then return end

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

  -- DEBUG: Log what we extracted for Fantastical notifications
  if bundleID:find("flexibits", 1, true) then
    U.log.df("Fantastical notification: %d static texts found", #staticTexts)
    for i, text in ipairs(staticTexts) do
      U.log.df("  [%d]: %s", i, text or "nil")
    end

    -- Also check for other potential text attributes
    local desc = notificationElement:attributeValue("AXDescription")
    local value = notificationElement:attributeValue("AXValue")
    local title_attr = notificationElement:attributeValue("AXTitle")
    U.log.df("  AXDescription: %s", desc or "nil")
    U.log.df("  AXValue: %s", value or "nil")
    U.log.df("  AXTitle: %s", title_attr or "nil")

    -- Check all children for potential text
    local children = notificationElement:attributeValue("AXChildren") or {}
    U.log.df("  Total children: %d", #children)
    for i, child in ipairs(children) do
      local role = child.AXRole
      local childValue = child.AXValue
      local childDesc = child:attributeValue("AXDescription")
      if childValue or childDesc then
        U.log.df("    Child %d [%s]: value=%s, desc=%s", i, role or "?", tostring(childValue), tostring(childDesc))
      end
    end
  end

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
    sender = title, -- For backward compat (old rules use "sender")
    bundleID = bundleID,
    axStackingID = axStackingID,
    notificationType = notificationType,
    subrole = subrole,
    notificationID = notificationID,
  }

  -- Process routing rules (first match wins)
  local rules = C.notifier.rules or {}

  for _, rule in ipairs(rules) do
    local matched = false
    local matchedCriteria = nil
    
    -- Try new-style match criteria first
    if rule.match then
      matched = matchesNewRule(notifData, rule.match)
      if matched then
        -- Serialize match criteria for logging
        matchedCriteria = hs.json.encode(rule.match)
      end
    -- Fall back to old-style matching for backward compatibility
    elseif rule.appBundleID then
      matched = matchesOldRule(notifData, rule)
      if matched then
        -- Serialize old-style criteria
        local criteria = { appBundleID = rule.appBundleID }
        if rule.senders then criteria.senders = rule.senders end
        matchedCriteria = hs.json.encode(criteria)
      end
    end

    if matched then
      -- Rule matched! Log match details
      local action = rule.action or "redirect"
      U.log.nf("%s: %s [ID=%s, type=%s, criteria=%s, action=%s]", 
        rule.name, title or bundleID, 
        tostring(notificationID or "nil"), 
        tostring(notificationType or "nil"), 
        matchedCriteria or "nil",
        action)

      local timestamp = os.time()
      
      -- Handle different actions
      if action == "dismiss" then
        -- DISMISS: Find and click close button
        local success = dismissNotification(notificationElement, title)
        
        -- Log dismissal to database
        local db = require("lib.notifications.db")
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
          priority = "normal", -- dismissals don't have priority logic
          focus_mode = nil, -- could add getCurrentFocusMode() if needed
          shown = false,
        })
        
        -- Update menubar indicator
        require("lib.notifications.menubar").update()
        
      elseif action == "ignore" then
        -- IGNORE: Silent drop (no logging, no display)
        U.log.df("Ignoring notification per rule: %s", rule.name)
        
      else
        -- REDIRECT (default): Delegate to processor for canvas display
        local ok, err = pcall(N.process, rule, title, subtitle, message, axStackingID, bundleID, 
          notificationID, notificationType, subrole, matchedCriteria)
        
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

-- Scan for existing persistent notifications on startup
-- This catches system notifications that were already present before Hammerspoon loaded
local function scanExistingNotifications()
  local ncApp = hs.application.find("com.apple.notificationcenterui")
  if not ncApp then return end
  
  local notificationCenter = hs.axuielement.applicationElement(ncApp)
  if not notificationCenter then return end
  
  -- Navigate to scroll area containing notifications
  local windows = notificationCenter:attributeValue("AXWindows") or {}
  if #windows == 0 then return end
  
  local window = windows[1]
  local children = window:attributeValue("AXChildren") or {}
  if #children == 0 then return end
  
  local hostingView = children[1]
  local hostingChildren = hostingView:attributeValue("AXChildren") or {}
  if #hostingChildren == 0 then return end
  
  local innerGroup = hostingChildren[1]
  local innerChildren = innerGroup:attributeValue("AXChildren") or {}
  if #innerChildren == 0 then return end
  
  local scrollArea = innerChildren[1]
  local notifications = scrollArea:attributeValue("AXChildren") or {}
  
  local count = 0
  for _, notif in ipairs(notifications) do
    if notif.AXSubrole == "AXNotificationCenterAlert" or notif.AXSubrole == "AXNotificationCenterBanner" then
      -- Try to process it through our normal handler
      -- Use pcall in case any notification fails to process
      pcall(function()
        handleNotification(notif)
        count = count + 1
      end)
    end
  end
  
  if count > 0 then
    U.log.df("Scanned %d existing notification(s) on startup", count)
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

  M.currentPID = nil
  M.processedNotificationIDs = {}
  U.log.i("stopped")
end

return M
