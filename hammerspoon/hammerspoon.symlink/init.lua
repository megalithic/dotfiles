inspect = require('inspect') -- useful for outputting a table's data `print(inspect(someTable))`
log = require('log')
log.warning()

-- where all the magic is defined (check here for every piece of configuration)
require('config')

local handler = require('key-handler')
local hotkey = require('hs.hotkey')

-- window/app auto-layout for my dual-monitor (or single laptop) setup
require('auto-layout').init()

-- push-to-talk (e.g., mute my input until i hold down the requisite keys)
require('push-to-talk').init(config.ptt)

-- laptop docking mode things (change system settings based on being in "docking" mode or not)
require('laptop-docking-mode').init()

-- helper to prevent accidental/unintentional app quitting
require('app-quit-guard')

-- :: spoons
-- hs.loadSpoon() -- none yet, maybe I'll convert my existing modules to spoons

-- :: app-launching (basic app launching and toggling)
for _, app in pairs(config.applications) do
  if app.superKey ~= nil and app.shortcut ~= nil then
    hotkey.bind(app.superKey, app.shortcut, function() handler.toggleApp(app.name) end)
  end
end

-- :: utilities (things like config reloading, mouse cursor highlighting, manually forcing re-snapping window/app layout)
for _, util in pairs(config.utilities) do
  hotkey.bind(util.superKey, util.shortcut, util.fn)
end

-- :: media (spotify)
for _, media in pairs(config.media) do
  hotkey.bind(media.superKey, media.shortcut, function() handler.spotify(media.action, media.label) end)
end

-- :: window-manipulation (manual window snapping)
for _, snap in pairs(config.snap) do
  hotkey.bind(snap.superKey, snap.shortcut, snap.locations)
end
