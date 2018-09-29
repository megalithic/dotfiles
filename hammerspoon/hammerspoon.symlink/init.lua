inspect = require('inspect')
log = require('log')
log.warning()

local handler = require('key-handler')
local hotkey = require('hs.hotkey')

require('config')
require('auto-layout').init()
require('push-to-talk').init(config.ptt)
require('laptop-docking-mode').init()

-- :: spoons
-- hs.loadSpoon() -- none yet

-- :: app-launching
for _, app in pairs(config.applications) do
  if app.superKey ~= nil and app.shortcut ~= nil then
    hotkey.bind(app.superKey, app.shortcut, function() handler.toggleApp(app.name) end)
  end
end

-- :: utilities
for _, util in pairs(config.utilities) do
  hotkey.bind(util.superKey, util.shortcut, util.callback)
end

-- :: media(spotify/volume)
for _, media in pairs(config.media) do
  hotkey.bind(media.superKey, media.shortcut, function() handler.spotify(media.action, media.label) end)
end

-- :: window-manipulation
for _, mover in pairs(config.windowMover) do
  hotkey.bind(mover.superKey, mover.shortcut, mover.chain)
end
