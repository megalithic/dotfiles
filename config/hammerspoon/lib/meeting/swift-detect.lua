-- Swift-based meeting detection wrapper
-- Uses the meeting-detect Swift CLI for deep AX tree inspection
--
-- Usage:
--   local detect = require("lib.meeting.swift-detect")
--
--   -- Async (recommended)
--   detect.query("com.microsoft.teams2", function(result)
--     if result.inMeeting then
--       print("In meeting! Muted:", result.isMuted)
--     end
--   end)
--
--   -- Sync (blocks, use sparingly)
--   local result = detect.querySync("com.microsoft.teams2")

local M = {}

-- Path to Swift CLI
local SWIFT_CLI = os.getenv("HOME") .. "/.dotfiles/bin/meeting-detect"

-- Cache to avoid hammering the CLI
local cache = {
  results = {},    -- bundleID -> result
  timestamps = {}, -- bundleID -> timestamp
  ttl = 2,         -- Cache TTL in seconds
}

-- Check if cached result is still valid
local function getCached(bundleID)
  local ts = cache.timestamps[bundleID]
  if ts and (os.time() - ts) < cache.ttl then
    return cache.results[bundleID]
  end
  return nil
end

-- Store result in cache
local function setCache(bundleID, result)
  cache.results[bundleID] = result
  cache.timestamps[bundleID] = os.time()
end

-- Clear cache for a bundle ID (or all)
function M.clearCache(bundleID)
  if bundleID then
    cache.results[bundleID] = nil
    cache.timestamps[bundleID] = nil
  else
    cache.results = {}
    cache.timestamps = {}
  end
end

-- Set cache TTL
function M.setCacheTTL(seconds)
  cache.ttl = seconds
end

-- Parse JSON output from Swift CLI
local function parseResult(output)
  if not output or #output == 0 then
    return { error = "Empty output from CLI" }
  end

  local ok, result = pcall(hs.json.decode, output)
  if not ok then
    return { error = "Failed to parse JSON: " .. tostring(result) }
  end

  return result
end

-- Async query (recommended)
-- Calls callback(result) when complete
function M.query(bundleID, callback, options)
  options = options or {}

  -- Check cache first
  if not options.skipCache then
    local cached = getCached(bundleID)
    if cached then
      if callback then callback(cached) end
      return
    end
  end

  local args = { bundleID }
  if options.verbose then
    table.insert(args, "--verbose")
  end

  local task = hs.task.new(SWIFT_CLI, function(exitCode, stdOut, stdErr)
    local result
    if exitCode == 0 then
      result = parseResult(stdOut)
      setCache(bundleID, result)
    else
      result = {
        error = "CLI failed",
        exitCode = exitCode,
        stderr = stdErr,
        bundleID = bundleID,
      }
    end

    if callback then callback(result) end
  end, args)

  task:start()
  return task -- Return task handle for cancellation if needed
end

-- Sync query (blocks - use sparingly!)
function M.querySync(bundleID, options)
  options = options or {}

  -- Check cache first
  if not options.skipCache then
    local cached = getCached(bundleID)
    if cached then return cached end
  end

  local args = { bundleID }
  if options.verbose then
    table.insert(args, "--verbose")
  end

  local output, status = hs.execute(SWIFT_CLI .. " " .. table.concat(args, " "))

  if status then
    local result = parseResult(output)
    setCache(bundleID, result)
    return result
  else
    return {
      error = "CLI execution failed",
      bundleID = bundleID,
    }
  end
end

-- Convenience: Check if app is in a meeting
function M.isInMeeting(bundleID, callback)
  M.query(bundleID, function(result)
    callback(result.inMeeting == true, result)
  end)
end

-- Convenience: Get mute state
function M.isMuted(bundleID, callback)
  M.query(bundleID, function(result)
    callback(result.isMuted, result)
  end)
end

-- Convenience: Get camera state
function M.isCameraOn(bundleID, callback)
  M.query(bundleID, function(result)
    callback(result.cameraOn, result)
  end)
end

-- Convenience: Get sharing state
function M.isSharing(bundleID, callback)
  M.query(bundleID, function(result)
    callback(result.isSharing, result)
  end)
end

-- Query multiple apps and return first one in a meeting
function M.findActiveMeeting(bundleIDs, callback)
  local pending = #bundleIDs
  local found = nil

  for _, bundleID in ipairs(bundleIDs) do
    M.query(bundleID, function(result)
      pending = pending - 1

      if not found and result.inMeeting then
        found = result
      end

      if pending == 0 then
        callback(found)
      end
    end)
  end
end

-- Known meeting app bundle IDs
M.KNOWN_APPS = {
  teams = "com.microsoft.teams2",
  zoom = "us.zoom.xos",
  slack = "com.tinyspeck.slackmacgap",
  discord = "com.hnc.Discord",
  facetime = "com.apple.FaceTime",
  webex = "com.webex.meetingmanager",
  pop = "com.pop.pop.app",
}

-- Query all known meeting apps
function M.findAnyMeeting(callback)
  local bundleIDs = {}
  for _, bundleID in pairs(M.KNOWN_APPS) do
    table.insert(bundleIDs, bundleID)
  end
  M.findActiveMeeting(bundleIDs, callback)
end

return M
