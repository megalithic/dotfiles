utils = {}
utils.log = hs.logger.new('replicant', 'debug') -- debug or info

local lastSeenChain = nil
local lastSeenWindow = nil

-- Gets the config.application entry for a specific named app, e.g. 'Chrome'
--
utils.getConfigForApp = function(name)
  local config = require('config')
  local found
  for _, hash in pairs(config) do
    if (hash.name == name) then
      found = hash
      return found
    end
  end

  return found
end

-- Chain the specified movement commands.
-- This is like the "chain" feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.
--
utils.chain = function (movements)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

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

-- TOGGLE the given app
utils.toggleApp = function (_app)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(_app)

  if app ~= nil then
    utils.log.df('[toggleApp] - attempting to toggle visibility of %s', app:bundleID())
  end

  if not app then
    -- FIXME: this may not be working properly.. creating extraneous PIDs?
    utils.log.wf('[toggleApp] - launchOrFocusByBundleID(%s) (non PID-managed app?)', _app)

    hs.application.launchOrFocusByBundleID(_app)
  else
    local mainWin = app:mainWindow()
    utils.log.df('[toggleApp] - main window: %s', mainWin)

    if mainWin then
      if mainWin == hs.window.focusedWindow() then
        utils.log.df('[toggleApp] - hiding %s', app:bundleID())

        mainWin:application():hide()
      else
        utils.log.df('[toggleApp] - activating/unhiding/focusing %s', app:bundleID())

        mainWin:application():activate(true)
        mainWin:application():unhide()
        mainWin:focus()
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      utils.log.df('[toggleApp] - launchOrFocusByBundleID(%s)', app)

      if (app:focusedWindow() == hs.window.focusedWindow()) then
        app:hide()
      else
        app:unhide()
        hs.application.launchOrFocusByBundleID(app:bundleID())
      end
    end
  end
end

-- -------------------- Media / Volume Key Events --------------------

utils.handleMediaKeyEvents = function (event, alertText)
  hs.eventtap.event.newSystemKeyEvent(event, true):post()
end

utils.handleSpotifyEvents = function (event, alertText)
  if event == 'playpause' then
    hs.spotify.playpause()
  elseif event == 'next' then
    hs.spotify.next()
  elseif event == 'previous' then
    hs.spotify.previous()
  end

  utils.log.df('[hotkeys] event; %s', event)

  if alertText then
    hs.alert.closeAll()
    -- hs.alert.show(alertText, 0.5)
    hs.timer.doAfter(0.5, function ()
      if event == 'playpause' and not hs.spotify.isPlaying() then
        hs.alert.show('Spotify Paused')
      else
        hs.alert.show(hs.spotify.getCurrentArtist() .. " - " .. hs.spotify.getCurrentTrack(), 1)
      end
    end)
  end
end

-- -------------------- Cursor Locator --------------------

function removeCircle(mouseCircle)
  mouseCircle:hide(0.25)
  hs.timer.doAfter(1, function() mouseCircle:delete() end)
end

utils.mouseHighlight = function ()
  local red =   {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1}
  local white = {["red"]=1,["blue"]=1,["green"]=1,["alpha"]=1}

  local radius = 40
  local diameter = (radius * 2)

  -- Delete an existing highlight if it exists
  if mouseCircle then
      removeCircle(mouseCircle)

      if mouseCircleTimer then
          mouseCircleTimer:stop()
      end
  end

  -- Get the current co-ordinates of the mouse pointer
  mousepoint = hs.mouse.getAbsolutePosition()

  -- Prepare a circle around the mouse pointer
  mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x - radius, mousepoint.y - radius, diameter, diameter))
  mouseCircle:setStrokeColor(red)
  mouseCircle:setFill(true)
  mouseCircle:setStrokeWidth(1)
  mouseCircle:setAlpha(.5)
  -- mouseCircle:setFillGradient(red, white, 90)
  mouseCircle:show()

  -- Set a timer to delete the circle
  mouseCircleTimer = hs.timer.doAfter(0.75, function() removeCircle(mouseCircle) end)
end

utils.windowsForApp = function (app)
  return app:allWindows()
end

utils.validWindowsForApp = function (app)
  return app:allWindows()
end

utils.validWindowsForWindow = function (window)
  return utils.canManageWindow(window)
end

-- Returns the number of standard, non-minimized windows in the application.
--
-- (For Chrome, which has two windows per visible window on screen, but only one
-- window per minimized window).
utils.windowCount = function (app)
  local count = 0
  if app then
    for _, window in pairs(utils.windowsForApp(app)) do
      if utils.canManageWindow(window) and app:bundleID() ~= 'com.googlecode.iterm2' then
        count = count + 1
      end
    end
  end
  return count
end

-- hides an application
--
utils.hide = function (bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:hide()
  end
end

-- activates/shows an application
--
utils.activate = function (bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  end
end

-- determines if a window is manageable (takes into account iterm2)
--
utils.canManageWindow = function (window)
  local bundleID = window:application():bundleID()

  -- Special handling for iTerm: windows without title bars are
  -- non-standard.
  return window:isStandard() and not window:isMinimized() or
    bundleID == 'com.googlecode.iterm2'
end

return utils
