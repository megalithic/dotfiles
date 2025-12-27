-- Scratchpad Module
-- Toggle-able floating windows that persist and follow you across spaces
--
-- Uses app:hide()/unhide() pattern from lib/summon.lua
-- Tracks previousApp to restore focus when hiding
--
-- Supports persistent nvim sessions via --listen/--server/--remote
-- for fast file switching without nvim restart overhead
--
local M = {}
local fmt = string.format
local nvimLib = require("lib.interop.nvim")

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

M.config = {
  -- Default floating window size (percentage of screen)
  floatWidth = 0.6,
  floatHeight = 0.5,
  -- Time to wait for window to appear on first launch (seconds)
  windowWaitTime = 0.8,
}

-- Track previously focused app (to restore when hiding scratchpad)
M.previousApp = nil

--------------------------------------------------------------------------------
-- WINDOW HELPERS
--------------------------------------------------------------------------------

--- Calculate centered frame for floating window
---@param screen hs.screen|nil Screen to use (defaults to main screen)
---@return hs.geometry frame
function M.getFloatFrame(screen)
  screen = screen or hs.screen.mainScreen()
  local frame = screen:frame()

  local width = math.floor(frame.w * M.config.floatWidth)
  local height = math.floor(frame.h * M.config.floatHeight)
  local x = math.floor(frame.x + (frame.w - width) / 2)
  local y = math.floor(frame.y + (frame.h - height) / 2)

  return hs.geometry.rect(x, y, width, height)
end

--- Move window to current space and position it
---@param win hs.window
---@param frame? hs.geometry Optional frame to apply
local function moveToCurrentSpace(win, frame)
  if not win then return end

  -- Move to current space
  local currentSpace = hs.spaces.focusedSpace()
  local winSpaces = hs.spaces.windowSpaces(win)

  if winSpaces and not hs.fnutils.contains(winSpaces, currentSpace) then
    hs.spaces.moveWindowToSpace(win, currentSpace)
  end

  -- Apply frame if provided
  if frame then win:setFrame(frame) end
end

--------------------------------------------------------------------------------
-- SCRATCHPAD CORE
--------------------------------------------------------------------------------

--- Find scratchpad window by title pattern
---@param titlePattern string
---@return hs.window|nil
local function findWindowByTitle(titlePattern)
  local allWindows = hs.window.allWindows()
  for _, win in ipairs(allWindows) do
    local title = win:title() or ""
    if title:lower():find(titlePattern:lower(), 1, true) then return win end
  end
  return nil
end

--- Toggle a scratchpad window
--- Uses app:hide()/unhide() pattern, restores previousApp on hide
---@param name string Unique name for this scratchpad
---@param opts table Options
---@field opts.titlePattern string Pattern to find the window by title
---@field opts.launcher function Function to launch if not running
---@field opts.frame? hs.geometry Optional fixed frame
---@return boolean success
function M.toggle(name, opts)
  opts = opts or {}
  local titlePattern = opts.titlePattern or name
  local launcher = opts.launcher
  local frame = opts.frame or M.getFloatFrame()

  -- Try to find existing window
  local win = findWindowByTitle(titlePattern)

  if win then
    local app = win:application()
    if app and app:isFrontmost() and win:isVisible() then
      -- Window is focused and visible -> hide app and restore previous
      app:hide()
      if M.previousApp then M.previousApp:activate() end
      return true
    else
      -- Window exists but not focused -> store previous, show and focus
      local focusedWin = hs.window.focusedWindow()
      if focusedWin then M.previousApp = focusedWin:application() end
      app:unhide()
      moveToCurrentSpace(win, frame)
      win:focus()
      return true
    end
  else
    -- No window found -> store previous app, then launch
    local focusedWin = hs.window.focusedWindow()
    if focusedWin then M.previousApp = focusedWin:application() end

    if launcher then
      launcher()
      -- Wait for window to appear and position it
      hs.timer.doAfter(M.config.windowWaitTime, function()
        local newWin = findWindowByTitle(titlePattern)
        if newWin then
          moveToCurrentSpace(newWin, frame)
          newWin:focus()
        end
      end)
      return true
    else
      hs.alert.show(fmt("Scratchpad '%s' has no launcher", name), 2)
      return false
    end
  end
end

--------------------------------------------------------------------------------
-- GHOSTTY SCRATCHPAD
--------------------------------------------------------------------------------

