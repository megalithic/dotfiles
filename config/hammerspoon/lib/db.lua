-- Unified Hammerspoon Database
-- Manages all persistent data: notifications, connections, cache, metrics
--
local M = {}
local fmt = string.format

-- Database path (unified for all Hammerspoon data)
M.dbPath = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
M.dbPath = M.dbPath .. "/hammerspoon/hammerspoon.db"

-- Legacy path for migration
M.legacyNotificationsPath = M.dbPath:gsub("hammerspoon%.db$", "notifications.db")

-- Ensure directory exists
local function ensureDirectory()
  local dir = M.dbPath:match("(.*/)")
  if dir then os.execute(fmt("mkdir -p '%s'", dir)) end
end

-- Escape single quotes for SQL safety
local function escapeSql(str)
  if not str then return "" end
  return str:gsub("'", "''")
end

-- Initialize database and create schema
function M.init()
  ensureDirectory()

  M.db = hs.sqlite3.open(M.dbPath)

  if not M.db then
    U.log.ef("Failed to open unified database at: %s", M.dbPath)
    return false
  end

  -- Schema Migration: Rename old notifications table to legacy_notifications
  -- and create new clean schema with enhanced fields
  local needsMigration = false
  
  -- Check if notifications table exists and legacy doesn't
  local hasNotifications = false
  local hasLegacy = false
  
  for row in M.db:nrows("SELECT name FROM sqlite_master WHERE type='table'") do
    if row.name == "notifications" then hasNotifications = true end
    if row.name == "legacy_notifications" then hasLegacy = true end
  end
  
  if hasNotifications and not hasLegacy then
    -- Migration needed: rename existing table to legacy
    needsMigration = true
    U.log.i("Migrating notifications schema: renaming existing table to legacy_notifications")
    
    if not M.db:execute("ALTER TABLE notifications RENAME TO legacy_notifications") then
      U.log.e("Failed to rename notifications table to legacy_notifications")
      return false
    end
    
    -- Also rename the old FTS table if it exists
    M.db:execute("DROP TABLE IF EXISTS ft_notifications")
    M.db:execute("DROP TRIGGER IF EXISTS notifications_ai")
    
    U.log.i("Successfully renamed notifications → legacy_notifications")
  end
  
  -- Create new notifications table with clean schema
  local notificationsSchema = [[
    CREATE TABLE IF NOT EXISTS notifications (
      -- Core identification
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER NOT NULL,
      notification_id TEXT,
      
      -- Content
      title TEXT,
      subtitle TEXT,
      message TEXT NOT NULL,
      sender TEXT NOT NULL,
      
      -- Source
      app_id TEXT NOT NULL,
      app_name TEXT,
      notification_type TEXT,
      subrole TEXT,
      
      -- Rule matching
      rule_name TEXT NOT NULL,
      match_criteria TEXT,
      
      -- Action/routing
      action TEXT NOT NULL,
      action_detail TEXT,
      priority TEXT,
      
      -- State tracking
      shown INTEGER NOT NULL DEFAULT 1,
      first_seen INTEGER,
      dismissed_at INTEGER,
      dismiss_method TEXT,
      focus_mode TEXT
    )
  ]]

  if not M.db:execute(notificationsSchema) then
    U.log.e("Failed to create notifications table")
    return false
  end
  
  if needsMigration then
    U.log.i("Created new notifications table with enhanced schema")
  end

  -- Create connection_events table (for future connection watcher)
  local connectionsSchema = [[
    CREATE TABLE IF NOT EXISTS connection_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER NOT NULL,
      event_type TEXT NOT NULL,
      duration_seconds INTEGER,
      dismissed INTEGER DEFAULT 0,
      created_at INTEGER DEFAULT (strftime('%s', 'now'))
    )
  ]]

  M.db:execute(connectionsSchema)

  -- Migration: Add dismissed column to connection_events if it doesn't exist
  local hasDismissed = false
  for row in M.db:nrows("PRAGMA table_info(connection_events)") do
    if row.name == "dismissed" then
      hasDismissed = true
      break
    end
  end
  if not hasDismissed then
    M.db:execute("ALTER TABLE connection_events ADD COLUMN dismissed INTEGER DEFAULT 0")
    U.log.i("Added dismissed column to connection_events table")
  end

  -- Migration: Add title column to notifications if it doesn't exist
  local hasTitle = false
  for row in M.db:nrows("PRAGMA table_info(notifications)") do
    if row.name == "title" then
      hasTitle = true
      break
    end
  end
  if not hasTitle then
    M.db:execute("ALTER TABLE notifications ADD COLUMN title TEXT")
    U.log.i("Added title column to notifications table")
  end

  -- Create user_cache table (for caching external data)
  local cacheSchema = [[
    CREATE TABLE IF NOT EXISTS user_cache (
      key TEXT PRIMARY KEY,
      value TEXT,
      cached_at INTEGER DEFAULT (strftime('%s', 'now')),
      expires_at INTEGER
    )
  ]]

  M.db:execute(cacheSchema)

  -- Indexes for notifications
  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_notifications_timestamp
    ON notifications(timestamp DESC)
  ]])

  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_notifications_sender
    ON notifications(sender, timestamp DESC)
  ]])

  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_notifications_action
    ON notifications(action, shown, timestamp DESC)
  ]])
  
  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_notifications_type
    ON notifications(notification_type, timestamp DESC)
  ]])
  
  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_notifications_priority
    ON notifications(priority, timestamp DESC)
  ]])

  -- Indexes for connections
  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_connections_timestamp
    ON connection_events(timestamp DESC)
  ]])

  -- Indexes for cache
  M.db:execute([[
    CREATE INDEX IF NOT EXISTS idx_cache_expires
    ON user_cache(expires_at)
  ]])

  -- Full-text search on notification content
  M.db:execute([[
    CREATE VIRTUAL TABLE IF NOT EXISTS ft_notifications
    USING FTS5(title, sender, message, content=notifications, content_rowid=id)
  ]])

  -- Trigger to keep FTS in sync
  M.db:execute([[
    CREATE TRIGGER IF NOT EXISTS notifications_ai
    AFTER INSERT ON notifications BEGIN
      INSERT INTO ft_notifications(rowid, title, sender, message)
      VALUES (new.id, new.title, new.sender, new.message);
    END
  ]])

  U.log.f("Unified database initialized: %s", M.dbPath)

  -- Migrate data from legacy notifications.db if it exists
  M.migrateFromLegacy()

  return true
