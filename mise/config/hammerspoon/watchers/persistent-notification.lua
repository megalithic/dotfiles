-- Persistent Notification Scanner
-- Monitors Notification Center for long-lived system notifications and auto-dismisses them
-- System notifications (Login Items, Background Permissions, etc.) don't auto-dismiss
-- and need manual dismissal or programmatic cleanup
--
local fmt = string.format
local M = {}

M.scanTimer = nil
M.trackedNotifications = {} -- { [notificationID] = { firstSeen = timestamp, title = string, message = string } }

-- Helper to extract text content from notification element
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

-- Check if notification matches whitelist (should NOT be dismissed)
local function isWhitelisted(title, message)
  local whitelist = C.notifier.persistentNotifications.whitelist or {}
  
  for _, rule in ipairs(whitelist) do
    if rule.title and title:match(rule.title) then
      return true
    end
    
    if rule.message and message:match(rule.message) then
      return true
    end
  end
  
  return false
end

-- Get custom timeout for notification, or default
local function getDismissTimeout(title, message)
  local customTimeouts = C.notifier.persistentNotifications.customTimeouts or {}
  
  for _, rule in ipairs(customTimeouts) do
    local matches = false
    
    if rule.title and title:match(rule.title) then
      matches = true
    end
    
    if rule.message and message:match(rule.message) then
      matches = true
    end
    
    if matches then
      return rule.timeout
    end
  end
  
  return C.notifier.persistentNotifications.defaultDismissTimeout or 3
end

-- Attempt to dismiss a notification via AX API
local function dismissNotification(notificationElement, title)
  -- Try AXPress action (primary action, often triggers default behavior)
  local actions = notificationElement:actionNames() or {}
  local hasClose = false
  
  for _, action in ipairs(actions) do
    if action:match("Close") or action == "AXPress" then
      hasClose = true
      break
    end
  end
  
  if hasClose then
    U.log.df("Dismissing persistent notification: %s", title)
    notificationElement:performAction("AXPress")
    return true
  end
  
  U.log.wf("Could not find dismiss action for notification: %s", title)
  return false
end

-- Scan Notification Center for persistent notifications
local function scanNotificationCenter()
  local ncApp = hs.application.find("com.apple.notificationcenterui")
  if not ncApp then
    U.log.df("Notification Center not found during persistent scan")
    return
  end
  
  local notificationCenter = hs.axuielement.applicationElement(ncApp)
  if not notificationCenter then
    U.log.df("Could not get NC AX element")
    return
  end
  
  -- Navigate to notification scroll area
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
  
  local now = os.time()
  local seenIDs = {}
  
  -- Process each notification
  for _, notif in ipairs(notifications) do
    if notif.AXSubrole == "AXNotificationCenterAlert" then
      local notifID = notif.AXIdentifier
      
      if notifID then
        seenIDs[notifID] = true
        
        -- Extract text
        local title, message = extractNotificationText(notif)
        
        -- Check if whitelisted (skip dismissal)
        if isWhitelisted(title, message) then
          U.log.df("Notification whitelisted, skipping: %s", title)
          goto continue
        end
        
        -- Track first seen time
        if not M.trackedNotifications[notifID] then
          M.trackedNotifications[notifID] = {
            firstSeen = now,
            title = title,
            message = message,
            element = notif, -- Keep reference for dismissal
          }
          U.log.df("Tracking new persistent notification: %s (ID: %s)", title, notifID)
        end
        
        -- Check if it's time to dismiss
        local tracked = M.trackedNotifications[notifID]
        local age = now - tracked.firstSeen
        local dismissTimeout = getDismissTimeout(title, message)
        
        if age >= dismissTimeout then
          U.log.nf("Auto-dismissing notification after %ds: %s", age, title)
          
          -- Attempt dismissal
          local dismissed = dismissNotification(notif, title)
          
          if dismissed then
            -- Log to notification database
            if N and N.log then
              N.log({
                timestamp = now,
                rule_name = "Persistent Notification Auto-Dismiss",
                app_id = "system",
                title = title,
                sender = "System",
                subtitle = nil,
                message = message,
                action_taken = "auto_dismissed",
                focus_mode = nil,
                shown = false,
              })
            end
            
            -- Remove from tracking
            M.trackedNotifications[notifID] = nil
          end
        end
      end
      
      ::continue::
    end
  end
  
  -- Cleanup notifications that are no longer present
  for notifID, tracked in pairs(M.trackedNotifications) do
    if not seenIDs[notifID] then
      U.log.df("Notification no longer present, removing from tracking: %s", tracked.title)
      M.trackedNotifications[notifID] = nil
    end
  end
end

function M:start()
  if not C.notifier.persistentNotifications or not C.notifier.persistentNotifications.enabled then
    U.log.i("Persistent notification scanner disabled in config")
    return
  end
  
  local interval = C.notifier.persistentNotifications.scanInterval or 10
  
  -- Run initial scan after short delay (let system settle)
  hs.timer.doAfter(5, function()
    scanNotificationCenter()
  end)
  
  -- Start periodic scanning
  M.scanTimer = hs.timer.doEvery(interval, function()
    scanNotificationCenter()
  end)
  
  U.log.i(fmt("started (scanning every %ds)", interval))
end

function M:stop()
  if M.scanTimer then
    M.scanTimer:stop()
    M.scanTimer = nil
  end
  
  M.trackedNotifications = {}
  U.log.i("stopped")
end

return M
