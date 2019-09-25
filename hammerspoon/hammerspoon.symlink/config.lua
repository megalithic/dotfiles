local log = hs.logger.new('config|', 'debug')

local utils = require('utils')
local hotkey = require('hs.hotkey')
local airpods = require('airpods')
local mouse = require('mouse')

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
    -- handler = function(win)
    --   if win == nil then return end
    --   local appBundleID = win:application():bundleID()
    --   local visibleWindows = win:application():visibleWindows()
    --   log.df('executing app handler for %s instance, for %s windows..', appBundleID, #visibleWindows)
    -- end
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
    position = config.grid.rightHalf,
    quitGuard = true,
    ignoredWindows = {'Slack Call Minipanel'},
    handler = (function(win)
      if win == nil then return end

      -- if appWatcher ~= nil then
      --   appWatcher:stop()
      --   appWatcher = nil
      -- end

      local appBundleID = win:application():bundleID()
      local visibleWindows = win:application():visibleWindows()
      log.df('executing app handler for %s instance, for %s windows..', appBundleID, #visibleWindows)

      local appKeybinds = {
        -- quick search/jump
        -- hotkey.new({"ctrl"}, "g", function()
        --   hs.eventtap.keyStroke({"cmd"}, "k")
        -- end),
        -- next channel or dm
        -- hotkey.new({"ctrl"}, "j", function()
        --   hs.eventtap.keyStroke({"alt"}, "Down")
        -- end),
        -- previous channel or dm
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
        -- Disables cmd-w entirely, which is so annoying on slack
        -- hotkey.new({"cmd"}, "w", function()
        --   hs.eventtap.keyStroke({""}, "Esc")
        -- end)
      }

      -- FIXME: find a better way than spinning up this app watcher.
      -- REF for more info/digging: https://github.com/agzam/spacehammer/blob/4666c81111c4cd402736cf7b1e5da249dbcfa9b5/slack.lua#L10
      -- local appWatcher = hs.application.watcher.new(function(name, eventType, _)
      --   if eventType ~= hs.application.watcher.activated then return end

      --   local fnName = name == "Slack" and "enable" or "disable"
      --   for _, keybind in ipairs(appKeybinds) do
      --     -- Remember that lua is weird, so this is the same as keybind.enable() in JS, `this` is first param
      --     keybind[fnName](keybind)
      --   end
      -- end)

      -- appWatcher:start()

      -- local appWatcherHandler = function(appName, eventType, appObject)
      --   log.df("appName: %s | eventType: %s | appObject: %s", appName, eventType, hs.inspect( appObject ))

      --   if (eventType == hs.application.watcher.activated) then
      --     log.df("activated")
      --   elseif (eventType == hs.application.watcher.deactivated) then
      --       log.df("deactivated")
      --     localAppWatcher:stop()
      --   end
      -- end

      -- localAppWatcher = hs.application.watcher.new(appWatcherHandler)
      -- localAppWatcher:start()
    end)
  },
  ['com.readdle.smartemail-Mac'] = {
    hint = 'com.readdle.smartemail-Mac',
    superKey = config.superKeys.mashShift,
    distraction = true,
    shortcut = 'm',
    preferredDisplay = 2,
    position = config.grid.rightHalf
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
    position = config.grid.centeredLarge,
    dnd = { enabled = true,  mode = "zoom" },
  },
  ['com.spotify.client'] = {
    hint = 'com.spotify.client',
    superKey = config.superKeys.cmdShift,
    shortcut = '8',
    preferredDisplay = 1,
    position = '5,0 5x5'
  },
  ['com.apple.iChat'] = {
    hint = 'com.apple.iChat',
    superKey = config.superKeys.cmdShift,
    shortcut = 'm',
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
  -- ['Fantastical'] = {
  --   name = 'Fantastical',
  --   hint = 'com.flexibits.fantastical2.mac',
  --   -- superKey = config.superKeys.cmdShift,
  --   -- shortcut = 'f',
  --   preferredDisplay = 1,
  --   position = config.grid.centeredMedium
  -- },
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
  -- {
  --   name = 'Re-layout All',
  --   superKey = config.superKeys.mashShift,
  --   shortcut = 'w',
  --   fn = (function()
  --     require('layout').snapAll()
  --   end)
  -- },
  -- {
  --   name = 'Re-layout App',
  --   superKey = config.superKeys.cmdCtrl,
  --   shortcut = 'w',
  --   fn = (function()
  --     require('layout').snapApp(hs.application.frontmostApplication())
  --   end)
  -- },
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
    fontSize = 18.0,
  },
  ['undocked'] = {
    wifi = 'on',
    profile = 'internal',
    input = '"MacBook Pro Microphone"',
    output = '"MacBook Pro Speakers"',
    fontSize = 15.0,
  },
}

-- log.d('Found the following attached USB devices:\r\n')
-- log.d('---------------------------------------------')
-- log.d(print(hs.inspect(hs.usb.attachedDevices())))
-- log.d('---------------------------------------------')

return config