end

-- Migrate data from old notifications.db to unified database
function M.migrateFromLegacy()
  local legacyFile = io.open(M.legacyNotificationsPath, "r")
  if not legacyFile then
    -- No legacy file, nothing to migrate
    return
  end
  legacyFile:close()

  -- Check if migration already happened
  local checkQuery = "SELECT COUNT(*) as count FROM notifications"
  for row in M.db:nrows(checkQuery) do
    if row.count > 0 then
      U.log.d("Notifications already migrated, skipping")
      return
    end
  end

  U.log.i("Migrating notifications from legacy database...")

  -- Attach legacy database
  local attachCmd = fmt("ATTACH DATABASE '%s' AS legacy", M.legacyNotificationsPath)
  if not M.db:execute(attachCmd) then
    U.log.w("Failed to attach legacy database for migration")
    return
  end

  -- Copy notifications
  local migrateCmd = [[
    INSERT INTO notifications
    SELECT * FROM legacy.notifications
  ]]

  if M.db:execute(migrateCmd) then
    U.log.i("Successfully migrated notifications from legacy database")
  else
    U.log.w("Failed to migrate notifications")
  end

  -- Detach
  M.db:execute("DETACH DATABASE legacy")
end

-- Close database connection
function M.close()
  if M.db then
    M.db:close()
    M.db = nil
  end
end

--------------------------------------------------------------------------------
-- NOTIFICATIONS NAMESPACE
--------------------------------------------------------------------------------

M.notifications = {}

