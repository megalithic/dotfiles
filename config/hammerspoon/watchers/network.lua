-- Network Watcher - Monitor internet and router connectivity
-- Sends notifications when network connection is lost or regained
--
local M = {}

-- Watchers
M.internetWatcher = nil
M.routerWatcher = nil

-- State tracking
M.internetStatus = nil -- true = connected, false = disconnected, nil = unknown
M.routerStatus = nil -- true = connected, false = disconnected, nil = unknown

-- Log connection event to database
local function logConnectionEvent(eventType)
  local DB = require("lib.db")
  DB.connections.logEvent({
    timestamp = os.time(),
    event_type = eventType,
  })
end

-- Send notification via notification system
local function sendConnectionNotification(title, message, priority)
  -- Use the notifier module directly to avoid going through the watcher
  local notifier = require("lib.notifications.notifier")

  local config = {
    appImageID = "com.apple.Network-Settings",
    appBundleID = "com.apple.systempreferences",
    includeProgram = false,
    priority = priority or "normal",
    anchor = "screen",
    position = "SW",
    dimBackground = false,
  }

  notifier.sendCanvasNotification(title, message, 5, config)
end

-- Update menubar with new event
local function updateMenubar()
  local menubar = require("lib.notifications.menubar")
  if menubar and menubar.update then menubar.update() end
end

-- Handle internet connection status changes
local function handleInternetStatus(flags)
  local isConnected = (flags and hs.network.reachability.flags.reachable) ~= 0

  -- Skip if status hasn't changed
  if M.internetStatus == isConnected then return end

  -- Update status
  local previousStatus = M.internetStatus
  M.internetStatus = isConnected

  -- Don't send notification on initial status discovery
  if previousStatus == nil then
    U.log.i("Initial internet status: " .. (isConnected and "connected" or "disconnected"))
    return
  end

  -- Send notification and log event
  if isConnected then
    U.log.i("Internet connection restored")
    sendConnectionNotification("Internet Connected", "Connection to the internet has been restored", "normal")
    logConnectionEvent("internet_connected")
  else
    U.log.w("Internet connection lost")
    sendConnectionNotification("Internet Disconnected", "Connection to the internet has been lost", "high")
    logConnectionEvent("internet_disconnected")
  end

  -- Update menubar to show event
  updateMenubar()
end

-- Handle router connection status changes
local function handleRouterStatus(flags)
  local isConnected = (flags and hs.network.reachability.flags.reachable) ~= 0

  -- Skip if status hasn't changed
  if M.routerStatus == isConnected then return end

  -- Update status
  local previousStatus = M.routerStatus
  M.routerStatus = isConnected

  -- Don't send notification on initial status discovery
  if previousStatus == nil then
    U.log.i("Initial router status: " .. (isConnected and "connected" or "disconnected"))
    return
  end

  -- Send notification and log event
  if isConnected then
    U.log.i("Router connection restored")
    sendConnectionNotification("Router Connected", "Connection to the local network has been restored", "normal")
    logConnectionEvent("router_connected")
  else
    U.log.w("Router connection lost")
    sendConnectionNotification("Router Disconnected", "Connection to the local network has been lost", "high")
    logConnectionEvent("router_disconnected")
  end

  -- Update menubar to show event
  updateMenubar()
end

function M:start()
  -- Stop existing watchers first to avoid duplicates
  if M.internetWatcher then
    M.internetWatcher:stop()
    M.internetWatcher = nil
  end
  if M.routerWatcher then
    M.routerWatcher:stop()
    M.routerWatcher = nil
  end

  -- Monitor internet connectivity (0.0.0.0 is a standard way to check internet)
  M.internetWatcher = hs.network.reachability.internet()
  M.internetWatcher:setCallback(handleInternetStatus)
  M.internetWatcher:start()

  -- Monitor router connectivity (using gateway address)
  -- This checks connectivity to the local network/router
  M.routerWatcher = hs.network.reachability.forAddress("192.168.1.1")
  M.routerWatcher:setCallback(handleRouterStatus)
  M.routerWatcher:start()

  U.log.i("started")
end

function M:stop()
  if M.internetWatcher then
    M.internetWatcher:stop()
    M.internetWatcher = nil
  end

  if M.routerWatcher then
    M.routerWatcher:stop()
    M.routerWatcher = nil
  end

  U.log.i("stopped")
end

return M
