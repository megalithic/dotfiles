local log = hs.logger.new("[config]", "warning")

-- grid config
hs.grid.GRIDWIDTH = 8
hs.grid.GRIDHEIGHT = 8
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

local M = {}

-- available and preferred displays
M.displays = {
  laptop = "Color LCD",
  external = "LG UltraFine",
}

M.network = {
  home = "shaolin",
  hostname = hs.host.localizedName(),
  currentConnected = hs.wifi.currentNetwork(),
}

M.dirs = {
  -- screenshots = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/screenshots",
  screenshots = os.getenv("HOME") .. "/screenshots",
}

M.preferred = {
  terms = { "kitty", "alacritty", "iTerm" },
  browsers = { "Brave Browser", "Brave Browser Dev", "Firefox", "Google Chrome", "Safari" },
  media = { "Spotify" },
  vpn = { "Cloudflare WARP" },
  -- TODO: hyperGroup
  -- https://github.com/evantravers/hammerspoon-config/blob/master/init.lua#L72-L119
  bindings = { "ptt", "quitguard", "tabjump", "hyper", "apps", "snap", "media", "airpods", "misc", "browser", "capture" },
  controlplane = { "dock", "office" },
  watchers = { "urlevent" },
}

M.window = {
  highlightBorder = false,
  highlightMouse = true,
  historyLimit = 0,
}

M.office = {}

-- legacy layouts:
M.grid = {
  topHalf = "0,0 8x4",
  bottomHalf = "0,4 8x4",
  rightHalf = "4,0 4x8",
  rightOneThird = "5,0 3x8",
  rightTwoThirds = "3,0 5x8",
  leftHalf = "0,0 4x8",
  leftOneThird = "0,0 3x8",
  leftTwoThirds = "0,0 5x8",
  fullScreen = "0,0 8x8",
  centeredLarge = "1,1 6x6",
  centeredMedium = "2,2 4x4",
  centeredSmall = "3,3 2x2",
}

-- actively used layouts:
M.layout = {
  topHalf = { 0, 0, 1, 0.5 },
  bottomHalf = { 0, 0.5, 1, 0.5 },
  rightHalf = hs.layout.right50,
  rightOneThird = hs.layout.right30,
  rightTwoThirds = hs.layout.right70,
  bottomRight = { 0.5, 0.5, 0.5, 0.5 },
  bottomRight30 = { 0.7, 0.5, 0.3, 0.5 },
  bottomRight40 = { 0.6, 0.5, 0.4, 0.5 },
  bottomRight60 = { 0.4, 0.5, 0.6, 0.5 },
  bottomRight70 = { 0.3, 0.5, 0.7, 0.5 },
  topRight30 = { 0.7, 0, 0.3, 0.5 },
  leftHalf = hs.layout.left50,
  leftOneThird = hs.layout.left30,
  leftTwoThirds = hs.layout.left70,
  fullScreen = hs.layout.maximized,
  centeredLarge = { x = 0.10, y = 0.10, w = 0.80, h = 0.80 },
  centeredMedium = { x = 0.25, y = 0.25, w = 0.50, h = 0.50 },
  centeredSmall = { x = 0.35, y = 0.35, w = 0.30, h = 0.30 },
}

M.modifiers = {
  ctrl = { "ctrl" },
  shift = { "shift" },
  cmd = { "cmd" },
  cmdAlt = { "cmd", "alt" },
  cmdShift = { "cmd", "shift" },
  ctrlShift = { "ctrl", "shift" },
  cmdCtrl = { "cmd", "ctrl" },
  ctrlAlt = { "ctrl", "alt" },
  mashShift = { "cmd", "ctrl", "shift" },
  mash = { "cmd", "alt", "ctrl" },
  ultra = { "cmd", "alt", "ctrl", "shift" },
  hyper = "F19",
}

-- REF for url handling: https://github.com/sjthespian/dotfiles/blob/master/hammerspoon/config.lua#L76
M.distractionUrls = {
  "https://www.youtube.com",
  "https://www.twitter.com",
  "https://www.instagram.com",
  "https://www.facebook.com",
  "https://www.reddit.com",
}

