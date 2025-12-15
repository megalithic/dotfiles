-- Notification Database Facade
-- Thin wrapper around lib/db.lua for notification-specific operations
--
local DB = require("lib.db")
local M = {}

-- Re-export database path for compatibility
M.dbPath = DB.dbPath

-- Initialize (delegates to unified database)
function M.init()
  return DB.init()
end

-- Close database
function M.close()
  return DB.close()
end

-- Log a notification event
function M.log(data)
  return DB.notifications.log(data)
end

-- Get recent notifications
function M.getRecent(hours)
  return DB.notifications.getRecent(hours)
end

-- Get notifications blocked by focus mode
function M.getBlockedByFocus()
  return DB.notifications.getBlockedByFocus()
end

-- Get missed notifications
function M.getMissed(hours)
  return DB.notifications.getMissed(hours)
end

-- Get notifications by sender
function M.getBySender(sender, limit)
  return DB.notifications.getBySender(sender, limit)
end

-- Full-text search
function M.search(searchTerm, limit)
  return DB.notifications.search(searchTerm, limit)
end

-- Get statistics
function M.getStats(hours)
  return DB.notifications.getStats(hours)
end

-- Mark notification as dismissed
function M.dismiss(notificationId)
  return DB.notifications.dismiss(notificationId)
end

-- Cleanup old notifications
function M.cleanup(days)
  return DB.notifications.cleanup(days)
end

-- Print results
function M.printResults(results, title)
  return DB.notifications.printResults(results, title)
end

-- Ensure directory exists (for compatibility)
function M.ensureDirectory()
  -- Handled by lib/db.lua
  return true
end

-- Access to underlying database object (for advanced queries)
M.db = DB.db

return M
