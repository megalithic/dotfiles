local log = hs.logger.new("[bindings.media]", "info")
local media = hs.hotkey.modal.new()
local alert = require("ext.alert")

local module = {}

function media:entered()
  log.i("-> entered media modal..")
  local image = hs.image.imageFromAppBundle("com.spotify.client")
  local isPlaying = hs.spotify.isPlaying()
  local icon = isPlaying and "契" or ""
  local state = isPlaying and "Currently Playing" or "Currently Paused"
  module.notify(
    {
      icon = icon,
      state = state,
      artist = hs.spotify.getCurrentArtist(),
      track = hs.spotify.getCurrentTrack(),
      album = hs.spotify.getCurrentAlbum(),
      image = image
    },
    true
  )
end

function media:exited()
  log.i("-> exited media modal..")
  alert.close()
end

module.notify = function(n, shouldAlert)
  log.df("Spotify notification: %s", hs.inspect(n))

  if n.artist ~= nil then
    hs.notify.new(
      {
        title = n.artist .. " (" .. n.state .. ")",
        subTitle = n.track,
        informativeText = n.album
      }
    ):setIdImage(n.image):send()
  else
    log.wf("Spotify unable to get current song info: %s", hs.inspect(n))
  end

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
    print("pausing spotify")
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
              state = "Now Paused",
              artist = hs.spotify.getCurrentArtist(),
              track = hs.spotify.getCurrentTrack(),
              album = hs.spotify.getCurrentAlbum(),
              image = image
            },
            true
          )
        else
          module.notify(
            {
              icon = "契",
              state = "Now Playing",
              artist = hs.spotify.getCurrentArtist(),
              track = hs.spotify.getCurrentTrack(),
              album = hs.spotify.getCurrentAlbum(),
              image = image
            },
            true
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

      -- set a timeout to kill our modal in case no follow-on keys are pressed
      -- hs.timer.doAfter(
      --   2,
      --   function()
      --     media:exit()
      --   end
      -- )
    end
  )

  for _, c in pairs(config.media) do
    if (c.action == "view") then
      media:bind(
        "",
        c.shortcut,
        function()
          require("ext.application").toggle(c.bundleID, false)
          media:exit()
        end
      )
    else
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

  media:bind(
    "",
    "escape",
    function()
      media:exit()
    end
  )
end

module.stop = function()
  media:exit()
end

return module
