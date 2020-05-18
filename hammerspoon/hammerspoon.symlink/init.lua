-- logging config
require('hs.logger').idLength(20)

local log = hs.logger.new('init', 'warning')

-- global stuff
require('console').init()
-- require('overrides').init()

-- load config for all modules
config = require('config')

-- ensure IPC is there
hs.ipc.cliInstall()

-- lower logging level for hotkeys
require('hs.hotkey').setLogLevel("warning")

hs.window.animationDuration = 0.0
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)

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
bindings.enabled            = { 'ptt', 'quitguard', 'tabjump', 'apps', 'snap', 'airpods', 'media', 'misc' }

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
