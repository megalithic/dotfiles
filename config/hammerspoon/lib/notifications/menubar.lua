-- Event Menubar Indicator
-- Shows important events: notifications blocked by focus mode, network status changes, etc.

local M = {}
local fmt = string.format
local DB = require("lib.db")
local db = DB.notifications  -- Alias for convenience

-- Menubar item
M.menubar = nil
M.pulseTimer = nil
M.pulseState = false
M.isShowing = false

-- Event categories
M.CATEGORY = {
  FOCUS_BLOCKED = "focus_blocked",
  NETWORK = "network",
}

-- Initialize menubar indicator
function M.init()
  M.menubar = hs.menubar.new()
  if not M.menubar then
    U.log.e("Failed to create notification menubar")
    return false
  end

  -- Set up dynamic menu (built on each click)
  M.menubar:setMenu(function(modifiers)
    return M.buildMenu()
  end)

  -- Start hidden (will show when there are notifications)
  M.menubar:removeFromMenuBar()
  M.isShowing = false

  -- Initial update
  M.update()

  -- Start pulse animation
  M.startPulse()

  U.log.i("Notification menubar initialized")
  return true
end

-- Get all important events
function M.getEvents()
  local events = {
    focusBlocked = db.getBlockedByFocus() or {},
    network = DB.connections.getEvents(24) or {}, -- Last 24 hours
  }
  return events
end

-- Get total event count
function M.getEventCount(events)
  local count = 0
  for _, categoryEvents in pairs(events) do
    count = count + #categoryEvents
  end
  return count
end

-- Update menubar display
function M.update()
  if not M.menubar then return end

  local events = M.getEvents()
  local totalCount = M.getEventCount(events)

  if totalCount > 0 then
    -- Show menubar if hidden
    if not M.isShowing then
      M.menubar:returnToMenuBar()
      M.isShowing = true
    end

    -- Single indicator with total count
    M.menubar:setTitle(fmt("🔴 %d", totalCount))
    M.menubar:setTooltip(fmt("%d important event%s", totalCount, totalCount == 1 and "" or "s"))
  else
    -- No events - hide menubar completely
    if M.isShowing then
      M.menubar:removeFromMenuBar()
      M.isShowing = false
    end
  end
end

-- Start pulsing animation
function M.startPulse()
  if M.pulseTimer then
    M.pulseTimer:stop()
  end

  M.pulseTimer = hs.timer.doEvery(0.5, function()
    if not M.menubar or not M.isShowing then return end

    local events = M.getEvents()
    local totalCount = M.getEventCount(events)

    if totalCount > 0 then
      -- Alternate between bright and dim indicator
      M.pulseState = not M.pulseState
      if M.pulseState then
        M.menubar:setTitle(fmt("🔴 %d", totalCount))
      else
        M.menubar:setTitle(fmt("⭕ %d", totalCount))
      end
    end
  end)
end

-- Stop pulsing animation
function M.stopPulse()
  if M.pulseTimer then
    M.pulseTimer:stop()
    M.pulseTimer = nil
  end
end

-- Format timestamp relative to now
local function formatTimeAgo(timestamp)
  local timeAgo = os.time() - timestamp
  if timeAgo < 60 then
    return "Just now"
  elseif timeAgo < 3600 then
    return fmt("%dm ago", math.floor(timeAgo / 60))
  elseif timeAgo < 86400 then
    return fmt("%dh ago", math.floor(timeAgo / 3600))
  else
    return fmt("%dd ago", math.floor(timeAgo / 86400))
  end
end

-- Get icon from config or use default
local function getNetworkIcon(eventType)
  local icons = C.notifier and C.notifier.networkIcons
  if icons and icons[eventType] then
    return icons[eventType]
  end

  -- Fallback icons if config not available
  local defaults = {
    internet_connected = "✅",
    internet_disconnected = "❌",
    router_connected = "🔗",
    router_disconnected = "⚠️",
  }
  return defaults[eventType] or "📡"
end

-- Render nerd font icon as image (for consistent sizing with app icons)
local function renderIconAsImage(iconChar, dimmed)
  if not iconChar or iconChar == "" then return nil end

  local size = 16
  local canvas = hs.canvas.new({ x = 0, y = 0, w = size, h = size })

  -- Use dimmed color for network events, full white for others
  local colorValue = dimmed and 0.45 or 1.0

  -- Render the icon character as text
  -- Adjust positioning to vertically center with menu item text
  canvas:appendElements({
    type = "text",
    text = iconChar,
    textSize = 18, -- Adjusted size for better fit
    textFont = "JetBrainsMono Nerd Font Mono", -- Use Nerd Font
    textColor = { white = colorValue }, -- Dimmed or full white
    textAlignment = "center",
    frame = { x = 0, y = -3, w = size, h = size },
  })

  -- Convert canvas to image
  local image = canvas:imageFromCanvas()
  canvas:delete()

  return image
end

-- Get app icon or fallback to default
local function getAppIcon(bundleID)
  if not bundleID then
    return nil
  end

  local icon = hs.image.imageFromAppBundle(bundleID)
  if icon then
    -- Resize to menubar size
    local size = { w = 16, h = 16 }
    return icon:setSize(size)
  end

  return nil
end

