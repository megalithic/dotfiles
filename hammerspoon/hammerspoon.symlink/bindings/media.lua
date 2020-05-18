local log = hs.logger.new('[bindings.media]', 'debug')

local module = {}

local adjustVolume = function(vol)
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
      log.df('Adjusting Spotify volume: %s', vol.action)
      if vol.action == "up" then
        hs.spotify.volumeUp()
      else
        hs.spotify.volumeDown()
      end
    else
      log.df('Adjusting system volume: %s %s', vol.diff, vol.action)
      output:setMuted(false)
      output:setVolume(output:volume() + vol.diff)
    end
  end
end

local notify = function(notification)
  print('Media notify: ' .. hs.inspect(notification))

  hs.notify.new({title=notification.title, subTitle=notification.subTitle,
    informativeText=notification.informativeText}):setIdImage(notification.image):send()
end

local spotify = function (event, alertText)
  if event == 'playpause' then
    hs.spotify.playpause()
  elseif event == 'next' then
    hs.spotify.next()
  elseif event == 'previous' then
    hs.spotify.previous()
  end

  if alertText then
    hs.alert.closeAll()
    hs.timer.doAfter(0.5, function ()
      local image = hs.image.imageFromAppBundle('com.spotify.client')

      if event == 'playpause' and not hs.spotify.isPlaying() then
        notify({ title='Paused', subTitle=hs.spotify.getCurrentArtist(),
          informativeText=hs.spotify.getCurrentTrack(), image=image })
      else
        notify({ title=hs.spotify.getCurrentArtist(), subTitle=hs.spotify.getCurrentTrack(), image=image })
      end
    end)
  end
end

module.start = function()
  -- :: media (spotify)
  for _, media in pairs(config.media) do
    hs.hotkey.bind(media.superKey, media.shortcut, function() spotify(media.action, media.label) end)
  end

  -- :: volume control
  for _, vol in pairs(config.volume) do
    hs.hotkey.bind(vol.superKey, vol.shortcut, function() adjustVolume(vol) end)
  end
end

module.stop = function()
  -- nil
end

return module
