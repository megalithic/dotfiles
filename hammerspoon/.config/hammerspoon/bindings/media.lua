local log = hs.logger.new("[bindings.media]", "warning")
local media = hs.hotkey.modal.new()
local alert = require("ext.alert")

local module = {}

function media:entered()
  local image = hs.image.imageFromAppBundle("com.spotify.client")
  local isPlaying = hs.spotify.isPlaying()
  local icon = isPlaying and "契" or ""
  local state = isPlaying and "playing" or "paused"
  module.notify(
  {
    icon = icon,
    state = state,
    artist = hs.spotify.getCurrentArtist(),
    track = hs.spotify.getCurrentTrack(),
    album = hs.spotify.getCurrentAlbum(),
    image = image
  }, false
  )
end

function media:exited()
  alert.close()
end

module.notify = function(n, shouldAlert)
  log.df("Spotify notification: %s", hs.inspect(n))

  hs.notify.new(
    {
      title = n.artist .. " (" .. n.state .. ")",
      subTitle = n.track,
      informativeText = n.album
    }
  ):setIdImage(n.image):send()

  if shouldAlert then
    alert.showOnly({text = "♬ " .. n.state .. " " .. n.icon})
  end
end

module.volume_control = function(vol)
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
      log.df("Adjusting Spotify volume: %s", vol.action)
      if vol.action == "up" then
        if not hs.spotify.isRunning() then
          return
        end
        hs.spotify.volumeUp()
        alert.showOnly({text = "↑ " .. hs.spotify.getVolume() .. "% ♬"})
      else
        if not hs.spotify.isRunning() then
          return
        end
        hs.spotify.volumeDown()
        alert.showOnly({text = "↓ " .. hs.spotify.getVolume() .. "% ♬"})
      end
    else
      log.df("Adjusting system volume: %s %s", vol.diff, vol.action)
      output:setMuted(false)
      output:setVolume(output:volume() + vol.diff)
    end
  end
end

module.media_control = function(event, alertText)
  if event == "playpause" then
    hs.spotify.playpause()
  elseif event == "pause" then
    hs.spotify.pause()
  elseif event == "play" then
    hs.spotify.play()
  elseif event == "next" then
    hs.spotify.next()
  elseif event == "previous" then
    hs.spotify.previous()
  end

  if alertText then
    hs.alert.closeAll()
    hs.timer.doAfter(
      0.5,
      function()
        local image = hs.image.imageFromAppBundle("com.spotify.client")

        if (event == "playpause" and not hs.spotify.isPlaying()) or event == "pause" then
          module.notify(
            {
              icon = "",
              state = "Paused",
              artist = hs.spotify.getCurrentArtist(),
              track = hs.spotify.getCurrentTrack(),
              album = hs.spotify.getCurrentAlbum(),
              image = image
            }, true
          )
        else
          module.notify(
            {
              icon = "契",
              state = "Playing",
              artist = hs.spotify.getCurrentArtist(),
              track = hs.spotify.getCurrentTrack(),
              album = hs.spotify.getCurrentAlbum(),
              image = image
            }, true
          )
        end
      end
    )
  end
end

module.start = function()
  local hyper = require("bindings.hyper")
  hyper:bind(
    {},
    "p",
    nil,
    function()
      media:enter()
    end
  )

  for _, c in pairs(config.media) do
    media:bind(
      "",
      c.shortcut,
      function()
        module.media_control(c.action, c.label)
        media:exit()
      end
    )
  end
end

module.stop = function()
  media:exit()
end

return module