--- Create a Ghostty-based scratchpad for editing a file
---@param name string Unique name (used in window title)
---@param filePath string Path to file to edit
---@param opts? table Additional options
---@return function toggleFn Function to toggle this scratchpad
function M.ghosttyEditor(name, filePath, opts)
  opts = opts or {}
  local title = opts.title or name

  local function launcher()
    -- On macOS, ghostty CLI doesn't support -e properly
    -- Must use: open -na Ghostty.app --args <ghostty-args>
    local className = "scratchpad-" .. name:gsub("%s+", "-"):lower()
    local task = hs.task.new("/usr/bin/open", nil, {
      "-na",
      "Ghostty.app",
      "--args",
      "--title=" .. title,
      "--class=" .. className,
      "-e",
      "nvim",
      filePath,
    })
    if task then task:start() end
  end

  return function()
    return M.toggle(name, {
      titlePattern = title,
      launcher = launcher,
      frame = opts.frame,
    })
  end
end

--------------------------------------------------------------------------------
-- KITTY SCRATCHPAD
--------------------------------------------------------------------------------

--- Create a Kitty-based scratchpad for editing a file
---@param name string Unique name (used in window title)
---@param filePath string Path to file to edit
---@param opts? table Additional options
---@return function toggleFn Function to toggle this scratchpad
function M.kittyEditor(name, filePath, opts)
  opts = opts or {}
  local title = opts.title or name

  local function launcher()
    -- Use /usr/bin/env to leverage PATH injection from overrides.lua
    -- This finds kitty and nvim via the Nix/Homebrew PATH
    -- Do NOT use -1 (single-instance) as it can cause issues with window control
    local task = hs.task.new("kitty", nil, {
      -- local task = hs.task.new("/usr/bin/env", nil, {
      -- "kitty",
      "--title=" .. title,
      "--override",
      "background_opacity=1.00",
      "-e",
      "nvim",
      filePath,
    })
    if task then task:start() end
  end

  return function()
    return M.toggle(name, {
      titlePattern = title,
      launcher = launcher,
      frame = opts.frame,
    })
  end
end

--------------------------------------------------------------------------------
-- PERSISTENT NVIM SCRATCHPAD (uses --listen/--server/--remote)
--------------------------------------------------------------------------------

--- Create a persistent nvim scratchpad that reuses the same nvim instance
--- First launch: terminal with `nvim --listen <socket> <file>`
--- Subsequent: send `--remote <file>` to existing nvim, focus terminal
---@param terminal "ghostty"|"kitty" Which terminal to use
---@param name string Unique name (used in window title)
---@param socketPath string Path to nvim socket
---@param opts? table Additional options
---@return function toggleFn Function to toggle and open a file
function M.persistentNvimEditor(terminal, name, socketPath, opts)
  opts = opts or {}
  local title = opts.title or name

  --- Launch terminal with nvim listening on socket
  ---@param filePath string Initial file to open
  local function launchServer(filePath)
    local nvimArgs = nvimLib.getServerArgs(socketPath, filePath)
    local task

    if terminal == "kitty" then
      local termArgs = {
        "kitty",
        "--title=" .. title,
        "--override",
        "background_opacity=1.00",
        "-e",
      }
      -- Combine terminal args with nvim args
      for _, arg in ipairs(nvimArgs) do
        table.insert(termArgs, arg)
      end
      task = hs.task.new("/usr/bin/env", nil, termArgs)
    else
      -- On macOS, ghostty CLI doesn't support -e properly
      -- Must use: open -na Ghostty.app --args <ghostty-args>
      local className = "scratchpad-" .. name:gsub("%s+", "-"):lower()
      local termArgs = {
        "-na",
        "Ghostty.app",
        "--args",
        "--title=" .. title,
        "--class=" .. className,
        "-e",
      }
      -- Combine terminal args with nvim args
      for _, arg in ipairs(nvimArgs) do
        table.insert(termArgs, arg)
      end
      task = hs.task.new("/usr/bin/open", nil, termArgs)
    end

    if task then task:start() end
  end

  --- Open a file in existing nvim and focus the window
  ---@param filePath string File to open
  ---@param win hs.window Existing window to focus
  ---@param frame hs.geometry Frame to apply
  local function openInExisting(filePath, win, frame)
    -- Send file to nvim server
    nvimLib.openFileAsync(socketPath, filePath, function(success)
      if not success then U.log.w(fmt("Failed to open %s in nvim server", filePath)) end
    end)

    -- Focus the window
    local app = win:application()
    if app then app:unhide() end
    moveToCurrentSpace(win, frame)
    win:focus()
  end

  --- Toggle the persistent scratchpad with a specific file
  ---@param filePath string File to open
  ---@return boolean success
  return function(filePath)
    local frame = opts.frame or M.getFloatFrame()

    -- Try to find existing window
    local win = findWindowByTitle(title)

    if win then
      local app = win:application()
      if app and app:isFrontmost() and win:isVisible() then
        -- Window is focused and visible -> hide app and restore previous
        app:hide()
        if M.previousApp then M.previousApp:activate() end
        return true
      else
        -- Window exists but not focused -> store previous, open file, focus
        local focusedWin = hs.window.focusedWindow()
        if focusedWin then M.previousApp = focusedWin:application() end
        openInExisting(filePath, win, frame)
        return true
      end
    else
      -- No window found -> check socket status and act accordingly
      local focusedWin = hs.window.focusedWindow()
      if focusedWin then M.previousApp = focusedWin:application() end

      -- Ensure socket is clean (remove orphan if needed)
      nvimLib.ensureSocketReady(socketPath, function(ready)
        if ready then
          launchServer(filePath)
          -- Wait for window to appear and position it
          hs.timer.doAfter(M.config.windowWaitTime, function()
            local newWin = findWindowByTitle(title)
            if newWin then
              moveToCurrentSpace(newWin, frame)
              newWin:focus()
            end
          end)
        else
          U.log.e(fmt("Failed to prepare socket %s", socketPath))
          hs.alert.show("Failed to start nvim server", 2)
        end
      end)
      return true
    end
  end
end

--------------------------------------------------------------------------------
-- PRE-CONFIGURED SCRATCHPADS
--------------------------------------------------------------------------------

--- Create a daily note scratchpad (uses persistent nvim session)
---@param terminal "ghostty"|"kitty" Which terminal to use
---@param usePersistent? boolean Use persistent nvim session (default: true)
---@return function toggleFn
function M.dailyNote(terminal, usePersistent)
  local notesLib = require("lib.notes")
  usePersistent = usePersistent ~= false -- default to true

  -- Ensure daily note exists before creating scratchpad
  local function getOrCreateDailyNote()
    notesLib.ensureDailyNote()
    return notesLib.getDailyNotePath()
  end

  local title = "Daily Note"

  if usePersistent then
    -- Use persistent nvim session - same nvim instance across toggles
    local toggleFn = M.persistentNvimEditor(terminal, "daily-note", nvimLib.NOTES_SOCKET, { title = title })
    return function()
      local filePath = getOrCreateDailyNote()
      return toggleFn(filePath)
    end
  else
    -- Legacy: spawn new nvim each time
    if terminal == "kitty" then
      return function()
        local filePath = getOrCreateDailyNote()
        local legacyToggle = M.kittyEditor("daily-note", filePath, { title = title })
        return legacyToggle()
      end
    else
      return function()
        local filePath = getOrCreateDailyNote()
        local legacyToggle = M.ghosttyEditor("daily-note", filePath, { title = title })
        return legacyToggle()
      end
    end
  end
end

--- Create a capture note scratchpad (uses persistent nvim session)
---@param terminal "ghostty"|"kitty" Which terminal to use
---@param filePath string Path to the capture note
---@param captureTitle? string Title for the capture
---@param usePersistent? boolean Use persistent nvim session (default: true)
---@return function toggleFn
function M.captureNote(terminal, filePath, captureTitle, usePersistent)
  local title = captureTitle or "Capture Note"
  usePersistent = usePersistent ~= false -- default to true

  if usePersistent then
    -- Use persistent nvim session - reuses daily note's nvim instance
    local toggleFn = M.persistentNvimEditor(terminal, "daily-note", nvimLib.NOTES_SOCKET, { title = "Daily Note" })
    -- Return a function that opens the capture file in the persistent session
    return function() return toggleFn(filePath) end
  else
    -- Legacy: spawn new nvim each time
    if terminal == "kitty" then
      return M.kittyEditor("capture-note", filePath, { title = title })
    else
      return M.ghosttyEditor("capture-note", filePath, { title = title })
    end
  end
end

return M
