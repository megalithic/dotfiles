local obj = {}

obj.__index = obj
obj.name = "spotify"
obj.debug = true
obj.refreshInterval = 1.0
local stext = require("hs.styledtext").new

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

local api = hs.spotify

local function spotifyRunning() return hs.application.get("Spotify") end

local function isPaused()
  local state = api.getPlaybackState()
  return state == api.state_paused
end

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

local function updateTitle()
  local artist, album, track = getCurrent()
  local titleInfo = ""
  if artist ~= nil then
    local icon = ""
    if isPaused() then
      icon = "󰏤" -- alts:  
    else
      icon = "󰝚" -- alts:  
    end

    icon = stext(icon, { font = { name = defaultFont.name, size = 13 } })
    titleInfo = icon .. fmt(" %s - %s", artist, U.truncate(track, 25))
  end

  return titleInfo
end

local function setMenubarTitle()
  local title = ""

  if spotifyRunning() then
    if not obj.menubar then obj.menubar = hs.menubar.new() end
    title = updateTitle()
  end

  if obj.menubar then obj.menubar:setTitle(title) end
end

function obj.toggle(show)
  if show then
    obj.menubar:returnToMenuBar()
  else
    obj.menubar:removeFromMenuBar()
  end
end

function obj:init()
  setMenubarTitle()

  return self
end

function obj:start()
  setMenubarTitle()
  obj.updateTimer = hs.timer.new(obj.refreshInterval, function() setMenubarTitle() end):start()

  return self
end

function obj:stop()
  -- if obj.menubar then obj.menubar:delete() end
  if obj.updateTimer then obj.updateTimer:stop() end

  return self
end

return obj
