-- Notification System Controller
-- Unified API and lifecycle management for the notification system
--
local M = {}

-- STATE
M.initialized = false
M.healthCheckTimer = nil
M.lastHealthCheck = nil
M.lastCleanup = nil
M.cleanupTimer = nil
M.initDelayTimer = nil  -- Reference to prevent GC of doAfter timer

-- SUBMODULES (re-exported for direct access: N.db.log(), N.menubar.update(), etc.)
M.types = require("lib.notifications.types")
M.db = require("lib.notifications.db")
M.processor = require("lib.notifications.processor")
M.menubar = require("lib.notifications.menubar")
M.notifier = require("lib.notifications.notifier")
M.sender = require("lib.notifications.send")

-- LIFECYCLE

---Initialize all notification subsystems
---Must be called before using any notification functions
---@return boolean success True if initialization succeeded
---@usage N.init()
function M.init()
  if M.initialized then
    U.log.w("Notification system already initialized")
    return true
  end

  U.log.i("Initializing notification system...")

  -- 1. Initialize database first
  local dbOk, dbErr = pcall(function() return M.db.init() end)

  if not dbOk then
    U.log.ef("CRITICAL: Failed to initialize notification database: %s", tostring(dbErr))
    hs.alert.show("⚠️ Notification Database Failed", 5)
    return false
  end

  if not dbErr then
    U.log.e("CRITICAL: Notification database init returned false")
    hs.alert.show("⚠️ Notification Database Failed", 5)
    return false
  end

  -- 2. Initialize menubar
  local menubarOk, menubarErr = pcall(function() return M.menubar.init() end)

  if not menubarOk then
    U.log.wf("Failed to initialize notification menubar: %s", tostring(menubarErr))
    -- Continue even if menubar fails
  elseif not menubarErr then
    U.log.w("Notification menubar init returned false (non-fatal)")
  end

  -- 3. Processor and notifier have no initialization

  M.initialized = true
  U.log.i("Notification system initialized ✓")

  -- Start health check (delayed to allow watchers to start)
  -- Store reference to prevent garbage collection during reload
  M.initDelayTimer = hs.timer.doAfter(5, function()
    M.initDelayTimer = nil  -- Clear reference after execution
    M.startHealthCheck()
  end)

  return true
end

---Gracefully shut down the notification system
---Stops health checks, cleans up menubar, closes database
---@return nil
---@usage N.cleanup()
function M.cleanup()
  U.log.i("Cleaning up notification system...")

  -- Stop init delay timer if still pending
  if M.initDelayTimer then
    M.initDelayTimer:stop()
    M.initDelayTimer = nil
  end

  -- Stop health check
  if M.healthCheckTimer then
    M.healthCheckTimer:stop()
    M.healthCheckTimer = nil
  end

  -- Stop cleanup timer
  if M.cleanupTimer then
    M.cleanupTimer:stop()
    M.cleanupTimer = nil
  end

  if M.menubar then M.menubar.cleanup() end

  if M.db then M.db.close() end

  M.initialized = false
  U.log.i("Notification system cleaned up")
end

-- Health check system - runs every 15 minutes to verify notification system is working
function M.startHealthCheck()
  if M.healthCheckTimer then M.healthCheckTimer:stop() end

  -- Run initial health check
  M.performHealthCheck()

  -- Set up periodic health check (every 15 minutes)
  M.healthCheckTimer = hs.timer.doEvery(900, function() M.performHealthCheck() end)

  U.log.i("Notification health check started (15 minute interval)")

  -- Start daily cleanup timer
  M.startCleanupSchedule()
end

-- Cleanup scheduler - runs cleanup once per day
function M.startCleanupSchedule()
  if M.cleanupTimer then M.cleanupTimer:stop() end

  -- Run cleanup shortly after startup (30 seconds delay to let system settle)
  hs.timer.doAfter(30, function() M.performCleanupIfNeeded() end)

  -- Schedule daily cleanup check (every 6 hours, but only runs if 24h have passed)
  M.cleanupTimer = hs.timer.doEvery(21600, function() M.performCleanupIfNeeded() end)

  U.log.f("Notification cleanup scheduled (%d day retention)", C.notifier.retentionDays)
