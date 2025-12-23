-- Scratchpad Module
-- Toggle-able floating windows that persist and follow you across spaces
--
-- Uses app:hide()/unhide() pattern from lib/summon.lua
-- Tracks previousApp to restore focus when hiding
--
local M = {}
local fmt = string.format

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
      if M.previousApp then
        M.previousApp:activate()
      end
      return true
    else
      -- Window exists but not focused -> store previous, show and focus
      local focusedWin = hs.window.focusedWindow()
      if focusedWin then
        M.previousApp = focusedWin:application()
      end
      app:unhide()
      moveToCurrentSpace(win, frame)
      win:focus()
      return true
    end
  else
    -- No window found -> store previous app, then launch
    local focusedWin = hs.window.focusedWindow()
    if focusedWin then
      M.previousApp = focusedWin:application()
    end

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
  local nvimPath = "/etc/profiles/per-user/seth/bin/nvim"
  local ghosttyPath = "/Applications/Ghostty.app/Contents/MacOS/ghostty"

  local function launcher()
    -- Use hs.task for non-blocking execution
    local className = "scratchpad-" .. name:gsub("%s+", "-"):lower()
    local task = hs.task.new(ghosttyPath, nil, {
      "--title=" .. title,
      "--class=" .. className,
      "-e", nvimPath, filePath,
    })
    if task then
      task:start()
    end
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
  local nvimPath = "/etc/profiles/per-user/seth/bin/nvim"
  local kittyPath = "/opt/homebrew/bin/kitty"

  local function launcher()
    -- Use hs.task for non-blocking execution
    -- Do NOT use -1 (single-instance) as it can cause issues with window control
    -- --title sets window title for identification
    local task = hs.task.new(kittyPath, nil, {
      "--title=" .. title,
      "--override", "background_opacity=0.95",
      "-e", nvimPath, filePath,
    })
    if task then
      task:start()
    end
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
-- PRE-CONFIGURED SCRATCHPADS
--------------------------------------------------------------------------------

--- Create a daily note scratchpad
---@param terminal "ghostty"|"kitty" Which terminal to use
---@return function toggleFn
function M.dailyNote(terminal)
  local notesLib = require("lib.notes")

  -- Ensure daily note exists before creating scratchpad
  local function getOrCreateDailyNote()
    notesLib.ensureDailyNote()
    return notesLib.getDailyNotePath()
  end

  local title = "Daily Note"

  if terminal == "kitty" then
    return function()
      local filePath = getOrCreateDailyNote()
      local toggleFn = M.kittyEditor("daily-note", filePath, { title = title })
      return toggleFn()
    end
  else
    return function()
      local filePath = getOrCreateDailyNote()
      local toggleFn = M.ghosttyEditor("daily-note", filePath, { title = title })
      return toggleFn()
    end
  end
end

--- Create a capture note scratchpad
---@param terminal "ghostty"|"kitty" Which terminal to use
---@param filePath string Path to the capture note
---@param captureTitle? string Title for the capture
---@return function toggleFn
function M.captureNote(terminal, filePath, captureTitle)
  local title = captureTitle or "Capture Note"

  if terminal == "kitty" then
    return M.kittyEditor("capture-note", filePath, { title = title })
  else
    return M.ghosttyEditor("capture-note", filePath, { title = title })
  end
end

return M
