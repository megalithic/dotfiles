local log = hs.logger.new('config|', 'debug')

local utils = require('utils')
local airpods = require('airpods')
local mouse = require('mouse')
local keys = require('keys')

hs.grid.GRIDWIDTH = 8
hs.grid.GRIDHEIGHT = 8
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- :: settings
hs.window.animationDuration = 0.0 -- 0 to disable animations
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)

local config = {}

config.hostname = hs.host.localizedName()
config.preferredSSID = 'shaolin'
config.lastSSID = hs.wifi.currentNetwork()

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

config.ptt = {'cmd', 'alt'}

config.ignoredApps = { 'iStat Menus Status', 'Fantastical', 'Contexts' }

-- REF for url handling: https://github.com/sjthespian/dotfiles/blob/master/hammerspoon/config.lua#L76
config.distractionUrls = {
  'https://www.youtube.com',
  'https://www.twitter.com',
  'https://www.instagram.com',
  'https://www.facebook.com',
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

config.apps = {
  ['_'] = {
    hint = '',
    preferredDisplay = 2,
    position = config.grid.centeredMedium,
  },
  ['net.kovidgoyal.kitty'] = {
    hint = 'net.kovidgoyal.kitty',
    hyperShortcut = 'k',
    superKey = config.superKeys.ctrl,
    shortcut = 'space',
    preferredDisplay = 1,
    position = config.grid.fullScreen,
    quitGuard = true,
  },
  ['com.kapeli.dashdoc'] = {
    hint = 'com.kapeli.dashdoc',
    preferredDisplay = 1,
    position = config.grid.centeredLarge,
  },
  ['com.brave.Browser.dev'] = {
    hint = 'com.brave.Browser.dev',
    hyperShortcut = '`',
    superKey = config.superKeys.cmd,
    shortcut = '`',
    preferredDisplay = 1,
    position = config.grid.fullScreen,
    quitGuard = true,
    handler = (function(win)
      local appName = appHandler(win)

      -- keys.remap(appName, {'cmd', 'ctrl'}, 'f', {}, 'Esc')
    end)
  },
  ['com.google.Chrome'] = {
    hint = 'com.google.Chrome',
    preferredDisplay = 1,
    position = config.grid.rightHalf,
    quitGuard = true
  },
  ['com.agiletortoise.Drafts-OSX'] = {
    hint = 'com.agiletortoise.Drafts-OSX',
    hyperShortcut ='d',
    local_bindings = {'x', '\''},
    superKey = config.superKeys.mashShift,
    shortcut = 'n',
    preferredDisplay = 1,
    position = config.grid.rightHalf,
    quitGuard = false,
  },
  ['com.brettterpstra.marked2'] = {
    hint = 'com.brettterpstra.marked2',
    preferredDisplay = 2,
    position = config.grid.leftHalf,
  },
  ['com.tinyspeck.slackmacgap'] = {
    hint = 'com.tinyspeck.slackmacgap',
    hyperShortcut = 's',
    superKey = config.superKeys.mashShift,
    shortcut = 's',
    distraction = true,
    preferredDisplay = 2,
    position = config.grid.fullScreen,
    quitGuard = true,
    ignoredWindows = {'Slack Call Minipanel'},
    handler = (function(win)
      local appName = appHandler(win)

      -- keys.remap(appName, {'ctrl'},          'k', {'alt'},          'up')
      -- keys.remap(appName, {'ctrl'},          'j', {'alt'},          'down')
      -- keys.remap(appName, {'ctrl'},          'g', {'cmd'},          'k')
      -- keys.remap(appName, {'ctrl', 'shift'}, 'k', {'alt', 'shift'}, 'down')
      -- keys.remap(appName, {'ctrl', 'shift'}, 'j', {'alt', 'shift'}, 'up')
      -- keys.remap(appName, {'cmd'},           'w', {},               'esc')
    end)
  },
  ['com.readdle.smartemail-Mac'] = {
    hint = 'com.readdle.smartemail-Mac',
    superKey = config.superKeys.mashShift,
    distraction = true,
    shortcut = 'm',
    preferredDisplay = 2,
    -- position = config.grid.rightHalf
    -- position = config.grid.rightTwoThirds
    position = config.grid.fullScreen,
  },
  ['com.apple.finder'] = {
    hint = 'com.apple.finder',
    superKey = config.superKeys.ctrl,
    shortcut = '`',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
  ['us.zoom.xos'] = {
    hint = 'us.zoom.xos',
    superKey = config.superKeys.mashShift,
    shortcut = 'z',
    preferredDisplay = 1,
    position = config.grid.fullScreen,
    dnd = { enabled = false,  mode = "zoom" },
  },
  ['com.spotify.client'] = {
    hint = 'com.spotify.client',
    superKey = config.superKeys.cmdShift,
    shortcut = '8',
    preferredDisplay = 2,
    -- position = '5,0 5x5'
    position = config.grid.rightHalf
  },
  ['com.apple.iChat'] = {
    hint = 'com.apple.iChat',
    superKey = config.superKeys.cmdShift,
    shortcut = 'm',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['WhatsApp'] = {
    hint = 'WhatsApp',
    superKey = config.superKeys.cmdShift,
    shortcut = 'w',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['com.agilebits.onepassword7'] = {
    hint = 'com.agilebits.onepassword7',
    superKey = config.superKeys.mashShift,
    shortcut = '1',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
  ['com.teamviewer.TeamViewer'] = {
    hint = 'com.teamviewer.TeamViewer',
    -- superKey = config.superKeys.mashShift,
    -- shortcut = 'v',
    preferredDisplay = 1,
    position = config.grid.centeredLarge
  },
  ['org.hammerspoon.Hammerspoon'] = {
    hint = 'org.hammerspoon.Hammerspoon',
    superKey = config.superKeys.mashShift,
    shortcut = 'h',
    preferredDisplay = 2,
    position = config.grid.centeredMedium,
    quitGuard = true,
  },
  ['com.apple.systempreferences'] = {
    hint = 'com.apple.systempreferences',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
  ['Fantastical'] = {
    name = 'Fantastical',
    hint = 'com.flexibits.fantastical2.mac',
    -- superKey = config.superKeys.cmdShift,
    -- shortcut = 'f',
    preferredDisplay = 1,
    position = config.grid.centeredLarge
  },
  ['85C27NK92C.com.flexibits.fantastical2.mac.helper'] = {
    name = 'Fantastical Helper',
    hint = '85C27NK92C.com.flexibits.fantastical2.mac.helper',
    -- superKey = config.superKeys.cmdShift,
    -- shortcut = 'f',
    preferredDisplay = 1,
    -- position = config.grid.centeredLarge
  },
  ['com.microsoft.autoupdate2'] = {
    name = 'Microsoft AutoUpdate',
    hint = 'com.microsoft.autoupdate2',
    -- superKey = config.superKeys.cmdShift,
    -- shortcut = 'f',
    preferredDisplay = 1,
    -- position = config.grid.centeredLarge
    handler = (function(win)
      -- AUTOHIDE
      win:application():hide()
    end)
  }
}

config.utilities = {
  {
    name = 'Hammerspoon Console',
    superKey = config.superKeys.ctrlAlt,
    shortcut = 'r',
    fn = function() hs.toggleConsole() end
  },
  -- NOTE: handle this with alfred and `sleep`/`lock` commands
  -- {
  --   name = 'Lock Screen',
  --   superKey = config.superKeys.mashShift,
  --   shortcut = 'L',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  -- {
  --   name = 'Pomodoro',
  --   superKey = config.superKeys.mashShift,
  --   shortcut = 'P',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  {
    name = 'Hammerspoon Reload',
    superKey = config.superKeys.mashShift,
    shortcut = 'r',
    fn = (function()
      -- require('auto-layout').teardown()
      -- require('layout').teardown()
      -- require('dock').teardown()
      -- require('ptt').teardown()
      hs.reload()
      hs.notify.show('Hammerspoon', 'Config Reloaded', '')
    end)
  },
  {
    name = 'Cursor Locator',
    superKey = config.superKeys.mashShift,
    shortcut = 'return',
    fn = (function()
      mouse.highlight()
    end)
  },
  {
    name = 'Re-layout All',
    superKey = config.superKeys.mashShift,
    shortcut = 'w',
    fn = (function()
      hs.alert.show("Relayout of all apps")
      require('layout').setLayoutForAll()
    end)
  },
  {
    name = 'Re-layout App',
    superKey = config.superKeys.ctrlShift,
    shortcut = 'w',
    fn = (function()
      local app = hs.application.frontmostApplication()
      hs.alert.show("Relayout of single app (" .. app:name() .. ")")
      require('layout').setLayoutForApp(app)
    end)
  },
  {
    name = 'Toggle Airpods',
    superKey = config.superKeys.cmdCtrl,
    shortcut = 'a',
    fn = (function()
      local ok, output = airpods.toggle('replipods')
      if ok then
        hs.alert.show(output)
      else
        hs.alert.show("Couldn't connect to AirPods!")
      end
    end)
  },
  {
    name = 'Pomodoro',
    superKey = config.superKeys.cmdCtrl,
    shortcut = 'p',
    fn = (function()
      -- local ok, output = airpods.toggle('replipods')
      -- if ok then
      --   hs.alert.show(output)
      -- else
      --   hs.alert.show("Couldn't connect to AirPods!")
      -- end
    end)
  }
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
}

config.volume = {
  {
    action = 'down',
    superKey = config.superKeys.ctrlShift,
    shortcut = 27,
    diff = -5,
  },
  {
    action = 'up',
    superKey = config.superKeys.ctrlShift,
    shortcut = 24,
    diff = 5,
  },
  {
    action = 'mute',
    superKey = config.superKeys.mashShift,
    shortcut = '\\',
  },
}

config.snap = {
  {
    name = 'left',
    superKey = config.superKeys.cmdCtrl,
    -- hyperKey = config.superKeys.hyper,
    shortcut = 'h',
    locations = utils.chain({
      config.grid.leftHalf,
      config.grid.leftOneThird,
      config.grid.leftTwoThirds,
    })
  },
  {
    name = 'right',
    superKey = config.superKeys.cmdCtrl,
    -- hyperKey = config.superKeys.hyper,
    shortcut = 'l',
    locations = utils.chain({
      config.grid.rightHalf,
      config.grid.rightOneThird,
      config.grid.rightTwoThirds,
    })
  },
  {
    name = 'down',
    superKey = config.superKeys.cmdCtrl,
    -- hyperKey = config.superKeys.hyper,
    shortcut = 'j',
    locations = utils.chain({
      config.grid.centeredLarge,
      config.grid.centeredMedium,
      config.grid.centeredSmall,
    })
  },
  {
    name = 'up',
    superKey = config.superKeys.cmdCtrl,
    -- hyperKey = config.superKeys.hyper,
    shortcut = 'k',
    locations = utils.chain({
      config.grid.fullScreen,
    })
  },
  {
    name = 'full',
    superKey = config.superKeys.cmdCtrl,
    -- hyperKey = config.superKeys.hyper,
    shortcut = 'return',
    locations = utils.chain({
      config.grid.fullScreen,
    })
  },
  -- {
  --   name = 'full',
  --   superKey = config.superKeys.cmdCtrl,
  --   -- hyperKey = config.superKeys.hyper,
  --   shortcut = 'return',
  --   locations = (function()
  --   -- toggle the focused window to full screen (workspace)
  --   local win = hs.window.focusedWindow()
  --     win:setFullScreen(not win:isFullScreen())
  --   end)
  -- },
}

config.docking = {
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

return config
