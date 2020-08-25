local log = hs.logger.new('[ext.window]', 'warning')

local focusScreen     = require('ext.screen').focusScreen
local highlightWindow = require('ext.drawing').highlightWindow

local cache = {
  windowPositions = hs.settings.get('windowPositions') or {}
}

local module = { cache = cache }

module.forceFocus = function(win)
  -- this flickers
  -- win:application():activate()

  win:becomeMain()
  win:raise():focus()
  highlightWindow()
end

-- cycle application windows
module.cycleWindows = function(direction, appWindowsOnly, screenWindowsOnly)
  direction = direction or "next"

  local win = hs.window.focusedWindow()

  -- try to find window based on mouse screen if there's no window focused
  if appWindowsOnly and not win then
    local mouseScreen = hs.mouse.getCurrentScreen()

    local screenWindows = hs.fnutils.filter(hs.window.visibleWindows(), function(testWin)
      return testWin:screen():id() == mouseScreen:id()
    end)

    -- if there's no windows, just focus the screen
    if #screenWindows == 0 then
      focusScreen(mouseScreen)
      return
    end

    win = screenWindows[1]
  end

  local allWindows = appWindowsOnly and win:application():allWindows() or hs.window.allWindows()

  -- we only care about standard and visible windows
  local windows = hs.fnutils.filter(allWindows, function(testWin)
    return testWin ~= nil and testWin:isStandard() and testWin:isVisible()
  end)

  -- filter for only current-screen windows if we want it to
  if screenWindowsOnly then
    local screenId = (win and win:screen() or hs.mouse.getCurrentScreen()):id()

    windows = hs.fnutils.filter(windows, function(testWin)
      return testWin:screen():id() == screenId
    end)
  end

  -- get id based of appname and window id
  -- this basically makes sorting windows bit saner
  local getId = function(testWin)
    local application = testWin:application()
    local appId = application and application:bundleID() or "unknown-app"

    return appId .. '-' .. testWin:id()
  end

  if #windows == 0 then
    focusScreen()
  elseif #windows == 1 then
    -- if we have only one window - focus it
    module.forceFocus(windows[1])
  elseif #windows > 1 then
    -- if there are more than one, sort them first by id
    table.sort(windows, function(a, b) return getId(a) > getId(b) end)

    -- check if one of them is active
    local activeWindowIndex = hs.fnutils.indexOf(windows, win)

    if activeWindowIndex then
      if direction == "next" then
        activeWindowIndex = activeWindowIndex + 1
        if activeWindowIndex > #windows then activeWindowIndex = 1 end
      else
        activeWindowIndex = activeWindowIndex - 1
        if activeWindowIndex < 1 then activeWindowIndex = #windows end
      end

      module.forceFocus(windows[activeWindowIndex])
    else
      -- otherwise focus first one
      module.forceFocus(windows[1])
    end
  end

  -- higlight when done
  highlightWindow()
end

-- show hints with highlight
module.windowHints = function()
  hs.hints.windowHints(nil, highlightWindow)
end

-- save and restore window positions
module.persistPosition = function(win, option)
  local windowPositions = cache.windowPositions

  -- store position into hs.settings
  if win == 'store' or option == 'store' then
    hs.settings.set('windowPositions', windowPositions)
    return
  end

  -- otherwise run the logic
  local application = win:application()
  local appId       = application:bundleID() or application:name()
  local frame       = win:frame()
  local index       = windowPositions[appId] and windowPositions[appId].index or nil
  local frames      = windowPositions[appId] and windowPositions[appId].frames or {}

  -- check if given frame differs frome last one in array
  local framesDiffer = function(testFrame, testFrames)
    return testFrame and (#testFrames == 0 or not testFrame:equals(testFrames[#testFrames]))
  end

  -- remove first element if we hit history limit (adjusting index if needed)
  if #frames > config.window.historyLimit then
    table.remove(frames, 1)
    index = index > #frames and #frames or math.max(index - 1, 1)
  end

  -- append window position to a table, only if it's a new frame
  if option == 'save' and framesDiffer(frame, frames) then
    table.insert(frames, frame.table)
    index = #frames
  end

  -- undo window position
  if option == 'undo' and index ~= nil then
    -- if we are at the last index
    -- (or more, which shouldn't happen?)
    if index >= #frames then
      if framesDiffer(frame, frames) then
        -- and current frame differs from last one - save it
        table.insert(frames, frame.table)
      else
        -- otherwise frames are the same, so get the previous one
        index = math.max(index - 1, 1)
      end
    end

    win:setFrame(frames[index])
    index = math.max(index - 1, 1)
  end

  -- redo window position
  if option == 'redo' and index ~= nil then
    index = math.min(#frames, index + 1)
    win:setFrame(frames[index])
  end

  -- update cached window positions object
  cache.windowPositions[appId] = {
    index  = index,
    frames = frames
  }
end


--
-- ============================================================================
-- LEGACY FUNCTIONS FROM MY ORIGINAL HS CONFIG --------------------------------
-- ============================================================================
--
-- TODO: salvage `chain` and other functions and delete the rest once we
-- determine what's actually needed.
--

module.canLayoutWindow = function(win)
  local bundleID = win:application():bundleID()

  return win:title() ~= "" and win:isStandard() and not win:isMinimized() and not win:isFullScreen() or
    bundleID == 'com.googlecode.iterm2' or bundleID == 'net.kovidgoyal.kitty'
end

module.getManageableWindows = function(windows)
  if windows == nil then return end

  return hs.fnutils.filter(windows, (function(win)
    if win == nil or config.rulesExistForWin(win) then return false end

    return module.canLayoutWindow(win)
  end))
end


-- Chain the specified movement commands.
-- This is like the "chain" feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.
--
module.chain = function (movements)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  local lastSeenChain = nil
  local lastSeenWindow = nil

  return function()
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    if
      lastSeenChain ~= movements or
      lastSeenAt < now - chainResetInterval or
      lastSeenWindow ~= id
    then
      sequenceNumber = 1
      lastSeenChain = movements
    elseif (sequenceNumber == 1) then
      -- At end of chain, restart chain on next screen.
      screen = screen:next()
    end
    lastSeenAt = now
    lastSeenWindow = id

    hs.grid.set(win, movements[sequenceNumber], screen)
    sequenceNumber = sequenceNumber % cycleLength + 1
  end
end

module.tableLength = function(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

module.windowsForApp = function (app)
  return app:allWindows()
end

module.validWindowsForApp = function (app)
  return app:allWindows()
end

module.validWindowsForWindow = function (window)
  return module.canManageWindow(window)
end

-- Returns the number of standard, non-minimized windows in the application.
--
-- (For Chrome, which has two windows per visible window on screen, but only one
-- window per minimized window).
module.windowCount = function (app)
  local count = 0
  if app then
    for _, window in pairs(module.windowsForApp(app)) do
      if module.canManageWindow(window) and app:bundleID() ~= 'com.googlecode.iterm2' then
        count = count + 1
      end
    end
  end
  return count
end

-- hides an application
--
module.hide = function (bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:hide()
  end
end

-- activates/shows an application
--
module.activate = function (bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  end
end

-- determines if a window is manageable (takes into account iterm2)
--
module.canManageWindow = function (window)
  local bundleID = window:application():bundleID()

  -- Special handling for iTerm: windows without title bars are
  -- non-standard.
  return window:title() ~= "" and window:isStandard() and not window:isMinimized() or
    bundleID == 'com.googlecode.iterm2'
end

module.hasValue = function(T, v)
  for _, item in pairs(T) do
    return item == v
  end
end

return module
