-- Notes Window Management
-- Toggle-able floating windows for daily notes
--
-- Uses Kitty terminal for editing via lib/interop/kitty.lua
-- NO window filters - uses timer-based positioning for performance
--
local M = {}
local fmt = string.format
local kittyLib = require("lib.interop.kitty")
local nvimLib = require("lib.interop.nvim")
local notesLib = require("lib.notes")

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

M.config = {
  -- Centered mode: percentage of screen
  centered = {
    width = 0.45,  -- 45% of screen width
    height = 0.5,  -- 50% of screen height
  },

  -- Side-by-side mode: notes on left
  sideBySide = {
    notesWidth = 0.3,  -- 30% for notes
    gap = 0,           -- pixels between windows
  },

  -- Time to wait for window to appear (seconds)
  windowWaitTime = 0.8,
}

-- Window title for daily notes (used for finding existing window)
local DAILY_NOTE_TITLE = "nvim:daily"

-- Socket path for persistent nvim server
local DAILY_NOTE_SOCKET = nvimLib.NOTES_SOCKET

-- Track previously focused app (to restore when hiding)
M.previousApp = nil

--------------------------------------------------------------------------------
-- FRAME CALCULATIONS
--------------------------------------------------------------------------------

--- Calculate centered frame on primary screen
---@return hs.geometry frame
function M.getCenteredFrame()
  local screen = hs.screen.primaryScreen()
  local sFrame = screen:frame()

  local width = math.floor(sFrame.w * M.config.centered.width)
  local height = math.floor(sFrame.h * M.config.centered.height)
  local x = math.floor(sFrame.x + (sFrame.w - width) / 2)
  local y = math.floor(sFrame.y + (sFrame.h - height) / 2)

  return hs.geometry.rect(x, y, width, height)
end

--- Calculate side-by-side frames (notes left, other app right)
---@return hs.geometry notesFrame Frame for notes window (left)
---@return hs.geometry otherFrame Frame for other window (right)
function M.getSideBySideFrames()
  local screen = hs.screen.primaryScreen()
  local sFrame = screen:frame()

  local notesWidth = math.floor(sFrame.w * M.config.sideBySide.notesWidth)
  local gap = M.config.sideBySide.gap
  local otherWidth = sFrame.w - notesWidth - gap

  -- Notes on left
  local notesFrame = hs.geometry.rect(sFrame.x, sFrame.y, notesWidth, sFrame.h)

  -- Other app on right
  local otherFrame = hs.geometry.rect(sFrame.x + notesWidth + gap, sFrame.y, otherWidth, sFrame.h)

  return notesFrame, otherFrame
end

--------------------------------------------------------------------------------
-- WINDOW HELPERS
--------------------------------------------------------------------------------

--- Find window by title pattern
---@param titlePattern string Pattern to match (plain text, case-insensitive)
---@return hs.window|nil
local function findWindowByTitle(titlePattern)
  local allWindows = hs.window.allWindows()
  for _, win in ipairs(allWindows) do
    local title = win:title() or ""
    if title:lower():find(titlePattern:lower(), 1, true) then
      return win
    end
  end
  return nil
end

--- Move window to current space and optionally position it
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
  if frame then win:setFrame(frame, 0) end
end

--------------------------------------------------------------------------------
-- TOGGLE BEHAVIOR
--------------------------------------------------------------------------------

--- Generic toggle: show/hide window, track previous app
---@param titlePattern string Pattern to find window
---@param frame hs.geometry Frame to position window
---@param launcher function Function to launch if not found
---@return boolean success
local function toggle(titlePattern, frame, launcher)
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
  end
end

--- Toggle side-by-side mode: notes on left, previous app on right
---@param titlePattern string Pattern to find window
---@param notesFrame hs.geometry Frame for notes (left)
---@param launcher function Function to launch if not found
---@return boolean success
local function toggleSideBySide(titlePattern, notesFrame, launcher)
  local win = findWindowByTitle(titlePattern)
  local _, otherFrame = M.getSideBySideFrames()

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
  end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--- Toggle daily note (centered floating window)
---@return function toggleFn Function to toggle the daily note
function M.dailyNote()
  return function()
    -- Ensure daily note file exists and get path
    notesLib.ensureDailyNote()
    local filePath = notesLib.getDailyNotePath()

    -- Calculate frame fresh each time (screen may have changed)
    local frame = M.getCenteredFrame()

    -- Check for existing window and open file in server if running
    local win = findWindowByTitle(DAILY_NOTE_TITLE)
    if win then
      nvimLib.openFileAsync(DAILY_NOTE_SOCKET, filePath, function() end)
    end

    -- Toggle behavior
    return toggle(DAILY_NOTE_TITLE, frame, function()
      nvimLib.ensureSocketReady(DAILY_NOTE_SOCKET, function(ready)
        if ready then
          kittyLib.createNvimLauncher(DAILY_NOTE_TITLE, DAILY_NOTE_SOCKET, filePath, frame)()
        else
          hs.alert.show("Failed to start nvim server", 2)
        end
      end)
    end)
  end
end

--- Toggle daily note in side-by-side mode (notes left, previous app right)
---@return function toggleFn Function to toggle the daily note
function M.dailyNoteTiled()
  return function()
    -- Ensure daily note file exists and get path
    notesLib.ensureDailyNote()
    local filePath = notesLib.getDailyNotePath()

    -- Calculate frames fresh each time
    local notesFrame, _ = M.getSideBySideFrames()

    -- Check for existing window and open file in server if running
    local win = findWindowByTitle(DAILY_NOTE_TITLE)
    if win then
      nvimLib.openFileAsync(DAILY_NOTE_SOCKET, filePath, function() end)
    end

    -- Toggle side-by-side behavior
    return toggleSideBySide(DAILY_NOTE_TITLE, notesFrame, function()
      nvimLib.ensureSocketReady(DAILY_NOTE_SOCKET, function(ready)
        if ready then
          kittyLib.createNvimLauncher(DAILY_NOTE_TITLE, DAILY_NOTE_SOCKET, filePath, notesFrame)()
        else
          hs.alert.show("Failed to start nvim server", 2)
        end
      end)
    end)
  end
end

return M
