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

  -- always force close apple music
  if event == hs.application.watcher.launched and bundleID == "com.apple.Music" then
    local app = hs.application.get(bundleID)
    app:kill()

    -- hs.timer.waitUntil(function() return not app:isRunning() end, function()
    --   hs.application.launchOrFocus("Spotify")
    --   hs.spotify.play()
    -- end)
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  return self
end

return obj
