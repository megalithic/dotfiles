-- Pi Coding Agent Interop
-- Allows Hammerspoon to send messages to pi sessions via Unix socket
--
local M = {}

---Last active pi context (session:window:pane:pid)
---Set when a notification is sent from pi with telegram flag
M.lastActiveContext = nil

---Parse tmux context to get socket path
---@param context string Format: "session:window:pane:pid"
---@return string|nil Socket path like /tmp/pi-mega-2.sock
local function contextToSocketPath(context)
  if not context then return nil end
  
  -- Parse context: "session:window:pane:pid"
  local session, window = context:match("^([^:]+):(%d+)")
  if not session or not window then return nil end
  
  return string.format("/tmp/pi-%s-%s.sock", session, window)
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
---@param context string|nil Tmux context (session:window:pane:pid)
function M.trackLastActive(context)
  if context then
    M.lastActiveContext = context
    U.log.df("Pi: tracked last active context: %s", context)
  end
end

---Forward a message to the last active pi session
---@param text string Message text
---@param source string Source identifier (e.g., "telegram")
---@return boolean success
function M.forwardMessage(text, source)
  local socketPath = contextToSocketPath(M.lastActiveContext)
  
  if not socketPath then
    U.log.w("Pi: no active session to forward message to")
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
---@param context string Tmux context (session:window:pane:pid)
---@param text string Message text
---@param source string Source identifier
---@return boolean success
function M.sendToSession(context, text, source)
  local socketPath = contextToSocketPath(context)
  
  if not socketPath then
    U.log.wf("Pi: invalid context: %s", context or "nil")
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
  local output = hs.execute("ls /tmp/pi-*.sock 2>/dev/null")
  
  if output then
    for line in output:gmatch("[^\n]+") do
      -- Parse: /tmp/pi-mega-2.sock
      local session, window = line:match("/tmp/pi%-([^-]+)%-(%d+)%.sock")
      if session and window then
        table.insert(sessions, {
          session = session,
          window = tonumber(window),
          path = line,
        })
      end
    end
  end
  
  return sessions
end

return M
