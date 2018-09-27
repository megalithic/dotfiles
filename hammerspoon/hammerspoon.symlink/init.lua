inspect = require('inspect')
local utils = require('utils')
local hotkey = require('hs.hotkey')

require('config')
require('auto-layout'):init()
require('push-to-talk'):init(config.ptt) -- having to set this in the module for some reason. :(
require('laptop-docking-mode'):init()

-- :: spoons
-- hs.loadSpoon() -- none yet

-- :: app-launching
for _, app in pairs(config.applications) do
  hotkey.bind(app.superKey, app.shortcut, function() utils.toggleApp(app.name) end)
end

-- :: utilities
for _, util in pairs(config.utilities) do
  hotkey.bind(util.superKey, util.shortcut, util.callback)
end

-- :: media(spotify/volume)
for _, media in pairs(config.media) do
  hotkey.bind(media.superKey, media.shortcut, function() utils.handleSpotifyEvents(media.action, media.label) end)
end

-- :: window-manipulation
hotkey.bind(config.superKeys.cmdCtrl, 'h', utils.chain({
  config.grid.leftHalf,
  config.grid.leftOneThird,
  config.grid.leftTwoThirds,
}))

hotkey.bind(config.superKeys.cmdCtrl, 'k', utils.chain({
  config.grid.fullScreen,
}))

hotkey.bind(config.superKeys.cmdCtrl, 'l', utils.chain({
  config.grid.rightHalf,
  config.grid.rightOneThird,
  config.grid.rightTwoThirds,
}))

hotkey.bind(config.superKeys.cmdCtrl, 'j', utils.chain({
  config.grid.centeredLarge,
  config.grid.centeredMedium,
  config.grid.centeredSmall,
}))

hotkey.bind(config.superKeys.ctrlAlt, 'h', function()
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():previous()
  win:moveToScreen(nextScreen)
end)

hotkey.bind(config.superKeys.ctrlAlt, 'l', function()
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():next()
  win:moveToScreen(nextScreen)
end)
