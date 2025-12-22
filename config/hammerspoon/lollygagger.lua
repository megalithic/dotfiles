-- Lollygagger: Auto-hide/quit apps after inactivity
--
-- When an app is deactivated (loses focus), starts a timer.
-- After the configured interval, hides or quits the app.
-- If the app is reactivated before the interval, the timer is cancelled.
--
-- Config format in C.lollygaggers:
--   [bundleID] = { hideAfter (minutes), quitAfter (minutes) }
--   nil = don't perform that action
--
-- Example:
--   ["org.hammerspoon.Hammerspoon"] = { 1, nil }     -- hide after 1 min
--   ["com.spotify.client"] = { 5, 30 }               -- hide after 5 min, quit after 30 min

local obj = {}

obj.__index = obj
obj.name = "lollygagger"

-- Timer cache: { [bundleID] = { hide = timer, quit = timer } }
-- Using a simple table, timers are properly stopped and set to nil on cleanup
local timers = {}

-- Cancel and nil out a specific timer
local function stopTimer(bundleID, timerType)
  if timers[bundleID] and timers[bundleID][timerType] then
    local timer = timers[bundleID][timerType]
    if timer and timer.stop then timer:stop() end
    timers[bundleID][timerType] = nil
  end
end

-- Cancel all timers for an app and clean up the entry
local function cancelTimers(bundleID)
  if not timers[bundleID] then return end

  stopTimer(bundleID, "hide")
  stopTimer(bundleID, "quit")

  -- Remove the entry entirely to free memory
  timers[bundleID] = nil
end

-- Hide an app (with safety checks)
local function hideApp(bundleID)
  -- Re-fetch the app by bundleID to avoid stale references
  local app = hs.application.get(bundleID)
  if app and app:isRunning() then
    app:hide()
    U.log.i(string.format("Hidden %s (%s)", app:name(), bundleID))
  end
end

-- Quit an app gracefully (with safety checks)
local function quitApp(bundleID)
  -- Re-fetch the app by bundleID to avoid stale references
  local app = hs.application.get(bundleID)
  if app and app:isRunning() then
    U.log.i(string.format("Quitting %s (%s)", app:name(), bundleID))
    app:kill()
  end
end

-- Start hide timer for an app
local function startHideTimer(bundleID, interval)
  if not interval then return end

  -- Initialize timer cache for this app
  if not timers[bundleID] then timers[bundleID] = {} end

  -- Cancel existing hide timer
  stopTimer(bundleID, "hide")

  -- Get app name for logging (may be nil if app already quit)
  local app = hs.application.get(bundleID)
  local appName = app and app:name() or bundleID

  U.log.i(string.format("%s will hide in %dm", appName, interval))

  -- Store bundleID in closure, not app object (which could become stale)
  timers[bundleID].hide = hs.timer.doAfter(interval * 60, function()
    hideApp(bundleID)
    -- Clean up timer reference
    if timers[bundleID] then
      timers[bundleID].hide = nil
      -- Clean up entry if no more timers
      if not timers[bundleID].quit then timers[bundleID] = nil end
    end
  end)
end

-- Start quit timer for an app
local function startQuitTimer(bundleID, interval)
  if not interval then return end

  -- Initialize timer cache for this app
  if not timers[bundleID] then timers[bundleID] = {} end

  -- Cancel existing quit timer
  stopTimer(bundleID, "quit")

  -- Get app name for logging (may be nil if app already quit)
  local app = hs.application.get(bundleID)
  local appName = app and app:name() or bundleID

  U.log.i(string.format("%s will quit in %dm", appName, interval))

  -- Store bundleID in closure, not app object (which could become stale)
  timers[bundleID].quit = hs.timer.doAfter(interval * 60, function()
    quitApp(bundleID)
    -- Clean up timer reference
    if timers[bundleID] then
      timers[bundleID].quit = nil
      -- Clean up entry if no more timers
      if not timers[bundleID].hide then timers[bundleID] = nil end
    end
  end)
end

-- Main entry point called from app watcher
-- Called on every app event (activated, deactivated, launched, terminated)
function obj:run(_elementOrAppName, event, app)
  if not app then return end

  local bundleID = app:bundleID()
  if not bundleID then return end

  local config = C.lollygaggers[bundleID]
  if not config then return end

  -- On activation, cancel any pending timers
  if event == hs.application.watcher.activated then
    cancelTimers(bundleID)
    return
  end

  -- On deactivation, start timers
  if event == hs.application.watcher.deactivated then
    local hideAfter, quitAfter = table.unpack(config)
    if hideAfter then startHideTimer(bundleID, hideAfter) end
    if quitAfter then startQuitTimer(bundleID, quitAfter) end
    return
  end

  -- On termination, clean up timers
  if event == hs.application.watcher.terminated then
    cancelTimers(bundleID)
    return
  end
end

function obj:start()
  U.log.i("started")
  return self
end

function obj:stop()
  -- Cancel all pending timers and clear the cache
  for bundleID, _ in pairs(timers) do
    cancelTimers(bundleID)
  end
  timers = {}
  U.log.i("stopped")
  return self
end

return obj
