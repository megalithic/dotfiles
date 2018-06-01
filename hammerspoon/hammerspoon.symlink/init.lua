-------------------------------------------------------------------------------
--/ initialize /--
-------------------------------------------------------------------------------

-- References:
-- https://github.com/knu/hs-knu
-- https://github.com/wassimk/dotfiles
-- https://github.com/tekezo/Karabiner-Elements/issues/137


-- :: imports/requires
-- require 'mpd'
-- require 'redshift'
-- require('control-escape') -- is now handled by karabiner-elements
-- require('delete-words')
-- require('hyper')
-- require('markdown')
-- require('microphone')
-- require('panes')
-- require('super')
-- require('windows')
local utils = require 'utils'
local wm = require 'wm'
local hotkey = require 'hs.hotkey'
local settings   = require 'hs.settings'
local ptt = require 'pushToTalk'

-- :: initialize all the things!
wm.events.initEventHandling()

-- key bindings
-------------------------------------------------------------------------------
cmdAlt = {'cmd', 'alt'}
cmdShift = {'cmd', 'shift'}
ctrlShift = {'ctrl', 'shift'}
cmdCtrl = {'cmd', 'ctrl'}
ctrlAlt = {'ctrl', 'alt'}
mashShift = {'cmd', 'ctrl', 'shift'}
mash = {'cmd', 'alt', 'ctrl'}
hyper = {'cmd', 'alt', 'ctrl', 'shift' }

-- :: utility
ptt.init({'cmd', 'alt'})
hotkey.bind(ctrlAlt, 'r', function() hs.toggleConsole() end)
hotkey.bind(mashShift, 'L', function()
  hs.caffeinate.startScreensaver()
end)
hotkey.bind(mashShift, 'r', function()
  wm.events.tearDownEventHandling()
  hs.reload()
  hs.notify.show('Hammerspoon', 'Config Reloaded', '')
end)

keyUpDown = function(modifiers, key)
  -- Un-comment & reload config to log each keystroke that we're triggering
  -- log.d('Sending keystroke:', hs.inspect(modifiers), key)
  hs.eventtap.keyStroke(modifiers, key, 0)
end

-- :: media
hotkey.bind(ctrlShift, '[', function() utils.handleSpotifyEvents('previous', "⇤ previous") end) -- < - > 27
hotkey.bind(ctrlShift, '\\', function() utils.handleSpotifyEvents('playpause', 'play/pause') end)   -- < \ >
hotkey.bind(ctrlShift, ']', function() utils.handleSpotifyEvents('next', 'next ⇥') end)         -- < = > 24

hotkey.bind(ctrlShift, 27, function() utils.handleMediaKeyEvents('SOUND_DOWN', '') end) -- < - > 27
hotkey.bind(ctrlShift, 24, function() utils.handleMediaKeyEvents('SOUND_UP', '') end)         -- < = > 24

-- :: apps
hotkey.bind('ctrl', '`', function() utils.toggleApp('Finder') end)

hotkey.bind('ctrl', 'space', function() utils.toggleApp('io.alacritty') end)
hotkey.bind('ctrl', 'space', function() utils.toggleApp('com.googlecode.iterm2') end)
hotkey.bind('ctrl', 'space', function() utils.toggleApp('net.kovidgoyal.kitty') end)

hotkey.bind(mashShift, 'space', function() utils.toggleApp('io.alacritty') end)
hotkey.bind(mashShift, 'space', function() utils.toggleApp('net.kovidgoyal.kitty') end)
hotkey.bind(mashShift, 'space', function() utils.toggleApp('com.googlecode.iterm2') end)

hotkey.bind('ctrl', 'return', function() utils.toggleApp('com.google.Chrome') end)
hotkey.bind('cmd', '`', function() utils.toggleApp('com.google.Chrome') end)
hotkey.bind('cmd', 'f4', function() utils.toggleApp('com.readdle.smartemail-Mac') end)
hotkey.bind(mashShift, 'm', function() utils.toggleApp('com.readdle.smartemail-Mac') end)
hotkey.bind('cmd', 'f5', function() utils.toggleApp('com.tapbots.TweetbotMac') end)
hotkey.bind('cmd', 'f6', function() utils.toggleApp('com.tinyspeck.slackmacgap') end)
hotkey.bind(mashShift, 's', function() utils.toggleApp('com.tinyspeck.slackmacgap') end)
hotkey.bind(mashShift, 'z', function() utils.toggleApp('us.zoom.xos') end)
hotkey.bind(cmdShift, '8', function() utils.toggleApp('com.spotify.client') end)
hotkey.bind(cmdCtrl, '8', function() utils.toggleApp('com.spotify.client') end)
hotkey.bind(cmdShift, 'M', function() utils.toggleApp('com.apple.iChat') end)
hotkey.bind(ctrlShift, 'M', function() utils.toggleApp('com.github.yakyak') end)

-- :: window manipulation
hotkey.bind(cmdCtrl, 'h', utils.chain({
  wm.config.grid.leftHalf,
  wm.config.grid.leftOneThird,
  wm.config.grid.leftTwoThirds,
}))

hotkey.bind(cmdCtrl, 'k', utils.chain({
  wm.config.grid.fullScreen,
}))

hotkey.bind(cmdCtrl, 'l', utils.chain({
  wm.config.grid.rightHalf,
  wm.config.grid.rightOneThird,
  wm.config.grid.rightTwoThirds,
}))

hotkey.bind(cmdCtrl, 'j', utils.chain({
  wm.config.grid.centeredLarge,
  wm.config.grid.centeredMedium,
  wm.config.grid.centeredSmall,
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


-- :: monitor layout overrides
hotkey.bind(cmdCtrl, '1', (function()
  wm.config.applyLayout(1)
  hs.notify.show('Hammerspoon', 'Loading single-monitor layout', '')
end))

hotkey.bind(cmdCtrl, '2', (function()
  wm.config.applyLayout(2)
  hs.notify.show('Hammerspoon', 'Loading dual-monitor layout', '')
end))
