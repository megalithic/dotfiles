-- :: imports/requires
require 'config'
require('auto-layout'):init()
require('push-to-talk'):init({'cmd', 'alt'}) -- activate ptt with the given keybinding
require('laptop-docking-mode'):init()

local utils = require 'utils'
local wm = require 'wm'
local hotkey = require 'hs.hotkey'
local switchToApp = require 'keystroke-to-app'


-- :: event-init
-- wm.events.initEventHandling()


-- :: spoons
-------------------------------------------------------------------------------
-- hs.loadSpoon() -- none yet


-- :: utilities
for _, util in pairs(config.utilities) do
  hotkey.bind(util.superKey, util.shortcut, util.callback)
end


-- :: app-launching
for _, app in pairs(config.applications) do
  switchToApp.register(app.name, app.superKey, app.shortcut, true)
  -- hotkey.bind(app.superKey, app.shortcut, function() utils.toggleApp(app.name) end)
end


-- :: cursor-locator
hotkey.bind(mashShift, 'return', function() utils.mouseHighlight() end)


-- :: media(spotify/volume)
for _, media in pairs(config.media) do
  hotkey.bind(media.superKey, media.shortcut, function() utils.handleSpotifyEvents(media.action, media.label) end)
end


-- :: window-manipulation
hotkey.bind(cmdCtrl, 'h', utils.chain({
  config.grid.leftHalf,
  config.grid.leftOneThird,
  config.grid.leftTwoThirds,
}))

hotkey.bind(cmdCtrl, 'k', utils.chain({
  config.grid.fullScreen,
}))

hotkey.bind(cmdCtrl, 'l', utils.chain({
  config.grid.rightHalf,
  config.grid.rightOneThird,
  config.grid.rightTwoThirds,
}))

hotkey.bind(cmdCtrl, 'j', utils.chain({
  config.grid.centeredLarge,
  config.grid.centeredMedium,
  config.grid.centeredSmall,
}))

hotkey.bind(ctrlAlt, 'h', function()
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():previous()
  win:moveToScreen(nextScreen)
end)

hotkey.bind(ctrlAlt, 'l', function()
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():next()
  win:moveToScreen(nextScreen)
end)
