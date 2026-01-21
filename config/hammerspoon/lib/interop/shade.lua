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
local NOTIFICATION_CAPTURE_SIDEBAR = "io.shade.note.capture.sidebar"
local NOTIFICATION_SIDEBAR_RECALL = "io.shade.sidebar.recall"

-- Export notification names for other modules (e.g., clipper.lua)
M.notifications = {
  toggle = NOTIFICATION_TOGGLE,
  show = NOTIFICATION_SHOW,
  hide = NOTIFICATION_HIDE,
  quit = NOTIFICATION_QUIT,
  capture = NOTIFICATION_CAPTURE,
  daily = NOTIFICATION_DAILY,
  captureImage = NOTIFICATION_CAPTURE_IMAGE,
  captureSidebar = NOTIFICATION_CAPTURE_SIDEBAR,
  sidebarRecall = NOTIFICATION_SIDEBAR_RECALL,
}

-- Binary paths by version enum
-- _G.SHADE_VER controls which binary to use: "debug" | "release" | "install" | "/custom/path"
local BINARY_NAME = "shade"
local BINARY_PATHS = {
  install = os.getenv("HOME") .. "/.local/bin/shade",
  release = os.getenv("HOME") .. "/code/shade/.build/release/shade",
  debug = os.getenv("HOME") .. "/code/shade/.build/debug/shade",
}

--- Resolve binary path from _G.SHADE_VER
--- Returns the path for the configured version, or the version string if it's a custom path
---@return string path Binary path to use
---@return string version The resolved version enum or "custom"
local function resolveBinaryPath()
  local ver = _G.SHADE_VER or "install"

  -- Check if it's a known enum value
  if BINARY_PATHS[ver] then
    return BINARY_PATHS[ver], ver
  end

  -- Otherwise treat as custom path
  return ver, "custom"
end

-- Socket path for nvim RPC (XDG compliant)
local NVIM_SOCKET = STATE_DIR .. "/nvim.sock"

-- Error log path for debugging
local ERROR_LOG = STATE_DIR .. "/errors.log"

-- Default configuration
local config = {
  -- shade binary (nil = auto-detect via PATH or known locations)
  cmd = nil,

  -- -- Panel size (0.0-1.0 = percentage, >1.0 = pixels)
  -- width = 0.5,
  -- height = 0.5,

  -- Command to run (nil = auto-build nvim command with socket)
  -- Example: "nvim ~/notes/capture.md"
  command = nil,

  -- Working directory (nil = use captures dir from notes lib)
  workingDirectory = nil,

  -- Start hidden (wait for first toggle)
  startHidden = false, -- Start visible so nvim actually launches
}

--- Build the default nvim command with socket cleanup and SHADE env var
---@return string command Shell command to launch nvim with socket
local function buildDefaultCommand()
  return fmt("/usr/bin/env zsh -c 'rm -f %s; SHADE=1 exec nvim --listen %s'", NVIM_SOCKET, NVIM_SOCKET)
end

--- Get the effective command (configured or default)
---@return string command
local function getEffectiveCommand() return config.command or buildDefaultCommand() end

--- Get the effective working directory (configured or captures dir)
---@return string|nil workdir
local function getEffectiveWorkingDirectory() return config.workingDirectory or notes.capturesDir end

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
--- Uses _G.SHADE_VER to determine which binary to use
--- Returns executable path and whether to use env wrapper
---@return string|nil path, boolean useEnv
local function findBinary()
  -- 1. Explicit path configured via M.configure({ cmd = ... })
  if config.cmd then
    if isExecutable(config.cmd) then
      return config.cmd, false
    else
      U.log.w(fmt("Configured cmd not found: %s", config.cmd))
    end
  end

  -- 2. Resolve from _G.SHADE_VER
  local path, ver = resolveBinaryPath()
  if isExecutable(path) then
    U.log.i(fmt("Using shade binary [%s]: %s", ver, path))
    return path, false
  end

  -- 3. Binary not found at resolved path - warn and try PATH
  U.log.w(fmt("shade binary not found for SHADE_VER=%s at: %s", ver, path))
  U.log.d(fmt("Falling back to PATH lookup for: %s", BINARY_NAME))
  return BINARY_NAME, true
end

--- Post a distributed notification to the Shade app
---@param name string The notification name
local function postNotification(name) hs.distributednotifications.post(name, nil, nil) end

--- Ensure state directory exists
local function ensureStateDir() os.execute("mkdir -p " .. STATE_DIR) end

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
--- Uses effective command/workdir (falls back to defaults if not configured)
---@return table args Array of CLI arguments
local function buildArgs()
  local args = {}

  -- if config.width then
  --   table.insert(args, "--width")
  --   table.insert(args, tostring(config.width))
  -- end
  --
  -- if config.height then
  --   table.insert(args, "--height")
  --   table.insert(args, tostring(config.height))
  -- end

  -- Always include command (use effective = configured or default nvim)
  local cmd = getEffectiveCommand()
  table.insert(args, "--command")
  table.insert(args, cmd)

  -- Always include working directory (use effective = configured or captures dir)
  local workdir = getEffectiveWorkingDirectory()
  if workdir then
    table.insert(args, "--working-directory")
    table.insert(args, workdir)
  end

  if config.startHidden then table.insert(args, "--hidden") end

  return args
end

--- Toggle the shade panel visibility
--- Note: Shade resets to floating mode when showing from hidden state
function M.toggle()
  postNotification(NOTIFICATION_TOGGLE)
  -- Shade resets to floating mode on show, so sync local state
  inSidebarMode = false
  -- Move to primary screen after a short delay to let it appear
  hs.timer.doAfter(0.1, M.moveToMainScreen)
