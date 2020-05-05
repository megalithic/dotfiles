local log = hs.logger.new('[init]', 'verbose')

log.i(":: initializing hammerspoon..")

hs.ipc.cliInstall()
hs.console.darkMode(true)
hs.application.enableSpotlightForNameSearches(true)

-- where all the magic is defined (check here for every piece of configuration)
local config = require('config')
local keys = require('keys')
local hotkey = require('hs.hotkey')
local tabjump = require('tabjump')

-- handles initiating laptop docking mode behaviors
local isDocked = require('dock').init()
log.i(":: -- currently docked? ", isDocked)

-- window/app auto-layout
require('layout').init(isDocked)
-- require('auto-layout').init(isDocked)

-- push-to-talk (e.g., mute my input until i hold down the requisite keys)
require('ptt').init(config.ptt)

-- helper to prevent accidental/unintentional app quitting
require('quit')

-- handles screen/wake things
require('caffeinate').init(isDocked)

-- handles pomodoro
-- require('pomodoro').init()

-- :: app-launching (basic app launching and toggling)
for bundleID, app in pairs(config.apps) do
  if app.superKey ~= nil and app.shortcut ~= nil then

    if (app.tabjump ~= nil) then
      hotkey.bind(app.superKey, app.shortcut, function() tabjump(app.tabjump) end)
    else
      -- hotkey.bind(app.superKey, app.shortcut, function() keys.launch(app.name) end)
      hotkey.bind(app.superKey, app.shortcut, function() keys.toggle(bundleID) end)
    end

  end


  if (app.hyperKey ~= nil) then
    hotkey.bind(app.hyperKey, app.shortcut, app.locations)
  end
end

-- :: utilities (things like config reloading, screen locking, manually forcing re-snapping windows/apps layout, pomodoro)
for _, util in pairs(config.utilities) do
  hotkey.bind(util.superKey, util.shortcut, util.fn)
end

-- :: media (spotify)
for _, media in pairs(config.media) do
  hotkey.bind(media.superKey, media.shortcut, function() keys.spotify(media.action, media.label) end)
end

-- :: volume control
for _, vol in pairs(config.volume) do
  hotkey.bind(vol.superKey, vol.shortcut, function() keys.adjustVolume(vol) end)
end

-- :: window-manipulation (manual window snapping)
for _, snap in pairs(config.snap) do
  hotkey.bind(snap.superKey, snap.shortcut, snap.locations)

  if (snap.hyperKey ~= nil) then
    hotkey.bind(snap.hyperKey, snap.shortcut, snap.locations)
  end
end

-- -- Reload configuration on changes
-- -- REF: https://github.com/adamgibbins/hammerspoon-config/blob/master/init.lua
-- local pathWatcher = hs.pathwatcher.new(hs.configdir, function(files)
--   for _,file in pairs(files) do
--     if file:sub(-4) == '.lua' then
--       -- require('auto-layout').teardown()
--       require('layout').teardown()
--       require('dock').teardown()
--       require('ptt').teardown()
--       hs.reload()
--       hs.notify.show('Hammerspoon', 'Config Reloaded', '')
--     end
--   end
-- end)
-- pathWatcher:start()
