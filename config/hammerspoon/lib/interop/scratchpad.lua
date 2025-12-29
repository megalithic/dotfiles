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

  -- Visor mode: slides down from top (Quake-style)
  visor = {
    width = 0.45,  -- 45% of screen width
    height = 0.5,  -- 50% of screen height (top half)
    animationDuration = 0.2,  -- seconds
  },

  -- Side-by-side mode: notes on left, previous app on right
  sideBySide = {
    notesWidth = 0.3,  -- 30% for notes
    gap = 0,           -- pixels between windows (0 = flush)
  },
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

--- Calculate visor frame (top of primary screen, centered horizontally)
---@return hs.geometry frame The visible visor position
---@return hs.geometry hiddenFrame The hidden position (above screen)
function M.getVisorFrames()
  local screen = hs.screen.primaryScreen()
  local frame = screen:frame()

  local width = math.floor(frame.w * M.config.visor.width)
  local height = math.floor(frame.h * M.config.visor.height)
  local x = math.floor(frame.x + (frame.w - width) / 2)

  -- Visible: sticky to top edge
  local visibleFrame = hs.geometry.rect(x, frame.y, width, height)

  -- Hidden: positioned above the screen (negative y)
  local hiddenFrame = hs.geometry.rect(x, frame.y - height, width, height)

  return visibleFrame, hiddenFrame
end

--- Calculate side-by-side frames (notes left, other app right)
---@param otherWin hs.window|nil The other window to position (optional)
---@return hs.geometry notesFrame Frame for notes window (left)
---@return hs.geometry otherFrame Frame for other window (right)
function M.getSideBySideFrames(otherWin)
  local screen = hs.screen.primaryScreen()
  local frame = screen:frame()

  local notesWidth = math.floor(frame.w * M.config.sideBySide.notesWidth)
  local gap = M.config.sideBySide.gap
  local otherWidth = frame.w - notesWidth - gap

  -- Notes on left
  local notesFrame = hs.geometry.rect(frame.x, frame.y, notesWidth, frame.h)

  -- Other app on right
  local otherFrame = hs.geometry.rect(frame.x + notesWidth + gap, frame.y, otherWidth, frame.h)

  return notesFrame, otherFrame
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

--- Toggle a scratchpad with visor-style animation (slides from top)
--- Uses app:hide()/unhide() pattern with animated transitions
---@param name string Unique name for this scratchpad
---@param opts table Options
---@field opts.titlePattern string Pattern to find the window by title
---@field opts.launcher function Function to launch if not running
---@return boolean success
function M.toggleVisor(name, opts)
  opts = opts or {}
  local titlePattern = opts.titlePattern or name
  local launcher = opts.launcher
  local visibleFrame, hiddenFrame = M.getVisorFrames()
  local duration = M.config.visor.animationDuration

  -- Try to find existing window
  local win = findWindowByTitle(titlePattern)

  if win then
    local app = win:application()
    if app and app:isFrontmost() and win:isVisible() then
      -- Window is focused and visible -> animate up then hide
      win:setFrame(hiddenFrame, duration)
      hs.timer.doAfter(duration, function()
        app:hide()
        if M.previousApp then M.previousApp:activate() end
      end)
      return true
    else
      -- Window exists but not focused -> store previous, unhide, animate down
      local focusedWin = hs.window.focusedWindow()
      if focusedWin then M.previousApp = focusedWin:application() end
      app:unhide()
      moveToCurrentSpace(win)
      win:setFrame(hiddenFrame, 0)  -- Start at hidden position (instant)
      win:focus()
      win:setFrame(visibleFrame, duration)  -- Animate to visible
      return true
    end
  else
    -- No window found -> store previous app, then launch
    local focusedWin = hs.window.focusedWindow()
    if focusedWin then M.previousApp = focusedWin:application() end

    if launcher then
      launcher()
      -- Wait for window to appear, position hidden, then animate down
      hs.timer.doAfter(M.config.windowWaitTime, function()
        local newWin = findWindowByTitle(titlePattern)
        if newWin then
          moveToCurrentSpace(newWin)
          newWin:setFrame(hiddenFrame, 0)  -- Start hidden (instant)
          newWin:focus()
          newWin:setFrame(visibleFrame, duration)  -- Animate down
        end
      end)
      return true
    else
      hs.alert.show(fmt("Scratchpad '%s' has no launcher", name), 2)
      return false
    end
  end
end

