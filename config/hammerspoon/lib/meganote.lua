--- meganote - Toggle the floating notes terminal
--- Uses distributed notifications to communicate with the meganote app
---
--- Binary lookup order:
--- 1. Explicit cmd if configured via M.configure({ cmd = "/path/to/meganote" })
--- 2. Known paths: ~/.local/bin, ~/code/meganote/.build/release|debug
--- 3. PATH lookup via /usr/bin/env

local M = {}
local notes = require("lib.notes")

-- Notification names for IPC
local NOTIFICATION_TOGGLE = "com.meganote.toggle"
local NOTIFICATION_SHOW = "com.meganote.show"
local NOTIFICATION_HIDE = "com.meganote.hide"

-- Known binary locations (checked in order)
local BINARY_NAME = "meganote"
local KNOWN_PATHS = {
  os.getenv("HOME") .. "/.local/bin/meganote", -- Installed via `just install`
  os.getenv("HOME") .. "/code/meganote/.build/release/meganote", -- Release build
  os.getenv("HOME") .. "/code/meganote/.build/debug/meganote", -- Debug build
}

-- Default configuration
local config = {
  -- meganote binary (nil = auto-detect via PATH or known locations)
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

--- Configure meganote settings
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

--- Find the meganote binary
--- Returns executable path and whether to use env wrapper
---@return string|nil path, boolean useEnv
local function findBinary()
  -- 1. Explicit path configured
  if config.cmd then
    if isExecutable(config.cmd) then
      return config.cmd, false
    else
      hs.printf("[meganote] WARNING: Configured cmd not found: %s", config.cmd)
    end
  end

  -- 2. Check known paths
  for _, path in ipairs(KNOWN_PATHS) do
    if isExecutable(path) then
      hs.printf("[meganote] Found binary at: %s", path)
      return path, false
    end
  end

  -- 3. Fall back to PATH lookup via env
  -- This will find ~/.local/bin/meganote if installed
  hs.printf("[meganote] Using PATH lookup for: %s", BINARY_NAME)
  return BINARY_NAME, true
end

--- Post a distributed notification to the meganote app
---@param name string The notification name
local function postNotification(name) hs.distributednotifications.post(name, nil, nil) end

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

--- Toggle the meganote panel visibility
function M.toggle() postNotification(NOTIFICATION_TOGGLE) end

--- Show the meganote panel
function M.show() postNotification(NOTIFICATION_SHOW) end

--- Hide the meganote panel
function M.hide() postNotification(NOTIFICATION_HIDE) end

--- Check if meganote is running
---@return boolean
function M.isRunning()
  local app = hs.application.find("meganote")
  return app ~= nil
end

--- Launch meganote with configured settings
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

  hs.printf("[meganote] Launching: %s %s", executable, table.concat(taskArgs, " "))

  local task = hs.task.new(executable, nil, taskArgs)
  if not task then
    hs.printf("[meganote] ERROR: Failed to create task for %s", executable)
    hs.alert.show("meganote: Failed to launch", 2)
    return
  end

  task:start()

  -- Wait for app to start, then call callback
  if callback then hs.timer.doAfter(1, callback) end
end

--- Launch meganote if not running, then show
function M.ensureRunning()
  if not M.isRunning() then
    M.launch(function() M.show() end)
  else
    M.show()
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

--------------------------------------------------------------------------------
-- CAPTURE WORKFLOW
--------------------------------------------------------------------------------

--- Open a specific file in meganote's nvim instance
--- Uses nvim --remote to send file to existing server
---@param filePath string Path to file to open
---@param callback? fun(success: boolean) Optional callback
function M.openFile(filePath, callback)
  local captureSocket = "/tmp/nvim-capture.sock"

  -- Check if nvim server is running
  local checkTask = hs.task.new("/usr/bin/env", function(exitCode)
    if exitCode == 0 then
      -- Server running, send file via --remote
      local remoteTask = hs.task.new("/usr/bin/env", function(remoteExit)
        if callback then callback(remoteExit == 0) end
      end, {
        "nvim",
        "--server",
        captureSocket,
        "--remote",
        filePath,
      })
      if remoteTask then remoteTask:start() end
    else
      -- Server not running, will be started by meganote with this file
      -- Store the file path for when meganote launches
      M._pendingFile = filePath
      if callback then callback(true) end
    end
  end, {
    "nvim",
    "--server",
    captureSocket,
    "--remote-expr",
    "1",
  })
  if checkTask then checkTask:start() end
end

--- Capture with context: create note file, open in meganote, show panel
--- This is the main entry point for quick capture with context
---@return boolean success
function M.captureWithContext()
  local context = require("lib.interop.context")

  -- Gather context from frontmost app
  local ctx = context.getContext()

  -- Create capture note with context
  local success, notePath, captureFilename = notes.createTextCaptureNote(ctx)

  if success and notePath then
    -- Open file in nvim and show panel
    M.openFile(notePath, function(opened)
      if opened then
        -- Small delay to let nvim load the file
        hs.timer.doAfter(0.1, function() M.show() end)
      else
        hs.alert.show("Failed to open capture note", 2)
      end
    end)
    return true
  else
    hs.alert.show("Capture failed: " .. (captureFilename or "unknown error"), 2)
    return false
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