end

-- Perform cleanup only if 24 hours have passed since last cleanup
function M.performCleanupIfNeeded()
  local now = os.time()
  local oneDayAgo = now - 86400

  -- Skip if we've cleaned up in the last 24 hours
  if M.lastCleanup and M.lastCleanup > oneDayAgo then
    U.log.df("Skipping cleanup - last run was %d hours ago", math.floor((now - M.lastCleanup) / 3600))
    return
  end

  -- Perform the cleanup
  local DB = require("lib.db")
  local success = DB.notifications.cleanup(C.notifier.retentionDays)

  if success then
    M.lastCleanup = now
    U.log.i("Daily notification cleanup completed")
  else
    U.log.e("Daily notification cleanup failed")
  end
end

function M.performHealthCheck()
  local issues = {}
  local DB = require("lib.db")
  local isFirstCheck = M.lastHealthCheck == nil

  -- Check 1: Initialized flag
  if not M.initialized then table.insert(issues, "System not initialized") end

  -- Check 2: Database connection
  if not DB.db then table.insert(issues, "Database connection lost") end

  -- Check 3: Notification watcher (skip on first check as it might not be started yet)
  if not isFirstCheck then
    local watcherOk, watcher = pcall(require, "watchers.notification")
    if not watcherOk or not watcher.observer then table.insert(issues, "Notification watcher not running") end
  end

  -- Check 4: Menubar
  if M.menubar and not M.menubar.menubar then table.insert(issues, "Menubar indicator lost") end

  M.lastHealthCheck = os.time()

  if #issues > 0 then
    local issueStr = table.concat(issues, ", ")
    U.log.ef("⚠️ NOTIFICATION SYSTEM HEALTH CHECK FAILED: %s", issueStr)

    -- Only show alert if this isn't the first check
    if not isFirstCheck then
      hs.alert.show("⚠️ Notification System Issue\n" .. issueStr, 8)

      -- Try to reinitialize (but not on first check)
      U.log.w("Attempting to reinitialize notification system...")
      M.initialized = false
      local success = M.init()
      if success then
        U.log.i("Notification system successfully reinitialized")
        hs.alert.show("✓ Notification System Restored", 3)
      else
        U.log.e("Failed to reinitialize notification system!")
      end
    end
  end
  -- No log on success - only log errors
end

-- Health check
function M.isReady()
  local DB = require("lib.db")
  return M.initialized and DB.db ~= nil
end

-- PUBLIC API
-- These functions provide a clean interface for scripts, CLI, and console usage

---Process a notification according to rule configuration
---This is the main entry point called by watchers/notification.lua
---@param rule NotificationRule The notification rule configuration
---@param title string Notification title
---@param subtitle string|nil Notification subtitle (optional)
---@param message string Notification message body
---@param axStackingID string Full AX stacking identifier from notification center
---@param bundleID string Parsed bundle ID from stacking identifier
---@param notificationID string|nil UUID from AXIdentifier
---@param notificationType string|nil "system" | "app"
---@param subrole string|nil AXSubrole value
---@param matchedCriteria string|nil JSON string of what matched (for logging)
---@param urgency string|nil Resolved urgency level: "critical"|"high"|"normal"|"low"
---@return nil
---@usage N.process(rule, "Test", nil, "Message", "bundleIdentifier=com.app", "com.app", nil, nil, nil, nil, "normal")
function M.process(rule, title, subtitle, message, axStackingID, bundleID, notificationID, notificationType, subrole, matchedCriteria, urgency)
  if not M.initialized then
    U.log.e("Notification system not initialized - cannot process notification")
    return
  end

  -- Delegate to processor with all enhanced fields including match criteria and urgency
  M.processor.process(rule, title, subtitle, message, axStackingID, bundleID, notificationID, notificationType, subrole, matchedCriteria, urgency)
end

