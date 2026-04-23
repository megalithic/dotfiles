-- Pi Coding Agent Interop
-- Allows Hammerspoon to send messages to pi sessions via Unix socket
--
-- Uses hs.socket for persistent bidirectional connections to bridge.ts.
-- Connections are pooled per socket path with auto-reconnect on failure.
--
-- SOCKET CONFIGURATION (nix is single source of truth):
--   Pattern: /tmp/pi-{session}-{window}.sock (one socket per tmux window)
--   Env vars (defined in ~/.dotfiles/home/common/programs/ai/pi-coding-agent/default.nix):
--     - PI_SOCKET_DIR: /tmp
--     - PI_SOCKET_PREFIX: pi
--     - PI_SESSION: tmux session name
--     - PI_WINDOW: tmux window index
--
-- Used by:
--   - pinvim/pisock/p wrapper (sets PI_SOCKET env var)
--   - bridge.ts extension (listens on PI_SOCKET)
--   - config/nvim/after/plugin/pi-bridge.lua (connects to socket)
--   - This file (forwards Telegram messages)
--   - bin/ftm (checks for socket existence)
--   - bin/tmux-toggle-pi (finds/manages agent window)
--
local M = {}

-- Socket configuration (matches nix config)
local SOCKET_DIR = "/tmp"
local SOCKET_PREFIX = "pi"

---Default pi session for Telegram forwarding
local DEFAULT_SESSION = "mega"

---Last active pi session name
---Defaults to "mega" - can be overridden by trackLastActive()
M.lastActiveSession = DEFAULT_SESSION

