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
  external = 'LG UltraFine'
}

local module = {
  network = {
    home = 'shaolin',
    hostname = hs.host.localizedName(),
    currentConnected = hs.wifi.currentNetwork()
  },

  preferred = {
    terms    = { 'kitty' },
    browsers = { 'Brave Browser', 'Brave Browser Dev', 'Firefox', 'Google Chrome', 'Safari' },
    vpn = { 'ExpressVPN' }
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
    ultra =           {'cmd', 'alt', 'ctrl', 'shift'},
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
    bundleID = 'net.kovidgoyal.kitty',
    name = 'kitty',
    hyper_key = 'k',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    quitGuard = true,
  },
  ['com.brave.Browser'] = {
    bundleID = 'com.brave.Browser',
    name = 'Brave Browser',
    hyper_key = 'j',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    quitGuard = true,
  },
  ['com.insomnia.app'] = {
    bundleID = 'com.insomnia.app',
    name = 'Insomnia',
    hyper_key ='i',
    preferredDisplay = 1,
    position = module.grid.rightHalf,
    quitGuard = false
  },
  ['com.runningwithcrayons.Alfred'] = {
    name = 'Alfred',
    bundleID = 'com.runningwithcrayons.Alfred',
    local_bindings = {'c', 'space', 'o'},
  },
  ['com.agiletortoise.Drafts-OSX'] = {
    bundleID = 'com.agiletortoise.Drafts-OSX',
    name = 'Drafts',
    -- hyper_key ='d',
    local_bindings = {';'},
    preferredDisplay = 1,
    position = module.grid.rightHalf,
    quitGuard = false,
    hideAfter = 1,
    -- rules = {
    --   {title = 'Workspaces', rule = 'ignore'},
    --   {title = 'Capture', rule = 'snap', position = '5,5 3x3'},
    -- },
  },
  ['com.culturedcode.ThingsMac'] = {
    bundleID = 'com.culturedcode.ThingsMac',
    name = 'Things',
    hyper_key = 't',
    preferred_display = 1,
    hideAfter = 1,
    position = module.grid.centeredMedium,
    local_bindings = {',', '.'}
  },
  ['com.kapeli.dashdoc'] = {
    bundleID = 'com.kapeli.dashdoc',
    name = 'Dash',
    hyper_key = 'd',
    preferredDisplay = 1,
    position = module.grid.centeredLarge,
  },
  ['com.brettterpstra.marked2'] = {
    bundleID = 'com.brettterpstra.marked2',
    name = 'Marked',
    preferredDisplay = 2,
    position = module.grid.leftHalf,
  },
  ['com.tinyspeck.slackmacgap'] = {
    bundleID = 'com.tinyspeck.slackmacgap',
    name = 'Slack',
    hyper_key ='s',
    context = 'slack',
    distraction = true,
    preferredDisplay = 2,
    position = module.grid.leftHalf,
    quitGuard = true,
  },
  ['io.canarymail.mac'] = {
    bundleID = 'io.canarymail.mac',
    name = 'Canary Mail',
    hyper_key ='e',
    context = 'canary',
    distraction = true,
    preferredDisplay = 2,
    position = module.grid.rightHalf,
  },
  ['com.apple.finder'] = {
    bundleID = 'com.apple.finder',
    name = 'Finder',
    hyper_key ='f',
    preferredDisplay = 1,
    position = module.grid.centeredMedium,
    rules = {
      {title = 'Finder Preferences', rule = 'ignore'},
    },
  },
  ['us.zoom.xos'] = {
    bundleID = 'us.zoom.xos',
    name = 'zoom.us',
    context = 'zoom',
    hyper_key ='z',
    preferredDisplay = 1,
    position = module.grid.fullScreen,
    launchMode = 'focus',
  },
  ['com.loom.desktop'] = {
    bundleID = 'com.loom.desktop',
    name = 'Loom',
    context = 'loom',
    dnd = { enabled = true, mode = "loom" },
  },
  ['com.spotify.client'] = {
    bundleID = 'com.spotify.client',
    name = 'Spotify',
    hyper_key ='8',
    preferredDisplay = 2,
    hideAfter = 1,
    position = module.grid.rightHalf
  },
  ['com.apple.iChat'] = {
    bundleID = 'com.apple.iChat',
    name = 'Messages',
    hyper_key ='m',
    context = 'messages',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['hangouts'] = {
    bundleID = 'hangouts',
    name = 'Hangouts',
    modifier = module.modifiers.cmdCtrl,
    shortcut = 'm',
    distraction = true,
    preferredDisplay = 1,
    tabjump = 'hangouts.google.com'
  },
  ['WhatsApp'] = {
    bundleID = 'WhatsApp',
    name = 'WhatsApp',
    hyper_key ='w',
    context = 'whatsapp',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3'
  },
  ['com.agilebits.onepassword7'] = {
    bundleID = 'com.agilebits.onepassword7',
    name = '1Password',
    hyper_key = '1',
    preferredDisplay = 1,
    hideAfter = 1,
    position = module.grid.centeredMedium
  },
  ['com.teamviewer.TeamViewer'] = {
    bundleID = 'com.teamviewer.TeamViewer',
    name = 'TeamViewer',
    preferredDisplay = 1,
    position = module.grid.centeredLarge
  },
  ['org.hammerspoon.Hammerspoon'] = {
    bundleID = 'org.hammerspoon.Hammerspoon',
    name = 'Hammerspoon',
    hyper_key = 'r',
    context = 'hammerspoon',
    preferredDisplay = 2,
    hideAfter = 1,
    quitGuard = true,
  },
  ['com.apple.systempreferences'] = {
    bundleID = 'com.apple.systempreferences',
    name = 'System Preferences',
    preferredDisplay = 1,
    position = module.grid.centeredMedium
  },
  ['com.flexibits.fantastical2.mac'] = {
    bundleID = 'com.flexibits.fantastical2.mac',
    name = 'Fantastical',
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
  ['org.pqrs.Karabiner-Elements.Preferences'] = {
    bundleID = 'org.pqrs.Karabiner-Elements.Preferences',
    name = 'Karabiner-Elements',
    preferredDisplay = 1,
    position = module.grid.centeredSmall,
    quitGuard = true,
    hideAfter = 0.5,
    rules = {
      { title="Karabiner-Elements Preferences", rule="quit" }
    }
  },
  ['com.microsoft.autoupdate2'] = {
    bundleID = 'com.microsoft.autoupdate2',
    name = 'Microsoft AutoUpdate',
    preferredDisplay = 1,
    quitAfter = 0,
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
  local rulesExist = appConfig ~= nil and appConfig.rules ~= nil and #appConfig.rules > 0

  return rulesExist
end

module.ruleForWin = function(win, rule)
  local appConfig = module.getAppConfigForWin(win)
  local foundRule = hs.fnutils.find(appConfig.rules, function(datum)
    return datum.title == win:title() and datum.rule == rule
  end)

  return foundRule
end

module.ruleExistsForWin = function(win, rule)
  local appConfig = module.getAppConfigForWin(win)
  local rulesExist = module.rulesExistForWin(win)
  local exists = false

  if rulesExist then
    local foundRule = module.ruleForWin(win, rule)
    exists = rulesExist and foundRule ~= nil
  end

  if exists then
    log.df("Found rule (%s) found for %s", rule, win:title())
  -- else
  --   log.df("No rule (%s) found for %s", rule, win:title())
  end

  return exists
end


module.utilities = {
  -- NOTE: handle this with alfred and `sleep`/`lock` commands
  -- {
  --   name = 'Lock Screen',
  --   modifier = module.modifiers.mashShift,
  --   shortcut = 'L',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  {
    name = 'Hammerspoon Reload',
    hyper_key = 'r',
    hyper_mod = {'shift'},
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

-- TODO: want to control these with hyper_key too..
module.media = {
  {
    action = 'previous',
    hyper_key = '[',
    hyper_mod = {'shift'},
    modifier = module.modifiers.ctrlShift,
    shortcut = '[',
    label = '⇤ previous'
  },
  {
    action = 'next',
    hyper_key = ']',
    hyper_mod = {'shift'},
    modifier = module.modifiers.ctrlShift,
    shortcut = ']',
    label = 'next ⇥'
  },
  {
    action = 'playpause',
    hyper_key = '\\',
    hyper_mod = {'shift'},
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
    hyper_key = 27,
    hyper_mod = {'shift'},
    diff = -5,
  },
  {
    action = 'up',
    modifier = module.modifiers.ctrlShift,
    shortcut = 24,
    hyper_key = 24,
    hyper_mod = {'shift'},
    diff = 5,
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
    fontSize = 14.0,
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
