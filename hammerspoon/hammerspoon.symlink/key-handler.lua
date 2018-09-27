handler = {}

handler.toggleApp = function (_app)
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

-- FIXME: not really working
handler.mediaKeys = function (event, alertText)
  hs.eventtap.event.newSystemKeyEvent(event, true):post()
end

handler.spotify = function (event, alertText)
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

return handler