end

--- Show the shade panel
--- Note: Shade resets to floating mode when showing from hidden state
function M.show()
  postNotification(NOTIFICATION_SHOW)
  -- Shade resets to floating mode on show, so sync local state
  inSidebarMode = false
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

--- Check if Shade is the frontmost (focused) application
--- Used to prevent captures when Shade itself is focused (no useful context to capture)
---@return boolean
local function isShadeFocused()
  local app = hs.application.frontmostApplication()
  return app and app:name() == BINARY_NAME
end

--- Get the Shade window (NSPanel)
--- Note: Shade uses NSPanel which has isStandard()=false, so we find it
--- via allWindows() rather than relying on mainWindow() or standard filters.
--- This enables Hammerspoon to control position/size for sidebar mode.
---@return hs.window|nil
function M.getWindow()
  local app = M.getApp()
  if not app then return nil end

  -- Find the shade window from all windows (includes panels)
  local windows = app:allWindows()
  for _, win in ipairs(windows) do
    if win:title() == "shade" then return win end
  end

  -- Fallback: return first window if title doesn't match
  return windows[1]
end

--- Move Shade window to the primary (main) screen, centered
function M.moveToMainScreen()
  local win = M.getWindow()
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
-- CAPTURE WORKFLOW
--------------------------------------------------------------------------------

--- Capture with context: signal Shade to gather context and create a capture note
--- Shade handles all context gathering internally using its proactive app tracking.
---
--- Flow:
--- 1. Hammerspoon sends io.shade.note.capture notification
--- 2. Shade uses its proactively-tracked lastNonShadeFrontApp for context
--- 3. Shade gathers context (window title, URL, selection, etc.)
--- 4. Shade writes context.json and opens nvim with capture template
---
---@return boolean success
function M.captureWithContext()
  -- Don't capture from Shade itself - there's no useful context
  if isShadeFocused() then
    U.log.d("captureWithContext: ignoring - Shade is focused")
    return false
  end

  local function triggerCapture()
    postNotification(NOTIFICATION_CAPTURE)
    hs.timer.doAfter(0.1, function() M.show() end)
  end

  if M.isRunning() then
    triggerCapture()
  else
    M.launch(function() hs.timer.doAfter(0.5, triggerCapture) end)
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
    M.launch(function() hs.timer.doAfter(0.5, triggerDaily) end)
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

-- =============================================================================
-- Sidebar Mode
-- =============================================================================
-- NOTE: As of 2026-01-13, Shade handles ALL sidebar window management directly
-- using AXUIElement APIs. Hammerspoon just sends the mode notification.
-- No companion window tracking needed here - Shade does it all.

-- Track sidebar state for toggle (simple boolean, not window state)
local inSidebarMode = false

--- Set panel mode (floating, sidebar-left, sidebar-right)
--- Uses separate notification names (more reliable cross-process than userInfo)
---@param mode string The mode to set
function M.setMode(mode)
  local notificationName = "io.shade.mode." .. mode
  hs.distributednotifications.post(notificationName, nil, nil)
  inSidebarMode = (mode ~= "floating")
  U.log.d("shade: sent notification: " .. notificationName)
end

--- Enter sidebar mode on the left
function M.toSidebarLeft() M.setMode("sidebar-left") end

--- Enter sidebar mode on the right
function M.sidebarRight() M.setMode("sidebar-right") end

--- Return to floating mode
function M.toFloating() M.setMode("floating") end

--- Toggle sidebar mode (left sidebar <-> floating)
function M.sidebarToggle()
  if inSidebarMode then
    M.toFloating()
  else
    M.toSidebarLeft()
  end
end

--- Capture with context in sidebar mode
--- Opens Shade in sidebar-left with a new capture note
--- Perfect for taking notes while referencing another app side-by-side
--- Shade captures the focused window element immediately upon receiving the notification,
--- ensuring the correct window is resized even with multiple windows open.
---@return boolean success
function M.captureWithContextSidebar()
  -- Don't capture from Shade itself - there's no useful context
  if isShadeFocused() then
    U.log.d("captureWithContextSidebar: ignoring - Shade is focused")
    return false
  end

  local function triggerSidebarCapture()
    -- Use dedicated sidebar capture notification - Shade handles mode + capture in one step
    postNotification(NOTIFICATION_CAPTURE_SIDEBAR)
    inSidebarMode = true
  end

  if M.isRunning() then
    triggerSidebarCapture()
  else
    M.launch(function() hs.timer.doAfter(0.5, triggerSidebarCapture) end)
  end

  return true
end

--- Recall sidebar mode with the last companion window
--- Re-enters sidebar mode using the previously stored companion window
--- Use this when you want to re-sidebar with the same window you used before
---@return boolean success
function M.recallSidebar()
  if not M.isRunning() then
    U.log.d("recallSidebar: Shade not running, nothing to recall")
    return false
  end

  postNotification(NOTIFICATION_SIDEBAR_RECALL)
  inSidebarMode = true
  return true
end

--- Get info about current binary selection (useful for debugging)
--- Returns table with version enum, resolved path, and whether it exists
---@return table info { version: string, path: string, exists: boolean }
function M.getBinaryInfo()
  local path, ver = resolveBinaryPath()
  return {
    version = ver,
    path = path,
    exists = isExecutable(path),
  }
end

return M