--- Toggle side-by-side mode: notes on left, previous app on right
--- Both windows are positioned on primary screen
---@param name string Unique name for this scratchpad
---@param opts table Options
---@field opts.titlePattern string Pattern to find the window by title
---@field opts.launcher function Function to launch if not running
---@return boolean success
function M.toggleSideBySide(name, opts)
  opts = opts or {}
  local titlePattern = opts.titlePattern or name
  local launcher = opts.launcher

  -- Try to find existing window
  local win = findWindowByTitle(titlePattern)
  local notesFrame, otherFrame = M.getSideBySideFrames()

  if win then
    local app = win:application()
    if app and app:isFrontmost() and win:isVisible() then
      -- Window is focused and visible -> hide and restore previous app's frame
      app:hide()
      if M.previousApp then
        M.previousApp:activate()
        -- Restore previous app to full screen (undo split)
        local prevWin = M.previousApp:focusedWindow()
        if prevWin then
          local screen = hs.screen.primaryScreen()
          prevWin:setFrame(screen:frame())
        end
      end
      return true
    else
      -- Window exists but not focused -> enter side-by-side mode
      local focusedWin = hs.window.focusedWindow()
      if focusedWin then
        M.previousApp = focusedWin:application()
        -- Position the previous app on the right
        focusedWin:setFrame(otherFrame)
      end
      app:unhide()
      moveToCurrentSpace(win, notesFrame)
      win:focus()
      return true
    end
  else
    -- No window found -> store previous app, position it, then launch notes
    local focusedWin = hs.window.focusedWindow()
    if focusedWin then
      M.previousApp = focusedWin:application()
      -- Position the previous app on the right
      focusedWin:setFrame(otherFrame)
    end

    if launcher then
      launcher()
      -- Wait for window to appear and position it on left
      hs.timer.doAfter(M.config.windowWaitTime, function()
        local newWin = findWindowByTitle(titlePattern)
        if newWin then
          moveToCurrentSpace(newWin, notesFrame)
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

-- Separate titles for daily note vs capture (prevents toggle conflicts)
local DAILY_NOTE_TITLE = "nvim:daily"
local CAPTURE_NOTE_TITLE = "nvim:capture"

-- Separate sockets for daily note vs capture
local DAILY_NOTE_SOCKET = nvimLib.NOTES_SOCKET  -- reuse existing
local CAPTURE_NOTE_SOCKET = "/tmp/nvim-capture.sock"

--------------------------------------------------------------------------------
-- WINDOW FILTER: Immediate positioning for notes windows
-- Positions window at center as soon as it's detected
--------------------------------------------------------------------------------

local notesWindowFilter = nil

--- Initialize the window filter for notes windows (called once on module load)
local function initNotesWindowFilter()
  if notesWindowFilter then return end  -- Already initialized

  -- Create filter that matches our notes window titles
  notesWindowFilter = hs.window.filter.new(function(win)
    if not win then return false end
    local title = win:title() or ""
    return title == DAILY_NOTE_TITLE or title == CAPTURE_NOTE_TITLE
  end)

  -- Subscribe to windowCreated to immediately position new notes windows
  notesWindowFilter:subscribe(hs.window.filter.windowCreated, function(win, appName, event)
    if not win then return end

    -- Calculate centered frame
    local screen = hs.screen.primaryScreen()
    local sFrame = screen:frame()
    local width = math.floor(sFrame.w * M.config.visor.width)
    local height = math.floor(sFrame.h * M.config.visor.height)
    local x = math.floor(sFrame.x + (sFrame.w - width) / 2)
    local y = math.floor(sFrame.y + (sFrame.h - height) / 2)
    local targetFrame = hs.geometry.rect(x, y, width, height)

    -- Move to current space first
    local currentSpace = hs.spaces.focusedSpace()
    local winSpaces = hs.spaces.windowSpaces(win)
    if winSpaces and not hs.fnutils.contains(winSpaces, currentSpace) then
      hs.spaces.moveWindowToSpace(win, currentSpace)
    end

    -- Position immediately (no animation for now - animation was unreliable)
    win:setFrame(targetFrame, 0)
    win:focus()
  end)
end

-- Initialize filter when module loads
initNotesWindowFilter()

--- Calculate centered frame on primary screen
---@return hs.geometry frame
local function getCenteredFrame()
  local screen = hs.screen.primaryScreen()
  local frame = screen:frame()
  local width = math.floor(frame.w * M.config.visor.width)
  local height = math.floor(frame.h * M.config.visor.height)
  local x = math.floor(frame.x + (frame.w - width) / 2)
  local y = math.floor(frame.y + (frame.h - height) / 2)
  return hs.geometry.rect(x, y, width, height)
end

--- Create Kitty launcher with scratchpad-friendly overrides
--- Passes explicit pixel dimensions so Kitty starts at correct size immediately
---@param title string Window title
---@param socketPath string Nvim socket path
---@param filePath string File to open
---@param frame hs.geometry Target frame (for initial dimensions)
---@return function launcher
local function createKittyLauncher(title, socketPath, filePath, frame)
  return function()
    local nvimArgs = nvimLib.getServerArgs(socketPath, filePath)
    local termArgs = {
      "kitty",
      -- CRITICAL: Disable single-instance so our overrides actually work!
      -- With single-instance=yes (from config), the existing Kitty process
      -- creates the window and IGNORES all --override flags.
      -- This is a CLI flag, not a config option, so use direct flag not --override
      "--single-instance=no",
      "--title=" .. title,
      "--override", "background_opacity=1.00",
      "--override", "remember_window_size=no",
      "--override", "placement_strategy=center",
      -- Show native macOS window border (overrides hide_window_decorations=yes)
      -- Options: no (full decorations), titlebar-only, titlebar-and-corners
      "--override", "hide_window_decorations=titlebar-and-corners",
      -- Pass explicit pixel dimensions so Kitty starts at correct size (no resize flash)
      -- Note: plain numbers are pixels in Kitty, 'c' suffix would be cells
      "--override", fmt("initial_window_width=%d", frame.w),
      "--override", fmt("initial_window_height=%d", frame.h),
      "-e",
    }
    for _, arg in ipairs(nvimArgs) do
      table.insert(termArgs, arg)
    end
    local task = hs.task.new("/usr/bin/env", nil, termArgs)
    if task then task:start() end
  end
end

--- Create a daily note scratchpad (toggle behavior, centered float)
---@param terminal "ghostty"|"kitty" Which terminal to use
---@return function toggleFn
function M.dailyNote(terminal)
  local notesLib = require("lib.notes")

  local function getOrCreateDailyNote()
    notesLib.ensureDailyNote()
    return notesLib.getDailyNotePath()
  end

  return function()
    -- Calculate frame fresh each time (screen may have changed)
    local frame = getCenteredFrame()
    local filePath = getOrCreateDailyNote()
    local win = findWindowByTitle(DAILY_NOTE_TITLE)

    -- If window exists, open file in existing server
    if win then
      nvimLib.openFileAsync(DAILY_NOTE_SOCKET, filePath, function() end)
    end

    -- Toggle behavior (show/hide)
    return M.toggle("daily-note", {
      titlePattern = DAILY_NOTE_TITLE,
      frame = frame,
      launcher = function()
        nvimLib.ensureSocketReady(DAILY_NOTE_SOCKET, function(ready)
          if ready then
            createKittyLauncher(DAILY_NOTE_TITLE, DAILY_NOTE_SOCKET, filePath, frame)()
          else
            hs.alert.show("Failed to start nvim server", 2)
          end
        end)
      end,
    })
  end
end

--- Create a daily note scratchpad with side-by-side layout
---@param terminal "ghostty"|"kitty" Which terminal to use
---@return function toggleFn
function M.dailyNoteSideBySide(terminal)
  local notesLib = require("lib.notes")

  local function getOrCreateDailyNote()
    notesLib.ensureDailyNote()
    return notesLib.getDailyNotePath()
  end

  return function()
    local filePath = getOrCreateDailyNote()
    local win = findWindowByTitle(DAILY_NOTE_TITLE)
    local notesFrame, _ = M.getSideBySideFrames()

    -- If window exists, open file in existing server
    if win then
      nvimLib.openFileAsync(DAILY_NOTE_SOCKET, filePath, function() end)
    end

    return M.toggleSideBySide("daily-note", {
      titlePattern = DAILY_NOTE_TITLE,
      launcher = function()
        nvimLib.ensureSocketReady(DAILY_NOTE_SOCKET, function(ready)
          if ready then
            createKittyLauncher(DAILY_NOTE_TITLE, DAILY_NOTE_SOCKET, filePath, notesFrame)()
          else
            hs.alert.show("Failed to start nvim server", 2)
          end
        end)
      end,
    })
  end
end

--- Create a capture note scratchpad (always shows, separate from daily note)
--- Capture ALWAYS appears - never toggles to hide
---@param terminal "ghostty"|"kitty" Which terminal to use
---@param filePath string Path to the capture note
---@param captureTitle? string Title for the capture (unused)
---@return function showFn
function M.captureNote(terminal, filePath, captureTitle)
  return function()
    -- Calculate frame fresh each time (screen may have changed)
    local frame = getCenteredFrame()
    local win = findWindowByTitle(CAPTURE_NOTE_TITLE)

    if win then
      -- Window exists -> open file and focus (never hide)
      nvimLib.openFileAsync(CAPTURE_NOTE_SOCKET, filePath, function() end)
      local app = win:application()
      if app then app:unhide() end
      moveToCurrentSpace(win, frame)
      win:focus()
      return true
    else
      -- No window -> store previous app and launch
      local focusedWin = hs.window.focusedWindow()
      if focusedWin then M.previousApp = focusedWin:application() end

      nvimLib.ensureSocketReady(CAPTURE_NOTE_SOCKET, function(ready)
        if ready then
          createKittyLauncher(CAPTURE_NOTE_TITLE, CAPTURE_NOTE_SOCKET, filePath, frame)()
          hs.timer.doAfter(M.config.windowWaitTime, function()
            local newWin = findWindowByTitle(CAPTURE_NOTE_TITLE)
            if newWin then
              moveToCurrentSpace(newWin, frame)
              newWin:focus()
            end
          end)
        else
          hs.alert.show("Failed to start capture nvim server", 2)
        end
      end)
      return true
    end
  end
end

--- Hide capture note window (separate from daily note toggle)
---@return boolean success
function M.hideCaptureNote()
  local win = findWindowByTitle(CAPTURE_NOTE_TITLE)
  if win then
    local app = win:application()
    if app then
      app:hide()
      if M.previousApp then M.previousApp:activate() end
      return true
    end
  end
  return false
end

return M
