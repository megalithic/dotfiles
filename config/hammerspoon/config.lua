local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "config"

obj.settings = {}

local preferred = {
  terms = { "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = {
    "Vivaldi",
    "Brave Browser",
    "Brave Browser Dev",
    "Brave Browser Beta",
    "Firefox",
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

local grid = {
  screen_edge_margins = {
    top = 32, -- px
    left = 0,
    right = 0,
    bottom = 0,
  },
  partition_margins = {
    x = 0, -- px
    y = 0,
  },
  -- Partitions --
  split_screen_partitions = {
    x = 0.5, -- %
    y = 0.5,
  },
  quarter_screen_partitions = {
    x = 0.5, -- %
    y = 0.5,
  },
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

local wm = {
  pushLeft = { hyper, "h" },
  pushRight = { hyper, "l" },
  pushUp = { hyper, "k" },
  pushDown = { hyper, "j" },
  maximize = { hyper, "return" },
  center = { hyper, "space" },
}

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
    quitGuard = false,
    rules = {
      -- { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.vivaldi.Vivaldi"] = {
    bundleID = "com.vivaldi.Vivaldi",
    name = "Vivaldi",
    quitGuard = true,
    key = "j",
    localBindings = {},
    tags = { "browsers" },
    rules = {
      -- { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.brave.Browser"] = {
    bundleID = "com.brave.Browser",
    name = "Brave Browser",
    quitGuard = true,
    -- key = "j",
    localBindings = {},
    tags = { "browsers" },
    rules = {
      -- { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.kapeli.dashdoc"] = {
    bundleID = "com.kapeli.dashdoc",
    name = "Dash",
    key = "d",
    rules = {
      -- { nil, 1, M.layout.centeredLarge },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    key = "s",
    context = "slack",
    distraction = true,
    quitGuard = false,
    rules = {
      -- { nil, 2, M.layout.fullScreen },
    },
  },
  ["com.freron.MailMate"] = {
    bundleID = "com.freron.MailMate",
    name = "MailMate",
    key = "e",
    -- context = "mailmate",
    distraction = true,
    hideAfter = 5,
    rules = {
      -- { nil, 2, M.layout.leftHalf },
      -- { "Inbox", 2, M.layout.fullScreen },
    },
  },
  ["com.apple.finder"] = {
    bundleID = "com.apple.finder",
    name = "Finder",
    key = "f",
    rules = {
      -- { "Finder", 1, M.layout.centeredMedium },
    },
  },
  ["us.zoom.xos"] = {
    bundleID = "us.zoom.xos",
    name = "zoom.us",
    context = "zoom",
    key = "z",
    launchMode = "focus",
    rules = {
      -- { nil, 1, M.layout.centeredMedium },
      -- { "Zoom Meeting", 1, M.layout.fullScreen },
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
    key = "p",
    -- mods = M.modifiers.shift,
    hideAfter = 1,
    rules = {
      -- { nil, 2, M.layout.rightHalf },
    },
  },
  ["com.apple.MobileSMS"] = {
    bundleID = "com.apple.MobileSMS",
    name = "Messages",
    key = "m",
    context = "messages",
    distraction = true,
    tags = { "personal" },
    rules = {
      -- { nil, 2, M.layout.rightHalf },
    },
  },
  ["org.whispersystems.signal-desktop"] = {
    bundleID = "org.whispersystems.signal-desktop",
    name = "Signal",
    key = "w",
    context = "signal",
    distraction = true,
    tags = { "personal" },
    rules = {
      -- { nil, 2, M.layout.rightHalf },
    },
  },
  ["com.agilebits.onepassword7"] = {
    bundleID = "com.agilebits.onepassword7",
    name = "1Password",
    key = "1",
    hideAfter = 1,
    rules = {
      -- { nil, 1, M.layout.centeredMedium },
    },
  },
  ["org.hammerspoon.Hammerspoon"] = {
    bundleID = "org.hammerspoon.Hammerspoon",
    name = "Hammerspoon",
    key = "r",
    context = "hammerspoon",
    hideAfter = 15,
    quitGuard = true,
    rules = {
      -- { nil, 2, M.layout.fullScreen },
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
      -- { nil, 1, M.layout.centeredLarge },
    },
  },
  ["com.figma.Desktop"] = {
    bundleID = "com.figma.Desktop",
    name = "Figma",
    key = "f",
    mods = { "shift" },
    quitGuard = true,
    rules = {
      -- { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.surteesstudios.Bartender"] = {
    bundleID = "com.surteesstudios.Bartender",
    name = "Bartender 4",
    quitGuard = true,
    localBindings = { "b" },
  },
}

local utils = {
  {
    name = "Hammerspoon",
    key = "r",
    mods = { "shift" },
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
    ["grid"] = grid,
    ["keys"] = {
      ["hyper"] = hyper,
      ["ptt"] = ptt,
      ["mods"] = mods,
      ["wm"] = wm,
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
