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
bindings                    = require('bindings')
controlplane                = require('utils.controlplane')
watchables                  = require('utils.watchables')
watchers                    = require('utils.watchers')
wm                          = require('utils.wm')

-- controlplane
controlplane.enabled        = { 'office' }

-- watchers
watchers.enabled            = { 'urlevent' }
watchers.urlPreference      = { 'Brave Browser Dev', 'Google Chrome', 'Firefox', 'Safari' }

-- bindings
bindings.enabled            = { 'ptt', 'quitguard', 'tabjump', 'apps', 'snap', 'airpods', 'media', 'misc', 'slack' }

-- start/stop modules
local modules               = { bindings, controlplane, watchables, watchers, wm }

hs.fnutils.each(modules, function(module)
  if module then module.start() end
end)

-- stop modules on shutdown
hs.shutdownCallback = function()
  hs.fnutils.each(modules, function(module)
    if module then module.stop() end
  end)
end
