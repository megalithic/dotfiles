-- logging configuration
require('hs.logger').idLength(25)

local log = hs.logger.new('[init]', 'warning')

-- global stuff
require('console').init()
-- require('overrides').init()

-- ensure IPC is there
hs.ipc.cliInstall()

-- lower logging level for hotkeys
require('hs.hotkey').setLogLevel("warning")

-- TODO: move this hs.alert config to ext.alert and use it by default
-- alert configuration
hs.alert.defaultStyle['textSize'] = 24
hs.alert.defaultStyle['radius'] = 20
hs.alert.defaultStyle['strokeColor'] = {
  white = 1,
  alpha = 0
}
hs.alert.defaultStyle['fillColor'] = {
  red   = 9/255,
  green = 8/255,
  blue  = 32/255,
  alpha = 0.9
}
hs.alert.defaultStyle['textColor'] = {
  red   = 209/255,
  green = 236/255,
  blue  = 240/255,
  alpha = 1
}
hs.alert.defaultStyle['textFont'] = 'Helvetica Light'

-- misc configuration
hs.window.animationDuration = 0.0
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)
hs.allowAppleScript(true)

-- requires
config                      = require('config')
bindings                    = require('bindings')
controlplane                = require('utils.controlplane')
watchables                  = require('utils.watchables')
watchers                    = require('utils.watchers')
wm                          = require('utils.wm')

-- controlplane
controlplane.enabled        = { 'office' } -- dock?

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
