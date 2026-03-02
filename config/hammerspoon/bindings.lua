--- REFS:
--- https://github.com/NateEag/dotfiles/blob/master/src/.hammerspoon/init.lua#L505-L537

local M = {}

-- NOTE: _G.Hypers is managed by hyper.lua module (not here)

local fmt = string.format
local wm = req("wm")
local summon = req("lib.summon")
local chain = req("chain")
local enum = req("hs.fnutils")
local utils = require("utils")

function M.loadApps()
  local hyper = req("hyper", { id = "apps" }):start()
  enum.each(C.launchers, function(bindingTable)
    local bundleID, globalBind, localBinds, focusOnly = table.unpack(bindingTable)
    if globalBind ~= nil then
      local key = globalBind
      local mods = {}
      local pressCount = nil

      if type(key) == "table" then
        mods, key, pressCount = table.unpack(globalBind)
      end

      if string.match(bundleID, "noop") then
        hyper:bind(mods, key, function() end)
      else
        hyper:bind(mods, key, function()
          if focusOnly ~= nil and focusOnly then
            summon.focus(bundleID)
          else
            summon.toggle(bundleID)
          end
        end)
      end
    end

    if localBinds then
      enum.each(localBinds, function(binds)
        local mods = {}
        local key = binds

        if type(binds) == "table" and #binds == 2 and type(binds[1]) == "table" then
          mods, key = table.unpack(binds)
        end

        hyper:bindPassThrough(mods, key, bundleID)
      end)
    end
  end)
end

-- Generic meeting window finder
-- Searches for windows using U.app.isMeetingWindow for classification
-- Returns: window (if meeting found), nil (if no meeting)
-- IMPORTANT: Does NOT fall back to "any window" - only returns confirmed/likely meetings
local function findMeetingWindow(app)
  if not app then return nil end

  local windows = app:allWindows()

  -- Pass 1: Find a window CONFIRMED as a meeting by isMeetingWindow
  -- This is the most reliable detection - explicit "yes this is a meeting"
  for _, window in ipairs(windows) do
    if window:isStandard() then
      local isMeeting, reason = U.app.isMeetingWindow(app, window)
      if isMeeting == true then
        U.log.d(string.format("[meeting] Found confirmed meeting: %s (%s)", window:title(), reason))
        return window
      end
    end
  end

  -- Pass 2: For UNKNOWN windows (nil, not false), use size heuristic
  -- Only on external screen, only large windows - likely a video call
  -- Skip if isMeetingWindow returned false (e.g., Teams main window)
  for _, window in ipairs(windows) do
    if window:isStandard() then
      local isMeeting, reason = U.app.isMeetingWindow(app, window)
      -- Only consider windows where detection was uncertain (nil), NOT explicitly false
      if isMeeting == nil then
        local windowScreen = window:screen()
        local screenName = windowScreen and windowScreen:name() or ""
        local isOnExternalScreen = screenName ~= C.displays.internal and screenName ~= ""
        if isOnExternalScreen then
          local frame = window:frame()
          if frame.w >= 2000 and frame.h >= 1400 then
            U.log.d(string.format("[meeting] Found likely meeting via size heuristic: %s", window:title()))
            return window
          end
        end
      end
    end
  end

  -- NO Pass 3 fallback! If we can't confirm it's a meeting, return nil.
  -- This prevents focusing Teams/Zoom/etc when they're running but not in a meeting.
  U.log.d(string.format("[meeting] No meeting window found for %s", app:bundleID()))
  return nil
end

function M.loadMeeting()
  req("hyper", { id = "meeting" }):start():bind({}, "z", nil, function()
    -- Check native meeting apps in priority order
    local meetingApps = {
      "com.pop.pop.app", -- Pop
      "us.zoom.xos", -- Zoom
      "com.microsoft.teams2", -- Teams
    }

    -- Browser-based meeting URL patterns (regex patterns for JavaScript)
    -- Used by osascript JavaScript, supports standard regex syntax
    local meetingUrlPatterns = {
      "meet.google.com",
      "hangouts.google.com.call",
      "www.valant.io",
      "telehealth.px.athena.io",
      -- Add more patterns as needed (e.g., "teams.microsoft.com", "whereby.com")
    }

    local targetWindow = nil

    -- Check browser-based meetings as fallback
    local urlPattern = table.concat(meetingUrlPatterns, "|")
    if req("lib.interop.browser").hasTab(urlPattern) then
      req("lib.interop.browser").jump(urlPattern)
    else
      -- Find first running meeting app with a valid meeting window
      for _, bundleID in ipairs(meetingApps) do
        local app = hs.application.find(bundleID)
        if app then
          targetWindow = findMeetingWindow(app)
          if targetWindow then
            break -- Found a meeting window, stop searching
          end
        end
      end

      -- Focus the meeting window if found
      if targetWindow then
        targetWindow:focus()
      else
        -- No meeting found
        U.log.w("No active meeting window found")
      end
    end
  end)
end

