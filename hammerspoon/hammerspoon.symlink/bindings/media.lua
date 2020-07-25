local log = hs.logger.new('[bindings.media]', 'warning')

local module = {}
local alert = require('ext.alert')

module.adjustVolume = function(vol)
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
        if not hs.spotify.isRunning() then return end
        hs.spotify.volumeUp()
        alert.showOnly({ text = '↑ '..hs.spotify.getVolume()..'% ♬' })

      else
        if not hs.spotify.isRunning() then return end
        hs.spotify.volumeDown()
        alert.showOnly({ text = '↓ '..hs.spotify.getVolume()..'% ♬' })
      end
    else
      log.df('Adjusting system volume: %s %s', vol.diff, vol.action)
      output:setMuted(false)
      output:setVolume(output:volume() + vol.diff)
    end
  end
end

module.notify = function(n)
  log.df('Spotify notification: %s', hs.inspect(n))

  hs.notify.new({
      title=n.artist .. " (" .. n.state .. ")",
      subTitle=n.track,
      informativeText=n.album,
    })
  :setIdImage(n.image)
  :send()

  alert.showOnly({ text = '♬ '..n.state.. n.icon })
end

module.spotify = function (event, alertText)
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
        module.notify({
            icon="",
            state="Paused",
            artist=hs.spotify.getCurrentArtist(),
            track=hs.spotify.getCurrentTrack(),
            album=hs.spotify.getCurrentAlbum(),
            image=image
          })
      else
        module.notify({
            icon="契",
            state="Playing",
            artist=hs.spotify.getCurrentArtist(),
            track=hs.spotify.getCurrentTrack(),
            album=hs.spotify.getCurrentAlbum(),
            image=image
          })
      end
    end)
  end
end

module.start = function()
  -- :: media (spotify)
  for _, media in pairs(config.media) do
    hs.hotkey.bind(media.modifier, media.shortcut, function() module.spotify(media.action, media.label) end)
  end

  -- :: volume control
  for _, vol in pairs(config.volume) do
    hs.hotkey.bind(vol.modifier, vol.shortcut, function() module.adjustVolume(vol) end)
  end
end

module.stop = function()
  -- nil
end

return module
