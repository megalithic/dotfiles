local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "config"

obj.settings = {}

local preferred = {
  terms = { "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = {
    "Firefox",
    "Vivaldi",
    "Firefox Developer Edition",
    "Brave Browser Dev",
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

local watchers = { "dock", "bluetooth", "audio", "wifi", "url", "downloads" }

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

local quitter = {
  launchdRunInterval = 600, --- 10 minutes
  -- rules = require("appquitter_rules"),
  defaultQuitInterval = 14400, -- 4 hours
  defaultHideInterval = 1800, -- 30 minutes
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
    quitGuard = true,
  },
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    key = "k",
    localBindings = {},
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["org.mozilla.firefox"] = {
    bundleID = "org.mozilla.firefox",
    name = "Firefox",
    quitGuard = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["org.mozilla.firefoxdeveloperedition"] = {
    bundleID = "org.mozilla.firefoxdeveloperedition",
    name = "Firefox Developer Edition",
    quitGuard = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.vivaldi.Vivaldi"] = {
    bundleID = "com.vivaldi.Vivaldi",
    name = "Vivaldi",
    quitGuard = true,
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
    quitGuard = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.brave.Browser"] = {
    bundleID = "com.brave.Browser",
    name = "Brave Browser",
    quitGuard = true,
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.apple.Safari"] = {
    bundleID = "com.apple.Safari",
    name = "Safari",
    quitGuard = true,
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
    hideAfter = 5,
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
    hideAfter = 15,
    quitGuard = true,
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["com.flexibits.fantastical2.mac"] = {
    bundleID = "com.flexibits.fantastical2.mac",
    name = "Fantastical",
    key = "y",
    localBindings = { "'" },
    quitGuard = true,
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
    quitGuard = true,
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.surteesstudios.Bartender"] = {
    bundleID = "com.surteesstudios.Bartender",
    name = "Bartender 4",
    localBindings = { "\\" },
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
    ["quitter"] = quitter,
    ["transientApps"] = transientApps,
    ["watchers"] = watchers,
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
