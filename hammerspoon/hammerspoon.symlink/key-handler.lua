handler = {}

handler.toggleApp = function (_app)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(_app)
  log.df('[key-handler] toggleApp - app = %s', app)

  if app ~= nil then
    log.df('[key-handler] toggleApp - attempting to toggle visibility of %s', app:bundleID())
  end

  if not app then
    -- FIXME: this may not be working properly.. creating extraneous PIDs?
    log.wf('[key-handler] toggleApp - launchOrFocusByBundleID(%s) (non PID-managed app?)', _app)

    -- NOTE: for some reason when we don't find an app by a specific name we should try and still launch it by name;
    -- we could try and regex match the string as a bundleID; if it is, we call: hs.application.launchOrFocusByBundleID(_app)
    hs.application.launchOrFocus(_app)
  else
    local mainWin = app:mainWindow()
    log.df('[key-handler] toggleApp - main window: %s', mainWin)

    if mainWin then
      if mainWin == hs.window.focusedWindow() then
        log.df('[key-handler] toggleApp - hiding %s', app:bundleID())

        mainWin:application():hide()
      else
        log.df('[key-handler] toggleApp - showing %s', app:bundleID())

        mainWin:application():activate(true)
        mainWin:application():unhide()
        mainWin:focus()
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      log.df('[key-handler] toggleApp - launchOrFocusByBundleID(%s)', app)

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

handler.notify = function(title, text, image)
  hs.notify.new({title=title, informativeText=text}):setIdImage(image):send()
end

handler.spotify = function (event, alertText)
  if event == 'playpause' then
    hs.spotify.playpause()
  elseif event == 'next' then
    hs.spotify.next()
  elseif event == 'previous' then
    hs.spotify.previous()
  end

  log.df('[key-handler] spotify - %s (%s)', event, alertText)

  if alertText then
    hs.alert.closeAll()
    hs.timer.doAfter(0.5, function ()
      local image = hs.image.imageFromAppBundle('com.spotify.client')

      if event == 'playpause' and not hs.spotify.isPlaying() then
        handler.notify('Spotify', 'Paused', image)
      else
        handler.notify('Spotify', hs.spotify.getCurrentArtist() .. ' - ' .. hs.spotify.getCurrentTrack(), image)
      end
    end)
  end
end

return handler
