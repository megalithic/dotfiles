local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "config"

obj.settings = {}

local preferred = {
  terms = { "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = {
    hs.urlevent.getDefaultHandler("https"),
    "Brave Browser Dev",
    "Firefox",
    "Vivaldi",
    "Firefox Developer Edition",
    "Brave Browser",
    "Brave Browser Beta",
    "Google Chrome",
    "Safari",
  },
  personal = { "Messages", "Signal" },
  chat = { "Slack" },
  media = { "Spotify" },
  vpn = { "Cloudflare WARP" },
}
preferred["browser"] = hs.urlevent.getDefaultHandler("https")

local watchers = { "status", "bluetooth", "dock", "audio", "wifi", "url", "downloads" }

local transientApps = {
  ["LaunchBar"] = { allowRoles = "AXSystemDialog" },
  ["1Password 7"] = { allowTitles = "1Password mini" },
  ["Spotlight"] = { allowRoles = "AXSystemDialog" },
  ["Paletro"] = { allowRoles = "AXSystemDialog" },
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true,
}

local networks = { "shaolin" }

local displays = {
  laptop = "Color LCD",
  external = "LG UltraFine",
}

local dirs = {
  screenshots = os.getenv("HOME") .. "/screenshots",
}


-- stylua: ignore start
--- REF: https://github.com/asmagill/hammerspoon_asm/blob/master/extras/init.lua
local mods = {
  casc = {                     }, casC = {                       "ctrl"},
  caSc = {              "shift"}, caSC = {              "shift", "ctrl"},
  cAsc = {       "alt"         }, cAsC = {       "alt",          "ctrl"},
  cASc = {       "alt", "shift"}, cASC = {       "alt", "shift", "ctrl"},
  Casc = {"cmd"                }, CasC = {"cmd",                 "ctrl"},
  CaSc = {"cmd",        "shift"}, CaSC = {"cmd",        "shift", "ctrl"},
  CAsc = {"cmd", "alt"         }, CAsC = {"cmd", "alt",          "ctrl"},
  CASc = {"cmd", "alt", "shift"}, CASC = {"cmd", "alt", "shift", "ctrl"},
}
-- stylua: ignore end

local hyper = "F19"
local ptt = mods.CAsc

