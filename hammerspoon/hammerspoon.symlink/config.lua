config = {}

config.hostname = hs.host.localizedName()
config.homeSSID = 'shaolin'
config.lastSSID = hs.wifi.currentNetwork()

local utils = require 'utils'

hs.grid.GRIDWIDTH = 8
hs.grid.GRIDHEIGHT = 8
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- :: settings
hs.window.animationDuration = 0.0 -- 0 to disable animations
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)


config.ptt = {'cmd', 'alt'}

config.grid = {
  topHalf =         '0,0 8x4',
  rightHalf =       '4,0 4x8',
  bottomHalf =      '0,4 8x4',
  leftHalf =        '0,0 4x8',
  rightOneThird =   '5,0 3x8',
  rightTwoThirds =  '3,0 5x8',
  leftOneThird =    '0,0 3x8',
  leftTwoThirds =   '0,0 5x8',
  fullScreen =      '0,0 8x8',
  centeredLarge =   '1,1 6x6',
  centeredMedium =  '2,2 4x4',
  centeredSmall =   '3,3 2x2',
}

config.superKeys = {
  ctrl = {'ctrl'},
  cmd = {'cmd'},
  cmdAlt = {'cmd', 'alt'},
  cmdShift = {'cmd', 'shift'},
  ctrlShift = {'ctrl', 'shift'},
  cmdCtrl = {'cmd', 'ctrl'},
  ctrlAlt = {'ctrl', 'alt'},
  mashShift = {'cmd', 'ctrl', 'shift'},
  mash = {'cmd', 'alt', 'ctrl'},
  hyper = {'cmd', 'alt', 'ctrl', 'shift' },
}

config.applications = {
  ['kitty'] = {
    name = 'kitty',
    bundleID = 'net.kovidgoyal.kitty',
    superKey = config.superKeys.ctrl,
    shortcut = 'space',
    preferredDisplay = 1,
    position = config.grid.fullScreen
  },
  ['Google Chrome'] = {
    name = 'Google Chrome',
    bundleID = 'com.google.Chrome',
    superKey = config.superKeys.cmd,
    shortcut = '`',
    preferredDisplay = 1,
    position = config.grid.fullScreen
  },
  ['Slack'] = {
    name = 'Slack',
    bundleID = 'com.tinyspeck.slackmacgap',
    superKey = config.superKeys.mashShift,
    shortcut = 's',
    preferredDisplay = 2,
    position = config.grid.rightHalf
  },
  ['Spark'] = {
    name = 'Spark',
    bundleID = 'com.readdle.smartemail-Mac',
    superKey = config.superKeys.mashShift,
    shortcut = 'm',
    preferredDisplay = 2,
    position = config.grid.leftHalf
  },
  ['Finder'] = {
    name = 'Finder',
    superKey = config.superKeys.ctrl,
    shortcut = '`',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
  ['zoom.us'] = {
    name = 'zoom.us',
    bundleID = 'us.zoom.xos',
    superKey = config.superKeys.mashShift,
    shortcut = 'z',
    preferredDisplay = 2,
    position = config.grid.centeredLarge
  },
  ['Spotify'] = {
    name = 'Spotify',
    bundleID = 'com.spotify.client',
    superKey = config.superKeys.cmdShift,
    shortcut = '8',
    preferredDisplay = 2,
    position = '5,0 5x5'
  },
  ['Messages'] = {
    name = 'Messages',
    bundleID = 'com.apple.iChat',
    superKey = config.superKeys.cmdShift,
    shortcut = 'm',
    preferredDisplay = 2,
    position = '5,5 3x3'
  },
  ['yakyak'] = {
    name = 'yakyak',
    bundleID = 'com.github.yakyak',
    superKey = config.superKeys.ctrlShift,
    shortcut = 'm',
    preferredDisplay = 2,
    position = '5,5 3x3'
  },
  ['1Password'] = {
    name = '1Password',
    bundleID = 'com.agilebits.onepassword4',
    superKey = config.superKeys.mashShift,
    shortcut = '1',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
}

config.utilities = {
  {
    name = 'Hammerspoon Console',
    superKey = config.superKeys.ctrlAlt,
    shortcut = 'r',
    preferredDisplay = 1,
    position = config.grid.centeredMedium,
    callback = function() hs.toggleConsole() end
  },
  {
    name = 'Logout',
    superKey = config.superKeys.mashShift,
    shortcut = 'L',
    preferredDisplay = 1,
    position = config.grid.centeredMedium,
    callback = function() hs.caffeinate.startScreensaver() end
  },
  {
    name = 'Hammerspoon Reload',
    superKey = config.superKeys.mashShift,
    shortcut = 'r',
    preferredDisplay = 1,
    position = config.grid.centeredMedium,
    callback = (function()
      require('auto-layout'):teardown()
      require('laptop-docking-mode'):teardown()
      require('push-to-talk'):teardown()
      hs.reload()
      hs.notify.show('Hammerspoon', 'Config Reloaded', '')
    end)
  },
  {
    name = 'Cursor Locator',
    superKey = config.superKeys.mashShift,
    shortcut = 'return',
    preferredDisplay = 1,
    position = config.grid.centeredMedium,
    callback = (function()
      utils.mouseHighlight()
    end)
  },
}

config.media = {
  {
    action = 'previous',
    superKey = config.superKeys.ctrlShift,
    shortcut = '[',
    label = '⇤ previous'
  },
  {
    action = 'next',
    superKey = config.superKeys.ctrlShift,
    shortcut = ']',
    label = 'next ⇥'
  },
  {
    action = 'playpause',
    superKey = config.superKeys.ctrlShift,
    shortcut = '\\',
    label = 'play/pause'
  },
  {
    action = 'SOUND_DOWN',
    superKey = config.superKeys.ctrlShift,
    shortcut = 27,
    label = 'lowering sound'
  },
  {
    action = 'SOUND_UP',
    superKey = config.superKeys.ctrlShift,
    shortcut = 24,
    label = 'raising sound'
  },
}

return config
