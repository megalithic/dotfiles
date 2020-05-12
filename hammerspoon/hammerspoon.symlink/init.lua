local log = hs.logger.new('init', 'debug')

-- global stuff
-- require('config').init()
require('console').init()
-- require('overrides').init()

-- ensure IPC is there
hs.ipc.cliInstall()

-- lower logging level for hotkeys
require('hs.hotkey').setLogLevel("warning")

-- no animations
hs.window.animationDuration = 0.0

-- hints
hs.hints.fontName           = 'Helvetica-Bold'
hs.hints.fontSize           = 22
hs.hints.hintChars          = { 'A', 'S', 'D', 'F', 'J', 'K', 'L', 'Q', 'W', 'E', 'R', 'Z', 'X', 'C' }
hs.hints.iconAlpha          = 1.0
hs.hints.showTitleThresh    = 0

hs.application.enableSpotlightForNameSearches(true)
hs.window.setShadows(false)

-- requires
hotkey = require('hs.hotkey')
config                      = require('config')
keys                        = require('keys')
tabjump                     = require('tabjump')
isDocked                    = require('dock').init()
 require('layout').init(isDocked)
 require('ptt'):init(config.ptt)
 require('quit')
 require('caffeinate').init(isDocked)

-- keys                        = require('keys')
-- tabjump                     = require('tabjump')
-- isDocked                    = require('dock').init()
-- wm                          = require('wm').init(isDocked)
-- ptt                         = require('ptt'):init(config.ptt)
-- quit                        = require('quit')
-- caffeinate                  = require('caffeinate').init(isDocked)
-- pomodoro                    = require('pomodoro').init()

-- bindings                    = require('bindings')
-- controlplane                = require('utils.controlplane')
-- watchables                  = require('utils.watchables')
-- watchers                    = require('utils.watchers')
-- wm                          = require('utils.wm')

-- -- controlplane
-- controlplane.enabled        = { 'dock' }

-- -- watchers
-- watchers.enabled            = { 'urlevent' }
-- watchers.urlPreference      = config.apps.browsers

-- -- bindings
-- -- bindings.enabled            = { 'ask-before-quit', 'block-hide', 'ctrl-esc', 'f-keys', 'focus', 'global', 'tiling', 'term-ctrl-i', 'viscosity' }
-- bindings.enabled            = { 'quit', 'tabjump', 'ptt' }
-- bindings.askBeforeQuitApps  = config.apps.browsers

-- start/stop modules
-- local modules               = { bindings, controlplane, watchables, watchers, wm }

-- hs.fnutils.each(modules, function(module)
--   if module then module.start() end
-- end)

-- -- stop modules on shutdown
-- hs.shutdownCallback = function()
--   hs.fnutils.each(modules, function(module)
--     if module then module.stop() end
--   end)
-- end



-- :: app-launching (basic app launching and toggling)
for bundleID, app in pairs(config.apps) do
  if app.superKey ~= nil and app.shortcut ~= nil then

    if (app.tabjump ~= nil) then
      hotkey.bind(app.superKey, app.shortcut, function()
        if hs.application.find(bundleID) then
          hs.application.launchOrFocusByBundleID(bundleID)
        else
          tabjump(app.tabjump)
        end
      end)
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