M.ptt = M.modifiers.cmdAlt -- toggling happens in bindings/misc.lua
-- M.quake = { M.modifiers.ctrl, "`" } -- toggling happens in bindings/misc.lua

M.apps = {
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    hyper_key = "k",
    quitGuard = true,
    rules = {
      { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.brave.Browser"] = {
    bundleID = "com.brave.Browser",
    name = "Brave Browser",
    hyper_key = "j",
    quitGuard = true,
    tags = { "browsers" },
    rules = {
      { nil, 1, M.layout.fullScreen },
    },
  },
  ["org.mozilla.firefoxdeveloperedition"] = {
    bundleID = "org.mozilla.firefoxdeveloperedition",
    name = "Firefox Developer Edition",
    tags = { "browsers" },
    rules = {
      { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.apple.Safari"] = {
    bundleID = "com.apple.Safari",
    name = "Safari",
    tags = { "browsers" },
    rules = {
      { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.microsoft.edgemac"] = {
    bundleID = "com.microsoft.edgemac",
    name = "Microsoft Edge",
    tags = { "browsers" },
    rules = {
      { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.insomnia.app"] = {
    bundleID = "com.insomnia.app",
    name = "Insomnia",
    -- hyper_key = "i",
    quitGuard = false,
    rules = {
      { nil, 1, M.layout.rightHalf },
    },
  },
  ["com.runningwithcrayons.Alfred"] = {
    name = "Alfred",
    bundleID = "com.runningwithcrayons.Alfred",
    hyper_key = "space",
    quitGuard = true,
  },
  ["com.agiletortoise.Drafts-OSX"] = {
    bundleID = "com.agiletortoise.Drafts-OSX",
    name = "Drafts",
    hyper_key = "d",
    modifier = M.modifiers.shift,
    local_bindings = { ";" },
    quitGuard = false,
    hideAfter = 1,
    rules = {
      { nil, 1, M.layout.rightHalf },
      { "Capture", 1, M.layout.centeredSmall },
    },
  },
  ["com.culturedcode.ThingsMac"] = {
    bundleID = "com.culturedcode.ThingsMac",
    name = "Things",
    hyper_key = "t",
    hideAfter = 1,
    -- local_bindings = { ",", "." },
    rules = {
      { nil, 1, M.layout.centeredMedium },
    },
  },
  ["com.kapeli.dashdoc"] = {
    bundleID = "com.kapeli.dashdoc",
    name = "Dash",
    hyper_key = "d",
    rules = {
      { nil, 1, M.layout.centeredLarge },
    },
  },
  ["com.brettterpstra.marked2"] = {
    bundleID = "com.brettterpstra.marked2",
    name = "Marked",
    rules = {
      { nil, 1, M.layout.leftHalf },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    hyper_key = "s",
    context = "slack",
    distraction = true,
    quitGuard = false,
    rules = {
      { nil, 2, M.layout.fullScreen },
    },
  },
  ["com.readdle.smartemail-Mac"] = {
    bundleID = "com.readdle.smartemail-Mac",
    name = "Spark",
    hyper_key = "e",
    context = "spark",
    distraction = true,
    rules = {
      { nil, 2, M.layout.centereLarge },
      { "INBOX", 2, M.layout.fullScreen },
    },
  },
  ["io.canarymail.mac"] = {
    bundleID = "io.canarymail.mac",
    name = "Canary Mail",
    -- hyper_key = "e",
    context = "canary",
    distraction = true,
    rules = {
      { nil, 2, M.layout.centeredSmall },
      { "All", 2, M.layout.fullScreen },
    },
  },
  ["com.apple.finder"] = {
    bundleID = "com.apple.finder",
    name = "Finder",
    -- hyper_key = "f",
    rules = {
      { "Finder", 1, M.layout.centeredMedium },
    },
  },
  ["com.binarynights.ForkLift-3"] = {
    bundleID = "com.binarynights.ForkLift-3",
    name = "ForkLift",
    hyper_key = "f",
    rules = {
      { nil, 1, M.layout.centeredMedium },
    },
  },
  ["us.zoom.xos"] = {
    bundleID = "us.zoom.xos",
    name = "zoom.us",
    context = "zoom",
    hyper_key = "z",
    launchMode = "focus",
    rules = {
      { nil, 1, M.layout.centeredMedium },
      { "Zoom Meeting", 1, M.layout.fullScreen },
    },
  },
  ["com.loom.desktop"] = {
    bundleID = "com.loom.desktop",
    name = "Loom",
    context = "loom",
  },
  ["com.spotify.client"] = {
    bundleID = "com.spotify.client",
    name = "Spotify",
    hyper_key = "p",
    modifier = M.modifiers.shift,
    hideAfter = 1,
    rules = {
      { nil, 1, M.layout.rightHalf },
    },
  },
  ["com.apple.MobileSMS"] = {
    bundleID = "com.apple.MobileSMS",
    name = "Messages",
    hyper_key = "m",
    context = "messages",
    distraction = true,
    tags = { "personal" },
    rules = {
      { nil, 2, M.layout.rightHalf },
    },
  },
  ["hangouts"] = {
    bundleID = "hangouts",
    name = "Hangouts",
    modifier = M.modifiers.cmdCtrl,
    shortcut = "m",
    distraction = true,
    tabjump = "hangouts.google.com",
  },
  ["org.whispersystems.signal-desktop"] = {
    bundleID = "org.whispersystems.signal-desktop",
    name = "Signal",
    hyper_key = "w",
    context = "signal",
    distraction = true,
    tags = { "personal" },
    rules = {
      { nil, 2, M.layout.leftHalf },
    },
  },
  ["com.agilebits.onepassword7"] = {
    bundleID = "com.agilebits.onepassword7",
    name = "1Password",
    hyper_key = "1",
    hideAfter = 1,
    rules = {
      { nil, 1, M.layout.centeredMedium },
    },
  },
  ["com.teamviewer.TeamViewer"] = {
    bundleID = "com.teamviewer.TeamViewer",
    name = "TeamViewer",
    rules = {
      { nil, 1, M.layout.centeredLarge },
    },
  },
  ["org.hammerspoon.Hammerspoon"] = {
    bundleID = "org.hammerspoon.Hammerspoon",
    name = "Hammerspoon",
    hyper_key = "r",
    context = "hammerspoon",
    hideAfter = 15,
    quitGuard = true,
    rules = {
      { nil, 2, M.layout.fullScreen },
    },
  },
  ["com.apple.systempreferences"] = {
    bundleID = "com.apple.systempreferences",
    name = "System Preferences",
    rules = {
      { nil, 1, M.layout.centeredMedium },
    },
  },
  ["com.flexibits.fantastical2.mac"] = {
    bundleID = "com.flexibits.fantastical2.mac",
    name = "Fantastical",
    hyper_key = "y",
    local_bindings = { "'" },
    quitGuard = true,
    hideAfter = 2,
    rules = {
      { nil, 1, M.layout.centeredLarge },
    },
  },
  ["org.pqrs.Karabiner-Elements.Preferences"] = {
    bundleID = "org.pqrs.Karabiner-Elements.Preferences",
    name = "Karabiner-Elements",
    quitGuard = true,
    hideAfter = 0.5,
    rules = {
      { nil, 1, M.layout.centeredSmall },
    },
  },
  ["com.microsoft.autoupdate2"] = {
    bundleID = "com.microsoft.autoupdate2",
    name = "Microsoft AutoUpdate",
    quitAfter = 0,
  },
  ["com.figma.Desktop"] = {
    bundleID = "com.figma.Desktop",
    name = "Figma",
    hyper_key = "f",
    modifier = M.modifiers.shift,
    quitGuard = true,
    rules = {
      { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.surteesstudios.Bartender"] = {
    bundleID = "com.surteesstudios.Bartender",
    name = "Bartender 4",
    quitGuard = true,
    local_bindings = { "b" },
  },
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
    name = "Hammerspoon Reload",
    hyper_key = "r",
    hyper_mod = { "shift" },
    fn = function()
      hs.reload()
      hs.notify.show("Hammerspoon", "Hammerspoon Config Reloaded", "")
    end,
  },
  {
    name = "Pomodoro",
    modifier = M.modifiers.cmdCtrl,
    shortcut = "p",
    fn = function() end,
  },
  {
    name = "ScreenCapture",
    modifier = M.modifiers.ctrlShift,
    shortcut = "s",
    fn = function()
      -- current_date = os.date('%Y%m%d-%H%M%S')
      -- filename = "capture_" .. current_date .. ".png"
      -- capture_target = "~/Dropbox/captures/"..filename
      -- print("SCREENCAPTURE: "..hs.inspect(capture_target))
      -- hs.execute("screencapture -i ~/Dropbox/captures/shot_`date '+%Y-%m-%d_%H-%M-%S'`.png");
    end,
  },
}

-- TODO: want to control these with hyper_key too..
M.media = {
  {
    action = "view",
    hyper_key = "[",
    hyper_mod = { "shift" },
    modifier = M.modifiers.ctrlShift,
    shortcut = "k",
    label = "Spotify",
    bundleID = "com.spotify.client",
  },
  {
    action = "previous",
    hyper_key = "[",
    hyper_mod = { "shift" },
    modifier = M.modifiers.ctrlShift,
    shortcut = "h",
    label = "⇤ previous",
  },
  {
    action = "next",
    hyper_key = "]",
    hyper_mod = { "shift" },
    modifier = M.modifiers.ctrlShift,
    shortcut = "l",
    label = "next ⇥",
  },
  {
    action = "playpause",
    hyper_key = "\\",
    hyper_mod = { "shift" },
    modifier = M.modifiers.ctrlShift,
    shortcut = "j",
    label = "play/pause",
  },
}

M.volume = {
  {
    action = "down",
    modifier = M.modifiers.ctrlShift,
    shortcut = 27,
    hyper_key = 27,
    hyper_mod = { "shift" },
    diff = -5,
  },
  {
    action = "up",
    modifier = M.modifiers.ctrlShift,
    shortcut = 24,
    hyper_key = 24,
    hyper_mod = { "shift" },
    diff = 5,
  },
}

M.snap = {
  left = {
    name = "left",
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = "h",
    position = M.layout.leftHalf,
    locations = {
      M.grid.leftHalf,
      M.grid.leftOneThird,
      M.grid.leftTwoThirds,
    },
  },
  right = {
    name = "right",
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = "l",
    position = M.layout.rightHalf,
    locations = {
      M.grid.rightHalf,
      M.grid.rightOneThird,
      M.grid.rightTwoThirds,
    },
  },
  down = {
    name = "down",
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = "j",
    position = M.layout.centeredLarge,
    locations = {
      M.grid.centeredLarge,
      M.grid.centeredMedium,
      M.grid.centeredSmall,
    },
  },
  up = {
    name = "up",
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = "k",
    position = M.layout.centeredMedium,
    locations = {
      M.grid.fullScreen,
    },
  },
  full = {
    name = "full",
    modifier = M.modifiers.cmdCtrl,
    -- hyperKey = M.modifiers.hyper,
    shortcut = "return",
    position = M.layout.fullScreen,
    locations = {
      M.grid.fullScreen,
    },
  },
}

M.docking = {
  -- find your device IDs with `dumpUsbDevices()` (see console.lua) from the hammerspoon console
  ["device"] = {
    productID = 25907,
    productName = "CalDigit Thunderbolt 3 Audio",
    vendorID = 8584,
    vendorName = "CalDigit, Inc.",
  },
  ["keyboard"] = {
    productID = 24674,
    productName = "Atreus62",
    vendorID = 65261,
    vendorName = "Profet",
  },
  ["docked"] = {
    wifi = "off", -- wifi status
    profile = "atreus62", -- Karabiner-Elements profile name
    input = "Samson GoMic", -- microphone source
    -- https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/headphones.lua
    output = "megapods", -- speaker source
    fontSize = 15.0,
  },
  ["undocked"] = {
    wifi = "on",
    profile = "internal",
    input = "MacBook Pro Microphone",
    output = "MacBook Pro Speakers",
    fontSize = 15.0,
  },
}

return M
