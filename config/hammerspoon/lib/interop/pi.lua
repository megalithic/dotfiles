-- Pi Coding Agent Interop
-- Allows Hammerspoon to send messages to pi sessions via Unix socket
--
-- Uses hs.socket for persistent bidirectional connections to bridge.ts.
-- Connections are pooled per socket path with auto-reconnect on failure.
--
-- SOCKET CONFIGURATION (mise is single source of truth):
--   Pattern: ${PI_STATE_DIR}/sockets/pi-{session}-{window}-{paneId}.sock (one socket per Pi pane)
--   Env vars and wrapper live under ~/.dotfiles/home/.pi/:
--     - PI_STATE_DIR: ~/.local/state/pi
--     - PI_SESSION: tmux session name
--     - PI_WINDOW: tmux window index
--
-- Used by:
--   - pinvim/pisock/p wrapper (sets PI_SOCKET env var)
--   - bridge.ts extension (listens on PI_SOCKET)
--   - config/nvim/after/plugin/pi-bridge.lua (connects to socket)
--   - lib/interop/pidewave.lua (sends pi.control.v1 payloads via sendPayload)
--   - bin/ftm (checks for socket existence)
--   - bin/tmux-toggle-pi (finds/manages agent window)
--
local M = {}

-- Socket configuration (matches mise config)
local function join_path(...) return table.concat({ ... }, "/") end

local home = os.getenv("HOME") or "~"
local xdgStateHome = os.getenv("XDG_STATE_HOME") or join_path(home, ".local", "state")
local PI_STATE_DIR = os.getenv("PI_STATE_DIR") or join_path(xdgStateHome, "pi")
local MANIFEST_DIR = join_path(PI_STATE_DIR, "manifests")

-- =============================================================================
-- Connection Pool
-- =============================================================================

---@class SocketConnection
---@field socket userdata hs.socket object
---@field path string Socket file path
---@field connected boolean Connection state
---@field reconnectTimer userdata|nil Pending reconnect timer
---@field lastError string|nil Last error message

---Connection pool keyed by socket path
---@type table<string, SocketConnection>
local connections = {}

---Reconnect delay in seconds
local RECONNECT_DELAY = 2

---Max reconnect attempts before giving up (resets on successful send)
local MAX_RECONNECT_ATTEMPTS = 5

---Reconnect attempt counters keyed by socket path
---@type table<string, number>
local reconnectAttempts = {}

---Close and clean up a connection
---@param path string Socket path
local function closeConnection(path)
  local conn = connections[path]
  if not conn then return end

  if conn.reconnectTimer then
    pcall(function() conn.reconnectTimer:stop() end)
    conn.reconnectTimer = nil
  end

  if conn.socket then pcall(function() conn.socket:disconnect() end) end

  connections[path] = nil
  U.log.df("closed connection to %s", path)
end

---Schedule a reconnect attempt for a socket path
---@param path string Socket path to reconnect to
local function scheduleReconnect(path)
  -- Don't reconnect if socket file gone
  local output = hs.execute(string.format("test -S '%s' && echo yes", path))
  if not output or not output:match("yes") then
    U.log.df("socket gone, not reconnecting: %s", path)
    reconnectAttempts[path] = nil
    return
  end

  local attempts = (reconnectAttempts[path] or 0) + 1
  reconnectAttempts[path] = attempts

  if attempts > MAX_RECONNECT_ATTEMPTS then
    U.log.wf("max reconnect attempts reached for %s, giving up", path)
    closeConnection(path)
    reconnectAttempts[path] = nil
    return
  end

  U.log.df("scheduling reconnect %d/%d to %s", attempts, MAX_RECONNECT_ATTEMPTS, path)

  -- Clean up existing connection first
  local conn = connections[path]
  if conn then
    if conn.reconnectTimer then pcall(function() conn.reconnectTimer:stop() end) end
    conn.reconnectTimer = hs.timer.doAfter(RECONNECT_DELAY, function()
      local c = connections[path]
      if c then c.reconnectTimer = nil end
      -- getOrConnect will create a fresh connection
      closeConnection(path)
      -- Intentionally don't call getOrConnect here - next send will reconnect
    end)
  end
end

---Get or create a persistent connection to a socket path
---@param path string Unix socket path
---@return SocketConnection|nil connection
local function getOrConnect(path)
  -- Return existing connected socket
  local conn = connections[path]
  if conn and conn.connected and conn.socket then
    local isConnected = false
    pcall(function() isConnected = conn.socket:connected() end)
    if isConnected then return conn end
    -- Stale connection, clean up
    closeConnection(path)
  end

  -- Check socket file exists
  local output = hs.execute(string.format("test -S '%s' && echo yes", path))
  if not output or not output:match("yes") then return nil end

  -- Create new connection
  local newConn = {
    path = path,
    connected = false,
    socket = nil,
    reconnectTimer = nil,
    lastError = nil,
  }

  -- Create socket with read callback for responses
  local sock = hs.socket.new(function(data, tag)
    if not data or data == "" then return end

    -- Parse newline-delimited JSON responses
    for line in data:gmatch("[^\n]+") do
      local ok, response = pcall(hs.json.decode, line)
      if ok and response then
        if response.ok then
          U.log.df("response ok from %s", path)
        else
          U.log.wf("error response from %s: %s", path, response.error or "unknown")
        end
      end
    end

    -- Keep reading for more responses
    local c = connections[path]
    if c and c.socket and c.connected then pcall(function() c.socket:read("\n") end) end
  end)

  if not sock then
    U.log.wf("failed to create socket for %s", path)
    return nil
  end

  newConn.socket = sock
  connections[path] = newConn

  -- hs.socket passes Unix paths through NSURL, so escape `%` (tmux pane IDs)
  -- and other URL-reserved characters before connecting.
  local connectPath = hs.http.encodeForQuery(path)
  local result = sock:connect(connectPath, function()
    local c = connections[path]
    if c then
      c.connected = true
      reconnectAttempts[path] = 0
      U.log.f("connected to %s", path)
      -- Start reading responses
      pcall(function() c.socket:read("\n") end)
    end
  end)

  if not result then
    U.log.wf("failed to connect to %s", path)
    connections[path] = nil
    return nil
  end

  -- Connection is async; CocoaAsyncSocket queues writes until it connects.
  return newConn