-- Log a notification event
function M.notifications.log(data)
  if not M.db then
    U.log.e("Database not initialized - cannot log notification")
    return false
  end

  -- Extract and escape fields (support both old and new field names for backward compat)
  local timestamp = data.timestamp or os.time()
  local notification_id = data.notification_id and escapeSql(data.notification_id) or "NULL"
  local rule_name = escapeSql(data.rule_name or "unknown")
  local app_id = escapeSql(data.app_id or "unknown")
  local app_name = data.app_name and escapeSql(data.app_name) or "NULL"
  local title = escapeSql(data.title or "")
  local sender = escapeSql(data.sender or "")
  local subtitle = escapeSql(data.subtitle or "")
  local message = escapeSql(data.message or "")
  local notification_type = data.notification_type and escapeSql(data.notification_type) or "NULL"
  local subrole = data.subrole and escapeSql(data.subrole) or "NULL"
  local match_criteria = data.match_criteria and escapeSql(data.match_criteria) or "NULL"
  
  -- Action fields (support old action_taken or new action/action_detail)
  local action = data.action and escapeSql(data.action) or escapeSql(data.action_taken or "unknown")
  local action_detail = data.action_detail and escapeSql(data.action_detail) or "NULL"
  local priority = data.priority and escapeSql(data.priority) or "NULL"
  
  -- State fields
  local shown = data.shown and 1 or 0
  local first_seen = data.first_seen or "NULL"
  local dismissed_at = data.dismissed_at or "NULL"
  local dismiss_method = data.dismiss_method and escapeSql(data.dismiss_method) or "NULL"
  local focus_mode = data.focus_mode and escapeSql(data.focus_mode) or "NULL"

  local query = fmt(
    [[
    INSERT INTO notifications
    (timestamp, notification_id, rule_name, app_id, app_name, title, sender, subtitle, message,
     notification_type, subrole, match_criteria, action, action_detail, priority,
     shown, first_seen, dismissed_at, dismiss_method, focus_mode)
    VALUES (%d, %s, '%s', '%s', %s, '%s', '%s', '%s', '%s',
     %s, %s, %s, '%s', %s, %s,
     %d, %s, %s, %s, %s)
  ]],
    timestamp,
    notification_id == "NULL" and "NULL" or "'" .. notification_id .. "'",
    rule_name,
    app_id,
    app_name == "NULL" and "NULL" or "'" .. app_name .. "'",
    title,
    sender,
    subtitle,
    message,
    notification_type == "NULL" and "NULL" or "'" .. notification_type .. "'",
    subrole == "NULL" and "NULL" or "'" .. subrole .. "'",
    match_criteria == "NULL" and "NULL" or "'" .. match_criteria .. "'",
    action,
    action_detail == "NULL" and "NULL" or "'" .. action_detail .. "'",
    priority == "NULL" and "NULL" or "'" .. priority .. "'",
    shown,
    first_seen,
    dismissed_at,
    dismiss_method == "NULL" and "NULL" or "'" .. dismiss_method .. "'",
    focus_mode == "NULL" and "NULL" or "'" .. focus_mode .. "'"
  )

  return M.db:execute(query) ~= nil
end

-- Get recent notifications
function M.notifications.getRecent(hours)
  hours = hours or 24
  local cutoff = os.time() - (hours * 3600)

  local query = fmt(
    [[
    SELECT
      datetime(timestamp, 'unixepoch', 'localtime') as time,
      rule_name, sender, message, action_taken, focus_mode, shown
    FROM notifications
    WHERE timestamp > %d
    ORDER BY timestamp DESC
  ]],
    cutoff
  )

  local results = {}
  for row in M.db:nrows(query) do
    table.insert(results, row)
  end

  return results
end

-- Get notifications blocked by focus mode
function M.notifications.getBlockedByFocus()
  local query = [[
    SELECT
      id, timestamp,
      datetime(timestamp, 'unixepoch', 'localtime') as time,
      rule_name, app_id, sender, message
    FROM notifications
    WHERE dismissed_at IS NULL
      AND shown = 0
      AND action_taken = 'blocked_by_focus'
    ORDER BY timestamp DESC
    LIMIT 50
  ]]

  local results = {}
  for row in M.db:nrows(query) do
    table.insert(results, row)
  end

  return results
end

-- Get missed notifications
function M.notifications.getMissed(hours)
  hours = hours or 24
  local cutoff = os.time() - (hours * 3600)

  local query = fmt(
    [[
    SELECT
      datetime(timestamp, 'unixepoch', 'localtime') as time,
      rule_name, sender, message, focus_mode
    FROM notifications
    WHERE timestamp > %d
      AND action_taken = 'blocked_by_focus'
      AND shown = 0
    ORDER BY timestamp DESC
  ]],
    cutoff
  )

  local results = {}
  for row in M.db:nrows(query) do
    table.insert(results, row)
  end

  return results
