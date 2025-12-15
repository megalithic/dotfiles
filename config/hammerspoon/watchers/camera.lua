-- REF: https://github.com/muescha/dotfiles-2/blob/main/tilde/.hammerspoon/system/videoCalls.lua
--
local fmt = string.format
local M = {}

-- Debouncing state to prevent rapid-fire camera events
local lastProcessedTime = 0
local DEBOUNCE_INTERVAL = 1.0 -- 1 second - ignore events within this window

-- Lobby debounce: delay before treating camera-off as "meeting ended"
-- This handles the lobby→room transition where camera briefly goes inactive
local MEETING_END_DELAY = 3.0 -- seconds to wait before stopping meeting mode
local pendingMeetingEnd = nil -- timer for delayed meeting end

-- Path to VDC plugin binary (camera framework)
local VDC_PATH = "/System/Library/Frameworks/CoreMediaIO.framework/Versions/A/Resources/VDC.plugin/Contents/MacOS/VDC"

-- System processes to ignore when detecting camera usage
-- These always have VDC loaded but aren't the actual camera-using app
local VDC_IGNORE_PROCESSES = {
  ["ControlCe"] = true, -- Control Center
  ["Hammerspo"] = true, -- Hammerspoon itself
  ["avconfere"] = true, -- AV conference daemon
  ["VDCAssist"] = true, -- VDC Assistant
  ["coreaudio"] = true, -- Core Audio daemon
}