-- Convert events to unified format for sorting and display
local function normalizeEvents(events)
  local normalized = {}

  -- Add network events
  for _, event in ipairs(events.network) do
    local iconChar = getNetworkIcon(event.event_type)
    local iconImage = renderIconAsImage(iconChar, true) -- Pass true to dim network icons
    local title

    if event.event_type == "internet_connected" then
      title = "Internet Connected"
    elseif event.event_type == "internet_disconnected" then
      title = "Internet Disconnected"
    elseif event.event_type == "router_connected" then
      title = "Router Connected"
    elseif event.event_type == "router_disconnected" then
      title = "Router Disconnected"
    else
      title = event.event_type
    end

    table.insert(normalized, {
      type = "network",
      icon = iconImage and { image = iconImage } or iconChar, -- Use image if available, fallback to char
      title = title,
      timestamp = event.timestamp,
      data = event,
    })
  end

  -- Add focus-blocked notifications
  for _, notif in ipairs(events.focusBlocked) do
    local sender = notif.sender or "Unknown"
    local preview = notif.message and notif.message:sub(1, 40) or ""
    if #preview == 40 then preview = preview .. "..." end

    -- Try to get app icon, fallback to 🔴
    local appIcon = getAppIcon(notif.app_id)

    table.insert(normalized, {
      type = "notification",
      icon = appIcon and { image = appIcon } or "🔴",
      title = fmt("%s: %s", sender, preview),
      timestamp = notif.timestamp,
      data = notif,
    })
  end

  -- Sort by timestamp (most recent first)
  table.sort(normalized, function(a, b)
    return a.timestamp > b.timestamp
  end)

  return normalized
end

-- Build menu with unified event list
function M.buildMenu()
  local events = M.getEvents()
  local menu = {}

  local totalCount = M.getEventCount(events)

  if totalCount == 0 then
    table.insert(menu, {
      title = "No important events",
      disabled = true,
    })
    return menu
  end

  -- Get normalized and sorted events
  local allEvents = normalizeEvents(events)

  -- Add header
  table.insert(menu, {
    title = fmt("Important Events (%d)", totalCount),
    disabled = true,
  })
  table.insert(menu, { title = "-" }) -- Separator

  -- Add all events in chronological order
  for _, event in ipairs(allEvents) do
    local timeStr = formatTimeAgo(event.timestamp)

    -- Build menu item with icon support
    local menuItem = {
      fn = function()
        if event.type == "notification" then
          M.handleNotificationClick(event.data)
        end
        -- Network events don't have a click action currently
      end,
    }

    -- Build tooltip with full details
    local tooltip = {}
    if event.type == "notification" then
      local notif = event.data
      table.insert(tooltip, fmt("From: %s", notif.sender or "Unknown"))
      if notif.subtitle and notif.subtitle ~= "" then
        table.insert(tooltip, fmt("Subject: %s", notif.subtitle))
      end
      table.insert(tooltip, fmt("Message: %s", notif.message or ""))
      table.insert(tooltip, fmt("App: %s", notif.app_id or "Unknown"))
      table.insert(tooltip, fmt("Focus Mode: %s", notif.focus_mode or "None"))
      table.insert(tooltip, fmt("Date: %s", os.date("%A, %B %d, %Y", notif.timestamp)))
      table.insert(tooltip, fmt("Time: %s", os.date("%I:%M:%S %p", notif.timestamp)))
    else
      -- Network event tooltip
      table.insert(tooltip, fmt("Event: %s", event.title))
      table.insert(tooltip, fmt("Date: %s", os.date("%A, %B %d, %Y", event.timestamp)))
      table.insert(tooltip, fmt("Time: %s", os.date("%I:%M:%S %p", event.timestamp)))
    end
    menuItem.tooltip = table.concat(tooltip, "\n")

    -- Handle icon (string emoji/nerd font or image)
    if type(event.icon) == "table" and event.icon.image then
      -- App icon (image) - title without extra prefix
      menuItem.title = fmt("%s (%s)", event.title, timeStr)
      menuItem.image = event.icon.image
    elseif event.icon then
      -- Network icon (emoji/nerd font string)
      menuItem.title = fmt("%s %s (%s)", event.icon, event.title, timeStr)
    else
      -- No icon available - add spacing character to maintain alignment
      -- Use a narrow non-breaking space to reserve icon space
      menuItem.title = fmt("   %s (%s)", event.title, timeStr)
    end

    table.insert(menu, menuItem)
  end

  table.insert(menu, { title = "-" }) -- Separator

  -- Clear Actions
  table.insert(menu, {
    title = "Clear All Events",
    fn = function()
      M.clearAll()
    end,
  })

  return menu
end

-- Handle clicking on a notification
function M.handleNotificationClick(notif)
  -- Launch the app
  if notif.app_id then
    hs.application.launchOrFocusByBundleID(notif.app_id)
  end

  -- Mark as dismissed
  db.dismiss(notif.id)

  -- Update display
  hs.timer.doAfter(0.1, function()
    M.update()
  end)
end

-- Clear all events (notifications and network events)
function M.clearAll()
  -- Clear blocked notifications
  db.dismiss("all")

  -- Clear network events
  DB.connections.dismissAll()

  -- Update menubar
  hs.timer.doAfter(0.1, function()
    M.update()
  end)

  U.log.i("Cleared all events from menubar")
end

-- Cleanup
function M.cleanup()
  M.stopPulse()
  if M.menubar then
    M.menubar:delete()
    M.menubar = nil
  end
end

return M
