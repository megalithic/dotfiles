local log = hs.logger.new('[keys]', 'debug')
local handler = {}

-- REF: https://github.com/octplane/hammerspoon-config/blob/master/init.lua#L105
-- +--- possibly more robust app toggler
handler.toggle = function (_app)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(_app)
  local appBundleID = app and (app:bundleID() or _app)

  if app ~= nil then
    log.df('attempting to toggle visibility of %s..', appBundleID)
  end

  if not app then
    if _app ~= nil then
      log.wf('launchOrFocusByBundleID(%s) (non PID-managed app?)', _app)
      hs.application.launchOrFocusByBundleID(_app)
    else
      log.wf('_app (%s) || app (%s) is nil!!', _app, appBundleID)
    end
  else
    local mainWin = app:mainWindow()
    -- log.df('main window: %s', mainWin)

    if mainWin then
      if mainWin == hs.window.focusedWindow() then
        log.df('hiding %s..', appBundleID)

        mainWin:application():hide()
      else
        log.df('showing %s..', appBundleID)

        mainWin:application():activate(true)
        mainWin:application():unhide()
        mainWin:focus()
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      log.df('launchOrFocusByBundleID(%s)', appBundleID)

      if (app:focusedWindow() == hs.window.focusedWindow()) then
        app:hide()
      else
        app:unhide()
        hs.application.launchOrFocusByBundleID(appBundleID)
      end
    end
  end
end

handler.adjustVolume = function(vol)
  local output = hs.audiodevice.defaultOutputDevice()

  if vol.action == "mute" then
    if output:muted() then
      output:setMuted(false)
    else
      output:setMuted(true)
    end
  else
    local playing = hs.spotify.isPlaying()
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
  hs.notify.new({title=notification.title, subTitle=notification.subTitle,
    informativeText=notification.informativeText}):setIdImage(notification.image):send()
end

handler.spotify = function (event, alertText)
  if event == 'playpause' then
    hs.spotify.playpause()
  elseif event == 'next' then
    hs.spotify.next()
  elseif event == 'previous' then
    hs.spotify.previous()
  end

  log.df('spotify - %s (%s)', event, alertText)

  if alertText then
    hs.alert.closeAll()
    hs.timer.doAfter(0.5, function ()
      local image = hs.image.imageFromAppBundle('com.spotify.client')

      if event == 'playpause' and not hs.spotify.isPlaying() then
        handler.notify({ title='Paused', subTitle=hs.spotify.getCurrentArtist(),
          informativeText=hs.spotify.getCurrentTrack(), image=image })
      else
        handler.notify({ title=hs.spotify.getCurrentArtist(), subTitle=hs.spotify.getCurrentTrack(), image=image })
      end
    end)
  end
end

-- Total hat-tip to YusukeKokubo for this!
-- REF: https://github.com/YusukeKokubo/dotfiles/blob/master/hammerspoon/init.lua
local function keyStroke(mod, key)
  return function() hs.eventtap.keyStroke(mod, key) end
end

handler.remap = function(appName, mod1, key1, mod2, key2)
  if (not appName) then
    return hs.hotkey.bind(mod1, key1, keyStroke(mod2, key2))
  end

  local hotkey = hs.hotkey.new(mod1, key1, keyStroke(mod2, key2))
  return hs.window.filter.new(appName)
    :subscribe(hs.window.filter.windowFocused,   function() hotkey:enable()  end)
    :subscribe(hs.window.filter.windowUnfocused, function() hotkey:disable() end)
end


return handler
