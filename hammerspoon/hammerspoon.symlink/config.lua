local log = hs.logger.new('config', 'warning')
local module = { network = {} }

local utils = require('utils')
local mouse = require('mouse')

hs.grid.GRIDWIDTH = 8
hs.grid.GRIDHEIGHT = 8
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0


module.hostname = hs.host.localizedName()
module.network.home = 'shaolin'
module.network.currentConnected = hs.wifi.currentNetwork()

module.grid = {
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

module.superKeys = {
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

module.ptt = {'cmd', 'alt'}

module.ignoredApps = { 'iStat Menus Status', 'Fantastical', 'Contexts'  }

-- REF for url handling: https://github.com/sjthespian/dotfiles/blob/master/hammerspoon/config.lua#L76
module.distractionUrls = {
  'https://www.youtube.com',
  'https://www.twitter.com',
  'https://www.instagram.com',
  'https://www.facebook.com',
  'https://www.reddit.com',
}

module.window = {
  highlightBorder = false,
  highlightMouse  = true,
  historyLimit    = 0
}

local appHandler = function(win)
  if win == nil then return end

  local appBundleID = win:application():bundleID()
  local appName = win:application():name()
  local visibleWindows = win:application():visibleWindows()
  if appName == nil then return end

  log.df('executing app handler for %s (%s) instance, for %s windows..', appName, appBundleID, #visibleWindows)

  return appName
end

module.apps = {
  ['_'] = {
    hint = '',
    name = '',
    preferredDisplay = 2,
    position = module.grid.centeredMedium,
  },
  ['net.kovidgoyal.kitty'] = {
    hint = 'net.kovidgoyal.kitty',
    name = 'kitty',
    hyperShortcut = 'k',
    superKey = module.superKeys.ctrl,
    shortcut = 'space',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    quitGuard = true,
  },
  ['com.kapeli.dashdoc'] = {
    hint = 'com.kapeli.dashdoc',
    name = 'Dash',
    preferredDisplay = 1,
    position = module.grid.centeredLarge,
  },
  ['com.brave.Browser.dev'] = {
    hint = 'com.brave.Browser.dev',
    name = 'Brave Browser Dev',
    hyperShortcut = '`',
    superKey = module.superKeys.cmd,
    shortcut = '`',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    quitGuard = true,
  },
  ['com.google.Chrome'] = {
    hint = 'com.google.Chrome',
    name = 'Google Chrome',
    preferredDisplay = 1,
    position = module.grid.rightHalf,
    quitGuard = true
  },
  ['com.agiletortoise.Drafts-OSX'] = {
    hint = 'com.agiletortoise.Drafts-OSX',
    name = 'Drafts',
    hyperShortcut ='d',
    local_bindings = {'x', '\''},
    superKey = module.superKeys.mashShift,
    shortcut = 'n',
    preferredDisplay = 1,
    position = module.grid.rightHalf,
    quitGuard = false,
  },
  ['com.brettterpstra.marked2'] = {
    hint = 'com.brettterpstra.marked2',
    name = 'Marked',
    preferredDisplay = 2,
    position = module.grid.leftHalf,
  },
  ['com.tinyspeck.slackmacgap'] = {
    hint = 'com.tinyspeck.slackmacgap',
    name = 'Slack',
    hyperShortcut = 's',
    superKey = module.superKeys.mashShift,
    shortcut = 's',
    distraction = true,
    preferredDisplay = 2,
    position = module.grid.fullScreen,
    quitGuard = true,
    ignoredWindows = {'Slack Call Minipanel'},
  },
  ['com.readdle.smartemail-Mac'] = {
    hint = 'com.readdle.smartemail-Mac',
    name = 'Spark',
    superKey = module.superKeys.mashShift,
    distraction = true,
    shortcut = 'm',
    preferredDisplay = 2,
    -- position = module.grid.rightHalf
    -- position = module.grid.rightTwoThirds
    position = module.grid.fullScreen,
  },
  ['com.apple.finder'] = {
    hint = 'com.apple.finder',
    name = 'Finder',
    superKey = module.superKeys.ctrl,
    shortcut = '`',
    preferredDisplay = 1,
    position = module.grid.centeredMedium
  },
  ['us.zoom.xos'] = {
    hint = 'us.zoom.xos',
    name = 'Zoom',
    superKey = module.superKeys.mashShift,
    shortcut = 'z',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    dnd = { enabled = false,  mode = "zoom" },
    ignoredWindows = {'Zoom'},
    -- tabjump = 'zoom.us'
  },
  ['com.spotify.client'] = {
    hint = 'com.spotify.client',
    name = 'Spotify',
    superKey = module.superKeys.cmdShift,
    shortcut = '8',
    preferredDisplay = 2,
    -- position = '5,0 5x5'
    position = module.grid.rightHalf
  },
  ['com.apple.iChat'] = {
    hint = 'com.apple.iChat',
    name = 'Messages',
    superKey = module.superKeys.cmdShift,
    shortcut = 'm',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['hangouts'] = {
    hint = 'hangouts',
    name = 'Brave Browser Dev',
    superKey = module.superKeys.cmdCtrl,
    shortcut = 'm',
    distraction = true,
    preferredDisplay = 1,
    tabjump = 'hangouts.google.com'
  },
  ['WhatsApp'] = {
    hint = 'WhatsApp',
    name = 'WhatsApp',
    superKey = module.superKeys.cmdShift,
    shortcut = 'w',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['com.agilebits.onepassword7'] = {
    hint = 'com.agilebits.onepassword7',
    name = '1Password',
    superKey = module.superKeys.mashShift,
    shortcut = '1',
    preferredDisplay = 1,
    position = module.grid.centeredMedium
  },
  ['com.teamviewer.TeamViewer'] = {
    hint = 'com.teamviewer.TeamViewer',
    name = 'TeamViewer',
    -- superKey = module.superKeys.mashShift,
    -- shortcut = 'v',
    preferredDisplay = 1,
    position = module.grid.centeredLarge
  },
  ['org.hammerspoon.Hammerspoon'] = {
    hint = 'org.hammerspoon.Hammerspoon',
    name = 'Hammerspoon',
    superKey = module.superKeys.mashShift,
    shortcut = 'h',
    preferredDisplay = 2,
    position = module.grid.centeredMedium,
    quitGuard = true,
  },
  ['com.apple.systempreferences'] = {
    hint = 'com.apple.systempreferences',
    name = 'System Preferences',
    preferredDisplay = 1,
    position = module.grid.centeredMedium
  },
  ['Fantastical'] = {
    hint = 'com.flexibits.fantastical2.mac',
    name = 'Fantastical',
    -- superKey = module.superKeys.cmdShift,
    -- shortcut = 'f',
    preferredDisplay = 1,
    position = module.grid.centeredLarge
  },
  ['85C27NK92C.com.flexibits.fantastical2.mac.helper'] = {
    hint = '85C27NK92C.com.flexibits.fantastical2.mac.helper',
    name = 'Fantastical Helper',
    -- superKey = module.superKeys.cmdShift,
    -- shortcut = 'f',
    preferredDisplay = 1,
    -- position = module.grid.centeredLarge
  },
  ['com.microsoft.autoupdate2'] = {
    hint = 'com.microsoft.autoupdate2',
    name = 'Microsoft AutoUpdate',
    -- superKey = module.superKeys.cmdShift,
    -- shortcut = 'f',
    preferredDisplay = 1,
    -- position = module.grid.centeredLarge
    handler = (function(win)
      -- AUTOHIDE
      win:application():hide()
    end)
  }
}

module.utilities = {
  {
    name = 'Hammerspoon Console',
    superKey = module.superKeys.ctrlAlt,
    shortcut = 'r',
    fn = function() hs.toggleConsole() end
  },
  -- NOTE: handle this with alfred and `sleep`/`lock` commands
  -- {
  --   name = 'Lock Screen',
  --   superKey = module.superKeys.mashShift,
  --   shortcut = 'L',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  -- {
  --   name = 'Pomodoro',
  --   superKey = module.superKeys.mashShift,
  --   shortcut = 'P',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  {
    name = 'Hammerspoon Reload',
    superKey = module.superKeys.mashShift,
    shortcut = 'r',
    fn = (function()
      -- require('auto-layout').teardown()
      -- require('layout').teardown()
      -- require('dock').teardown()
      -- require('ptt').teardown()
      hs.reload()
      hs.notify.show('Hammerspoon', 'module Reloaded', '')
    end)
  },
  {
    name = 'Cursor Locator',
    superKey = module.superKeys.mashShift,
    shortcut = 'return',
    fn = (function()
      mouse.highlight()
    end)
  },
  {
    name = 'Re-layout All',
    superKey = module.superKeys.mashShift,
    shortcut = 'w',
    fn = (function()
      hs.alert.show("Relayout of all apps")
      require('layout').setLayoutForAll()
    end)
  },
  {
    name = 'Re-layout App',
    superKey = module.superKeys.ctrlShift,
    shortcut = 'w',
    fn = (function()
      local app = hs.application.frontmostApplication()
      hs.alert.show("Relayout of single app (" .. app:name() .. ")")
      require('layout').setLayoutForApp(app)
    end)
  },
  {
    name = 'Pomodoro',
    superKey = module.superKeys.cmdCtrl,
    shortcut = 'p',
    fn = (function()
    end)
  }
}

module.media = {
  {
    action = 'previous',
    superKey = module.superKeys.ctrlShift,
    shortcut = '[',
    label = '⇤ previous'
  },
  {
    action = 'next',
    superKey = module.superKeys.ctrlShift,
    shortcut = ']',
    label = 'next ⇥'
  },
  {
    action = 'playpause',
    superKey = module.superKeys.ctrlShift,
    shortcut = '\\',
    label = 'play/pause'
  },
}

module.volume = {
  {
    action = 'down',
    superKey = module.superKeys.ctrlShift,
    shortcut = 27,
    diff = -5,
  },
  {
    action = 'up',
    superKey = module.superKeys.ctrlShift,
    shortcut = 24,
    diff = 5,
  },
  {
    action = 'mute',
    superKey = module.superKeys.mashShift,
    shortcut = '\\',
  },
}

module.snap = {
  {
    name = 'left',
    superKey = module.superKeys.cmdCtrl,
    -- hyperKey = module.superKeys.hyper,
    shortcut = 'h',
    locations = utils.chain({
      module.grid.leftHalf,
      module.grid.leftOneThird,
      module.grid.leftTwoThirds,
    })
  },
  {
    name = 'right',
    superKey = module.superKeys.cmdCtrl,
    -- hyperKey = module.superKeys.hyper,
    shortcut = 'l',
    locations = utils.chain({
      module.grid.rightHalf,
      module.grid.rightOneThird,
      module.grid.rightTwoThirds,
    })
  },
  {
    name = 'down',
    superKey = module.superKeys.cmdCtrl,
    -- hyperKey = module.superKeys.hyper,
    shortcut = 'j',
    locations = utils.chain({
      module.grid.centeredLarge,
      module.grid.centeredMedium,
      module.grid.centeredSmall,
    })
  },
  {
    name = 'up',
    superKey = module.superKeys.cmdCtrl,
    -- hyperKey = module.superKeys.hyper,
    shortcut = 'k',
    locations = utils.chain({
      module.grid.fullScreen,
    })
  },
  {
    name = 'full',
    superKey = module.superKeys.cmdCtrl,
    -- hyperKey = module.superKeys.hyper,
    shortcut = 'return',
    locations = utils.chain({
      module.grid.fullScreen,
    })
  },
}

module.docking = {
  -- find your device IDs with `print(hs.inspect(hs.usb.attachedDevices()))` from the hammerspoon console
  ['device'] = {
    productID = 25907,
    productName = "CalDigit Thunderbolt 3 Audio",
    vendorID = 8584,
    vendorName = "CalDigit, Inc."
  },
  ['docked'] = {
    wifi = 'off', -- wifi status
    profile = 'dz60', -- Karabiner-Elements profile name
    input = '"Samson GoMic"', -- microphone source
    output = '"CalDigit Thunderbolt 3 Audio"', -- speaker source
    fontSize = 16.0,
  },
  ['undocked'] = {
    wifi = 'on',
    profile = 'internal',
    input = '"MacBook Pro Microphone"',
    output = '"MacBook Pro Speakers"',
    fontSize = 14.0,
  },
}

-- log.d('Found the following attached USB devices:\r\n')
-- log.d('---------------------------------------------')
-- log.d(print(hs.inspect(hs.usb.attachedDevices())))
-- log.d('---------------------------------------------')

return module