function M.loadFigma()
  req("hyper", { id = "figma" }):start():bind({ "shift" }, "f", nil, function()
    local focusedApp = hs.application.frontmostApplication()
    if hs.application.find("com.figma.Desktop") then
      hs.application.launchOrFocusByBundleID("com.figma.Desktop")
    elseif req("lib.interop.browser").hasTab("figma.com") then
      req("lib.interop.browser").jump("figma.com")
    else
      print(fmt("%s: neither figma.app, nor figma web are opened", "bindings.hyper.figma"))

      focusedApp:activate()
    end
  end)
end

function M.loadUtils()
  local lastBrowsedApp
  req("hyper", { id = "config.utils" })
    :start()
    :bind({ "shift" }, "r", nil, function()
      hs.notify.new({ title = "hammerspork", subTitle = "config is reloading..." }):send()
      hs.reload()
    end)
    :bind({ "shift", "ctrl" }, "l", nil, req("wm").placeAllApps)
    :bind({ "ctrl" }, "d", nil, function() utils.dnd() end)
    :bind({ "ctrl" }, "b", nil, function()
      local axb = require("axbrowse")
      local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
      if currentApp == lastBrowsedApp then
        axb.browse() -- try to continue from where we left off
      else
        lastBrowsedApp = currentApp
        axb.browse(currentApp) -- new app, so start over
      end
    end)
end

function M.loadShade()
  local shade = require("lib.interop.shade")

  -- Configure Shade for quick capture workflow
  -- Use nvim with a socket for RPC commands (context injection, file opening)
  -- Socket path: ~/.local/state/shade/nvim.sock (XDG compliant)
  local socketPath = shade.getSocketPath()
  local capturesDir = shade.getCapturesDir()

  -- Command needs shell wrapper for:
  -- 1. Socket cleanup (stale socket from crash/kill)
  -- 2. Multiple commands (rm + nvim)
  -- 3. SHADE=1 env var for nvim to detect it's running in Shade
  -- Opens nvim in captures dir - user creates/opens capture notes there
  local nvimCmd = string.format("/usr/bin/env zsh -c 'rm -f %s; SHADE=1 exec nvim --listen %s'", socketPath, socketPath)

  shade.configure({
    width = 0.4,
    height = 0.4,
    command = nvimCmd,
    workingDirectory = capturesDir,
    startHidden = false, -- Launch visible so nvim actually starts
  })

  local shadeModality = require("hypemode").new("shade", {
    showIndicator = false,
    showAlert = false,
  })
  shadeModality
    :start()
    -- toggle Shade visibility (focus, hide, show)
    :bind({}, "n", nil, function() shade.smartToggle() end)
    -- daily note: open in Shade floating panel
    :bind({}, "o", nil, function() shade.openDailyNote() end)
    :bind({}, "d", nil, function() shade.openDailyNote() end)
    -- text capture: gather context from frontmost app and create capture note
    :bind(
      {},
      "c",
      nil,
      function() shade.captureWithContext() end
    )
    -- sidebar capture: capture note in sidebar mode (side-by-side with main app)
    -- TODO: similar ergonomics as our window tiling?
    :bind(
      {},
      "v",
      nil,
      function() shade.captureWithContextSidebar() end
    )
    -- recall sidebar: re-enter sidebar mode with last companion window
    :bind(
      {},
      "r",
      nil,
      function() shade.recallSidebar() end
    )
    -- mode toggles (vim-style: h=left/sidebar, l=right/float)
    :bind(
      {},
      "h",
      nil,
      function() shade.toSidebarLeft() end
    )
    :bind({}, "l", nil, function() shade.toFloating() end)

  -- Direct shade bindings (no modal required)
  req("hyper", { id = "shade" })
    :start()
    -- hyper+return: toggle Shade visibility (quick access)
    :bind({}, "return", function() shade.smartToggle() end)
    -- hyper+shift+return: quick capture with context (floating)
    :bind({ "shift" }, "return", function() shade.captureWithContext() end)
    -- hyper+n: enter shade modal for advanced operations
    :bind({}, "n", function() shadeModality:toggle() end)
end

function M.loadNotifications()
  -- Dismiss active HUD notification with F19+escape
  local dismissBindings = C.notifier.dismissBindings
  if dismissBindings then
    local mods, key = table.unpack(dismissBindings)
    req("hyper", { id = "notifications" }):start():bind(mods, key, nil, function()
      -- Dismiss all active HUDs
      if HUD and #HUD.getActive() > 0 then HUD.dismissAll() end
    end)
  end
end

-- HYPER+Q: Force quit (NUKE IT!) the frontmost application
-- Uses kill9() for immediate termination (SIGKILL equivalent)
-- Silent operation - no alerts, just console logging
function M.loadForceQuit()
  req("hyper", { id = "force-quit" }):start():bind({}, "q", nil, function()
    local app = hs.application.frontmostApplication()
    if app then
      local appName = app:name()
      local bundleID = app:bundleID()
      U.log.i(string.format("[NUKE] Force quitting %s (%s)", appName, bundleID))
      app:kill9()
    end
  end)
end

-- WM: Window management with real-time visual tracking
function M.loadWm()
  local wm = require("wm")
  wm.init()
end

function M:init()
  M.loadApps()
  M.loadMeeting()
  M.loadFigma()
  M.loadUtils()
  M.loadWm()
  M.loadNotifications()
  M.loadForceQuit()
  M.loadShade()

  U.log.i("initialized")
end

return M