local apps = {
  ["com.runningwithcrayons.Alfred"] = {
    name = "Alfred",
    bundleID = "com.runningwithcrayons.Alfred",
    key = "space",
    quitter = true,
  },
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    key = "k",
    quitter = false,
    localBindings = {},
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.github.wez.wezterm"] = {
    bundleID = "com.github.wez.wezterm",
    name = "wezterm",
    -- key = "k",
    quitter = true,
    localBindings = {},
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["org.mozilla.firefox"] = {
    bundleID = "org.mozilla.firefox",
    name = "Firefox",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["org.mozilla.firefoxdeveloperedition"] = {
    bundleID = "org.mozilla.firefoxdeveloperedition",
    name = "Firefox Developer Edition",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.vivaldi.Vivaldi"] = {
    bundleID = "com.vivaldi.Vivaldi",
    name = "Vivaldi",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.brave.Browser.dev"] = {
    bundleID = "com.brave.Browser.dev",
    name = "Brave Browser Dev",
    key = "j",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.brave.Browser"] = {
    bundleID = "com.brave.Browser",
    name = "Brave Browser",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.apple.Safari"] = {
    bundleID = "com.apple.Safari",
    name = "Safari",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.apple.SafariTechnologyPreview"] = {
    bundleID = "com.apple.SafariTechnologyPreview",
    name = "Safari Technology Preview",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.kapeli.dashdoc"] = {
    bundleID = "com.kapeli.dashdoc",
    name = "Dash",
    key = "d",
    rules = {
      { "", 1, "centeredLarge" },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    tags = { "chat" },
    distraction = true,
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["com.freron.MailMate"] = {
    bundleID = "com.freron.MailMate",
    name = "MailMate",
    key = "e",
    distraction = true,
    rules = {
      { "", 2, "left50" },
      { "Inbox", 2, "maximized" },
    },
  },
  ["com.apple.finder"] = {
    bundleID = "com.apple.finder",
    name = "Finder",
    key = "f",
    rules = {
      { "Finder", 1, "centeredMedium" },
    },
  },
  ["us.zoom.xos"] = {
    bundleID = "us.zoom.xos",
    name = "zoom.us",
    key = "z",
    launchMode = "focus",
  },
  ["com.loom.desktop"] = {
    bundleID = "com.loom.desktop",
    name = "Loom",
  },
  ["com.spotify.client"] = {
    bundleID = "com.spotify.client",
    name = "Spotify",
    key = "p",
    hideAfter = 1,
    rules = {
      { "", 2, "right50" },
    },
  },
  ["com.apple.MobileSMS"] = {
    bundleID = "com.apple.MobileSMS",
    name = "Messages",
    key = "m",
    distraction = true,
    tags = { "personal" },
    rules = {
      { "", 2, "right50" },
    },
  },
  ["org.whispersystems.signal-desktop"] = {
    bundleID = "org.whispersystems.signal-desktop",
    name = "Signal",
    key = "w",
    distraction = true,
    tags = { "personal" },
    rules = {
      { "", 2, "right50" },
    },
  },
  ["com.agilebits.onepassword7"] = {
    bundleID = "com.agilebits.onepassword7",
    name = "1Password",
    key = "1",
    hideAfter = 1,
    rules = {
      { "", 1, "centeredMedium" },
    },
  },
  ["org.hammerspoon.Hammerspoon"] = {
    bundleID = "org.hammerspoon.Hammerspoon",
    name = "Hammerspoon",
    key = "r",
    hideAfter = 1,
    quitter = true,
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["com.flexibits.fantastical2.mac"] = {
    bundleID = "com.flexibits.fantastical2.mac",
    name = "Fantastical",
    key = "y",
    localBindings = { "'" },
    quitter = true,
    hideAfter = 2,
    rules = {
      { "", 1, "centeredLarge" },
    },
  },
  ["com.figma.Desktop"] = {
    bundleID = "com.figma.Desktop",
    name = "Figma",
    key = "f",
    mods = mods.caSc,
    quitter = true,
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.surteesstudios.Bartender"] = {
    bundleID = "com.surteesstudios.Bartender",
    name = "Bartender 4",
    localBindings = { "\\" },
  },
  ["com.apple.iphonesimulator"] = {
    bundleID = "com.apple.iphonesimulator",
    name = "iPhone Simulator",
    key = "i",
    quitter = false,
    launchMode = "focus",
    localBindings = {},
    rules = {
      { "", 1, "right30" },
    },
  },
}

local utils = {
  {
    name = "Hammerspoon",
    key = "r",
    mods = mods.caSc,
    fn = { { "hs.reload" }, { "hs.notify.show", "Hammerspoon", "Config reloaded.." } },
  },
}

local dock = {
  ["target"] = {
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
    profile = "leeloo", -- Karabiner-Elements profile name
    input = "Samson GoMic", -- microphone source
    -- https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/headphones.lua
    output = "megapods", -- speaker source
  },
  ["undocked"] = {
    wifi = "on",
    profile = "internal",
    input = "MacBook Pro Microphone",
    output = "MacBook Pro Speakers",
  },
}

function obj:init(opts)
  opts = opts or {}

  obj.settings = {
    ["bindings"] = {
      ["apps"] = apps,
      ["utils"] = utils,
    },
    ["dirs"] = dirs,
    ["displays"] = displays,
    ["keys"] = {
      ["hyper"] = hyper,
      ["ptt"] = ptt,
      ["mods"] = mods,
    },
    ["networks"] = networks,
    ["preferred"] = preferred,
    ["transientApps"] = transientApps,
    ["watchers"] = watchers,
    ["dock"] = dock,
  }

  Settings.set(CONFIG_KEY, obj.settings)

  return self
end

function obj:stop()
  Settings.clear(CONFIG_KEY)
  obj.settings = {}

  return self
end

return obj