---Send a canvas notification directly
---Displays a custom notification using the canvas renderer
---@param title string Notification title
---@param message string Notification message body
---@param opts table|nil Optional configuration { duration = number, urgency = string, position = string, includeProgram = boolean }
---@return nil
---@usage N.notify("Test Title", "Test message", { duration = 5, urgency = "high" })
---@usage N.notify("Quick note", "This is a message") -- uses defaults
function M.notify(title, message, opts)
  if not M.initialized then
    U.log.e("Notification system not initialized - cannot send notification")
    return
  end

  opts = opts or {}
  local duration = opts.duration or 3

  -- Delegate to notifier (it expects: title, message, duration, opts)
  M.notifier.sendCanvasNotification(title, message, duration, opts)
end

---Manually trigger a health check of the notification system
---Useful for debugging. Returns the timestamp of the health check.
---@return number|nil timestamp Unix timestamp of the health check
---@usage N.checkHealth()
function M.checkHealth()
  U.log.i("Running manual notification system health check...")
  M.performHealthCheck()
  return M.lastHealthCheck
end

---Check if the notification system is ready to use
---@return boolean ready True if initialized and database is connected
---@usage if N.isReady() then N.notify("Test", "Message") end
function M.isReady()
  local DB = require("lib.db")
  return M.initialized and DB.db ~= nil
end

-- DATABASE QUERY METHODS (convenience shortcuts)

---Log a notification event to the database
---@param data table Notification data { sender, message, bundle_id, action_taken, focus_mode, urgency, etc. }
---@return boolean success True if logged successfully
---@usage N.log({ sender = "Test", message = "Test message", bundle_id = "com.test", action_taken = "shown" })
function M.log(data) return M.db.log(data) end

---Get recent notifications from the database
---@param hours number|nil Number of hours to look back (default: 24)
---@return table notifications Array of notification records
---@usage local recent = N.getRecent(12) -- get notifications from last 12 hours
function M.getRecent(hours) return M.db.getRecent(hours) end

---Get notifications that were blocked by focus mode
---@return table notifications Array of blocked notification records
---@usage local blocked = N.getBlocked()
function M.getBlocked() return M.db.getBlockedByFocus() end

---Search notifications by query string
---@param query string Search query (searches sender, message, bundle_id)
---@param limit number|nil Maximum results to return (default: 50)
---@return table notifications Array of matching notification records
---@usage local results = N.search("Abby", 10)
function M.search(query, limit) return M.db.search(query, limit) end

---Get notification statistics
---@param hours number|nil Number of hours to analyze (default: 24)
---@return table stats Statistics including total count, by sender, by app, by action
---@usage local stats = N.getStats(24)
function M.getStats(hours) return M.db.getStats(hours) end

---Update the menubar indicator
---Call this after database changes to refresh the menubar display
---@return nil
---@usage N.updateMenubar()
function M.updateMenubar()
  if M.menubar then M.menubar.update() end
end

-- AI AGENT SEND API (convenience re-exports from sender module)

---Send a notification via the unified AI agent API
---Routes to appropriate channels based on attention state
---@param opts SendOpts { title, message, urgency?, phone?, pushover?, question?, context? }
---@return SendResult { sent, channels, reason, questionId? }
---@usage N.send({ title = "Done", message = "Tests passed", urgency = "normal" })
---@usage N.send({ title = "Question", message = "Continue?", question = true, context = "main:claude" })
function M.send(opts) return M.sender.send(opts) end

---Mark a question as answered (stops retry reminders)
---@param questionId string|nil Question ID returned by send()
---@param title string|nil Title to look up if no questionId
---@param message string|nil Message to look up if no questionId
---@return boolean success
---@usage N.answerQuestion(questionId)
---@usage N.answerQuestion(nil, "Question Title", "Question message")
function M.answerQuestion(questionId, title, message) return M.sender.answerQuestion(questionId, title, message) end

---Get list of pending questions awaiting answers
---@return table[] Array of { id, title, timestamp, retryCount, age }
---@usage local pending = N.getPendingQuestions()
function M.getPendingQuestions() return M.sender.getPendingQuestions() end

---Check current attention state
---@param context string|nil Calling context (e.g., "main:claude")
---@return { state: string, shouldNotify: string }
---@usage local attention = N.checkAttention("main:claude")
function M.checkAttention(context) return M.sender.checkAttention(context) end

return M
