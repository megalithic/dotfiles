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

return module
