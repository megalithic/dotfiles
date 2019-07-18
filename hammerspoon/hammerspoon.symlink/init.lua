local log = require('log')
log.verbose()

hs.ipc.cliInstall()

-- where all the magic is defined (check here for every piece of configuration)
local config = require('config')
local handler = require('keyhandler')
local hotkey = require('hs.hotkey')

-- window/app auto-layout for my dual-monitor (or single laptop) setup
require('auto-layout').init()

-- push-to-talk (e.g., mute my input until i hold down the requisite keys)
require('ptt').init(config.ptt)

-- helper to prevent accidental/unintentional app quitting
require('quit')

-- handles initiating laptop docking mode behaviors
require('dock').init()

-- laptop docking mode things (change system settings based on being in "docking" mode or not)
-- home-assistant helper to automate my office based on computer events; only want this to run when i'm in my office
-- if (require('dock').init()) then
--   require('home-assistant').init()
-- end

-- :: spoons
-- hs.loadSpoon() -- none yet, maybe I'll convert my existing modules to spoons

-- :: app-launching (basic app launching and toggling)
for _, app in pairs(config.applications) do
  if app.superKey ~= nil and app.shortcut ~= nil then
    -- hotkey.bind(app.superKey, app.shortcut, function() handler.launch(app.name) end)
    hotkey.bind(app.superKey, app.shortcut, function() handler.toggleApp(app.hint) end)
  end

  if (app.hyperKey ~= nil) then
    hotkey.bind(app.hyperKey, app.shortcut, app.locations)
  end
end

-- :: utilities (things like config reloading, screen locking, manually forcing re-snapping windows/apps layout)
for _, util in pairs(config.utilities) do
  hotkey.bind(util.superKey, util.shortcut, util.fn)
end

-- :: media (spotify)
for _, media in pairs(config.media) do
  hotkey.bind(media.superKey, media.shortcut, function() handler.spotify(media.action, media.label) end)
end

-- :: volume control
for _, vol in pairs(config.volume) do
  hotkey.bind(vol.superKey, vol.shortcut, function() handler.adjustVolume(vol) end)
end

-- :: window-manipulation (manual window snapping)
for _, snap in pairs(config.snap) do
  hotkey.bind(snap.superKey, snap.shortcut, snap.locations)

  if (snap.hyperKey ~= nil) then
    hotkey.bind(snap.hyperKey, snap.shortcut, snap.locations)
  end
end
