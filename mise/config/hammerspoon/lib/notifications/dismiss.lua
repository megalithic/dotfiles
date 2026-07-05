-- Native Notification Dismissal
-- Shared utility for dismissing macOS Notification Center notifications via AX
--
local M = {}

-- Dismiss a notification by performing Close action or clicking close button
-- @param notificationElement: AX element of the notification
-- @param title: Notification title (for logging)
-- @return boolean: true if dismissed successfully, false otherwise
function M.dismiss(notificationElement, title)
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

return M