---Last active pi window (for multi-instance support)
M.lastActiveWindow = nil

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

  if conn.socket then
    pcall(function() conn.socket:disconnect() end)
  end

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
    if conn.reconnectTimer then
      pcall(function() conn.reconnectTimer:stop() end)
    end
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
    if isConnected then
      return conn
    end
    -- Stale connection, clean up
    closeConnection(path)
  end

  -- Check socket file exists
  local output = hs.execute(string.format("test -S '%s' && echo yes", path))
  if not output or not output:match("yes") then
    return nil
  end

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
    if c and c.socket and c.connected then
      pcall(function() c.socket:read("\n") end)
    end
  end)

  if not sock then
    U.log.wf("failed to create socket for %s", path)
    return nil
  end

  newConn.socket = sock
  connections[path] = newConn

  -- Connect to Unix domain socket
  local result = sock:connect(path, function()
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

  -- Connection is async, but return the conn object.
  -- Caller should check conn.connected before writing.
  -- For the common case, hs.socket connects very fast for local Unix sockets.
  return newConn
end

-- =============================================================================
-- Socket Path Resolution
-- =============================================================================

---Check whether a socket path is an ephemeral pi (spawned via <localleader>pn).
---Ephemerals contain `-eph-` in the basename and must NEVER be picked by
---Hammerspoon forwarders (Telegram, tell, lastActiveSession).
---@param path string|nil
---@return boolean
local function isEphemeralSocket(path)
  if not path then return false end
  return path:match("%-eph%-[^/]+%.sock$") ~= nil
end

---Get socket path for a session and optional window
---@param session string Session name (e.g., "mega")
---@param window string|nil Window index (e.g., "0", "agent"). If nil, finds first available non-ephemeral.
---@return string|nil Socket path like /tmp/pi-mega-0.sock or nil if not found
local function getSocketPath(session, window)
  if window then
    local p = string.format("%s/%s-%s-%s.sock", SOCKET_DIR, SOCKET_PREFIX, session, window)
    if isEphemeralSocket(p) then return nil end
    return p
  else
    -- Find first available NON-ephemeral socket for this session
    local pattern = string.format("%s/%s-%s-*.sock", SOCKET_DIR, SOCKET_PREFIX, session)
    local output = hs.execute(string.format("ls %s 2>/dev/null | grep -v -- '-eph-' | head -1", pattern))
    if output and output ~= "" then
      return output:gsub("%s+$", "")  -- trim trailing whitespace
    end
    return nil
  end
end

---Parse tmux context to get session and window
---@param context string Format: "session:window:pane:pid" or "session-window" or just "session"
---@return string|nil session, string|nil window
local function parseContext(context)
  if not context then return nil, nil end

  -- Handle new format: session-window (from socket path)
  local session, window = context:match("^([^-]+)-([^-]+)$")
  if session and window then
    return session, window
  end

  -- Handle legacy format: session:window:pane:pid
  session = context:match("^([^:]+)")
  window = context:match("^[^:]+:([^:]+)")
  return session, window
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
    conn.socket:write(json .. "\n", -1, function(tag)
      U.log.df("write complete to %s", socketPath)
    end)
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

---Track that a notification was sent from a pi session
---Called by send.lua when telegram flag is set
---@param context string|nil Tmux context (session:window:pane:pid) or session-window
function M.trackLastActive(context)
  if not context then return end
  -- Skip ephemeral pi contexts — they must never become the last-active target
  -- for Telegram/tell forwarders.
  if context:match("%-eph%-") then
    U.log.df("ignoring ephemeral context for lastActive: %s", context)
    return
  end
  local session, window = parseContext(context)
  if session then
    M.lastActiveSession = session
    M.lastActiveWindow = window
    U.log.df("tracked last active session: %s, window: %s", session, window or "any")
  end
end

---Forward a message to the last active pi session
---@param text string Message text
---@param source string Source identifier (e.g., "telegram")
---@return boolean success
function M.forwardMessage(text, source)
  if not M.lastActiveSession then
    U.log.w("no active session to forward message to")
    return false
  end

  local socketPath = getSocketPath(M.lastActiveSession, M.lastActiveWindow)

  if not socketPath then
    U.log.wf("no socket found for session %s", M.lastActiveSession)
    return false
  end

  local payload = {
    type = "telegram",
    text = text,
    source = source or "telegram",
    timestamp = os.time(),
  }

  return sendToSocket(socketPath, payload)
end

---Send a message to a specific pi session
---@param session string Session name (e.g., "mega")
---@param text string Message text
---@param source string Source identifier
---@param window string|nil Optional window index
---@return boolean success
function M.sendToSession(session, text, source, window)
  if not session then
    U.log.w("no session provided")
    return false
  end

  local socketPath = getSocketPath(session, window)

  if not socketPath then
    U.log.wf("no socket found for session %s", session)
    return false
  end

  local payload = {
    type = "telegram",
    text = text,
    source = source or "telegram",
    timestamp = os.time(),
  }

  return sendToSocket(socketPath, payload)
end

---Get list of available pi sockets (ephemerals EXCLUDED — forwarders must
---never auto-pick them).
---@return table Array of { session, window, path, connected }
function M.getActiveSessions()
  local sessions = {}
  local pattern = string.format("%s/%s-*.sock", SOCKET_DIR, SOCKET_PREFIX)
  local output = hs.execute(string.format("ls %s 2>/dev/null", pattern))

  if output then
    for line in output:gmatch("[^\n]+") do
      if not isEphemeralSocket(line) then
        local session, window = line:match("/tmp/pi%-([^-]+)%-([^%.]+)%.sock")
        if session and window then
          local conn = connections[line]
          table.insert(sessions, {
            session = session,
            window = window,
            path = line,
            connected = conn and conn.connected or false,
          })
        end
      end
    end
  end

  return sessions
end

---Get all non-ephemeral sockets for a specific session
---@param session string Session name
---@return table Array of { window, path, connected }
function M.getSessionSockets(session)
  local sockets = {}
  local pattern = string.format("%s/%s-%s-*.sock", SOCKET_DIR, SOCKET_PREFIX, session)
  local output = hs.execute(string.format("ls %s 2>/dev/null", pattern))

  if output then
    for line in output:gmatch("[^\n]+") do
      if not isEphemeralSocket(line) then
        local window = line:match("/tmp/pi%-[^-]+%-([^%.]+)%.sock")
        if window then
          local conn = connections[line]
          table.insert(sockets, {
            window = window,
            path = line,
            connected = conn and conn.connected or false,
          })
        end
      end
    end
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
