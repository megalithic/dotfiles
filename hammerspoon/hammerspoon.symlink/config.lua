local log = hs.logger.new('[config]', 'warning')

-- TODO:
-- - investigate using hs.settings: https://github.com/rsefer/hammerspoon-config/blob/master/lib/settings.lua

-- grid config
hs.grid.GRIDWIDTH = 8
hs.grid.GRIDHEIGHT = 8
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- available and preferred displays
local displays = {
  laptop = 'Color LCD',
  external = 'Dell P2415Q'
}

local module = {
  network = {
    home = 'shaolin',
    hostname = hs.host.localizedName(),
    currentConnected = hs.wifi.currentNetwork()
  },

  preferred = {
    terms    = { 'kitty' },
    browsers = { 'Brave Browser Dev', 'Firefox', 'Google Chrome', 'Safari' }
  },

  displays = displays,

  window = {
    highlightBorder = false,
    highlightMouse  = true,
    historyLimit    = 0
  },

  office = {
    -- studioSpeakers = { aid = 10, iid = 11, name = "Studio Speakers" },
    -- studioLights   = { aid = 9,  iid = 11, name = "Studio Lights"   },
    -- tvLights       = { aid = 6,  iid = 11, name = "TV Lights"       }
  },

  grid =  {
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
  },

  modifiers = {
    ctrl =            {'ctrl'},
    cmd =             {'cmd'},
    cmdAlt =          {'cmd', 'alt'},
    cmdShift =        {'cmd', 'shift'},
    ctrlShift =       {'ctrl', 'shift'},
    cmdCtrl =         {'cmd', 'ctrl'},
    ctrlAlt =         {'ctrl', 'alt'},
    mashShift =       {'cmd', 'ctrl', 'shift'},
    mash =            {'cmd', 'alt', 'ctrl'},
    ultra =           {'cmd', 'alt', 'ctrl', 'shift' },
    hyper =           'F19',
  },


  -- REF for url handling: https://github.com/sjthespian/dotfiles/blob/master/hammerspoon/config.lua#L76
  distractionUrls = {
    'https://www.youtube.com',
    'https://www.twitter.com',
    'https://www.instagram.com',
    'https://www.facebook.com',
    'https://www.reddit.com',
  },
}

module.ptt = module.modifiers.cmdAlt