end

-- Get notifications by sender
function M.notifications.getBySender(sender, limit)
  limit = limit or 50
  sender = escapeSql(sender)

  local query = fmt(
    [[
    SELECT
      datetime(timestamp, 'unixepoch', 'localtime') as time,
      rule_name, message, action_taken, focus_mode, shown
    FROM notifications
    WHERE sender = '%s'
    ORDER BY timestamp DESC
    LIMIT %d
  ]],
    sender,
    limit
  )

  local results = {}
  for row in M.db:nrows(query) do
    table.insert(results, row)
  end

  return results
end

-- Full-text search on message content
function M.notifications.search(searchTerm, limit)
  limit = limit or 50
  searchTerm = escapeSql(searchTerm)

  local query = fmt(
    [[
    SELECT
      datetime(n.timestamp, 'unixepoch', 'localtime') as time,
      n.rule_name, n.sender, n.message, n.action_taken, n.shown
    FROM notifications n
    JOIN ft_notifications ft ON n.id = ft.rowid
    WHERE ft_notifications MATCH '%s'
    ORDER BY n.timestamp DESC
    LIMIT %d
  ]],
    searchTerm,
    limit
  )

  local results = {}
  for row in M.db:nrows(query) do
    table.insert(results, row)
  end

  return results
end

-- Get notification statistics
function M.notifications.getStats(hours)
  hours = hours or 24
  local cutoff = os.time() - (hours * 3600)

  local query = fmt(
    [[
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN shown = 1 THEN 1 ELSE 0 END) as shown,
      SUM(CASE WHEN shown = 0 THEN 1 ELSE 0 END) as blocked,
      COUNT(DISTINCT sender) as unique_senders
    FROM notifications
    WHERE timestamp > %d
  ]],
    cutoff
  )

  for row in M.db:nrows(query) do
    return row
  end

  return nil
end

-- Mark notification(s) as dismissed
function M.notifications.dismiss(notificationId)
  if not M.db then return false end

  local dismissTime = os.time()
  local query

  if notificationId == "all" then
    query = fmt(
      [[
      UPDATE notifications
      SET dismissed_at = %d
      WHERE dismissed_at IS NULL
        AND shown = 0
        AND (action_taken LIKE 'blocked%%')
    ]],
      dismissTime
    )
  else
    query = fmt(
      [[
      UPDATE notifications
      SET dismissed_at = %d
      WHERE id = %d
    ]],
      dismissTime,
      notificationId
    )
  end

  return M.db:execute(query) ~= nil
end

-- Cleanup old notifications with statistics and space reclamation
function M.notifications.cleanup(days)
  days = days or 30
  local cutoff = os.time() - (days * 86400)

  -- Count rows to be deleted first (using nrows iterator)
  local countQuery = fmt([[SELECT COUNT(*) as count FROM notifications WHERE timestamp < %d]], cutoff)
  local rowsToDelete = 0
  for row in M.db:nrows(countQuery) do
    rowsToDelete = row.count
  end

  if rowsToDelete == 0 then
    U.log.f("Notification cleanup: no records older than %d days", days)
    return true
  end

  -- Delete old notifications
  local deleteQuery = fmt([[DELETE FROM notifications WHERE timestamp < %d]], cutoff)
  local result = M.db:execute(deleteQuery)

  if not result then
    U.log.ef("Failed to cleanup notifications older than %d days", days)
    return false
  end

  -- Clean orphaned FTS entries (if FTS table exists)
  M.db:execute([[
    DELETE FROM ft_notifications WHERE rowid NOT IN (SELECT id FROM notifications)
  ]])

  -- Reclaim disk space
  M.db:execute("VACUUM")

  U.log.f("Notification cleanup: deleted %d records older than %d days", rowsToDelete, days)
  return true
end

