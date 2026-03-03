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

-- Native macOS window tiling via menu commands
-- Uses selectMenuItem to trigger Sequoia/Tahoe's Window > Move & Resize menu
-- NOTE: Forged fn key events don't work - macOS validates fn at hardware/IOKit level
function M.loadNativeTiling()
  local hypemode = require("hypemode")

  -- Menu-based tiling (works reliably, uses native macOS tiling with animation)
  local function menuTile(position)
    local app = hs.application.frontmostApplication()
    if app then
      local ok = app:selectMenuItem({"Window", "Move & Resize", position})
      if not ok then
        U.log.w("menuTile: failed to select menu item:", position)
      end
    end
  end

  -- Move window to next screen, then apply tiling
  local function tileOnOtherScreen(position)
    local win = hs.window.frontmostWindow()
    if not win then return end
    win:moveToScreen(win:screen():next())
    -- Small delay to let the move complete, then tile
    hs.timer.doAfter(0.1, function()
      menuTile(position)
    end)
  end

  -- Create hypemode for native tiling (hyper+w)
  local nativeWmMode = hypemode.new("nativeWm", { showIndicator = true })
  
  -- Chain state for native tiling mode
  local chainState = { key = nil, index = 0, timer = nil }
  
  local function resetChain()
    chainState.key = nil
    chainState.index = 0
    if chainState.timer then
      chainState.timer:stop()
      chainState.timer = nil
    end
  end
  
  -- Hybrid chain: native half first, then grid for thirds/other sizes
  local function chainTile(key, nativePosition, gridPositions)
    return function()
      -- If same key pressed again within timeout, advance chain
      if chainState.key == key then
        chainState.index = chainState.index + 1
        if chainState.index > #gridPositions then
          chainState.index = 1
        end
      else
        -- New key, start fresh
        chainState.key = key
        chainState.index = 1
      end
      
      -- Reset timer
      if chainState.timer then chainState.timer:stop() end
      chainState.timer = hs.timer.doAfter(2.0, resetChain)
      
      local idx = chainState.index
      
      if idx == 1 then
        -- First press: use native macOS tiling (half)
        menuTile(nativePosition)
      else
        -- Subsequent presses: use grid for thirds, etc.
        local win = hs.window.frontmostWindow()
        if win then
          hs.grid.set(win, gridPositions[idx])
        end
      end
    end
  end
  
  -- Grid positions for chaining (after native half)
  local leftChain = {
    C.grid.halves.left,       -- 1: half (native)
    C.grid.thirds.left,       -- 2: third
    C.grid.twoThirds.left,    -- 3: two-thirds
    C.grid.sixths.left,       -- 4: sixth
  }
  local rightChain = {
    C.grid.halves.right,
    C.grid.thirds.right,
    C.grid.twoThirds.right,
    C.grid.sixths.right,
  }
  
  nativeWmMode
    -- H: tile left - chains through half → third → two-thirds → sixth
    :bind({}, "h", chainTile("h", "Left", leftChain))
    :bind({"shift"}, "h", function() tileOnOtherScreen("Left") end, function() nativeWmMode:exit(0.3) end)
    
    -- L: tile right - chains through half → third → two-thirds → sixth
    :bind({}, "l", chainTile("l", "Right", rightChain))
    :bind({"shift"}, "l", function() tileOnOtherScreen("Right") end, function() nativeWmMode:exit(0.3) end)
    
    -- K: tile top half (no chaining for vertical, just native)
    :bind({}, "k", function() menuTile("Top") end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "k", function() tileOnOtherScreen("Top") end, function() nativeWmMode:exit(0.3) end)
    
    -- J: tile bottom half (no chaining for vertical, just native)
    :bind({}, "j", function() menuTile("Bottom") end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "j", function() tileOnOtherScreen("Bottom") end, function() nativeWmMode:exit(0.3) end)
    
    -- Space: center window
    :bind({}, "space", function()
      local app = hs.application.frontmostApplication()
      if app then app:selectMenuItem({"Window", "Center"}) end
    end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "space", function()
      local win = hs.window.frontmostWindow()
      if win then win:moveToScreen(win:screen():next()) end
      hs.timer.doAfter(0.1, function()
        local app = hs.application.frontmostApplication()
        if app then app:selectMenuItem({"Window", "Center"}) end
      end)
    end, function() nativeWmMode:exit(0.3) end)
    
    -- Return: fill screen
    :bind({}, "return", function()
      local app = hs.application.frontmostApplication()
      if app then app:selectMenuItem({"Window", "Fill"}) end
    end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "return", function()
      local win = hs.window.frontmostWindow()
      if win then win:moveToScreen(win:screen():next()) end
      hs.timer.doAfter(0.1, function()
        local app = hs.application.frontmostApplication()
        if app then app:selectMenuItem({"Window", "Fill"}) end
      end)
    end, function() nativeWmMode:exit(0.3) end)
    
    -- Backspace: return to previous size
    :bind({}, "delete", function() menuTile("Return to Previous Size") end, function() nativeWmMode:exit(0.3) end)
    
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
          if app1 then app1:selectMenuItem({"Window", "Move & Resize", "Left"}) end
          
          -- Then tile the other window right
          hs.timer.doAfter(0.15, function()
            other:focus()
            hs.timer.doAfter(0.05, function()
              local app2 = other:application()
              if app2 then app2:selectMenuItem({"Window", "Move & Resize", "Right"}) end
              
              -- Return focus to original window
              hs.timer.doAfter(0.1, function()
                focused:focus()
              end)
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
    :bind({}, "u", function() menuTile("Top Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "u", function() tileOnOtherScreen("Top Left") end, function() nativeWmMode:exit(0.3) end)
    
    :bind({}, "i", function() menuTile("Top Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "i", function() tileOnOtherScreen("Top Right") end, function() nativeWmMode:exit(0.3) end)
    
    :bind({}, "n", function() menuTile("Bottom Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "n", function() tileOnOtherScreen("Bottom Left") end, function() nativeWmMode:exit(0.3) end)
    
    :bind({}, "m", function() menuTile("Bottom Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({"shift"}, "m", function() tileOnOtherScreen("Bottom Right") end, function() nativeWmMode:exit(0.3) end)
    
    -- Arrange (two-window layouts) - use number keys
    -- These arrange the CURRENT window with another window
    :bind({}, "1", function() menuTile("Left & Right") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "2", function() menuTile("Right & Left") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "3", function() menuTile("Top & Bottom") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "4", function() menuTile("Bottom & Top") end, function() nativeWmMode:exit(0.3) end)
    :bind({}, "5", function() menuTile("Quarters") end, function() nativeWmMode:exit(0.3) end)
    
    -- B: Browser tab split - split active tab to new window, tile right
    :bind({}, "b", function()
      nativeWmMode:exit()
      
      local app = hs.application.frontmostApplication()
      if not app then return end
      
      local bundleID = app:bundleID()
      local isBrowser = bundleID and (
        bundleID:match("brave") or 
        bundleID:match("chrome") or 
        bundleID:match("firefox") or
        bundleID:match("safari") or
        bundleID:match("arc")
      )
      
      if not isBrowser then
        hs.alert.show("Not a browser")
        return
      end
      
      local mainWin = hs.window.frontmostWindow()
      if not mainWin then return end
      
      -- Store original window state for potential restore
      local originalFrame = mainWin:frame()
      local originalScreen = mainWin:screen()
      
      -- Move tab to new window (Cmd+Shift+N for most browsers, or use menu)
      -- Try menu first (more reliable across browsers)
      local moved = app:selectMenuItem({"Tab", "Move Tab to New Window"}) or
                    app:selectMenuItem({"Window", "Move Tab to New Window"})
      
      if not moved then
        -- Fallback: try keyboard shortcut
        hs.eventtap.keyStroke({"cmd", "shift"}, "n")
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
            app:selectMenuItem({"Window", "Move & Resize", "Left"})
            hs.timer.doAfter(0.15, function()
              newWin:focus()
              hs.timer.doAfter(0.05, function()
                app:selectMenuItem({"Window", "Move & Resize", "Right"})
              end)
            end)
          end)
        end
      end)
    end, nil)
    
    -- Shift+B: Undo browser split - merge tab back and restore window
    :bind({"shift"}, "b", function()
      nativeWmMode:exit()
      
      local state = _G._browserSplitState
      if not state then
        hs.alert.show("No browser split to undo")
        return
      end
      
      local mainWin = state.mainWin
      local splitWin = state.splitWin
      
      -- Check windows still exist
      if not mainWin or not mainWin:application() then
        hs.alert.show("Main window no longer exists")
        _G._browserSplitState = nil
        return
      end
      
      if splitWin and splitWin:application() then
        -- Focus split window and close it (merges tab back in most browsers)
        -- Or use Cmd+Shift+M to merge windows
        splitWin:focus()
        local app = splitWin:application()
        hs.timer.doAfter(0.1, function()
          -- Try to merge windows
          local merged = app:selectMenuItem({"Window", "Merge All Windows"})
          if not merged then
            -- Just close the split window
            splitWin:close()
          end
          
          -- Restore main window to original position
          hs.timer.doAfter(0.2, function()
            if mainWin and mainWin:application() then
              mainWin:focus()
              mainWin:setFrame(state.originalFrame)
            end
          end)
        end)
      end
      
      _G._browserSplitState = nil
    end, nil)

  -- Bind hyper+w to enter native tiling mode
  req("hyper", { id = "nativeWm" }):bind({}, "w", function()
    nativeWmMode:toggle()
  end)

  U.log.i("nativeTiling: initialized (hyper+w for native macOS tiling via menu)")
end

function M:init()
  M.loadApps()
  M.loadMeeting()
  M.loadFigma()
  M.loadUtils()
  M.loadWm()
  M.loadNativeTiling()  -- Experimental: hyper+w for native macOS tiling
  M.loadNotifications()
  M.loadForceQuit()
  M.loadShade()

  U.log.i("initialized")
end

return M
