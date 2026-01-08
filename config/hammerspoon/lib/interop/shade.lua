--- shade - Toggle the floating notes terminal
--- Uses distributed notifications to communicate with the Shade app
---
--- Architecture (as of 2026-01-08, shade-qji epic):
--- Hammerspoon's role is simplified to:
---   1. Hotkey handling (Hyper+Shift+N, Hyper+Shift+O, etc.)
---   2. Notification dispatch (io.shade.* notifications)
---   3. App lifecycle (launch Shade if not running)
---
--- Shade handles:
---   - Context gathering (AccessibilityHelper, JXABridge, AppTypeDetector)
---   - nvim RPC communication (native msgpack-rpc)
---   - Writing context.json for obsidian.nvim templates
---   - Panel visibility and window management
---
--- Capture workflow:
---   1. Hammerspoon sends io.shade.note.capture notification
---   2. Shade gathers context from frontmost app
---   3. Shade writes ~/.local/state/shade/context.json
---   4. Shade sends :Obsidian command to nvim via native RPC
---   5. obsidian.nvim creates note with template substitutions
---
--- Image capture workflow (clipper):
---   1. clipper.lua prepares image and writes context with imageFilename
---   2. Hammerspoon sends io.shade.note.capture.image notification
---   3. Shade reads context and opens capture-image template
---
--- Binary lookup order:
---   1. Explicit cmd if configured via M.configure({ cmd = "/path/to/shade" })
---   2. Known paths: ~/.local/bin, ~/code/shade/.build/release|debug
---   3. PATH lookup via /usr/bin/env

local M = {}
local notes = require("lib.notes")
local fmt = string.format

-- XDG state directory for Shade
local STATE_DIR = os.getenv("HOME") .. "/.local/state/shade"

-- Notification names for IPC (io.shade.* namespace)
local NOTIFICATION_TOGGLE = "io.shade.toggle"
local NOTIFICATION_SHOW = "io.shade.show"
local NOTIFICATION_HIDE = "io.shade.hide"
local NOTIFICATION_QUIT = "io.shade.quit"
local NOTIFICATION_CAPTURE = "io.shade.note.capture"
local NOTIFICATION_DAILY = "io.shade.note.daily"
local NOTIFICATION_CAPTURE_IMAGE = "io.shade.note.capture.image"

-- Export notification names for other modules (e.g., clipper.lua)
M.notifications = {
  toggle = NOTIFICATION_TOGGLE,
  show = NOTIFICATION_SHOW,
  hide = NOTIFICATION_HIDE,
  quit = NOTIFICATION_QUIT,
  capture = NOTIFICATION_CAPTURE,
  daily = NOTIFICATION_DAILY,
  captureImage = NOTIFICATION_CAPTURE_IMAGE,
}

-- Known binary locations (checked in order)
local BINARY_NAME = "shade"
local KNOWN_PATHS = {
  os.getenv("HOME") .. "/.local/bin/shade", -- Installed via `just install`
  os.getenv("HOME") .. "/code/shade/.build/release/shade", -- Release build
  os.getenv("HOME") .. "/code/shade/.build/debug/shade", -- Debug build
}

-- Socket path for nvim RPC (XDG compliant)
local NVIM_SOCKET = STATE_DIR .. "/nvim.sock"

-- Error log path for debugging
local ERROR_LOG = STATE_DIR .. "/errors.log"

-- Default configuration
local config = {
  -- shade binary (nil = auto-detect via PATH or known locations)
  cmd = nil,

  -- Panel size (0.0-1.0 = percentage, >1.0 = pixels)
  width = 0.45,
  height = 0.5,

  -- Command to run (nil = default shell)
  -- Example: "nvim ~/notes/capture.md"
  command = nil,

  -- Working directory (nil = home)
  workingDirectory = nil,

  -- Start hidden (wait for first toggle)
  startHidden = true,
}

--- Configure shade settings
---@param opts table Configuration options
function M.configure(opts)
  for k, v in pairs(opts) do
    config[k] = v
  end
end