-- Print query results
function M.notifications.printResults(results, title)
  if not results or #results == 0 then
    print("No results found")
    return
  end

  print("\n" .. (title or "Query Results") .. ":")
  print(string.rep("━", 80))

  for i, row in ipairs(results) do
    print(fmt("%d. %s", i, row.time or ""))
    if row.sender then print(fmt("   From: %s", row.sender)) end
    if row.rule_name then print(fmt("   Rule: %s", row.rule_name)) end
    if row.message then print(fmt("   Msg: %s", row.message:sub(1, 60))) end
    if row.action_taken then print(fmt("   Action: %s", row.action_taken)) end
    if row.focus_mode then print(fmt("   Focus: %s", row.focus_mode)) end
    if row.shown ~= nil then print(fmt("   Shown: %s", row.shown == 1 and "Yes" or "No")) end
    print("")
  end

  print(string.rep("━", 80))
end

--------------------------------------------------------------------------------
-- CONNECTIONS NAMESPACE (for future connection watcher)
--------------------------------------------------------------------------------

M.connections = {}

-- Log a connection event
function M.connections.logEvent(data)
  if not M.db then
    U.log.e("Database not initialized - cannot log connection event")
    return false
  end

  local timestamp = data.timestamp or os.time()
  local event_type = escapeSql(data.event_type or "unknown")
  local duration = data.duration_seconds or "NULL"

  local query = fmt(
    [[
    INSERT INTO connection_events
    (timestamp, event_type, duration_seconds)
    VALUES (%d, '%s', %s)
  ]],
    timestamp,
    event_type,
    duration == "NULL" and "NULL" or duration
  )

  return M.db:execute(query) ~= nil
end

-- Get recent connection events (non-dismissed only)
function M.connections.getEvents(hours)
  hours = hours or 24
  local cutoff = os.time() - (hours * 3600)

  local query = fmt(
    [[
    SELECT
      id,
      timestamp,
      datetime(timestamp, 'unixepoch', 'localtime') as time,
      event_type,
      duration_seconds
    FROM connection_events
    WHERE timestamp > %d AND dismissed = 0
    ORDER BY timestamp DESC
  ]],
    cutoff
  )

  local results = {}
  for row in M.db:nrows(query) do
    table.insert(results, row)
  end

  return results
end

--- Dismiss connection events from menubar
function M.connections.dismissAll()
  if not M.db then
    U.log.e("Database not initialized - cannot dismiss connection events")
    return false
  end

  local query = "UPDATE connection_events SET dismissed = 1 WHERE dismissed = 0"
  return M.db:execute(query) ~= nil
end

--------------------------------------------------------------------------------
-- CACHE NAMESPACE
--------------------------------------------------------------------------------

M.cache = {}

-- Set cache value with optional TTL
function M.cache.set(key, value, ttlSeconds)
  if not M.db then
    U.log.e("Database not initialized - cannot set cache")
    return false
  end

  key = escapeSql(key)
  value = escapeSql(value)
  local expiresAt = ttlSeconds and (os.time() + ttlSeconds) or "NULL"

  local query = fmt(
    [[
    INSERT OR REPLACE INTO user_cache
    (key, value, cached_at, expires_at)
    VALUES ('%s', '%s', %d, %s)
  ]],
    key,
    value,
    os.time(),
    expiresAt == "NULL" and "NULL" or expiresAt
  )

  return M.db:execute(query) ~= nil
end

-- Get cache value
function M.cache.get(key)
  if not M.db then return nil end

  key = escapeSql(key)

  local query = fmt(
    [[
    SELECT value, expires_at
    FROM user_cache
    WHERE key = '%s'
  ]],
    key
  )

  for row in M.db:nrows(query) do
    -- Check if expired
    if row.expires_at and row.expires_at < os.time() then
      -- Expired, delete and return nil
      M.cache.delete(key)
      return nil
    end
    return row.value
  end

  return nil
end

-- Delete cache entry
function M.cache.delete(key)
  if not M.db then return false end

  key = escapeSql(key)

  local query = fmt([[
    DELETE FROM user_cache WHERE key = '%s'
  ]], key)

  return M.db:execute(query) ~= nil
end

-- Cleanup expired cache entries
function M.cache.cleanup()
  if not M.db then return false end

  local query = fmt([[
    DELETE FROM user_cache
    WHERE expires_at IS NOT NULL AND expires_at < %d
  ]], os.time())

  return M.db:execute(query) ~= nil
end

return M
