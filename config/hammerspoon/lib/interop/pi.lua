-- Pi Coding Agent Interop
-- Allows Hammerspoon to send messages to pi sessions via Unix socket
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

---Get socket path for a session and optional window
---@param session string Session name (e.g., "mega")
---@param window string|nil Window index (e.g., "0", "agent"). If nil, finds first available.
---@return string|nil Socket path like /tmp/pi-mega-0.sock or nil if not found
local function getSocketPath(session, window)
  if window then
    -- Specific window requested
    return string.format("%s/%s-%s-%s.sock", SOCKET_DIR, SOCKET_PREFIX, session, window)
  else
    -- Find first available socket for this session
    local pattern = string.format("%s/%s-%s-*.sock", SOCKET_DIR, SOCKET_PREFIX, session)
    local output = hs.execute(string.format("ls %s 2>/dev/null | head -1", pattern))
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

---Check if a socket file exists
---@param path string
---@return boolean
local function socketExists(path)
  -- Use test -S to check for socket (io.open doesn't work on sockets)
  local output = hs.execute(string.format("test -S '%s' && echo yes", path))
  return output and output:match("yes") ~= nil
end

---Send a message to a pi session's socket
---@param socketPath string
---@param payload table JSON-serializable payload
---@return boolean success
local function sendToSocket(socketPath, payload)
  if not socketPath then
    U.log.w("Pi: no socket path provided")
    return false
  end
  
  if not socketExists(socketPath) then
    U.log.wf("Pi: socket not found: %s", socketPath)
    return false
  end
  
  local json = hs.json.encode(payload)
  if not json then
    U.log.w("Pi: failed to encode payload")
    return false
  end
  
  -- Send via netcat with -N flag (shutdown after EOF)
  -- Use printf to avoid echo adding extra newline issues
  local cmd = string.format("printf '%%s\\n' '%s' | nc -N -U '%s' 2>/dev/null", 
    json:gsub("'", "'\\''"), -- Escape single quotes for shell
    socketPath)
  
  local output, status = hs.execute(cmd)
  
  if status then
    U.log.f("Pi: sent message to %s", socketPath)
    return true
  else
    U.log.wf("Pi: failed to send to %s: %s", socketPath, output or "unknown error")
    return false
  end
end

---Track that a notification was sent from a pi session
---Called by send.lua when telegram flag is set
---@param context string|nil Tmux context (session:window:pane:pid) or session-window
function M.trackLastActive(context)
  if context then
    local session, window = parseContext(context)
    if session then
      M.lastActiveSession = session
      M.lastActiveWindow = window
      U.log.df("Pi: tracked last active session: %s, window: %s", session, window or "any")
    end
  end
end

---Forward a message to the last active pi session
---@param text string Message text
---@param source string Source identifier (e.g., "telegram")
---@return boolean success
function M.forwardMessage(text, source)
  if not M.lastActiveSession then
    U.log.w("Pi: no active session to forward message to")
    return false
  end
  
  local socketPath = getSocketPath(M.lastActiveSession, M.lastActiveWindow)
  
  if not socketPath then
    U.log.wf("Pi: no socket found for session %s", M.lastActiveSession)
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
    U.log.w("Pi: no session provided")
    return false
  end
  
  local socketPath = getSocketPath(session, window)
  
  if not socketPath then
    U.log.wf("Pi: no socket found for session %s", session)
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

---Get list of available pi sockets
---@return table Array of { session, window, path }
function M.getActiveSessions()
  local sessions = {}
  local pattern = string.format("%s/%s-*.sock", SOCKET_DIR, SOCKET_PREFIX)
  local output = hs.execute(string.format("ls %s 2>/dev/null", pattern))
  
  if output then
    for line in output:gmatch("[^\n]+") do
      -- Parse: /tmp/pi-mega-0.sock or /tmp/pi-mega-agent.sock
      local session, window = line:match("/tmp/pi%-([^-]+)%-([^%.]+)%.sock")
      if session and window then
        table.insert(sessions, {
          session = session,
          window = window,
          path = line,
        })
      end
    end
  end
  
  return sessions
end

---Get all sockets for a specific session
---@param session string Session name
---@return table Array of { window, path }
function M.getSessionSockets(session)
  local sockets = {}
  local pattern = string.format("%s/%s-%s-*.sock", SOCKET_DIR, SOCKET_PREFIX, session)
  local output = hs.execute(string.format("ls %s 2>/dev/null", pattern))
  
  if output then
    for line in output:gmatch("[^\n]+") do
      local window = line:match("/tmp/pi%-[^-]+%-([^%.]+)%.sock")
      if window then
        table.insert(sockets, {
          window = window,
          path = line,
        })
      end
    end
  end
  
  return sockets
end

return M