module.apps = {
  ['net.kovidgoyal.kitty'] = {
    id = 'net.kovidgoyal.kitty',
    name = 'kitty',
    hyper_key = 'k',
    -- modifier = module.modifiers.ctrl,
    -- shortcut = 'space',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    quitGuard = true,
  },
  ['com.brave.Browser.dev'] = {
    id = 'com.brave.Browser.dev',
    name = 'Brave Browser Dev',
    hyper_key = 'j',
    -- modifier = module.modifiers.cmd,
    -- shortcut = '`',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    quitGuard = true,
  },
  ['com.google.Chrome'] = {
    id = 'com.google.Chrome',
    name = 'Google Chrome',
    preferredDisplay = 1,
    position = module.grid.rightHalf,
    quitGuard = true
  },
  ['com.agiletortoise.Drafts-OSX'] = {
    id = 'com.agiletortoise.Drafts-OSX',
    name = 'Drafts',
    hyper_key ='n',
    local_bindings = {'x', ';'},
    modifier = module.modifiers.mashShift,
    shortcut = 'n',
    preferredDisplay = 1,
    position = module.grid.rightHalf,
    quitGuard = false,
    rules = {
      {title = 'Workspaces', rule = 'ignore'},
    },
  },
  ['com.kapeli.dashdoc'] = {
    id = 'com.kapeli.dashdoc',
    name = 'Dash',
    preferredDisplay = 1,
    position = module.grid.centeredLarge,
  },
  ['com.brettterpstra.marked2'] = {
    id = 'com.brettterpstra.marked2',
    name = 'Marked',
    preferredDisplay = 2,
    position = module.grid.leftHalf,
  },
  ['com.tinyspeck.slackmacgap'] = {
    id = 'com.tinyspeck.slackmacgap',
    name = 'Slack',
    hyper_key ='s',
    modifier = module.modifiers.mashShift,
    shortcut = 's',
    distraction = true,
    preferredDisplay = 2,
    position = module.grid.fullScreen,
    quitGuard = true,
    hideAfter = 5,
    rules = {
      {title = 'Slack Call Minipanel', rule = 'ignore'},
    },
  },
  ['com.readdle.smartemail-Mac'] = {
    id = 'com.readdle.smartemail-Mac',
    name = 'Spark',
    modifier = module.modifiers.mashShift,
    distraction = true,
    shortcut = 'm',
    preferredDisplay = 2,
    hideAfter = 5,
    position = module.grid.fullScreen,
  },
  ['com.apple.finder'] = {
    id = 'com.apple.finder',
    name = 'Finder',
    hyper_key ='f',
    -- modifier = module.modifiers.ctrl,
    -- shortcut = '`',
    preferredDisplay = 1,
    position = module.grid.centeredMedium
  },
  ['us.zoom.xos'] = {
    id = 'us.zoom.xos',
    name = 'zoom.us',
    -- modifier = module.modifiers.mashShift,
    -- shortcut = 'z',
    hyper_key ='z',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    dnd = { enabled = true, mode = "zoom" },
    rules = {
      {title = 'Zoom', rule = 'quit'},
      {title = 'Zoom Meeting', rule = 'snap'},
    },
  },
  ['com.spotify.client'] = {
    id = 'com.spotify.client',
    name = 'Spotify',
    -- modifier = module.modifiers.cmdShift,
    -- shortcut = '8',
    hyper_key ='8',
    preferredDisplay = 2,
    hideAfter = 1,
    position = module.grid.rightHalf
  },
  ['com.apple.iChat'] = {
    id = 'com.apple.iChat',
    name = 'Messages',
    -- modifier = module.modifiers.cmdShift,
    -- shortcut = 'm',
    hyper_key ='m',
    distraction = true,
    preferredDisplay = 1,
    hideAfter = 1,
    position = '5,5 3x3'
  },
  ['hangouts'] = {
    id = 'hangouts',
    name = 'Brave Browser Dev',
    modifier = module.modifiers.cmdCtrl,
    shortcut = 'm',
    distraction = true,
    preferredDisplay = 1,
    tabjump = 'hangouts.google.com'
  },
  ['WhatsApp'] = {
    id = 'WhatsApp',
    name = 'WhatsApp',
    modifier = module.modifiers.cmdShift,
    shortcut = 'w',
    distraction = true,
    preferredDisplay = 1,
    hideAfter = 1,
    position = '5,5 3x3'
  },
  ['com.agilebits.onepassword7'] = {
    id = 'com.agilebits.onepassword7',
    name = '1Password',
    modifier = module.modifiers.mashShift,
    shortcut = '1',
    preferredDisplay = 1,
    hideAfter = 1,
    position = module.grid.centeredMedium
  },
  ['com.teamviewer.TeamViewer'] = {
    id = 'com.teamviewer.TeamViewer',
    name = 'TeamViewer',
    -- modifier = module.modifiers.mashShift,
    -- shortcut = 'v',
    preferredDisplay = 1,
    position = module.grid.centeredLarge
  },
  ['org.hammerspoon.Hammerspoon'] = {
    id = 'org.hammerspoon.Hammerspoon',
    name = 'Hammerspoon',
    modifier = module.modifiers.mashShift,
    shortcut = 'h',
    preferredDisplay = 2,
    hideAfter = 1,
    position = module.grid.rightHalf,
    quitGuard = true,
  },
  ['com.apple.systempreferences'] = {
    id = 'com.apple.systempreferences',
    name = 'System Preferences',
    preferredDisplay = 1,
    position = module.grid.centeredMedium
  },
  ['com.flexibits.fantastical2.mac'] = {
    id = 'com.flexibits.fantastical2.mac',
    name = 'Fantastical',
    -- modifier = module.modifiers.mashShift,
    -- shortcut = 'f',
    hyper_key ='y',
    local_bindings = {']'},
    preferredDisplay = 1,
    position = module.grid.centeredLarge,
    quitGuard = true,
    hideAfter = 1,
    rules = {
      { title="Fantastical Helper", rule="ignore" }
    }
  },
  -- -- FIXME: should this move to the `rules` table for the main app?
  -- ['85C27NK92C.com.flexibits.fantastical2.mac.helper'] = {
  --   id = '85C27NK92C.com.flexibits.fantastical2.mac.helper',
  --   name = 'Fantastical Helper',
  --   -- modifier = module.modifiers.cmdShift,
  --   -- shortcut = 'f',
  --   preferredDisplay = 1,
  --   quitGuard = true,
  --   -- position = module.grid.centeredLarge
  -- },
  ['com.microsoft.autoupdate2'] = {
    id = 'com.microsoft.autoupdate2',
    name = 'Microsoft AutoUpdate',
    preferredDisplay = 1,
    quitAfter = 0,
    -- handler = (function(win)
    --   -- AUTOHIDE
    --   win:application():hide()
    -- end)
  }
}


-- Helpers to get various app config settings
module.getAppConfigForWin = function(win)
  local appBundleId = win:application():bundleID()
  local appConfig = module.apps[appBundleId]

  return appConfig
end

module.getAppConfigForApp = function(appName)
  local found
  for _, hash in pairs(module.apps) do
    if (hash.name == appName) then
      found = hash

      return found
    end
  end

  return found
end

