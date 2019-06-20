local airpods = require('airpods')
local utils = require('utils')
local hotkey = require('hs.hotkey')
local log = require('log')

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

config.ignoredApplications = { 'iStat Menus Status', 'Fantastical' }

config.applications = {
  ['default'] = {
    name = '',
    bundleID = '',
    preferredDisplay = 2,
    position = config.grid.centeredMedium,
  },
  ['kitty'] = {
    name = 'kitty',
    bundleID = 'net.kovidgoyal.kitty',
    superKey = config.superKeys.ctrl,
    shortcut = 'space',
    preferredDisplay = 1,
    position = config.grid.fullScreen,
    quitGuard = true,
  },
  ['Dash'] = {
    name = 'Dash',
    bundleID = 'com.kapeli.dashdoc',
    preferredDisplay = 1,
    position = config.grid.centeredLarge,
  },
  ['Google Chrome'] = {
    name = 'Google Chrome',
    bundleID = 'com.google.Chrome',
    superKey = config.superKeys.cmdCtrl,
    shortcut = '`',
    preferredDisplay = 1,
    position = config.grid.fullScreen,
    quitGuard = true
  },
  ['Brave Browser Dev'] = {
    name = 'Brave Browser Dev',
    bundleID = 'com.brave.Browser.dev',
    superKey = config.superKeys.cmd,
    shortcut = '`',
    preferredDisplay = 1,
    position = config.grid.fullScreen,
    quitGuard = true
  },
  ['Drafts'] = {
    name = 'Drafts',
    -- bundleID = 'com.tinyspeck.slackmacgap',
    -- superKey = config.superKeys.mashShift,
    -- shortcut = 's',
    windows = {
      ['Capture'] = {
        position = '5,0 5x5',
        preferredDisplay = 1
      },
      ['Drafts'] = {
        position = config.grid.centeredLarge,
        preferredDisplay = 1
      },
    },
    preferredDisplay = 1,
    position = config.grid.centeredMedium,
    quitGuard = false,
  },
  ['Slack'] = {
    name = 'Slack',
    bundleID = 'com.tinyspeck.slackmacgap',
    superKey = config.superKeys.mashShift,
    shortcut = 's',
    preferredDisplay = 2,
    position = config.grid.rightHalf,
    quitGuard = true,
    ignoredWindows = {'Slack Call Minipanel'},
    fn = (function(_)
      log.df('[config] app fn() - attempting to handle Slack instance')

      local appKeybinds = {
        -- next channel or dm
        -- hotkey.new({"ctrl"}, "g", function()
        --   hs.eventtap.keyStroke({"cmd"}, "k")
        -- end),

        -- -- next channel or dm
        -- hotkey.new({"ctrl"}, "j", function()
        --   hs.eventtap.keyStroke({"alt"}, "Down")
        -- end),
        -- -- previous channel or dm
        -- hotkey.new({"ctrl"}, "k", function()
        --   hs.eventtap.keyStroke({"alt"}, "Up")
        -- end),
        -- next unread channel or dm
        hotkey.new({"ctrl", "shift"}, "j", function()
          hs.eventtap.keyStroke({"alt", "shift"}, "Down")
        end),
        -- previous unread channel or dm
        hotkey.new({"ctrl", "shift"}, "k", function()
          hs.eventtap.keyStroke({"alt", "shift"}, "Up")
        end),
        -- -- Disables cmd-w entirely, which is so annoying on slack
        -- hotkey.new({"cmd"}, "w", function() return end)
      }

      local appWatcher = hs.application.watcher.new(function(name, eventType, _)
        if eventType ~= hs.application.watcher.activated then return end

        local fnName = name == "Slack" and "enable" or "disable"
        for _, keybind in ipairs(appKeybinds) do
          -- Remember that lua is weird, so this is the same as keybind.enable() in JS, `this` is first param
          keybind[fnName](keybind)
        end
      end)

      appWatcher:start()
    end)
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
    bundleID = 'com.apple.finder',
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
    position = config.grid.centeredLarge,
    dnd = true,
  },
  ['Spotify'] = {
    name = 'Spotify',
    bundleID = 'com.spotify.client',
    superKey = config.superKeys.cmdShift,
    shortcut = '8',
    preferredDisplay = 1,
    position = '5,0 5x5'
  },
  ['Messages'] = {
    name = 'Messages',
    bundleID = 'com.apple.iChat',
    superKey = config.superKeys.cmdShift,
    shortcut = 'm',
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['YakYak'] = {
    name = 'YakYak',
    bundleID = 'com.github.yakyak',
    -- superKey = config.superKeys.ctrlShift,
    -- shortcut = 'm',
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['1Password 7'] = {
    name = '1Password 7',
    bundleID = 'com.agilebits.onepassword7',
    superKey = config.superKeys.mashShift,
    shortcut = '1',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
  ['Hammerspoon'] = {
    name = 'Hammerspoon',
    bundleID = 'org.hammerspoon.Hammerspoon',
    preferredDisplay = 2,
    position = config.grid.centeredMedium,
    quitGuard = true,
  },
  ['System Preferences'] = {
    name = 'System Preferences',
    bundleID = 'com.apple.systempreferences',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
  ['Fantastical'] = {
    name = 'Fantastical',
    bundleID = 'com.flexibits.fantastical2.mac',
    preferredDisplay = 1,
    position = config.grid.centeredMedium
  },
}

config.utilities = {
  {
    name = 'Hammerspoon Console',
    superKey = config.superKeys.ctrlAlt,
    shortcut = 'r',
    fn = function() hs.toggleConsole() end
  },
  {
    name = 'Lock Screen',
    superKey = config.superKeys.mashShift,
    shortcut = 'L',
    fn = function() hs.caffeinate.systemSleep() end
  },
  {
    name = 'Hammerspoon Reload',
    superKey = config.superKeys.mashShift,
    shortcut = 'r',
    fn = (function()
      require('auto-layout').teardown()
      require('laptop-docking-mode').teardown()
      require('push-to-talk').teardown()
      hs.reload()
      hs.notify.show('Hammerspoon', 'Config Reloaded', '')
    end)
  },
  {
    name = 'Cursor Locator',
    superKey = config.superKeys.mashShift,
    shortcut = 'return',
    fn = (function()
      utils.mouseHighlight()
    end)
  },
  {
    name = 'Re-layout All',
    superKey = config.superKeys.mashShift,
    shortcut = 'w',
    fn = (function()
      require('auto-layout').snapAll()
    end)
  },
  {
    name = 'Re-layout App',
    superKey = config.superKeys.cmdCtrl,
    shortcut = 'w',
    fn = (function()
      require('auto-layout').snapApp(hs.application.frontmostApplication())
    end)
  },
  {
    name = 'Toggle Airpods',
    superKey = config.superKeys.cmdCtrl,
    shortcut = 'a',
    fn = (function()
      local ok, output = airpods('replipods')
      if ok then
        hs.alert.show(output)
      else
        hs.alert.show("Couldn't connect to AirPods!")
      end
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
    hyperKey = config.superKeys.hyper,
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
    hyperKey = config.superKeys.hyper,
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
    hyperKey = config.superKeys.hyper,
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
    hyperKey = config.superKeys.hyper,
    shortcut = 'k',
    locations = utils.chain({
      config.grid.fullScreen,
    })
  }
}

config.docking = {
  -- find your device IDs with `print(hs.inspect(hs.usb.attachedDevices()))` from the hammerspoon console
  ['device'] = {
    productID = 8800,
    productName = "DZ60",
    vendorID = 65261,
    vendorName = "KBDFans"
  },
  ['docked'] = {
    wifi = 'off', -- wifi status
    profile = 'dz60', -- Karabiner-Elements profile name
    input = '"Samson GoMic"', -- microphone source
    output = '"CalDigit Thunderbolt 3 Audio"', -- speaker source
  },
  ['undocked'] = {
    wifi = 'on',
    profile = 'internal',
    input = '"MacBook Pro Microphone"',
    output = '"MacBook Pro Speakers"',
  },
}

-- log.d('Found the following attached USB devices:\r\n')
-- log.d('---------------------------------------------')
-- log.d(print(hs.inspect(hs.usb.attachedDevices())))
-- log.d('---------------------------------------------')

return config
