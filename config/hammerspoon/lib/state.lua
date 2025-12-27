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

--- Reset a specific namespace by name
---@param namespace "notification"|"hypers"|"all" Namespace to reset
function M.reset(namespace)
  if namespace == "notification" or namespace == "all" then
    M.resetNotification()
  end
  if namespace == "hypers" or namespace == "all" then
    M.resetHypers()
  end
end

--- Reset all state (call on reload)
function M.resetAll()
  M.reset("all")
end

return M
