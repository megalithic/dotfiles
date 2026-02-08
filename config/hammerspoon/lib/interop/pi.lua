-- Pi Coding Agent Interop
-- Allows Hammerspoon to send messages to pi sessions via Unix socket
--
-- SOCKET CONFIGURATION (nix is single source of truth):
--   Pattern: /tmp/pi-{session}.sock (one socket per tmux session)
--   Env vars (defined in ~/.dotfiles/home/programs/ai/pi-coding-agent/default.nix):
--     - PI_SOCKET_DIR: /tmp
--     - PI_SOCKET_PREFIX: pi
--
-- Used by:
--   - pinvim/pisock wrapper (sets PI_SOCKET env var)
--   - bridge.ts extension (listens on PI_SOCKET)
--   - config/nvim/after/plugin/pi-bridge.lua (connects to socket)
--   - This file (forwards Telegram messages)
--   - bin/ftm (checks for socket existence)
--   - bin/tmux-pinvim-toggle (finds/manages agent window)
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

---Get socket path for a session
---@param session string Session name (e.g., "mega")
---@return string Socket path like /tmp/pi-mega.sock
local function getSocketPath(session)
  return string.format("%s/%s-%s.sock", SOCKET_DIR, SOCKET_PREFIX, session)
end

---Parse tmux context to get session name
---@param context string Format: "session:window:pane:pid" (legacy) or just "session"
---@return string|nil Session name
local function contextToSession(context)
  if not context then return nil end
  
  -- Handle both formats:
  -- New: just session name
  -- Legacy: "session:window:pane:pid"
  local session = context:match("^([^:]+)")
  return session
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
---@param context string|nil Tmux context (session:window:pane:pid) or just session name
function M.trackLastActive(context)
  if context then
    local session = contextToSession(context)
    if session then
      M.lastActiveSession = session
      U.log.df("Pi: tracked last active session: %s", session)
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
  
  local socketPath = getSocketPath(M.lastActiveSession)
  
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
---@return boolean success
function M.sendToSession(session, text, source)
  if not session then
    U.log.w("Pi: no session provided")
    return false
  end
  
  local socketPath = getSocketPath(session)
  
  local payload = {
    type = "telegram",
    text = text,
    source = source or "telegram",
    timestamp = os.time(),
  }
  
  return sendToSocket(socketPath, payload)
end

---Get list of available pi sockets
---@return table Array of { session, path }
function M.getActiveSessions()
  local sessions = {}
  local pattern = string.format("%s/%s-*.sock", SOCKET_DIR, SOCKET_PREFIX)
  local output = hs.execute(string.format("ls %s 2>/dev/null", pattern))
  
  if output then
    for line in output:gmatch("[^\n]+") do
      -- Parse: /tmp/pi-mega.sock
      local session = line:match("/tmp/pi%-([^%.]+)%.sock")
      if session then
        table.insert(sessions, {
          session = session,
          path = line,
        })
      end
    end
  end
  
  return sessions
end

return M
