local utils = require("utils")

local obj = {}

obj.__index = obj
obj.name = "spotify"
obj.debug = true
obj.refreshInterval = 1.0
local stext = require("hs.styledtext").new

local api = hs.spotify

local function spotifyRunning() return hs.application.get("Spotify") end

local function isPaused()
  local state = api.getPlaybackState()
  return state == api.state_paused
end

function obj.getCurrent()
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

function obj.updateTitle()
  local artist, album, track = obj.getCurrent()
  local titleInfo = ""
  if artist ~= nil then
    local icon = ""
    if isPaused() then
      icon = " " -- alts: 󰏤  
    else
      icon = "󰝚 " -- alts: 󰝚  
    end

    icon = stext(icon, { font = { name = DefaultFont.name, size = 13 } })
    titleInfo = icon .. fmt("%s - %s", artist, utils.truncate(track, 25))
  end

  return titleInfo
end

function obj.tmuxTitle()
  local artist, album, track = obj.getCurrent()
  local titleInfo = ""
  if artist ~= nil then
    local icon = ""
    if isPaused() then
      icon = "" -- alts:  
    else
      icon = "󰝚" -- alts:  
    end

    -- icon = stext(icon, { font = { name = DefaultFont.name, size = 13 } })
    titleInfo = fmt("%s %s - %s", icon, artist, utils.truncate(track, 25))
  end

  return titleInfo
end

local function setMenubarTitle()
  local title = ""

  if spotifyRunning() then
    if not obj.menubar then obj.menubar = hs.menubar.new() end
    title = obj.updateTitle()
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
  -- setMenubarTitle()

  return self
end

function obj:start()
  -- if hs.application.get("Spotify") then
  --   setMenubarTitle()
  --   obj.updateTimer = hs.timer.new(obj.refreshInterval, function() setMenubarTitle() end):start()
  -- end

  return self
end

function obj:stop()
  -- if self.menubar then self.menubar:delete() end
  -- if self.updateTimer then self.updateTimer:stop() end

  -- info("stopping spotify things")

  return self
end

return obj
