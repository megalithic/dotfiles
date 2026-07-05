-- AX Meeting Detection Spike
-- Run this while in a Teams/Zoom/etc meeting to explore what's detectable
--
-- Usage:
--   1. Start a meeting in Teams/Zoom/etc
--   2. In Hammerspoon console, run: Spike.meeting.explore("teams")
--   3. Review the output - it will show AX elements that might indicate meeting state
--
-- This is a spike/research script - NOT production code

local M = {}

-- Register on global Spike namespace for easy console access
_G.Spike = _G.Spike or {}
_G.Spike.meeting = M

-- Target apps and their bundle IDs
local APPS = {
  teams = "com.microsoft.teams2",
  zoom = "us.zoom.xos",
  pop = "com.pop.pop.app",
  facetime = "com.apple.FaceTime",
  discord = "com.hnc.Discord",
  webex = "com.webex.meetingmanager",
  slack = "com.tinyspeck.slackmacgap",
  brave = "com.brave.Browser.nightly",
}

-- Interesting AX attributes to look for in meeting UIs
local MEETING_INDICATORS = {
  -- Buttons that appear during meetings
  buttons = {
    "Mute", "Unmute",
    "Camera", "Video", "Turn off video", "Turn on video",
    "Share", "Stop sharing", "Present", "Stop presenting",
    "Leave", "End", "Hang up", "End call",
    "Participants", "People",
    "Chat",
    "More actions",
    "Raise hand",
    "React",
  },
  -- Window titles/roles that indicate meeting
  titles = {
    "Meeting", "Call", "Huddle",
    "Zoom Meeting",
    "Presenting",
    "Screen sharing",
  },
  -- AX roles that are interesting
  roles = {
    "AXButton",
    "AXToolbar",
    "AXGroup",
    "AXStaticText",
  },
}

