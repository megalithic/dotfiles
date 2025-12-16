-- Unified Meeting Detection Module
--
-- Combines multiple detection methods:
-- 1. Swift CLI for deep AX inspection (most accurate)
-- 2. VDC/lsof for camera detection (fast)
-- 3. Title patterns (fallback)
--
-- Usage:
--   local meeting = require("lib.meeting")
--
--   -- Quick check if any meeting app is active
--   meeting.isActive(function(active, info)
--     if active then
--       print("In meeting:", info.appName)
--     end
--   end)
--
--   -- Get detailed state for a specific app
--   meeting.getState("com.microsoft.teams2", function(state)
--     print("Muted:", state.isMuted)
--   end)

local M = {}

-- Sub-modules
M.swiftDetect = require("lib.meeting.swift-detect")

-- Re-export convenience functions
M.query = M.swiftDetect.query
M.querySync = M.swiftDetect.querySync
M.isInMeeting = M.swiftDetect.isInMeeting
M.isMuted = M.swiftDetect.isMuted
M.isCameraOn = M.swiftDetect.isCameraOn
M.isSharing = M.swiftDetect.isSharing
M.findActiveMeeting = M.swiftDetect.findActiveMeeting
M.findAnyMeeting = M.swiftDetect.findAnyMeeting
M.KNOWN_APPS = M.swiftDetect.KNOWN_APPS

-- High-level: Is there an active meeting?
function M.isActive(callback)
  M.findAnyMeeting(function(result)
    if result and result.inMeeting then
      callback(true, result)
    else
      callback(false, nil)
    end
  end)
end

-- High-level: Get meeting state with best available method
function M.getState(bundleID, callback)
  M.query(bundleID, function(result)
    -- Enhance with additional info if needed
    local state = {
      bundleID = bundleID,
      appName = result.appName,
      inMeeting = result.inMeeting or false,
      confidence = result.confidence or 0,
      isMuted = result.isMuted,
      cameraOn = result.cameraOn,
      isSharing = result.isSharing,
      evidence = result.evidence or {},
      error = result.error,
      -- Detection method info
      method = "swift_ax",
      windowCount = result.windowCount,
    }
    callback(state)
  end)
end

return M
