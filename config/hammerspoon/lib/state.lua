-- Centralized State Module
-- Replaces scattered _G.* globals with organized namespaces
--
-- Usage:
--   local S = require("lib.state")  -- or use _G.S after init
--   S.notification.canvas = canvas
--   S.notification.timers.animation = timer
--   S.reset("notification")  -- cleanup
--
-- Exported as _G.S in init.lua for REPL/cross-module access
--
local M = {}

--------------------------------------------------------------------------------
-- NOTIFICATION STATE (replaces _G.activeNotification*, _G.notification*)
--------------------------------------------------------------------------------

M.notification = {
  -- Canvas objects
  canvas = nil,   -- Active notification canvas
  overlay = nil,  -- Dimming overlay (reusable)

  -- Timers (stored for cleanup/cancellation)
  timers = {
    display = nil,    -- Auto-dismiss timer (was _G.activeNotificationTimer)
    animation = nil,  -- Slide animation timer (was _G.activeNotificationAnimTimer)
    overlay = nil,    -- Overlay hide delay (was _G.activeNotificationOverlayTimer)
  },

  -- Watchers
  appWatcher = nil,  -- App activation watcher for auto-dismiss

  -- Tracking state
  bundleID = nil,  -- Source app bundle ID for auto-dismiss logic
}

--------------------------------------------------------------------------------
-- HYPER MODAL STATE (replaces _G.Hypers)
--------------------------------------------------------------------------------

M.hypers = {}

--------------------------------------------------------------------------------
-- MICCHECK STATE (unified PTT + PTD voice control)
--------------------------------------------------------------------------------

M.miccheck = {
  -- Mode states
  pttMode = "push-to-talk",  -- "push-to-talk", "push-to-mute", "disabled"
  ptdMode = "push-to-dictate",  -- "push-to-dictate", "always-on", "disabled"

  -- Current activity state (for icon priority)
  isRecording = false,   -- Currently recording audio (PTD)
  isProcessing = false,  -- Transcribing audio (Whisper)
  isUnmuted = false,     -- PTT key held / mic unmuted

  -- UI elements
  menubar = nil,         -- Menubar item

  -- Hotkeys (stored for cleanup)
  hotkeys = {
    modifierTap = nil,   -- eventtap for cmd+opt (PTT) and cmd+opt+shift (PTD)
    pttToggle = nil,     -- cmd+opt+p
    ptdToggle = nil,     -- cmd+opt+shift+p
  },

  -- Watcher hooks (callbacks registered by other modules)
  hooks = {
    onMuteChange = {},   -- Called when mute state changes
    onRecordStart = {},  -- Called when recording starts
    onRecordEnd = {},    -- Called when recording ends
    onTranscribe = {},   -- Called when transcription completes
  },
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

--- Stop all timers in a namespace
---@param timers table Table of timer references
local function stopTimers(timers)
  for name, timer in pairs(timers) do
    if timer then
      pcall(function() timer:stop() end)
      timers[name] = nil
    end
  end
end

--- Delete all canvases in a list
---@param canvases table Table or list of canvas references
local function deleteCanvases(canvases)
  for key, canvas in pairs(canvases) do
    if canvas then
      pcall(function() canvas:delete(0) end)
      canvases[key] = nil
    end
  end
end

--- Stop a watcher safely
---@param watcher userdata|nil Watcher to stop
local function stopWatcher(watcher)
  if watcher then
    pcall(function() watcher:stop() end)
  end
end

--------------------------------------------------------------------------------
-- RESET FUNCTIONS (for cleanup on reload)
--------------------------------------------------------------------------------

--- Reset notification state (stop timers, delete canvases, stop watchers)
function M.resetNotification()
  -- Stop all timers
  stopTimers(M.notification.timers)

  -- Delete canvases
  if M.notification.canvas then
    pcall(function() M.notification.canvas:delete(0) end)
    M.notification.canvas = nil
  end
  if M.notification.overlay then
    pcall(function() M.notification.overlay:delete(0) end)
    M.notification.overlay = nil
  end

  -- Stop watcher
  stopWatcher(M.notification.appWatcher)
  M.notification.appWatcher = nil

  -- Clear tracking state
  M.notification.bundleID = nil
end

--- Reset hyper modal state
function M.resetHypers()
  M.hypers = {}
end

--- Reset miccheck state (stop hotkeys, delete menubar, clear hooks)
function M.resetMiccheck()
  -- Stop all hotkeys and eventtaps
  for name, binding in pairs(M.miccheck.hotkeys) do
    if binding then
      -- Try eventtap stop first (for modifierTap, keyDownTap, etc.)
      pcall(function() binding:stop() end)
      -- Then try hotkey delete (for pttToggle, ptdToggle, etc.)
      pcall(function() binding:delete() end)
      M.miccheck.hotkeys[name] = nil
    end
  end

  -- Delete menubar
  if M.miccheck.menubar then
    pcall(function() M.miccheck.menubar:delete() end)
    M.miccheck.menubar = nil
  end

  -- Reset activity state (keep mode preferences)
  M.miccheck.isRecording = false
  M.miccheck.isProcessing = false
  M.miccheck.isUnmuted = false

  -- Clear hooks
  M.miccheck.hooks = {
    onMuteChange = {},
    onRecordStart = {},
    onRecordEnd = {},
    onTranscribe = {},
  }
end

--- Reset a specific namespace by name
---@param namespace "notification"|"hypers"|"miccheck"|"all" Namespace to reset
function M.reset(namespace)
  if namespace == "notification" or namespace == "all" then
    M.resetNotification()
  end
  if namespace == "hypers" or namespace == "all" then
    M.resetHypers()
  end
  if namespace == "miccheck" or namespace == "all" then
    M.resetMiccheck()
  end
end

--- Reset all state (call on reload)
function M.resetAll()
  M.reset("all")
end

return M