-- Recursively search AX tree and collect interesting elements
local function collectElements(element, results, depth, maxDepth)
  depth = depth or 0
  maxDepth = maxDepth or 6
  results = results or { buttons = {}, texts = {}, groups = {}, all = {} }

  if not element or depth > maxDepth then return results end

  local role = element:attributeValue("AXRole")
  local title = element:attributeValue("AXTitle") or ""
  local value = element:attributeValue("AXValue") or ""
  local desc = element:attributeValue("AXDescription") or ""
  local identifier = element:attributeValue("AXIdentifier") or ""
  local subrole = element:attributeValue("AXSubrole") or ""

  local indent = string.rep("  ", depth)

  -- Collect all elements with interesting attributes
  local info = {
    role = role,
    subrole = subrole,
    title = title,
    value = value,
    description = desc,
    identifier = identifier,
    depth = depth,
  }

  -- Check if this looks like a meeting-related element
  local isMeetingRelated = false
  local combinedText = (title .. " " .. value .. " " .. desc .. " " .. identifier):lower()

  for _, indicator in ipairs(MEETING_INDICATORS.buttons) do
    if combinedText:find(indicator:lower(), 1, true) then
      isMeetingRelated = true
      info.matchedIndicator = indicator
      break
    end
  end

  if role == "AXButton" then
    table.insert(results.buttons, info)
    if isMeetingRelated then
      info.isMeetingRelated = true
    end
  elseif role == "AXStaticText" and #title > 0 then
    table.insert(results.texts, info)
  elseif role == "AXGroup" and (#title > 0 or #identifier > 0) then
    table.insert(results.groups, info)
  end

  if isMeetingRelated then
    table.insert(results.all, info)
  end

  -- Recurse into children
  local children = element:attributeValue("AXChildren")
  if children and #children > 0 then
    for _, child in ipairs(children) do
      collectElements(child, results, depth + 1, maxDepth)
    end
  end

  return results
end

-- Print results in a readable format
local function printResults(results, appName)
  print("\n" .. string.rep("=", 60))
  print("AX EXPLORATION: " .. appName)
  print(string.rep("=", 60))

  print("\n--- MEETING-RELATED ELEMENTS ---")
  if #results.all > 0 then
    for i, elem in ipairs(results.all) do
      print(string.format("  [%d] %s: '%s' (matched: %s)",
        i, elem.role, elem.title or elem.description or elem.identifier,
        elem.matchedIndicator or "?"))
      if elem.identifier and #elem.identifier > 0 then
        print(string.format("      identifier: %s", elem.identifier))
      end
    end
  else
    print("  (none found)")
  end

  print("\n--- ALL BUTTONS (" .. #results.buttons .. " total) ---")
  for i, btn in ipairs(results.buttons) do
    if #(btn.title or "") > 0 or #(btn.description or "") > 0 then
      print(string.format("  [%d] '%s' (desc: '%s', id: '%s')",
        i, btn.title, btn.description, btn.identifier))
    end
  end

  print("\n--- INTERESTING GROUPS ---")
  local count = 0
  for i, grp in ipairs(results.groups) do
    if count < 20 then  -- Limit output
      print(string.format("  [%d] '%s' (id: '%s', subrole: '%s')",
        i, grp.title, grp.identifier, grp.subrole))
      count = count + 1
    end
  end
  if count >= 20 then
    print("  ... and " .. (#results.groups - 20) .. " more")
  end

  print("\n" .. string.rep("=", 60))
end

-- Check if we can detect specific meeting states
local function detectMeetingState(element)
  local results = collectElements(element, nil, 0, 8)

  local state = {
    inMeeting = false,
    isMuted = nil,
    cameraOn = nil,
    isSharing = nil,
    confidence = 0,
    evidence = {},
  }

  for _, elem in ipairs(results.all) do
    local indicator = (elem.matchedIndicator or ""):lower()

    -- Mute state detection
    if indicator == "unmute" or indicator:find("unmute") then
      state.isMuted = true
      state.inMeeting = true
      table.insert(state.evidence, "Found 'Unmute' button - user is muted")
    elseif indicator == "mute" then
      state.isMuted = false
      state.inMeeting = true
      table.insert(state.evidence, "Found 'Mute' button - user is unmuted")
    end

    -- Camera state detection
    if indicator:find("turn on video") or indicator:find("turn on camera") then
      state.cameraOn = false
      state.inMeeting = true
      table.insert(state.evidence, "Found 'Turn on video' - camera is off")
    elseif indicator:find("turn off video") or indicator:find("turn off camera") then
      state.cameraOn = true
      state.inMeeting = true
      table.insert(state.evidence, "Found 'Turn off video' - camera is on")
    end

    -- Screen sharing detection
    if indicator:find("stop sharing") or indicator:find("stop presenting") then
      state.isSharing = true
      state.inMeeting = true
      table.insert(state.evidence, "Found 'Stop sharing' - user is presenting")
    elseif indicator:find("share") or indicator:find("present") then
      -- Only if we're in a meeting
      if state.inMeeting then
        state.isSharing = false
        table.insert(state.evidence, "Found 'Share' button - user is not presenting")
      end
    end

    -- Leave/End buttons are strong meeting indicators
    if indicator:find("leave") or indicator:find("end") or indicator:find("hang up") then
      state.inMeeting = true
      state.confidence = state.confidence + 30
      table.insert(state.evidence, "Found '" .. indicator .. "' button")
    end
  end

  -- Calculate confidence
  if state.inMeeting then
    state.confidence = state.confidence + 40
    if state.isMuted ~= nil then state.confidence = state.confidence + 15 end
    if state.cameraOn ~= nil then state.confidence = state.confidence + 15 end
  end

  return state
end

-- Main exploration function
function M.explore(appKey)
  appKey = appKey or "teams"
  local bundleID = APPS[appKey]

  if not bundleID then
    print("Unknown app: " .. appKey)
    print("Available: " .. table.concat(vim.tbl_keys and vim.tbl_keys(APPS) or {"teams", "zoom", "pop", "facetime", "discord", "webex", "slack", "brave"}, ", "))
    return
  end

  local app = hs.application.get(bundleID)
  if not app then
    print("App not running: " .. appKey .. " (" .. bundleID .. ")")
    return
  end

  print("Found app: " .. app:name() .. " (PID: " .. app:pid() .. ")")

  -- Get AX application element
  local axApp = hs.axuielement.applicationElement(app)
  if not axApp then
    print("Could not get AX application element")
    return
  end

  -- For Electron/WebView apps, enable manual accessibility
  -- This is REQUIRED for Electron apps to expose their AX tree
  local electronApps = { "slack", "discord", "teams" }
  for _, electronApp in ipairs(electronApps) do
    if appKey == electronApp then
      local success = axApp:setAttributeValue("AXManualAccessibility", true)
      print("Enabled AXManualAccessibility for Electron app: " .. tostring(success))
      -- Give the app time to populate the AX tree
      hs.timer.usleep(500000) -- 500ms
      break
    end
  end

  -- Explore all windows
  local windows = app:allWindows()
  print("Found " .. #windows .. " window(s)")

  for i, win in ipairs(windows) do
    print("\n>>> Window " .. i .. ": " .. (win:title() or "(no title)"))

    local axWin = hs.axuielement.windowElement(win)
    if axWin then
      local results = collectElements(axWin, nil, 0, 8)
      printResults(results, app:name() .. " - " .. (win:title() or "window " .. i))

      -- Try to detect meeting state
      print("\n--- MEETING STATE DETECTION ---")
      local state = detectMeetingState(axWin)
      print("  In meeting: " .. tostring(state.inMeeting))
      print("  Confidence: " .. state.confidence .. "%")
      print("  Muted: " .. tostring(state.isMuted))
      print("  Camera on: " .. tostring(state.cameraOn))
      print("  Sharing screen: " .. tostring(state.isSharing))
      if #state.evidence > 0 then
        print("  Evidence:")
        for _, ev in ipairs(state.evidence) do
          print("    - " .. ev)
        end
      end
    else
      print("  Could not get AX window element")
    end
  end
end

-- Quick test - just check if AX is working at all
function M.test()
  local frontApp = hs.application.frontmostApplication()
  print("Testing AX on: " .. frontApp:name())

  local axApp = hs.axuielement.applicationElement(frontApp)
  if not axApp then
    print("FAIL: Could not get AX application element")
    return false
  end

  local role = axApp:attributeValue("AXRole")
  print("AXRole: " .. tostring(role))

  local children = axApp:attributeValue("AXChildren")
  print("Children count: " .. (children and #children or 0))

  if role == "AXApplication" and children and #children > 0 then
    print("SUCCESS: AX queries working")
    return true
  else
    print("WARNING: AX may not be fully functional")
    return false
  end
end

-- Dump the raw AX tree structure (verbose)
function M.dumpTree(appKey, maxDepth)
  appKey = appKey or "teams"
  maxDepth = maxDepth or 6
  local bundleID = APPS[appKey]

  if not bundleID then
    print("Unknown app: " .. appKey)
    return
  end

  local app = hs.application.get(bundleID)
  if not app then
    print("App not running: " .. appKey)
    return
  end

  local axApp = hs.axuielement.applicationElement(app)
  if not axApp then
    print("Could not get AX application element")
    return
  end

  -- Enable manual accessibility
  axApp:setAttributeValue("AXManualAccessibility", true)
  print("Enabled AXManualAccessibility")
  hs.timer.usleep(500000)

  local function dumpElement(element, depth)
    if not element or depth > maxDepth then return end

    local indent = string.rep("  ", depth)
    local role = element:attributeValue("AXRole") or "?"
    local subrole = element:attributeValue("AXSubrole") or ""
    local title = element:attributeValue("AXTitle") or ""
    local desc = element:attributeValue("AXDescription") or ""
    local identifier = element:attributeValue("AXIdentifier") or ""
    local value = element:attributeValue("AXValue")
    local valueStr = ""
    if value and type(value) == "string" and #value > 0 and #value < 50 then
      valueStr = " val='" .. value .. "'"
    end

    -- Build display string
    local display = role
    if #subrole > 0 then display = display .. "/" .. subrole end
    if #title > 0 then display = display .. " '" .. title:sub(1,40) .. "'" end
    if #desc > 0 then display = display .. " desc='" .. desc:sub(1,30) .. "'" end
    if #identifier > 0 then display = display .. " id='" .. identifier:sub(1,30) .. "'" end
    display = display .. valueStr

    local children = element:attributeValue("AXChildren")
    local childCount = children and #children or 0

    -- Show child count to diagnose where the tree stops
    if childCount == 0 and depth < maxDepth then
      display = display .. " [LEAF - no children]"
    elseif depth == maxDepth and childCount > 0 then
      display = display .. " [TRUNCATED - " .. childCount .. " more children]"
    end

    print(indent .. display)

    if children then
      for _, child in ipairs(children) do
        dumpElement(child, depth + 1)
      end
    end
  end

  print("\n" .. string.rep("=", 70))
  print("RAW AX TREE DUMP: " .. app:name() .. " (max depth: " .. maxDepth .. ")")
  print(string.rep("=", 70))

  local windows = app:allWindows()
  for i, win in ipairs(windows) do
    print("\n>>> Window " .. i .. ": " .. (win:title() or "(no title)"))
    local axWin = hs.axuielement.windowElement(win)
    if axWin then
      dumpElement(axWin, 0)
    end
  end

  print("\n" .. string.rep("=", 70))
  print("Use Spike.meeting.dumpTree('teams', 10) for deeper exploration")
end

-- Deep dive into AXWebArea specifically
function M.deepDive(appKey)
  appKey = appKey or "teams"
  local bundleID = APPS[appKey]

  if not bundleID then
    print("Unknown app: " .. appKey)
    return
  end

  local app = hs.application.get(bundleID)
  if not app then
    print("App not running: " .. appKey)
    return
  end

  local axApp = hs.axuielement.applicationElement(app)
  if not axApp then
    print("Could not get AX application element")
    return
  end

  -- Enable manual accessibility for Electron apps
  axApp:setAttributeValue("AXManualAccessibility", true)
  print("Enabled AXManualAccessibility")
  hs.timer.usleep(1000000) -- 1 second wait

  -- Recursive function to find AXWebArea and explore deep inside
  local function findWebAreas(element, depth, path)
    depth = depth or 0
    path = path or "root"

    if not element or depth > 15 then return end

    local role = element:attributeValue("AXRole")
    local title = element:attributeValue("AXTitle") or ""
    local desc = element:attributeValue("AXDescription") or ""
    local identifier = element:attributeValue("AXIdentifier") or ""

    -- Found a web area - explore it deeply
    if role == "AXWebArea" then
      print(string.format("\n🌐 FOUND AXWebArea at depth %d: %s", depth, path))
      print("   Title: " .. title)
      print("   Description: " .. desc)

      -- Explore children of web area deeply
      local function exploreWebContent(webEl, webDepth, prefix)
        if not webEl or webDepth > 20 then return end

        local wRole = webEl:attributeValue("AXRole") or "?"
        local wTitle = webEl:attributeValue("AXTitle") or ""
        local wDesc = webEl:attributeValue("AXDescription") or ""
        local wValue = webEl:attributeValue("AXValue") or ""

        -- Only print interesting elements
        local interesting = wRole == "AXButton" or wRole == "AXLink" or
                           #wTitle > 0 or #wDesc > 0 or
                           wRole:find("Text") or wRole:find("Image")

        -- Check for meeting indicators
        local combined = (wTitle .. " " .. wDesc .. " " .. wValue):lower()
        local hasMeetingIndicator = combined:find("mute") or combined:find("leave") or
                                    combined:find("share") or combined:find("camera") or
                                    combined:find("video") or combined:find("participants")

        if hasMeetingIndicator then
          print(string.format("%s⭐ [%s] '%s' desc='%s' (MEETING INDICATOR!)",
            prefix, wRole, wTitle, wDesc))
        elseif interesting and webDepth < 12 then
          print(string.format("%s[%s] '%s' desc='%s'", prefix, wRole, wTitle, wDesc))
        end

        local children = webEl:attributeValue("AXChildren")
        if children then
          for _, child in ipairs(children) do
            exploreWebContent(child, webDepth + 1, prefix .. "  ")
          end
        end
      end

      exploreWebContent(element, 0, "   ")
    end

    -- Continue searching for web areas
    local children = element:attributeValue("AXChildren")
    if children then
      for i, child in ipairs(children) do
        findWebAreas(child, depth + 1, path .. "/" .. (role or "?") .. "[" .. i .. "]")
      end
    end
  end

  print("\n" .. string.rep("=", 60))
  print("DEEP DIVE: Searching for AXWebArea in " .. app:name())
  print(string.rep("=", 60))

  -- Search all windows
  local windows = app:allWindows()
  for i, win in ipairs(windows) do
    print("\n>>> Window " .. i .. ": " .. (win:title() or "(no title)"))
    local axWin = hs.axuielement.windowElement(win)
    if axWin then
      findWebAreas(axWin, 0, "window")
    end
  end

  print("\n" .. string.rep("=", 60))
  print("Deep dive complete")
end

-- Interactive browser shortcut
function M.browse(appKey)
  appKey = appKey or "teams"
  local bundleID = APPS[appKey]

  if not bundleID then
    print("Unknown app: " .. appKey)
    return
  end

  local app = hs.application.get(bundleID)
  if not app then
    print("App not running: " .. appKey)
    return
  end

  local axApp = hs.axuielement.applicationElement(app)
  require("axbrowse").browse(axApp)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Swift CLI Detection (the good stuff)
-- ══════════════════════════════════════════════════════════════════════════════

-- Test the Swift CLI detection
function M.swift(appKey)
  appKey = appKey or "teams"
  local bundleID = APPS[appKey]

  if not bundleID then
    print("Unknown app: " .. appKey)
    print("Available: teams, zoom, slack, discord, facetime, webex, pop, brave")
    return
  end

  print("\n" .. string.rep("=", 60))
  print("SWIFT MEETING DETECTION: " .. appKey)
  print(string.rep("=", 60))

  local meeting = require("lib.meeting")
  meeting.query(bundleID, function(result)
    print("\nResult:")
    print("  App: " .. (result.appName or "?"))
    print("  In Meeting: " .. tostring(result.inMeeting))
    print("  Confidence: " .. (result.confidence or 0) .. "%")
    print("  Muted: " .. tostring(result.isMuted))
    print("  Camera On: " .. tostring(result.cameraOn))
    print("  Sharing: " .. tostring(result.isSharing))

    if result.evidence and #result.evidence > 0 then
      print("  Evidence:")
      for _, ev in ipairs(result.evidence) do
        print("    - " .. ev)
      end
    end

    if result.error then
      print("  ERROR: " .. result.error)
    end

    print(string.rep("=", 60))
  end, { verbose = true })
end

-- Find any active meeting across all known apps
function M.findMeeting()
  print("\n" .. string.rep("=", 60))
  print("SEARCHING FOR ACTIVE MEETING...")
  print(string.rep("=", 60))

  local meeting = require("lib.meeting")
  meeting.findAnyMeeting(function(result)
    if result then
      print("\n✓ FOUND MEETING:")
      print("  App: " .. (result.appName or "?"))
      print("  Bundle: " .. (result.bundleID or "?"))
      print("  Muted: " .. tostring(result.isMuted))
      print("  Camera: " .. tostring(result.cameraOn))
      print("  Confidence: " .. (result.confidence or 0) .. "%")
    else
      print("\n✗ No active meeting found")
    end
    print(string.rep("=", 60))
  end)
end

return M
