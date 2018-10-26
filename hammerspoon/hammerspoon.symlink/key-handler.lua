handler = {}

handler.launch = function(appName)
  log.df('[key-handler] launch - attempting to launch or focus %s', appName)
  hs.application.launchOrFocus(appName)
end

handler.toggleApp = function (_app)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(_app)

  if app ~= nil then
    log.df('[key-handler] toggleApp - attempting to toggle visibility of %s', hs.inspect(app))
  end

  if not app then
    if _app ~= nil then
      log.wf('[key-handler] toggleApp - launchOrFocusByBundleID(%s) (non PID-managed app?)', _app)
      hs.application.launchOrFocusByBundleID(_app)
    else
      log.wf('[key-handler] toggleApp - _app (%s) || app (%s) is nil!!', _app, app)
    end
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

handler.adjustVolume = function(vol)
  output = hs.audiodevice.defaultOutputDevice()

  if vol.action == "mute" then
    if output:muted() then
      output:setMuted(false)
    else
      output:setMuted(true)
    end
  else
    playing = hs.spotify.isPlaying()
    if playing then
      if vol.action == "up" then
        hs.spotify.volumeUp()
      else
        hs.spotify.volumeDown()
      end
    else
      output:setMuted(false)
      output:setVolume(output:volume() + vol.diff)
    end
  end
end

handler.notify = function(notification)
  hs.notify.new({title=notification.title, subTitle=notification.subTitle, informativeText=notification.informativeText}):setIdImage(notification.image):send()
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
        handler.notify({ title='Paused', subTitle=hs.spotify.getCurrentArtist(), informativeText=hs.spotify.getCurrentTrack(), image=image })
      else
        handler.notify({ title=hs.spotify.getCurrentArtist(), subTitle=hs.spotify.getCurrentTrack(), image=image })
      end
    end)
  end
end

return handler
