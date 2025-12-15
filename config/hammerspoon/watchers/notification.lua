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
  if not notificationSubroles[notificationElement.AXSubrole] or M.processedNotificationIDs[notificationElement.AXIdentifier] then return end

  M.processedNotificationIDs[notificationElement.AXIdentifier] = true

  -- Get the stacking identifier to determine which app sent the notification
  -- Use notificationElement (the actual alert/banner), not the outer container
  local stackingID = notificationElement.AXStackingIdentifier or "unknown"

  -- Extract bundle ID from stackingID
  -- Format: bundleIdentifier=com.example.app,threadIdentifier=...
  -- Try to extract bundleIdentifier value first, fallback to simple extraction
  local bundleID = stackingID:match("bundleIdentifier=([^,;%s]+)") or stackingID:match("^([^;%s]+)") or stackingID

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
  end

  -- Process routing rules
  local rules = C.notifier.rules or {}

  for _, rule in ipairs(rules) do
    -- Quick app match (plain string search, not pattern)
    if stackingID:find(rule.appBundleID, 1, true) then
      -- Check sender if specified
      if rule.senders then
        local senderMatch = false
        for _, sender in ipairs(rule.senders) do
          if title == sender then -- Exact match, case-sensitive
            senderMatch = true
            break
          end
        end
        if not senderMatch then
          goto continue -- Skip to next rule
        end
      end

      -- Rule matched! Process via notification system
      U.log.nf("%s: %s", rule.name, title or bundleID)

      -- Delegate to unified notification system via clean API
      local ok, err = pcall(function() N.process(rule, title, subtitle, message, stackingID, bundleID) end)

      if not ok then U.log.ef("Error processing rule '%s': %s", rule.name, tostring(err)) end

      -- First match wins - stop processing rules
      return
    end

    ::continue::
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

function M:start()
  -- Start the observer
  if not startObserver() then
    U.log.e("Failed to start notification observer")
    return
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

  M.currentPID = nil
  M.processedNotificationIDs = {}
  U.log.i("stopped")
end

return M
