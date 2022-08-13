local obj = {}

obj.__index = obj
obj.name = "spotify"
obj.debug = true
obj.refreshInterval = 0.5
local stext = require("hs.styledtext").new

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

local SPOTIFY = "Spotify"
local fullSkip = true

local api = hs.spotify

-- launch or focus
local function openSpotify() hs.application.launchOrFocus(SPOTIFY) end

-- get information about the current track
local function getCurrent()
  local artist = nil
  local album = nil
  local track = nil
  if api then
    artist = api.getCurrentArtist()
    album = api.getCurrentAlbum()
    track = api.getCurrentTrack()
  end
  return artist, album, track
end

-- return true if paused
function obj.isPaused()
  local state = api.getPlaybackState()
  return state == api.state_paused
end

-- play if paused, or pause if playing
function obj.playPause()
  if api ~= nil then
    local state = api.getPlaybackState()
    if state == api.state_paused then
      api.play()
    elseif state ~= nil then
      api.pause()
    end
  end
end -- next track

function obj.nextTrack()
  if api ~= nil then
    local state = api.getPlaybackState()
    api.next()
    if state == api.state_paused then api.play() end
  end
end

-- previous track
local function prevTrack()
  local artist, album, track = nil, nil, nil
  if api ~= nil then
    local state = api.getPlaybackState()
    artist, album, track = getCurrent()
    api.previous()
    if state == api.state_paused then api.play() end
  end
  return artist, album, track
end

local function toggleSkipState() fullSkip = not fullSkip end

function obj.prevTrack()
  local partist, palbum, ptrack = prevTrack()
  if fullSkip then
    hs.timer.doAfter(0, function()
      local artist, album, track = getCurrent()
      if (partist == artist) and (palbum == album) and (ptrack == track) then prevTrack() end
    end)
  end
end

-- update data on click of the menubar option
local function updateData()
  local artist, album, track = getCurrent()
  if not (artist == nil) then
    local playlabel = "Pause"
    if obj.isPaused() then playlabel = "Play" end
    -- update and return the new track information
    local menubar_opts = {
      { title = "Artist: " .. artist, disabled = true },
      { title = "Album: " .. album, disabled = true },
      { title = "Track: " .. track, disabled = true },
      { title = "-" },
      { title = playlabel, fn = obj.playPause },
      { title = "Next", fn = obj.nextTrack },
      { title = "Previous", fn = obj.prevTrack },
      { title = "-" },
      { title = "Full skip back", checked = fullSkip, fn = toggleSkipState },
      { title = "-" },
      { title = "Open Spotify", fn = openSpotify },
    }
    return menubar_opts
  end
end

local function updateTitle()
  local artist, album, track = getCurrent()
  local titleInfo = ""
  if artist ~= nil then
    local icon = ""
    if obj.isPaused() then
      icon = "" -- alts:  
    else
      icon = "" -- alts:  
    end

    icon = stext(icon, { font = { name = defaultFont.name, size = 13 } })
    titleInfo = icon .. fmt(" %s - %s", artist, track)
  end

  return titleInfo
end

function obj:init()
  obj.menubar = hs.menubar.new()
  obj.menubar:setTitle(updateTitle())

  return self
end

function obj:start()
  -- TODO; kill apple music to open spotify instead; genius
  -- REF: https://github.com/mrjones2014/dotfiles/blob/master/.config/hammerspoon/apple-music-spotify-redirect.lua
  obj.menubar:setTitle(updateTitle())
  obj.updateTimer = hs.timer.new(obj.refreshInterval, function() obj.menubar:setTitle(updateTitle()) end):start()

  return self
end

function obj:stop()
  if obj.menubar then obj.menubar:delete() end
  if obj.updateTimer then obj.updateTimer:stop() end

  return self
end

return obj