module.rulesExistForAppConfig = function(appConfig)
  return appConfig.rules ~= nil and #appConfig.rules > 0
end

module.rulesExistForWin = function(win)
  local appConfig = module.getAppConfigForWin(win)
  local rulesExist = appConfig.rules ~= nil and #appConfig.rules > 0

  return rulesExist
end

module.ruleExistsForWin = function(win, rule)
  local appConfig = module.getAppConfigForWin(win)
  local targetRule = {title = win:title(), rule = rule}
  local rulesExist = module.rulesExistForWin(win)
  local ruleExists = false

  if rulesExist then
    foundRule = hs.fnutils.find(appConfig.rules, function(datum)
      return hs.inspect(datum) == hs.inspect(targetRule)
    end)

    ruleExists = rulesExist and foundRule ~= nil
  end

  if ruleExists then
    log.df("Found rule (%s) found for %s", rule, win:title())
  else
    log.df("No rule (%s) found for %s", rule, win:title())
  end

  return ruleExists
end


module.utilities = {
  {
    name = 'Hammerspoon Console',
    modifier = module.modifiers.ctrlAlt,
    shortcut = 'r',
    fn = function() hs.toggleConsole() end
  },
  -- NOTE: handle this with alfred and `sleep`/`lock` commands
  -- {
  --   name = 'Lock Screen',
  --   modifier = module.modifiers.mashShift,
  --   shortcut = 'L',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  -- {
  --   name = 'Pomodoro',
  --   modifier = module.modifiers.mashShift,
  --   shortcut = 'P',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  {
    name = 'Hammerspoon Reload',
    modifier = module.modifiers.mashShift,
    shortcut = 'r',
    fn = (function()
      hs.reload()
      hs.notify.show('Hammerspoon', 'Modules Reloaded', '')
    end)
  },
  {
    name = 'Pomodoro',
    modifier = module.modifiers.cmdCtrl,
    shortcut = 'p',
    fn = (function() end)
  },
  {
    name = 'ScreenCapture',
    modifier = module.modifiers.ctrlShift,
    shortcut = 's',
    fn = (function()
      current_date = os.date('%Y%m%d-%H%M%S')
      filename = "capture_" .. current_date .. ".png"
      capture_target = "~/Dropbox/captures/"..filename
      print("SCREENCAPTURE: "..hs.inspect(capture_target))

      -- hs.execute("screencapture -i ~/Dropbox/captures/shot_`date '+%Y-%m-%d_%H-%M-%S'`.png");
    end)
  }
}

module.media = {
  {
    action = 'previous',
    modifier = module.modifiers.ctrlShift,
    shortcut = '[',
    label = '⇤ previous'
  },
  {
    action = 'next',
    modifier = module.modifiers.ctrlShift,
    shortcut = ']',
    label = 'next ⇥'
  },
  {
    action = 'playpause',
    modifier = module.modifiers.ctrlShift,
    shortcut = '\\',
    label = 'play/pause'
  },
}

module.volume = {
  {
    action = 'down',
    modifier = module.modifiers.ctrlShift,
    shortcut = 27,
    diff = -5,
  },
  {
    action = 'up',
    modifier = module.modifiers.ctrlShift,
    shortcut = 24,
    diff = 5,
  },
  {
    action = 'mute',
    modifier = module.modifiers.mashShift,
    shortcut = '\\',
  },
}

module.snap = {
  {
    name = 'left',
    modifier = module.modifiers.cmdCtrl,
    -- hyperKey = module.modifiers.hyper,
    shortcut = 'h',
    locations = {
      module.grid.leftHalf,
      module.grid.leftOneThird,
      module.grid.leftTwoThirds,
    }
  },
  {
    name = 'right',
    modifier = module.modifiers.cmdCtrl,
    -- hyperKey = module.modifiers.hyper,
    shortcut = 'l',
    locations = {
      module.grid.rightHalf,
      module.grid.rightOneThird,
      module.grid.rightTwoThirds,
    }
  },
  {
    name = 'down',
    modifier = module.modifiers.cmdCtrl,
    -- hyperKey = module.modifiers.hyper,
    shortcut = 'j',
    locations = {
      module.grid.centeredLarge,
      module.grid.centeredMedium,
      module.grid.centeredSmall,
    }
  },
  {
    name = 'up',
    modifier = module.modifiers.cmdCtrl,
    -- hyperKey = module.modifiers.hyper,
    shortcut = 'k',
    locations = {
      module.grid.fullScreen,
    }
  },
  {
    name = 'full',
    modifier = module.modifiers.cmdCtrl,
    -- hyperKey = module.modifiers.hyper,
    shortcut = 'return',
    locations = {
      module.grid.fullScreen,
    }
  },
}

module.docking = {
  -- find your device IDs with `dumpUsbDevices()` (see console.lua) from the hammerspoon console
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

return module