--- Check if a file exists and is executable
---@param path string
---@return boolean
local function isExecutable(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    -- Check if executable (crude but works)
    return os.execute("test -x " .. hs.fs.pathToAbsolute(path)) == true
  end
  return false
end

--- Find the shade binary
--- Returns executable path and whether to use env wrapper
---@return string|nil path, boolean useEnv
local function findBinary()
  -- 1. Explicit path configured
  if config.cmd then
    if isExecutable(config.cmd) then
      return config.cmd, false
    else
      U.log.w(fmt("Configured cmd not found: %s", config.cmd))
    end
  end

  -- 2. Check known paths
  for _, path in ipairs(KNOWN_PATHS) do
    if isExecutable(path) then
      U.log.i(fmt("Found binary at: %s", path))
      return path, false
    end
  end

  -- 3. Fall back to PATH lookup via env
  -- This will find ~/.local/bin/shade if installed
  U.log.d(fmt("Using PATH lookup for: %s", BINARY_NAME))
  return BINARY_NAME, true
end

--- Post a distributed notification to the Shade app
---@param name string The notification name
local function postNotification(name) hs.distributednotifications.post(name, nil, nil) end

--- Ensure state directory exists
local function ensureStateDir()
  os.execute("mkdir -p " .. STATE_DIR)
end

--- Log error to file for debugging
---@param operation string What operation failed
---@param details string Error details
local function logError(operation, details)
  ensureStateDir()
  local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
  local entry = fmt("[%s] %s: %s\n", timestamp, operation, details)

  local f = io.open(ERROR_LOG, "a")
  if f then
    f:write(entry)
    f:close()
  end

  U.log.e(fmt("shade: %s - %s", operation, details))
end

--- Build CLI arguments from config
---@return table args Array of CLI arguments
local function buildArgs()
  local args = {}

  if config.width then
    table.insert(args, "--width")
    table.insert(args, tostring(config.width))
  end

  if config.height then
    table.insert(args, "--height")
    table.insert(args, tostring(config.height))
  end

  if config.command then
    table.insert(args, "--command")
    table.insert(args, config.command)
  end

  if config.workingDirectory then
    table.insert(args, "--working-directory")
    table.insert(args, config.workingDirectory)
  end

  if config.startHidden then table.insert(args, "--hidden") end

  return args
end

--- Toggle the shade panel visibility
function M.toggle()
  postNotification(NOTIFICATION_TOGGLE)
  -- Move to primary screen after a short delay to let it appear
  hs.timer.doAfter(0.1, M.moveToMainScreen)
end

--- Show the shade panel
function M.show()
  postNotification(NOTIFICATION_SHOW)
  -- Move to primary screen after a short delay to let it appear
  hs.timer.doAfter(0.1, M.moveToMainScreen)
end

--- Hide the shade panel
function M.hide() postNotification(NOTIFICATION_HIDE) end

--- Quit the shade app
function M.quit() postNotification(NOTIFICATION_QUIT) end

--- Get the Shade application
---@return hs.application|nil
function M.getApp()
  for _, app in ipairs(hs.application.runningApplications()) do
    if app:name() == BINARY_NAME then return app end
  end
  return nil
end

--- Move Shade window to the primary (main) screen, centered
function M.moveToMainScreen()
  local app = M.getApp()
  if not app then return end

  local win = app:mainWindow()
  if not win then return end

  local primaryScreen = hs.screen.primaryScreen()
  if not primaryScreen then return end

  -- Only move if not already on primary screen
  local currentScreen = win:screen()
  if currentScreen and currentScreen:id() == primaryScreen:id() then return end

  -- Get window and screen dimensions
  local winFrame = win:frame()
  local screenFrame = primaryScreen:frame()

  -- Center the window on primary screen
  local newFrame = {
    x = screenFrame.x + (screenFrame.w - winFrame.w) / 2,
    y = screenFrame.y + (screenFrame.h - winFrame.h) / 2,
    w = winFrame.w,
    h = winFrame.h,
  }

  win:setFrame(newFrame)
  U.log.d("Moved Shade to primary screen")
end

--- Check if shade is running
--- Uses process name matching to avoid false positives from window titles
---@return boolean
function M.isRunning()
  -- hs.application.find() does fuzzy matching on window titles too,
  -- which causes false positives (e.g., terminal with "shade" in title).
  -- Instead, look for exact process name match.
  for _, app in ipairs(hs.application.runningApplications()) do
    if app:name() == BINARY_NAME then return true end
  end
  return false
end

--- Launch shade with configured settings
---@param callback? fun() Optional callback when app is ready
function M.launch(callback)
  local binaryPath, useEnv = findBinary()
  local args = buildArgs()

  local executable, taskArgs
  if useEnv then
    -- Use /usr/bin/env to find binary in PATH
    executable = "/usr/bin/env"
    taskArgs = { binaryPath }
    for _, arg in ipairs(args) do
      table.insert(taskArgs, arg)
    end
  else
    -- Direct path to binary
    executable = binaryPath
    taskArgs = args
  end

  U.log.i(fmt("Launching: %s %s", executable, table.concat(taskArgs, " ")))

  local task = hs.task.new(executable, nil, taskArgs)
  if not task then
    U.log.e(fmt("Failed to create task for %s", executable))
    hs.alert.show("shade: Failed to launch", 2)
    return
  end

  task:start()

  -- Wait for app to start, then call callback
  if callback then hs.timer.doAfter(1, callback) end
end

--- Launch shade if not running, then show
---@param callback? fun() Optional callback when shade is shown
function M.ensureRunning(callback)
  if not M.isRunning() then
    M.launch(function()
      M.show()
      if callback then hs.timer.doAfter(0.3, callback) end
    end)
  else
    M.show()
    if callback then hs.timer.doAfter(0.1, callback) end
  end
end

--- Toggle with auto-launch: launch if not running, toggle if running
function M.smartToggle()
  if M.isRunning() then
    M.toggle()
  else
    M.ensureRunning()
  end
end

--- Get today's daily note path (from notes lib)
---@return string path
function M.getDailyNotePath() return notes.getDailyNotePath() end

--- Get captures directory path (from notes lib)
---@return string path
function M.getCapturesDir() return notes.capturesDir end

--- Get notes home directory (from notes lib)
---@return string path
function M.getNotesHome() return notes.notesHome end

--- Get the nvim socket path
---@return string path
function M.getSocketPath() return NVIM_SOCKET end

--- Get the state directory path
---@return string path
function M.getStateDir() return STATE_DIR end

--------------------------------------------------------------------------------
-- CONTEXT FILE MANAGEMENT
--------------------------------------------------------------------------------

--- Write context to JSON file for Shade to read
--- Shade reads from ~/.local/state/shade/context.json
---@param ctx table Context object from context.getContext()
---@return boolean success
function M.writeContext(ctx)
  ensureStateDir()

  local contextPath = STATE_DIR .. "/context.json"
  local json = hs.json.encode(ctx)
  if not json then
    U.log.e("Failed to encode context to JSON")
    return false
  end

  local f = io.open(contextPath, "w")
  if not f then
    U.log.e(fmt("Failed to open context file for writing: %s", contextPath))
    return false
  end

  f:write(json)
  f:close()

  U.log.d(fmt("Wrote context to %s", contextPath))
  return true
end

--------------------------------------------------------------------------------
-- NVIM SERVER HELPERS
--------------------------------------------------------------------------------

--- Check if nvim server is running (synchronous)
---@return boolean
function M.isNvimServerRunning()
  local cmd = fmt("nvim --server '%s' --remote-expr '1' 2>/dev/null", NVIM_SOCKET)
  local _, status = hs.execute(cmd, true) -- true = load user's shell environment (for PATH)
  return status == true
end

--- Send a command to nvim via RPC
--- Uses --remote-send to send keystrokes to the nvim server
---@param nvimCmd string Command to execute (e.g., ":ObsidianToday")
---@return boolean success
---@return string? error Error message if failed
function M.sendNvimCommand(nvimCmd)
  if not M.isNvimServerRunning() then
    local err = "nvim server not running"
    logError("sendNvimCommand", err)
    return false, err
  end

  -- Escape single quotes in command for shell
  local escapedCmd = nvimCmd:gsub("'", "'\\''")

  -- Use --remote-send to send keystrokes (command + Enter)
  local shellCmd = fmt("nvim --server '%s' --remote-send '%s<CR>' 2>&1", NVIM_SOCKET, escapedCmd)
  local output, status = hs.execute(shellCmd, true)

  if status ~= true then
    local err = fmt("command failed: %s (output: %s)", nvimCmd, output or "nil")
    logError("sendNvimCommand", err)
    return false, err
  end

  U.log.d(fmt("Sent nvim command: %s", nvimCmd))
  return true
end

--- Send command to nvim when server becomes ready
--- Uses hs.timer.waitUntil with timeout for safe cleanup
---@param nvimCmd string Command to execute
---@param timeout? number Timeout in seconds (default 5)
---@param onSuccess? fun() Callback on success
---@param onFailure? fun(err: string) Callback on failure
function M.sendNvimCommandWhenReady(nvimCmd, timeout, onSuccess, onFailure)
  timeout = timeout or 5

  local waitTimer = hs.timer.waitUntil(
    M.isNvimServerRunning,
    function()
      local success, err = M.sendNvimCommand(nvimCmd)
      if success then
        if onSuccess then onSuccess() end
      else
        if onFailure then onFailure(err or "unknown error") end
      end
    end,
    0.3 -- check every 300ms
  )

  -- Safety timeout to prevent infinite polling
  hs.timer.doAfter(timeout, function()
    if waitTimer:running() then
      waitTimer:stop()
      local err = fmt("timeout waiting for nvim server to send: %s", nvimCmd)
      logError("sendNvimCommandWhenReady", err)
      hs.alert.show("Nvim server not ready", 2)
      if onFailure then onFailure(err) end
    end
  end)
end

--- Open file when nvim server becomes ready
--- Uses hs.timer.waitUntil with timeout for safe cleanup
---@param filePath string Path to file to open
---@param timeout? number Timeout in seconds (default 5)
function M.openFileWhenReady(filePath, timeout)
  timeout = timeout or 5

  -- Wait for nvim server to be ready, then open file
  local waitTimer = hs.timer.waitUntil(
    M.isNvimServerRunning,
    function()
      local cmd = fmt("nvim --server '%s' --remote '%s' 2>/dev/null", NVIM_SOCKET, filePath)
      hs.execute(cmd, true) -- true = load user's shell environment (for PATH)
      U.log.d(fmt("Opened file in nvim: %s", filePath))
    end,
    0.3 -- check every 300ms
  )

  -- Safety timeout to prevent infinite polling
  hs.timer.doAfter(timeout, function()
    if waitTimer:running() then
      waitTimer:stop()
      U.log.w(fmt("Timeout waiting for nvim server, file not opened: %s", filePath))
      hs.alert.show("Nvim server not ready", 2)
    end
  end)
end

--------------------------------------------------------------------------------
-- CAPTURE WORKFLOW
--------------------------------------------------------------------------------

--- Open a specific file in shade's nvim instance
--- Uses nvim --remote to send file to existing server
---@param filePath string Path to file to open
---@param callback? fun(success: boolean) Optional callback
function M.openFile(filePath, callback)
  if M.isNvimServerRunning() then
    -- Server running, send file via --remote
    local cmd = fmt("nvim --server '%s' --remote '%s' 2>/dev/null", NVIM_SOCKET, filePath)
    local _, status = hs.execute(cmd, true)
    if callback then callback(status == true) end
  else
    -- Server not running
    if callback then callback(false) end
  end
end

--- Capture with context: signal Shade to gather context and create a capture note
--- As of 2026-01-08, Shade handles context gathering natively (shade-qji epic).
--- Hammerspoon just sends the notification and ensures Shade is ready.
---
--- Flow:
--- 1. Hammerspoon sends io.shade.note.capture notification
--- 2. Shade gathers context via ContextGatherer.swift
--- 3. Shade writes ~/.local/state/shade/context.json
--- 4. Shade opens nvim with capture template
--- 5. obsidian.nvim reads context.json for template substitution
---
---@return boolean success
function M.captureWithContext()
  local function triggerCapture()
    postNotification(NOTIFICATION_CAPTURE)
    hs.timer.doAfter(0.1, function() M.show() end)
  end

  if M.isRunning() then
    triggerCapture()
  else
    M.launch(function()
      hs.timer.doAfter(0.5, triggerCapture)
    end)
  end

  return true
end

--- Open daily note in Shade
--- As of 2026-01-08, Shade handles :ObsidianToday via native nvim RPC.
--- Hammerspoon just sends the notification and ensures Shade is ready.
function M.openDailyNote()
  local function triggerDaily()
    postNotification(NOTIFICATION_DAILY)
    hs.timer.doAfter(0.1, function() M.show() end)
  end

  if M.isRunning() then
    triggerDaily()
  else
    M.launch(function()
      hs.timer.doAfter(0.5, triggerDaily)
    end)
  end
end

--- Smart capture toggle: if visible, hide; if hidden, capture with context and show
---@return boolean success
function M.smartCaptureToggle()
  if M.isRunning() then
    -- App is running - check if we should toggle or capture
    -- For now, just toggle (capture happens on first show)
    M.toggle()
    return true
  else
    -- App not running - launch then capture
    M.launch(function()
      hs.timer.doAfter(0.5, function() M.captureWithContext() end)
    end)
    return true
  end
end

return M
