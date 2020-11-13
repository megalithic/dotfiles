local log = hs.logger.new('[config]', 'warning')

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

local M = {
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
    bottomHalf =      '0,4 8x4',
    rightHalf =       '4,0 4x8',
    rightOneThird =   '5,0 3x8',
    rightTwoThirds =  '3,0 5x8',
    leftHalf =        '0,0 4x8',
    leftOneThird =    '0,0 3x8',
    leftTwoThirds =   '0,0 5x8',
    fullScreen =      '0,0 8x8',
    centeredLarge =   '1,1 6x6',
    centeredMedium =  '2,2 4x4',
    centeredSmall =   '3,3 2x2',
  },

  layout =  {
    topHalf =         {  0,  0,  1, .5},
    bottomHalf =      {  0, .5,  1, .5},
    rightHalf =       hs.layout.right50,
    rightOneThird =   hs.layout.right30,
    rightTwoThirds =  hs.layout.right70,
    bottomRight  =    { .5, .5, .5, .5},
    bottomRight30 =   { .7, .5, .3, .5},
    bottomRight40 =   { .6, .5, .4, .5},
    bottomRight60 =   { .4, .5, .6, .5},
    bottomRight70 =   { .3, .5, .7, .5},
    leftHalf =        hs.layout.left50,
    leftOneThird =    hs.layout.left30,
    leftTwoThirds =   hs.layout.left70,
    fullScreen =      hs.layout.maximized,
    centeredLarge =   { x = 0.10, y = 0.10, w = 0.80, h = 0.80}, -- {1,1,6,6},
    centeredMedium =  { x = 0.25, y = 0.25, w = 0.50, h = 0.50}, -- {2,2,4,4},
    centeredSmall =   { x = 0.40, y = 0.35, w = 0.35, h = 0.35}, -- {3,3,2,2},
  },

  modifiers = {
    ctrl =            {'ctrl'},
    shift =           {'shift'},
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

M.ptt = M.modifiers.cmdAlt

M.apps = {
  ['net.kovidgoyal.kitty'] = {
    bundleID = 'net.kovidgoyal.kitty',
    name = 'kitty',
    hyper_key = 'k',
    preferredDisplay = 1,
    position = M.grid.fullScreen,
    quitGuard = true,
    rules = {
      {nil, 1, M.layout.fullScreen}
    }
  },
  ['com.brave.Browser'] = {
    bundleID = 'com.brave.Browser',
    name = 'Brave Browser',
    hyper_key = 'j',
    preferredDisplay = 1,
    position = M.grid.fullScreen,
    quitGuard = true,
    rules = {
      {nil, 1, M.layout.fullScreen}
    }
  },
  ['com.insomnia.app'] = {
    bundleID = 'com.insomnia.app',
    name = 'Insomnia',
    hyper_key ='i',
    preferredDisplay = 1,
    position = M.grid.rightHalf,
    quitGuard = false,
    rules = {
      {nil, 2, M.layout.rightHalf}
    }
  },
  ['com.runningwithcrayons.Alfred'] = {
    name = 'Alfred',
    bundleID = 'com.runningwithcrayons.Alfred',
    local_bindings = {'c', 'space', 'o'},
  },
  ['com.agiletortoise.Drafts-OSX'] = {
    bundleID = 'com.agiletortoise.Drafts-OSX',
    name = 'Drafts',
    hyper_key ='d',
    modifier = M.modifiers.shift,
    local_bindings = {';'},
    preferredDisplay = 1,
    position = M.grid.rightHalf,
    quitGuard = false,
    hideAfter = 1,
    rules = {
      {nil, 1, M.layout.rightHalf},
      {'Capture', 1, M.layout.bottomRight30},
      -- {title = 'Workspaces', action = 'ignore'},
      -- {title = 'Capture', action = 'snap', position = '5,5 3x3'},
    },
  },
  ['com.culturedcode.ThingsMac'] = {
    bundleID = 'com.culturedcode.ThingsMac',
    name = 'Things',
    hyper_key = 't',
    preferred_display = 1,
    hideAfter = 1,
    position = M.grid.centeredMedium,
    local_bindings = {',', '.'},
    rules = {
      {nil, 1, M.layout.centeredMedium},
    },
  },
  ['com.kapeli.dashdoc'] = {
    bundleID = 'com.kapeli.dashdoc',
    name = 'Dash',
    hyper_key = 'd',
    preferredDisplay = 1,
    position = M.grid.centeredLarge,
    rules = {
      {nil, 2, M.layout.centeredLarge},
    },

  },
  ['com.brettterpstra.marked2'] = {
    bundleID = 'com.brettterpstra.marked2',
    name = 'Marked',
    preferredDisplay = 2,
    position = M.grid.leftHalf,
    rules = {
      {nil, 2, M.layout.leftHalf},
    },
  },
  ['com.tinyspeck.slackmacgap'] = {
    bundleID = 'com.tinyspeck.slackmacgap',
    name = 'Slack',
    hyper_key ='s',
    context = 'slack',
    distraction = true,
    preferredDisplay = 2,
    position = M.grid.leftHalf,
    quitGuard = true,
    rules = {
      {nil, 2, M.layout.leftHalf},
      -- {title = 'Slack Call Minipanel', action = 'ignore'},
    }
  },
  ['com.readdle.smartemail-Mac'] = {
    bundleID = 'com.readdle.smartemail-Mac',
    name = 'Spark',
    hyper_key ='e',
    context = 'spark',
    distraction = true,
    preferredDisplay = 2,
    position = M.grid.rightHalf,
    rules = {
      {nil, 2, M.layout.rightHalf},
    },
  },

  ['io.canarymail.mac'] = {
    bundleID = 'io.canarymail.mac',
    name = 'Canary Mail',
    -- hyper_key ='e',
    context = 'canary',
    distraction = true,
    preferredDisplay = 2,
    position = M.grid.rightHalf,
    rules = {
      {nil, 2, M.layout.rightHalf}
      -- {title = 'Main Window', action = 'snap'},
      -- {title = 'Preferences', action = 'ignore'},
    }
  },
  ['com.apple.finder'] = {
    bundleID = 'com.apple.finder',
    name = 'Finder',
    hyper_key ='f',
    preferredDisplay = 1,
    position = M.grid.centeredMedium,
    rules = {
      -- {title = 'Finder Preferences', action = 'ignore'},
    },
  },
  ['us.zoom.xos'] = {
    bundleID = 'us.zoom.xos',
    name = 'zoom.us',
    context = 'zoom',
    hyper_key ='z',
    preferredDisplay = 1,
    position = M.grid.fullScreen,
    launchMode = 'focus',
    rules = {
      -- {title = 'Zoom', action = 'quit'},
      -- {title = 'Zoom Meeting', action = 'snap'},
      {"Zoom Meeting", 2, M.layout.fullScreen}
    },
  },
  ['com.loom.desktop'] = {
    bundleID = 'com.loom.desktop',
    name = 'Loom',
    context = 'loom',
    -- rules = {
    --   {nil, 2, M.grid.leftHalf},
    -- },
  },
  ['com.spotify.client'] = {
    bundleID = 'com.spotify.client',
    name = 'Spotify',
    hyper_key ='\\',
    preferredDisplay = 2,
    hideAfter = 1,
    position = M.grid.rightHalf,
    rules = {
      {nil, 2, M.layout.rightHalf},
    },
  },
  ['com.apple.iChat'] = {
    bundleID = 'com.apple.iChat',
    name = 'Messages',
    hyper_key ='m',
    context = 'messages',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3',
    rules = {
      {nil, 1, M.layout.bottomRight30},
    },
  },
  ['hangouts'] = {
    bundleID = 'hangouts',
    name = 'Hangouts',
    modifier = M.modifiers.cmdCtrl,
    shortcut = 'm',
    distraction = true,
    preferredDisplay = 1,
    tabjump = 'hangouts.google.com',
    -- rules = {
    --   {nil, 1, M.layout.leftHalf},
    -- },
  },
  ['WhatsApp'] = {
    bundleID = 'WhatsApp',
    name = 'WhatsApp',
    -- hyper_key ='w',
    context = 'whatsapp',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3',
    rules = {
      {nil, 1, M.layout.bottomRight30},
    },
  },
  ['org.whispersystems.signal-desktop'] = {
    bundleID = 'org.whispersystems.signal-desktop',
    name = 'Signal',
    hyper_key ='w',
    context = 'signal',
    distraction = true,
    preferredDisplay = 1,
    position = '5,5 3x3',
    rules = {
      {nil, 1, M.layout.bottomRight30},
    },
  },
  ['com.agilebits.onepassword7'] = {
    bundleID = 'com.agilebits.onepassword7',
    name = '1Password',
    hyper_key = '1',
    preferredDisplay = 1,
    hideAfter = 1,
    position = M.grid.centeredMedium,
    rules = {
      {nil, 1, M.layout.centeredSmall},
    },
  },
  ['com.teamviewer.TeamViewer'] = {
    bundleID = 'com.teamviewer.TeamViewer',
    name = 'TeamViewer',
    preferredDisplay = 1,
    position = M.grid.centeredLarge,
    rules = {
      {nil, 1, M.layout.centeredLarge},
    },
  },
  ['org.hammerspoon.Hammerspoon'] = {
    bundleID = 'org.hammerspoon.Hammerspoon',
    name = 'Hammerspoon',
    hyper_key = 'r',
    context = 'hammerspoon',
    preferredDisplay = 2,
    position = M.grid.rightHalf,
    hideAfter = 1,
    quitGuard = true,
    rules = {
      {'Hammerspoon Console', 2, M.layout.rightHalf},
      -- {title = 'Hammerspoon Console', action = 'snap', position = M.grid.rightHalf}
    }
  },
  ['com.apple.systempreferences'] = {
    bundleID = 'com.apple.systempreferences',
    name = 'System Preferences',
    preferredDisplay = 1,
    position = M.grid.centeredMedium,
    rules = {
      {nil, 1, M.layout.leftHalf},
    },
  },
  ['com.flexibits.fantastical2.mac'] = {
    bundleID = 'com.flexibits.fantastical2.mac',
    name = 'Fantastical',
    hyper_key ='y',
    local_bindings = {']'},
    preferredDisplay = 1,
    position = M.grid.centeredLarge,
    quitGuard = true,
    hideAfter = 1,
    rules = {
      {nil, 2, M.layout.centeredLarge},
      -- { title="Fantastical Helper", rule="ignore" }
    }
  },
  ['org.pqrs.Karabiner-Elements.Preferences'] = {
    bundleID = 'org.pqrs.Karabiner-Elements.Preferences',
    name = 'Karabiner-Elements',
    preferredDisplay = 1,
    position = M.grid.centeredSmall,
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

M.utilities = {
  -- NOTE: handle this with alfred and `sleep`/`lock` commands
  -- {
  --   name = 'Lock Screen',
  --   modifier = M.modifiers.mashShift,
  --   shortcut = 'L',
  --   fn = function() hs.caffeinate.systemSleep() end
  -- },
  {
    name = 'Hammerspoon Reload',
    hyper_key = 'r',
    hyper_mod = {'shift'},
    fn = (function()
      hs.reload()
      hs.notify.show('Hammerspoon', 'Hammerspoon Config Reloaded', '')
    end)
  },
  {
    name = 'Pomodoro',
    modifier = M.modifiers.cmdCtrl,
    shortcut = 'p',
    fn = (function() end)
  },
  {
    name = 'ScreenCapture',
    modifier = M.modifiers.ctrlShift,
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
M.media = {
  {
    action = 'previous',
    hyper_key = '[',
    hyper_mod = {'shift'},
    modifier = M.modifiers.ctrlShift,
    shortcut = '[',
    label = '⇤ previous'
  },
  {
    action = 'next',
    hyper_key = ']',
    hyper_mod = {'shift'},
    modifier = M.modifiers.ctrlShift,
    shortcut = ']',
    label = 'next ⇥'
  },
  {
    action = 'playpause',
    hyper_key = '\\',
    hyper_mod = {'shift'},
    modifier = M.modifiers.ctrlShift,
    shortcut = '\\',
    label = 'play/pause'
  },
}

M.volume = {
  {
    action = 'down',
    modifier = M.modifiers.ctrlShift,
    shortcut = 27,
    hyper_key = 27,
    hyper_mod = {'shift'},
    diff = -5,
  },
  {
    action = 'up',
    modifier = M.modifiers.ctrlShift,
    shortcut = 24,
    hyper_key = 24,
    hyper_mod = {'shift'},
    diff = 5,
  },
}

M.snap = {
  {
    name = 'left',
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = 'h',
    locations = {
      M.grid.leftHalf,
      M.grid.leftOneThird,
      M.grid.leftTwoThirds,
    }
  },
  {
    name = 'right',
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = 'l',
    locations = {
      M.grid.rightHalf,
      M.grid.rightOneThird,
      M.grid.rightTwoThirds,
    }
  },
  {
    name = 'down',
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = 'j',
    locations = {
      M.grid.centeredLarge,
      M.grid.centeredMedium,
      M.grid.centeredSmall,
    }
  },
  {
    name = 'up',
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = 'k',
    locations = {
      M.grid.ullScreen,
    }
  },
  {
    name = 'full',
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = 'return',
    locations = {
      M.grid.fullScreen,
    }
  },
}

M.docking = {
  -- find your device IDs with `dumpUsbDevices()` (see console.lua) from the hammerspoon console
  ['device'] = {
    productID = 25907,
    productName = 'CalDigit Thunderbolt 3 Audio',
    vendorID = 8584,
    vendorName = 'CalDigit, Inc.'
  },
  ['docked'] = {
    wifi = 'off', -- wifi status
    profile = 'dz60', -- Karabiner-Elements profile name
    input = 'Samson GoMic', -- microphone source
    output = 'CalDigit Thunderbolt 3 Audio', -- speaker source
    fontSize = 14.0,
  },
  ['undocked'] = {
    wifi = 'on',
    profile = 'internal',
    input = 'MacBook Pro Microphone',
    output = 'MacBook Pro Speakers',
    fontSize = 14.0,
  },
}

return M
