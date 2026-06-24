--- REFS:
--- https://github.com/NateEag/dotfiles/blob/master/src/.hammerspoon/init.lua#L505-L537

local M = {}

-- NOTE: _G.Hypers is managed by hyper.lua module (not here)

local fmt = string.format
local summon = req("lib.summon")
local enum = req("hs.fnutils")
local utils = require("utils")

local function unpackBind(bind)
  local mods = {}
  local key = bind

  if type(bind) == "table" then
    mods, key = table.unpack(bind)
  end

  return mods, key
end

function M.loadApps()
  local hyper = req("hyper", { id = "apps" }):start()
  enum.each(C.launchers, function(bindingTable)
    local bundleID, globalBind, opts = table.unpack(bindingTable)
    opts = opts or {}

    if globalBind ~= nil then
      local mods, key = unpackBind(globalBind)

      if string.match(bundleID, "noop") then
        hyper:bind(mods, key, function() end)
      else
        hyper:bind(mods, key, function()
          if opts.cycleWindows then
            summon.cycleWindows(bundleID)
          elseif opts.focusOnly then
            summon.focus(bundleID)
          else
            summon.toggle(bundleID)
          end
        end)
      end
    end

    enum.each(opts.passThrough or {}, function(bind)
      local mods, key = unpackBind(bind)
      hyper:bindPassThrough(mods, key, bundleID)
    end)

    enum.each(opts.urlSchemes or {}, function(binding)
      local bind, url = table.unpack(binding)
      local mods, key = unpackBind(bind)
      hyper:bind(mods, key, nil, function() hs.urlevent.openURL(url) end)
    end)
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
    :bind({ "shift", "ctrl" }, "l", nil, require("wm").placeAllApps)
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
  local nvimCmd = string.format("/bin/sh -c 'rm -f %s; SHADE=1 exec nvim --listen %s'", socketPath, socketPath)

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
    :bind(
      { "shift" },
      "return",
      function() shade.captureWithContext() end
    )
    -- hyper+shift+n / hyper+ctrl+n are owned by shade-next quick capture.
    -- Keep legacy shade modal available from bindings above, not a direct chord.
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

-- Native macOS window tiling via menu commands
-- Uses selectMenuItem to trigger Sequoia/Tahoe's Window > Move & Resize menu
-- NOTE: Forged fn key events don't work - macOS validates fn at hardware/IOKit level
function M.loadNativeTiling()
  local hypemode = require("hypemode")

  -- Menu-based tiling (works reliably, uses native macOS tiling with animation)
  local function menuTile(position)
    local app = hs.application.frontmostApplication()
    if app then
      local ok = app:selectMenuItem({ "Window", "Move & Resize", position })
      if not ok then U.log.w("menuTile: failed to select menu item:", position) end
    end
  end

  local function findMenuItemPath(app, titleParts)
    local function containsAll(title)
      title = string.lower(title or "")
      for _, part in ipairs(titleParts) do
        if not title:find(part, 1, true) then return false end
      end
      return true
    end

    local function walk(items, path)
      for _, item in ipairs(items or {}) do
        local title = item.AXTitle or ""
        local nextPath = path

        if title ~= "" then
          nextPath = { table.unpack(path) }
          table.insert(nextPath, title)
          if item.AXEnabled ~= false and containsAll(title) then return nextPath end
        end

        if not item.AXTitle and #item > 0 then
          local found = walk(item, nextPath)
          if found then return found end
        end

        for _, child in ipairs(item.AXChildren or {}) do
          local found = child.AXTitle and walk({ child }, nextPath) or walk(child, nextPath)
          if found then return found end
        end
      end

      return nil
    end

    return walk(app:getMenuItems(), {})
  end

  local function selectMenuItemContaining(app, titleParts)
    local path = findMenuItemPath(app, titleParts)
    if not path then return false end
    return app:selectMenuItem(path)
  end

  -- Move window to next screen, then apply tiling
  local function tileOnOtherScreen(position)
    local win = hs.window.frontmostWindow()
    if not win then return end
    win:moveToScreen(win:screen():next())
    -- Small delay to let the move complete, then tile
    hs.timer.doAfter(0.1, function() menuTile(position) end)
  end

  -- Create hypemode for native tiling (hyper+w)
  local nativeWmMode = hypemode.new("nativeWm", { showIndicator = true }):start()

  nativeWmMode
    -- H: tile left half
    :bind({}, "h", function() menuTile("Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "h", function() tileOnOtherScreen("Left") end, function() nativeWmMode:exit(0.3) end)
    -- L: tile right half
    :bind({}, "l", function() menuTile("Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "l", function() tileOnOtherScreen("Right") end, function() nativeWmMode:exit(0.3) end)
    -- K: tile top half (no chaining for vertical, just native)
    :bind(
      {},
      "k",
      function() menuTile("Top") end,
      function() nativeWmMode:exit(0.3) end
    )
    :bind({ "shift" }, "k", function() tileOnOtherScreen("Top") end, function() nativeWmMode:exit(0.3) end)
    -- J: tile bottom half (no chaining for vertical, just native)
    :bind(
      {},
      "j",
      function() menuTile("Bottom") end,
      function() nativeWmMode:exit(0.3) end
    )
    :bind({ "shift" }, "j", function() tileOnOtherScreen("Bottom") end, function() nativeWmMode:exit(0.3) end)
    -- Space: center window
    :bind({}, "space", function()
      local app = hs.application.frontmostApplication()
      if app then app:selectMenuItem({ "Window", "Center" }) end
    end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "space", function()
      local win = hs.window.frontmostWindow()
      if win then win:moveToScreen(win:screen():next()) end
      hs.timer.doAfter(0.1, function()
        local app = hs.application.frontmostApplication()
        if app then app:selectMenuItem({ "Window", "Center" }) end
      end)
    end, function() nativeWmMode:exit(0.3) end)
    -- Return: fill screen
    :bind({}, "return", function()
      local app = hs.application.frontmostApplication()
      if app then app:selectMenuItem({ "Window", "Fill" }) end
    end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "return", function()
      local win = hs.window.frontmostWindow()
      if win then win:moveToScreen(win:screen():next()) end
      hs.timer.doAfter(0.1, function()
        local app = hs.application.frontmostApplication()
        if app then app:selectMenuItem({ "Window", "Fill" }) end
      end)
    end, function() nativeWmMode:exit(0.3) end)
    -- Backspace: return to previous size
    :bind(
      {},
      "delete",
      function() menuTile("Return to Previous Size") end,
      function() nativeWmMode:exit(0.3) end
    )
    -- V: tile with another window (hybrid: chooser + native tiling)
    :bind({}, "v", function()
      nativeWmMode:exit()

      local focused = hs.window.frontmostWindow()
      if not focused then return end

      -- Build window list for chooser
      local windows = {}
      for _, win in ipairs(hs.window.orderedWindows()) do
        local app = win and win:application()
        if win and app and win ~= focused and win:isStandard() then
          table.insert(windows, {
            text = win:title(),
            subText = app:title(),
            image = hs.image.imageFromAppBundle(app:bundleID()),
            id = win:id(),
          })
        end
      end

      local chooser = hs.chooser.new(function(choice)
        if not choice then return end

        local other = hs.window.find(choice.id)
        if not focused or not other then return end

        -- Move both windows to same screen as focused
        local screen = focused:screen()
        other:moveToScreen(screen)

        -- Use native macOS tiling
        -- First, tile the focused window left
        focused:focus()
        hs.timer.doAfter(0.05, function()
          local app1 = focused:application()
          if app1 then app1:selectMenuItem({ "Window", "Move & Resize", "Left" }) end

          -- Then tile the other window right
          hs.timer.doAfter(0.15, function()
            other:focus()
            hs.timer.doAfter(0.05, function()
              local app2 = other:application()
              if app2 then app2:selectMenuItem({ "Window", "Move & Resize", "Right" }) end

              -- Return focus to original window
              hs.timer.doAfter(0.1, function() focused:focus() end)
            end)
          end)
        end)
      end)

      chooser
        :placeholderText("Choose window to tile right (native macOS tiling)")
        :searchSubText(true)
        :choices(windows)
        :show()
    end)
    -- Quarters: u/i/n/m for corners
    :bind(
      {},
      "u",
      function() menuTile("Top Left") end,
      function() nativeWmMode:exit(0.3) end
    )
    :bind({ "shift" }, "u", function() tileOnOtherScreen("Top Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "i", function() menuTile("Top Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "i", function() tileOnOtherScreen("Top Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "n", function() menuTile("Bottom Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "n", function() tileOnOtherScreen("Bottom Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "m", function() menuTile("Bottom Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({ "shift" }, "m", function() tileOnOtherScreen("Bottom Right") end, function() nativeWmMode:exit(0.3) end)
    -- Arrange (two-window layouts) - use number keys
    -- These arrange the CURRENT window with another window
    :bind(
      {},
      "1",
      function() menuTile("Left & Right") end,
      function() nativeWmMode:exit(0.3) end
    )
    :bind({}, "2", function() menuTile("Right & Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "3", function() menuTile("Top & Bottom") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "4", function() menuTile("Bottom & Top") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "5", function() menuTile("Quarters") end, function() nativeWmMode:exit(0.3) end)
    -- B: Browser tab split - split active tab to new window, tile right
    :bind({}, "s", function()
      nativeWmMode:exit()

      local app = hs.application.frontmostApplication()
      if not app then return end

      local bundleID = app:bundleID()
      local browserPatterns = { "helium", "brave", "orion", "chrome", "firefox", "safari", "arc" }
      local appID = string.lower(table.concat({ bundleID or "", app:name() or "" }, " "))
      local isBrowser = false
      for _, pattern in ipairs(browserPatterns) do
        if appID:find(pattern, 1, true) then
          isBrowser = true
          break
        end
      end

      if not isBrowser then
        hs.alert.show("Not a browser")
        return
      end

      local mainWin = hs.window.frontmostWindow()
      if not mainWin then return end

      -- Store original window state for potential restore
      local originalFrame = mainWin:frame()
      local originalScreen = mainWin:screen()

      -- Move tab to new window by finding a matching menu item.
      -- Do not fall back to Cmd+Shift+N: Chromium maps that to New Incognito Window.
      local moved = selectMenuItemContaining(app, { "move", "tab", "new", "window" })

      if not moved then
        hs.alert.show("No move-tab menu item")
        return
      end

      -- Wait for new window, then tile
      hs.timer.doAfter(0.3, function()
        local newWin = hs.window.frontmostWindow()
        if newWin and newWin ~= mainWin then
          -- Store split info for potential restore
          _G._browserSplitState = {
            mainWin = mainWin,
            splitWin = newWin,
            originalFrame = originalFrame,
            originalScreen = originalScreen,
            bundleID = bundleID,
          }

          -- Tile: main window left, new window right
          mainWin:focus()
          hs.timer.doAfter(0.05, function()
            app:selectMenuItem({ "Window", "Move & Resize", "Left" })
            hs.timer.doAfter(0.15, function()
              newWin:focus()
              hs.timer.doAfter(0.05, function() app:selectMenuItem({ "Window", "Move & Resize", "Right" }) end)
            end)
          end)
        end
      end)
    end, nil)
    -- Shift+S: Undo browser split - merge tab back and restore window
    :bind({ "shift" }, "s", function()
      nativeWmMode:exit()

      local state = _G._browserSplitState
      if not state then
        hs.alert.show("No browser split to undo")
        return
      end

      local mainWin = state.mainWin
      local splitWin = state.splitWin
      local originalFrame = state.originalFrame

      -- Check main window still exists
      if not mainWin or not pcall(function() return mainWin:id() end) then
        hs.alert.show("Main window no longer exists")
        _G._browserSplitState = nil
        return
      end

      -- Check split window still exists
      if not splitWin or not pcall(function() return splitWin:id() end) then
        hs.alert.show("Split window no longer exists")
        -- Still restore main window position
        if mainWin and originalFrame then
          mainWin:focus()
          mainWin:setFrame(originalFrame)
        end
        _G._browserSplitState = nil
        return
      end

      -- Focus split window and use keyboard shortcut to move tab back
      splitWin:focus()
      hs.timer.doAfter(0.1, function()
        -- Cmd+Shift+M merges all windows in Chrome/Brave
        -- Or we can close window (tab goes back to previous window in some browsers)
        local app = splitWin:application()
        if app then
          -- Try merge first
          local merged = app:selectMenuItem({ "Window", "Merge All Windows" })
          if not merged then
            -- Close the split window - tab should return to main window
            hs.eventtap.keyStroke({ "cmd" }, "w")
          end
        end

        -- Restore main window to original position after a delay
        hs.timer.doAfter(0.3, function()
          if mainWin and pcall(function() return mainWin:id() end) then
            mainWin:focus()
            if originalFrame then mainWin:setFrame(originalFrame) end
            -- Also restore from native tiling
            local mainApp = mainWin:application()
            if mainApp then mainApp:selectMenuItem({ "Window", "Move & Resize", "Return to Previous Size" }) end
          end
        end)
      end)

      _G._browserSplitState = nil
    end, nil)

  -- Bind hyper+w to enter native tiling mode
  req("hyper", { id = "nativeWm" }):bind({}, "w", function() nativeWmMode:toggle() end)

  U.log.i("nativeTiling: initialized (hyper+w for native macOS tiling via menu)")
end

function M:init()
  M.loadApps()
  M.loadMeeting()
  M.loadFigma()
  M.loadUtils()
  M.loadWm()
  M.loadNativeTiling() -- Optional native Tahoe tiling on hyper+w
  M.loadNotifications()
  M.loadForceQuit()
  M.loadShade()

  U.log.i("initialized")
end

return M
