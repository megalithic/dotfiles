-- Neovim Integration Library
-- Query and control nvim instances via RPC sockets
--
-- Socket ID formats:
--   - tmux: {session}_{window}_{pane}_{pid} (e.g., "dotfiles_1_0_48115")
--   - non-tmux: global_{pid} (e.g., "global_48115")
--
local M = {}
local fmt = string.format

-- Socket directory (matches neovim autocmd in config/nvim/lua/config/interop.lua)
M.socketDir = "/tmp/nvim-sockets"

--------------------------------------------------------------------------------
-- SOCKET ID PARSING
--------------------------------------------------------------------------------

---@class SocketInfo
---@field id string Full socket ID (e.g., "dotfiles_1_0_48115" or "global_48115")
---@field session string|nil Tmux session name (nil for global)
---@field window number|nil Tmux window index (nil for global)
---@field pane number|nil Tmux pane index (nil for global)
---@field pid number Neovim PID
---@field socket string Path to nvim server socket
---@field is_global boolean True if non-tmux global socket

--- Parse a socket ID into its components
--- Supports both tmux (session_window_pane_pid) and global (global_pid) formats
---@param socketId string Socket ID
---@return SocketInfo|nil Parsed info or nil if invalid
function M.parseSocketId(socketId)
  -- Check for global format first: global_{pid}
  local globalPid = socketId:match("^global_(%d+)$")
  if globalPid then
    return {
      id = socketId,
      session = nil,
      window = nil,
      pane = nil,
      pid = tonumber(globalPid),
      socket = nil, -- filled in by caller
      is_global = true,
    }
  end

  -- Parse tmux format: session_window_pane_pid
  -- (session can contain underscores, so parse from end)
  local pid = socketId:match("_(%d+)$")
  if not pid then return nil end

  local withoutPid = socketId:sub(1, -(#pid + 2)) -- remove _pid
  local pane = withoutPid:match("_(%d+)$")
  if not pane then return nil end

  local withoutPane = withoutPid:sub(1, -(#pane + 2)) -- remove _pane
  local window = withoutPane:match("_(%d+)$")
  if not window then return nil end

  local session = withoutPane:sub(1, -(#window + 2)) -- remove _window
  if session == "" then return nil end

  return {
    id = socketId,
    session = session,
    window = tonumber(window),
    pane = tonumber(pane),
    pid = tonumber(pid),
    socket = nil, -- filled in by caller
    is_global = false,
  }
end

--- Build socket ID prefix for current tmux context
---@return string|nil Prefix like "session_window_pane" or nil if not in tmux
function M.getActiveTmuxPrefix()
  local handle = io.popen("tmux display-message -p '#{session_name}_#{window_index}_#{pane_index}' 2>/dev/null")
  if not handle then return nil end

  local prefix = handle:read("*l")
  handle:close()

  return (prefix and prefix ~= "") and prefix or nil
end

--- Get PID of frontmost application window
--- Returns PID of nvim if frontmost window belongs to a terminal running nvim
---@return number|nil PID or nil if not found/applicable
function M.getFrontmostNvimPid()
  local frontmost = hs.application.frontmostApplication()
  if not frontmost then return nil end

  -- Get the bundle ID to check if it's a terminal
  local bundleId = frontmost:bundleID()
  local terminalBundles = {
    ["com.mitchellh.ghostty"] = true,
    ["net.kovidgoyal.kitty"] = true,
    ["com.apple.Terminal"] = true,
    ["com.googlecode.iterm2"] = true,
  }

  if not terminalBundles[bundleId] then return nil end

  -- Get window title - many terminals show the process name
  local window = frontmost:focusedWindow()
  if not window then return nil end

  local title = window:title()
  if not title or not title:match("n?vim") then return nil end

  -- Try to find nvim child process of this terminal window
  -- This is terminal-specific and may not always work perfectly
  -- For now, we'll rely on the socket file matching by checking all global sockets
  return nil
end

--- Find socket path by PID
---@param pid number Process ID to find
---@return string|nil Socket path or nil if not found
function M.getSocketByPid(pid)
  local socketId = fmt("global_%d", pid)
  local socketFile = fmt("%s/%s", M.socketDir, socketId)

  local f = io.open(socketFile, "r")
  if not f then return nil end

  local socketPath = f:read("*l")
  f:close()

  return (socketPath and socketPath ~= "") and socketPath or nil
end

--- Get most recently modified global socket
---@return string|nil Socket path or nil if none found
function M.getMostRecentGlobalSocket()
  -- Use shell to find most recent global_* file
  local cmd = fmt("ls -t '%s'/global_* 2>/dev/null | head -1", M.socketDir)
  local handle = io.popen(cmd)
  if not handle then return nil end

  local socketFile = handle:read("*l")
  handle:close()

  if not socketFile or socketFile == "" then return nil end

  -- Read socket path from file
  local f = io.open(socketFile, "r")
  if not f then return nil end

  local socketPath = f:read("*l")
  f:close()

  return (socketPath and socketPath ~= "") and socketPath or nil
end

--- Read socket info from a socket ID file
---@param socketId string The socket ID (filename)
---@return SocketInfo|nil Parsed socket info or nil if invalid
local function readSocketInfo(socketId)
  local socketFile = fmt("%s/%s", M.socketDir, socketId)
  local f = io.open(socketFile, "r")
  if not f then return nil end

  local socketPath = f:read("*l")
  f:close()

  if not socketPath or socketPath == "" then return nil end

  local info = M.parseSocketId(socketId)
  if info then
    info.socket = socketPath
  end
  return info
end

--------------------------------------------------------------------------------
-- SOCKET DISCOVERY
--------------------------------------------------------------------------------

--- Get all registered nvim sockets
---@return table<string, SocketInfo> Map of socket_id -> SocketInfo (with socket path)
function M.getSockets()
  local sockets = {}
  local dir = io.popen(fmt("ls '%s' 2>/dev/null", M.socketDir))
  if not dir then return sockets end

  for socketId in dir:lines() do
    local socketFile = fmt("%s/%s", M.socketDir, socketId)
    local f = io.open(socketFile, "r")
    if f then
      local socketPath = f:read("*l")
      f:close()
      if socketPath and socketPath ~= "" then
        local info = M.parseSocketId(socketId)
        if info then
          info.socket = socketPath
          sockets[socketId] = info
        end
      end
    end
  end
  dir:close()

  return sockets
end

--- Get socket for the currently active context
--- Detection cascade:
---   1. Tmux context (session_window_pane prefix match)
---   2. Frontmost application PID match (for global sockets)
---   3. Most recent global socket (fallback)
---@return string|nil Socket path or nil if not found
function M.getActiveSocket()
  -- 1. Try tmux-based detection first (existing behavior)
  local prefix = M.getActiveTmuxPrefix()
  if prefix then
    local handle = io.popen(fmt("ls '%s' 2>/dev/null | grep '^%s_'", M.socketDir, prefix))
    if handle then
      local socketId = handle:read("*l")
      handle:close()

      if socketId and socketId ~= "" then
        local socketFile = fmt("%s/%s", M.socketDir, socketId)
        local f = io.open(socketFile, "r")
        if f then
          local socketPath = f:read("*l")
          f:close()
          if socketPath and socketPath ~= "" then
            return socketPath
          end
        end
      end
    end
  end

  -- 2. Try frontmost application detection (requires Hammerspoon running)
  local frontmostPid = M.getFrontmostNvimPid()
  if frontmostPid then
    local socket = M.getSocketByPid(frontmostPid)
    if socket then return socket end
  end

  -- 3. Fallback to most recent global socket
  return M.getMostRecentGlobalSocket()
end

--- Get socket info for the currently active context
--- Detection cascade (same as getActiveSocket, but returns full SocketInfo):
---   1. Tmux context (session_window_pane prefix match)
---   2. Frontmost application PID match (for global sockets)
---   3. Most recent global socket (fallback)
---@return SocketInfo|nil Socket info or nil if not found
function M.getActiveSocketInfo()
  -- 1. Try tmux-based detection first
  local prefix = M.getActiveTmuxPrefix()
  if prefix then
    local handle = io.popen(fmt("ls '%s' 2>/dev/null | grep '^%s_'", M.socketDir, prefix))
    if handle then
      local socketId = handle:read("*l")
      handle:close()

      if socketId and socketId ~= "" then
        local info = readSocketInfo(socketId)
        if info then return info end
      end
    end
  end

  -- 2. Try frontmost application detection
  local frontmostPid = M.getFrontmostNvimPid()
  if frontmostPid then
    local socketId = fmt("global_%d", frontmostPid)
    local info = readSocketInfo(socketId)
    if info then return info end
  end

  -- 3. Fallback to most recent global socket
  local cmd = fmt("ls -t '%s'/global_* 2>/dev/null | head -1", M.socketDir)
  local handle = io.popen(cmd)
  if handle then
    local socketFile = handle:read("*l")
    handle:close()

    if socketFile and socketFile ~= "" then
      -- Extract socket ID from full path
      local socketId = socketFile:match("([^/]+)$")
      if socketId then
        return readSocketInfo(socketId)
      end
    end
  end

  return nil
end

--- Find sockets by tmux session name
---@param sessionName string Tmux session name
---@return table<string, SocketInfo> Matching sockets
function M.getSocketsBySession(sessionName)
  local all = M.getSockets()
  local filtered = {}
  for id, info in pairs(all) do
    if info.session == sessionName then
      filtered[id] = info
    end
  end
  return filtered
end

--------------------------------------------------------------------------------
-- NVIM RPC QUERIES
--------------------------------------------------------------------------------

--- Execute nvim command via --remote-expr
---@param socket string Socket path
---@param expr string Vimscript/Lua expression to evaluate
---@return string|nil Result or nil on error
function M.eval(socket, expr)
  if not socket then return nil end

  -- Escape the expression for shell
  local escaped = expr:gsub("'", "'\\''")
  local cmd = fmt("nvim --server '%s' --remote-expr '%s' 2>/dev/null", socket, escaped)

  local handle = io.popen(cmd)
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  -- Trim trailing newline
  if result then
    result = result:gsub("\n$", "")
  end

  return (result and result ~= "") and result or nil
end

--- Execute nvim Lua code and return result
---@param socket string Socket path
---@param luaCode string Lua code to execute (should return a value)
---@return string|nil Result or nil on error
function M.lua(socket, luaCode)
  if not socket then return nil end
  return M.eval(socket, fmt("luaeval('%s')", luaCode:gsub("'", "''")))
end

--- Send keys to nvim
---@param socket string Socket path
---@param keys string Keys to send (in nvim notation)
---@return boolean Success
function M.sendKeys(socket, keys)
  if not socket then return false end

  local escaped = keys:gsub("'", "'\\''")
  local cmd = fmt("nvim --server '%s' --remote-send '%s' 2>/dev/null", socket, escaped)

  local result = os.execute(cmd)
  return result == 0 or result == true
end

--- Open a file in nvim
---@param socket string Socket path
---@param filePath string Path to file
---@return boolean Success
function M.openFile(socket, filePath)
  if not socket then return false end

  local escaped = filePath:gsub("'", "'\\''")
  local cmd = fmt("nvim --server '%s' --remote '%s' 2>/dev/null", socket, escaped)

  local result = os.execute(cmd)
  return result == 0 or result == true
end

--------------------------------------------------------------------------------
-- CONTEXT QUERIES (High-level helpers)
--------------------------------------------------------------------------------

--- Get current buffer info from nvim
---@param socket string|nil Socket path (uses active socket if nil)
---@return table|nil { path, name, filetype, modified, line, col }
function M.getBufferInfo(socket)
  socket = socket or M.getActiveSocket()
  if not socket then return nil end

  -- Query multiple values in one call for efficiency
  local luaCode = [[
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local pos = vim.api.nvim_win_get_cursor(win)
    return vim.json.encode({
      path = vim.api.nvim_buf_get_name(buf),
      name = vim.fn.expand('%:t'),
      filetype = vim.bo[buf].filetype,
      modified = vim.bo[buf].modified,
      line = pos[1],
      col = pos[2] + 1
    })
  ]]

  local result = M.lua(socket, luaCode)
  if not result then return nil end

  -- Parse JSON result
  local ok, decoded = pcall(hs.json.decode, result)
  if not ok then return nil end

  return decoded
end

--- Get visual selection from nvim
---@param socket string|nil Socket path (uses active socket if nil)
---@return string|nil Selected text or nil
function M.getVisualSelection(socket)
  socket = socket or M.getActiveSocket()
  if not socket then return nil end

  -- This only works if we're in visual mode or just exited it
  -- Uses the '< and '> marks
  local luaCode = [[
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local end_pos = vim.api.nvim_buf_get_mark(0, '>')
    if start_pos[1] == 0 then return '' end
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, end_pos[1], false)
    if #lines == 0 then return '' end
    if #lines == 1 then
      return lines[1]:sub(start_pos[2] + 1, end_pos[2] + 1)
    end
    lines[1] = lines[1]:sub(start_pos[2] + 1)
    lines[#lines] = lines[#lines]:sub(1, end_pos[2] + 1)
    return table.concat(lines, '\n')
  ]]

  return M.lua(socket, luaCode)
end

--- Check if nvim is currently in a notes buffer
---@param socket string|nil Socket path (uses active socket if nil)
---@param notesPath string|nil Path to notes directory (defaults to $NOTES_HOME)
---@return boolean
function M.isInNotes(socket, notesPath)
  socket = socket or M.getActiveSocket()
  if not socket then return false end

  notesPath = notesPath or os.getenv("NOTES_HOME")
  if not notesPath then return false end

  local bufPath = M.eval(socket, "expand('%:p')")
  if not bufPath then return false end

  return bufPath:find(notesPath, 1, true) ~= nil
end

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

--- Check if any nvim instances are running
---@return boolean
function M.hasActiveInstances()
  local sockets = M.getSockets()
  for _ in pairs(sockets) do
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- STANDALONE SERVER MANAGEMENT (for scratchpads, not tmux-based)
--------------------------------------------------------------------------------

-- Default socket path for notes scratchpad
M.NOTES_SOCKET = "/tmp/hammerspoon-notes.sock"

--- Check if a standalone socket file exists
---@param socketPath string Path to the socket file
---@return boolean exists
function M.socketExists(socketPath)
  return hs.fs.attributes(socketPath) ~= nil
end

--- Check if nvim server is actually responding on a standalone socket (async)
---@param socketPath string Path to the socket file
---@param callback fun(running: boolean) Called with result
function M.isStandaloneServerRunning(socketPath, callback)
  if not M.socketExists(socketPath) then
    callback(false)
    return
  end

  -- Try to evaluate a simple expression on the server
  local task = hs.task.new("/usr/bin/env", function(exitCode, _, _)
    callback(exitCode == 0)
  end, { "nvim", "--server", socketPath, "--remote-expr", "1" })

  if task then
    task:start()
  else
    callback(false)
  end
end

--- Synchronous check if standalone server is running (blocks briefly)
---@param socketPath string Path to the socket file
---@return boolean running
function M.isStandaloneServerRunningSync(socketPath)
  if not M.socketExists(socketPath) then
    return false
  end

  -- Quick sync check
  local _, status = hs.execute(
    fmt("nvim --server '%s' --remote-expr '1' 2>/dev/null", socketPath)
  )
  return status == true
end

--- Open a file in a standalone nvim server (async, with callback)
---@param socketPath string Path to the socket file
---@param filePath string Path to the file to open
---@param callback? fun(success: boolean) Optional callback
function M.openFileAsync(socketPath, filePath, callback)
  local task = hs.task.new("/usr/bin/env", function(exitCode, _, _)
    if callback then callback(exitCode == 0) end
  end, { "nvim", "--server", socketPath, "--remote", filePath })

  if task then
    task:start()
  elseif callback then
    callback(false)
  end
end

--- Remove an orphan socket file
---@param socketPath string Path to the socket file
---@return boolean removed
function M.cleanupSocket(socketPath)
  if M.socketExists(socketPath) then
    local ok, err = os.remove(socketPath)
    if not ok then
      U.log.w(fmt("Failed to remove socket %s: %s", socketPath, err or "unknown"))
      return false
    end
    U.log.d(fmt("Cleaned up orphan socket: %s", socketPath))
    return true
  end
  return true -- Nothing to clean
end

--- Ensure socket is ready for use (clean up if orphaned, async)
---@param socketPath string Path to the socket file
---@param callback fun(ready: boolean) Called when ready
function M.ensureSocketReady(socketPath, callback)
  if not M.socketExists(socketPath) then
    callback(true) -- No socket, ready to create
    return
  end

  -- Socket exists - check if server is actually running
  M.isStandaloneServerRunning(socketPath, function(running)
    if running then
      callback(true) -- Server is running, socket is valid
    else
      -- Orphan socket - clean it up
      M.cleanupSocket(socketPath)
      callback(true)
    end
  end)
end

--- Get nvim arguments for starting as a server
---@param socketPath string Path to the socket file
---@param filePath string Initial file to open
---@return table args Arguments for nvim
function M.getServerArgs(socketPath, filePath)
  return { "nvim", "--listen", socketPath, filePath }
end

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

--- Debug: Print all registered sockets
function M.debugSockets()
  local sockets = M.getSockets()
  print("\nRegistered nvim sockets:")
  print(string.rep("━", 80))

  local count = 0
  for socketId, info in pairs(sockets) do
    count = count + 1
    print(fmt("  %s", socketId))
    print(fmt("    Session: %s | Window: %d | Pane: %d | PID: %d",
      info.session, info.window, info.pane, info.pid))
    print(fmt("    Socket: %s", info.socket))

    -- Try to get buffer info
    local bufInfo = M.getBufferInfo(info.socket)
    if bufInfo then
      print(fmt("    Buffer: %s (%s)", bufInfo.name or "(unnamed)", bufInfo.filetype or "no ft"))
      print(fmt("    Path: %s", bufInfo.path or "(no path)"))
      print(fmt("    Position: line %d, col %d", bufInfo.line or 0, bufInfo.col or 0))
    end
    print("")
  end

  if count == 0 then
    print("  (none)")
  end

  print(string.rep("━", 80))

  -- Show current tmux context
  local prefix = M.getActiveTmuxPrefix()
  if prefix then
    print(fmt("Current tmux context: %s_*", prefix))
    local activeSocket = M.getActiveSocket()
    if activeSocket then
      print(fmt("Active nvim socket: %s", activeSocket))
    else
      print("Active nvim socket: (none in current pane)")
    end
  else
    print("Current tmux context: (not in tmux)")
  end

  print(fmt("\nTotal: %d instance(s)\n", count))
end

return M
