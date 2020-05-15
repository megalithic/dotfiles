-- logging config
require('hs.logger').idLength(20)

local log = hs.logger.new('init', 'warning')

-- global stuff
-- require('config').init()
require('console').init()
-- require('overrides').init()
config = require('config')

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
keys                        = require('keys')
isDocked                    = require('dock').init()
 require('layout').init(isDocked)

-- keys                        = require('keys')
-- tabjump                     = require('tabjump')
-- isDocked                    = require('dock').init()
-- wm                          = require('wm').init(isDocked)
-- pomodoro                    = require('pomodoro').init()

bindings                    = require('bindings')
controlplane                = require('utils.controlplane')
watchables                  = require('utils.watchables')
watchers                    = require('utils.watchers')
-- wm                          = require('utils.wm')

-- controlplane
controlplane.enabled        = { 'office' }

-- watchers
watchers.enabled            = { 'urlevent' }
watchers.urlPreference      = { 'Brave', 'Brave Browser Dev' }

-- bindings
bindings.enabled            = { 'ptt', 'quitguard', 'tabjump', 'apps', 'snap', 'airpods', 'media' }
bindings.disabled            = { 'slack' } -- FIXME: can't get binding enable/disable right

-- start/stop modules
local modules               = { bindings, controlplane, watchables, watchers }
-- local modules               = { bindings, controlplane, watchables, watchers, wm }

hs.fnutils.each(modules, function(module)
  if module then module.start() end
end)

-- stop modules on shutdown
hs.shutdownCallback = function()
  hs.fnutils.each(modules, function(module)
    if module then module.stop() end
  end)
end


-- :: utilities (things like config reloading, screen locking, manually forcing re-snapping windows/apps layout, pomodoro)
for _, util in pairs(config.utilities) do
  hs.hotkey.bind(util.superKey, util.shortcut, util.fn)
end

-- -- :: media (spotify)
-- for _, media in pairs(config.media) do
--   hs.hotkey.bind(media.superKey, media.shortcut, function() keys.spotify(media.action, media.label) end)
-- end

-- -- :: volume control
-- for _, vol in pairs(config.volume) do
--   hs.hotkey.bind(vol.superKey, vol.shortcut, function() keys.adjustVolume(vol) end)
-- end