end

-- =============================================================================
-- Session Discovery
-- =============================================================================

---List live, non-ephemeral sockets from authoritative manifests. Manifest
---metadata is required because pane-qualified paths can be shortened and hashed.
---@param wantedSession string|nil
---@return table
local function listManifestSockets(wantedSession)
  local sockets = {}
  pcall(function()
    for filename in hs.fs.dir(MANIFEST_DIR) do
      if filename:match("%.info$") then
        local file = io.open(MANIFEST_DIR .. "/" .. filename, "r")
        local raw = file and file:read("*a") or nil
        if file then file:close() end
        local ok, manifest = pcall(hs.json.decode, raw or "")
        if
          ok
          and manifest
          and not manifest.ephemeral
          and (not wantedSession or manifest.session == wantedSession)
          and manifest.socket
          and hs.fs.attributes(manifest.socket)
        then
          table.insert(sockets, manifest)
        end
      end
    end
  end)
  table.sort(sockets, function(a, b) return tostring(a.socket) < tostring(b.socket) end)
  return sockets
end

-- =============================================================================
-- Send (persistent socket with response parsing)
-- =============================================================================

---Send a message to a pi session's socket via persistent connection
---@param socketPath string
---@param payload table JSON-serializable payload
---@return boolean success Whether the write was initiated
local function sendToSocket(socketPath, payload)
  if not socketPath then
    U.log.w("no socket path provided")
    return false
  end

  local json = hs.json.encode(payload)
  if not json then
    U.log.w("failed to encode payload")
    return false
  end

  local conn = getOrConnect(socketPath)
  if not conn then
    U.log.wf("no connection to %s", socketPath)
    return false
  end

  -- Write the JSON payload + newline
  local ok, err = pcall(function()
    conn.socket:write(json .. "\n", -1, function(tag) U.log.df("write complete to %s", socketPath) end)
  end)

  if not ok then
    U.log.wf("write failed to %s: %s", socketPath, tostring(err))
    conn.connected = false
    scheduleReconnect(socketPath)
    return false
  end

  U.log.f("sent message to %s", socketPath)
  reconnectAttempts[socketPath] = 0
  return true
end

-- =============================================================================
-- Public API
-- =============================================================================

---Send an arbitrary JSON payload to a specific bridge socket path.
---Used by pidewave.lua to deliver `pi.control.v1` requests to the exact
---bound socket instead of session-based resolution.
---@param socketPath string
---@param payload table JSON-serializable payload
---@return boolean success Whether the write was initiated
function M.sendPayload(socketPath, payload)
  return sendToSocket(socketPath, payload)
end

---Get list of available pi sockets (ephemerals EXCLUDED — forwarders must
---never auto-pick them).
---@return table Array of { session, window, windowIndex, pane, paneIndex, path, connected }
function M.getActiveSessions()
  local sessions = {}
  for _, manifest in ipairs(listManifestSockets(nil)) do
    local conn = connections[manifest.socket]
    table.insert(sessions, {
      session = manifest.session,
      window = manifest.window,
      windowIndex = manifest.windowIndex,
      pane = manifest.pane,
      paneIndex = manifest.paneIndex,
      path = manifest.socket,
      connected = conn and conn.connected or false,
    })
  end
  return sessions
end

---Get all non-ephemeral sockets for a specific session
---@param session string Session name
---@return table Array of { window, windowIndex, pane, paneIndex, path, connected }
function M.getSessionSockets(session)
  local sockets = {}
  for _, manifest in ipairs(listManifestSockets(session)) do
    local conn = connections[manifest.socket]
    table.insert(sockets, {
      window = manifest.window,
      windowIndex = manifest.windowIndex,
      pane = manifest.pane,
      paneIndex = manifest.paneIndex,
      path = manifest.socket,
      connected = conn and conn.connected or false,
    })
  end
  return sockets
end

---Get connection status for all active connections
---@return table<string, boolean> Map of socket path → connected status
function M.getConnectionStatus()
  local status = {}
  for path, conn in pairs(connections) do
    status[path] = conn.connected
  end
  return status
end

---Disconnect all persistent connections (call on Hammerspoon reload)
function M.cleanup()
  for path, _ in pairs(connections) do
    closeConnection(path)
  end
  connections = {}
  reconnectAttempts = {}
  U.log.i("all connections closed")
end

return M