-- Detect which application is using the camera
-- Uses multiple detection methods with fallbacks
-- PRIORITY: Apps with confirmed meeting windows > frontmost known video app > any VDC app
-- Returns: bundleID (string or nil), method (string), isMeeting (bool or nil)
local function detectCameraApp()
  -- Collect all candidate apps from VDC
  local candidates = {} -- { {bundleID, app, isMeeting, method, reason} }

  -- Method 1: VDC (Video Device Control) via lsof - most reliable
  -- Query the specific VDC binary instead of scanning all open files
  local vdcOutput, vdcStatus = hs.execute(fmt("lsof '%s' 2>/dev/null | tail -n +2 | head -10", VDC_PATH))

  if vdcStatus and vdcOutput and vdcOutput ~= "" then
    -- Collect ALL apps with VDC loaded (don't return on first match)
    for line in vdcOutput:gmatch("[^\r\n]+") do
      local processName = line:match("^(%S+)")
      if processName and not VDC_IGNORE_PROCESSES[processName] then
        -- Try to find the running application by name
        local app = hs.application.get(processName)
        if app then
          local bundleID = app:bundleID()
          -- Skip Hammerspoon itself
          if bundleID ~= "org.hammerspoon.Hammerspoon" then
            local window = app:focusedWindow() or app:mainWindow()
            local isMeeting, meetingMethod = U.app.isMeetingWindow(app, window)
            U.log.df("VDC candidate: %s (meeting: %s, %s)", bundleID, tostring(isMeeting), meetingMethod or "n/a")
            table.insert(candidates, { bundleID = bundleID, app = app, isMeeting = isMeeting, method = "vdc", reason = meetingMethod })
          end
        else
          -- Fallback: check VIDEO_BUNDLES mapping
          local bundleID = U.app.VIDEO_BUNDLES[processName]
          if bundleID then
            local mappedApp = hs.application.get(bundleID)
            local window = mappedApp and (mappedApp:focusedWindow() or mappedApp:mainWindow())
            local isMeeting, meetingMethod = U.app.isMeetingWindow(mappedApp, window)
            U.log.df("VDC mapped candidate: %s (meeting: %s, %s)", bundleID, tostring(isMeeting), meetingMethod or "n/a")
            table.insert(candidates, { bundleID = bundleID, app = mappedApp, isMeeting = isMeeting, method = "vdc_mapped", reason = meetingMethod })
          end
        end
      end
    end
  end

  -- Prioritize candidates: browser meetings > confirmed meetings > frontmost > unknown > false
  -- Browser meetings (Google Meet, etc.) are most reliable detection
  if #candidates > 0 then
    -- First pass: return browser app with confirmed meeting URL (most reliable)
    for _, c in ipairs(candidates) do
      if c.isMeeting == true and c.reason == "browser_meeting_url" then
        U.log.df("Selected (browser meeting URL): %s via %s", c.bundleID, c.method)
        return c.bundleID, c.method, c.isMeeting
      end
    end

    -- Second pass: return any app with confirmed meeting (isMeeting=true)
    for _, c in ipairs(candidates) do
      if c.isMeeting == true then
        U.log.df("Selected (confirmed meeting): %s via %s (%s)", c.bundleID, c.method, c.reason or "n/a")
        return c.bundleID, c.method, c.isMeeting
      end
    end

    -- Third pass: check if frontmost app is among candidates
    local frontmost = hs.application.frontmostApplication()
    if frontmost then
      local frontmostBundleID = frontmost:bundleID()
      for _, c in ipairs(candidates) do
        if c.bundleID == frontmostBundleID then
          U.log.df("Selected (frontmost candidate): %s via %s", c.bundleID, c.method)
          return c.bundleID, c.method, c.isMeeting
        end
      end
    end

    -- Fourth pass: return first candidate with unknown state (nil)
    for _, c in ipairs(candidates) do
      if c.isMeeting == nil then
        U.log.df("Selected (unknown state): %s via %s", c.bundleID, c.method)
        return c.bundleID, c.method, c.isMeeting
      end
    end

    -- Fifth pass: return first candidate (even if isMeeting=false)
    local c = candidates[1]
    U.log.df("Selected (fallback): %s via %s", c.bundleID, c.method)
    return c.bundleID, c.method, c.isMeeting
  end

  -- Method 2: Check for video capture service processes (app-specific optimization)
  local vcOutput, vcStatus =
    hs.execute("ps aux | grep -E 'video_capture|VideoCaptureService' | grep -v grep 2>/dev/null")

  if vcStatus and vcOutput and vcOutput ~= "" then
    for _, app in ipairs(hs.application.runningApplications()) do
      local appName = app:name()
      local appPath = app:path()

      if appName and (vcOutput:find(appName, 1, true) or (appPath and vcOutput:find(appPath, 1, true))) then
        if appPath and appPath:match("/Contents/") then
          local mainAppPath = appPath:match("(.-%.app)")
          if mainAppPath then
            local mainAppInfo = hs.application.infoForBundlePath(mainAppPath)
            if mainAppInfo and mainAppInfo.CFBundleIdentifier then
              local mainApp = hs.application.get(mainAppInfo.CFBundleIdentifier)
              local window = mainApp and (mainApp:focusedWindow() or mainApp:mainWindow())
              local isMeeting, meetingMethod = U.app.isMeetingWindow(mainApp, window)
              U.log.df(
                "Detected via video_capture: %s (meeting: %s, %s)",
                mainAppInfo.CFBundleIdentifier,
                tostring(isMeeting),
                meetingMethod or "n/a"
              )
              return mainAppInfo.CFBundleIdentifier, "video_capture", isMeeting
            end
          end
        else
          local bundleID = app:bundleID()
          if bundleID then
            local window = app:focusedWindow() or app:mainWindow()
            local isMeeting, meetingMethod = U.app.isMeetingWindow(app, window)
            U.log.df(
              "Detected via video_capture: %s (meeting: %s, %s)",
              bundleID,
              tostring(isMeeting),
              meetingMethod or "n/a"
            )
            return bundleID, "video_capture", isMeeting
          end
        end
      end
    end
  end

  -- Method 3: Frontmost application - but ONLY if it's a known video app
  -- This prevents misattribution when camera activates in background
  -- (e.g., Zoom starts camera while user is in Terminal)
  local frontmost = hs.application.frontmostApplication()
  if frontmost then
    local bundleID = frontmost:bundleID()
    local appName = frontmost:name()

    -- Check if frontmost is a known video app (by name or bundleID)
    local isKnownVideoApp = U.app.VIDEO_BUNDLES[appName] ~= nil
    if not isKnownVideoApp then
      -- Also check by bundleID (values in VIDEO_BUNDLES)
      for _, knownBundleID in pairs(U.app.VIDEO_BUNDLES) do
        if knownBundleID == bundleID then
          isKnownVideoApp = true
          break
        end
      end
    end

    if isKnownVideoApp then
      local window = frontmost:focusedWindow() or frontmost:mainWindow()
      local isMeeting, meetingMethod = U.app.isMeetingWindow(frontmost, window)
      U.log.df(
        "Detected via frontmost (known video app): %s (meeting: %s, %s)",
        bundleID,
        tostring(isMeeting),
        meetingMethod or "n/a"
      )
      return bundleID, "frontmost", isMeeting
    else
      U.log.df("Frontmost app %s is not a known video app, skipping", bundleID)
    end
  end

  U.log.w("Could not detect which app is using camera")
  return nil, "unknown", nil
end

-- Timer for delayed meeting confirmation (when detection is uncertain)
local meetingConfirmTimer = nil
local MEETING_CONFIRM_DELAY = 30 -- seconds to wait before confirming uncertain meeting

-- Actions to run when we're confident user is in a meeting
local function startMeetingMode(appName, reason)
  U.log.f("Starting meeting mode: %s (%s)", appName or "unknown", reason)
  U.dnd(true, "meeting")
  hs.spotify.pause()
  require("ptt").setState("push-to-talk")
end

local function cameraActive(camera, property)
  -- Cancel any pending meeting end (lobby→room transition)
  if pendingMeetingEnd then
    U.log.d("Camera reactivated - cancelling pending meeting end (likely lobby→room transition)")
    pendingMeetingEnd:stop()
    pendingMeetingEnd = nil
  end

  -- Detect which app is using the camera
  local appBundleID, detectionMethod, isMeeting = detectCameraApp()

  -- Get app name for display
  local app = appBundleID and hs.application.get(appBundleID)
  local appName = app and app:name() or appBundleID or "unknown"

  U.log.f("%s active: %s (method: %s, meeting: %s)", camera:name(), appName, detectionMethod, tostring(isMeeting))

  -- Cancel any pending confirmation timer
  if meetingConfirmTimer then
    meetingConfirmTimer:stop()
    meetingConfirmTimer = nil
  end

  if isMeeting == true then
    -- High confidence: definitely in a meeting
    startMeetingMode(appName, "confirmed_meeting")
  elseif isMeeting == false then
    -- High confidence: NOT a meeting (settings, preview, etc.)
    U.log.f("Camera active but not a meeting (likely settings): %s", appName)
    -- Don't trigger meeting mode
  else
    -- Unknown: wait and recheck after delay
    U.log.f("Camera active, uncertain if meeting. Will recheck in %ds: %s", MEETING_CONFIRM_DELAY, appName)
    meetingConfirmTimer = hs.timer.doAfter(MEETING_CONFIRM_DELAY, function()
      -- Recheck if camera is still in use
      if camera:isInUse() then
        local recheckBundleID, recheckMethod, recheckIsMeeting = detectCameraApp()
        local recheckApp = recheckBundleID and hs.application.get(recheckBundleID)
        local recheckAppName = recheckApp and recheckApp:name() or recheckBundleID or "unknown"

        if recheckIsMeeting == false then
          -- Still looks like settings after 30s - unusual but respect it
          U.log.f("Still not a meeting after %ds: %s", MEETING_CONFIRM_DELAY, recheckAppName)
        else
          -- Either confirmed meeting OR still unknown after 30s = treat as meeting
          startMeetingMode(recheckAppName, "confirmed_after_delay")
        end
      end
      meetingConfirmTimer = nil
    end)
  end
end

-- Actions to run when meeting ends
local function stopMeetingMode()
  U.log.f("Stopping meeting mode")
  U.dnd(false)
  require("ptt").setState("push-to-talk")
end

local function cameraInactive(camera, property)
  U.log.f("%s inactive", camera:name())

  -- Cancel any pending confirmation timer
  if meetingConfirmTimer then
    meetingConfirmTimer:stop()
    meetingConfirmTimer = nil
    U.log.d("Cancelled pending meeting confirmation (camera turned off)")
  end

  -- Delay meeting end to handle lobby→room transitions
  -- If camera reactivates within MEETING_END_DELAY, we won't stop meeting mode
  if pendingMeetingEnd then
    pendingMeetingEnd:stop()
  end

  U.log.df("Scheduling meeting end in %.1fs (lobby debounce)", MEETING_END_DELAY)
  pendingMeetingEnd = hs.timer.doAfter(MEETING_END_DELAY, function()
    -- Verify camera is still inactive before stopping meeting mode
    if not camera:isInUse() then
      U.log.d("Camera still inactive after delay - stopping meeting mode")
      stopMeetingMode()
    else
      U.log.d("Camera reactivated during delay - keeping meeting mode")
    end
    pendingMeetingEnd = nil
  end)
end

local function watchCameraProperty(camera, property)
  -- Weirdly, "gone" is used as the property  if the camera's use changes: https://www.hammerspoon.org/docs/hs.camera.html#setPropertyWatcherCallback
  if property == "gone" then
    local now = hs.timer.secondsSinceEpoch()
    local timeSinceLastProcess = now - lastProcessedTime

    -- Debounce: ignore events that occur too soon after the last one
    if timeSinceLastProcess < DEBOUNCE_INTERVAL then return end

    lastProcessedTime = now
    P({ camera:name(), property })

    if camera:isInUse() then
      cameraActive(camera, property)
    else
      cameraInactive(camera, property)
    end
  end
end

local function watchCamera(camera, status)
  U.log.i(fmt("camera detected: %s (%s)", camera:name(), status))
  if status == "Added" then
    if not camera:isPropertyWatcherRunning() then
      camera:setPropertyWatcherCallback(watchCameraProperty)
      camera:startPropertyWatcher()
    end
  end
end

local function addCameraOnInit()
  for _, camera in ipairs(hs.camera.allCameras() or {}) do
    U.log.n(fmt("initial detection: %s", camera:name()))
    camera:setPropertyWatcherCallback(watchCameraProperty)
    camera:startPropertyWatcher()
  end
end

function M:start()
  -- Stop existing watcher first to avoid duplicates
  if hs.camera.isWatcherRunning() then hs.camera.stopWatcher() end

  -- Stop and clean up any existing property watchers
  for _, camera in ipairs(hs.camera.allCameras() or {}) do
    if camera:isPropertyWatcherRunning() then camera:stopPropertyWatcher() end
  end

  hs.camera.setWatcherCallback(watchCamera)
  hs.camera.startWatcher()

  -- Start property watchers for existing cameras
  -- While startWatcher() may fire "Added" events, it's not always reliable,
  -- so we explicitly set up watchers for cameras that are already present
  for _, camera in ipairs(hs.camera.allCameras() or {}) do
    if not camera:isPropertyWatcherRunning() then
      U.log.n(fmt("initial detection: %s", camera:name()))
      camera:setPropertyWatcherCallback(watchCameraProperty)
      camera:startPropertyWatcher()
    end
  end
end

function M:stop()
  if hs.camera.isWatcherRunning() then
    for _, camera in ipairs(hs.camera.allCameras() or {}) do
      if camera:isPropertyWatcherRunning() then camera:stopPropertyWatcher() end
    end

    hs.camera.stopWatcher()
  end
end

return M
