local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.apple.music"
obj.debug = true

obj.modal = false
obj.actions = nil

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]
  local bundleID = opts["bundleID"]

  -- Never run Apple Music; I never use it!
  if event == hs.application.watcher.launched and bundleID == "com.apple.Music" then
    -- kill Apple Music
    dbg(bundleID)
    local app = hs.application.get(bundleID)
    -- local killed = false

    local killTimer = hs.timer.doUntil(function() return app == nil end, function() app:kill() end, 0.5)

    if not killTimer:running() then
      hs.application.launchOrFocus("Spotify")
      hs.spotify.play()
    end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  return self
end

return obj
