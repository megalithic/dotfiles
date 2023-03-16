local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "config"

obj.settings = {}

local preferred = {
  terms = { "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = {
    hs.urlevent.getDefaultHandler("https"),
    "Chromium",
    "Brave Browser Dev",
    "Firefox",
    "Vivaldi",
    "Firefox Developer Edition",
    "Brave Browser",
    "Brave Browser Beta",
    "Google Chrome",
    "Safari",
  },
  personal = { "Messages" },
  chat = { "Slack", "Signal" },
  media = { "Spotify" },
  vpn = { "Cloudflare WARP" },
}
preferred["browser"] = "com.brave.Browser.dev" --hs.urlevent.getDefaultHandler("https")

local watchers = { "status", "bluetooth", "dock", "audio", "wifi", "url", "downloads" }

local transientApps = {
  ["LaunchBar"] = { allowRoles = "AXSystemDialog" },
  -- ["1Password 7"] = { allowTitles = "1Password mini" },
  ["Spotlight"] = { allowRoles = "AXSystemDialog" },
  ["Paletro"] = { allowRoles = "AXSystemDialog" },
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true,
}

local networks = { "shaolin" }

local displays = {
  -- laptop = "Color LCD",
  laptop = "Built-in Retina Display",
  external = "LG UltraFine",
}
displays["internal"] = displays.laptop

-- if hs.network.configuration:hostname() == "megabookpro" then
--   displays.laptop = "Built-in Retina Display"
--   print(displays.laptop)
-- end

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
    -- key = "space",
    quitter = true,
  },
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    key = "k",
    quitter = true,
    localBindings = {},
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.github.wez.wezterm"] = {
    bundleID = "com.github.wez.wezterm",
    name = "wezterm",
    -- key = "k",
    -- quitter = true,
    localBindings = {},
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["org.chromium.Chromium"] = {
    bundleID = "org.chromium.Chromium",
    name = "Chromium",
    key = "j",
    quitter = true,
    localBindings = {},
    tags = { "browsers" },
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
    -- key = "j",
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
  ["com.obsproject.obs-studio"] = {
    bundleID = "com.obsproject.obs-studio",
    name = "OBS Studio",
    key = "o",
    launchMode = "focus",
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
      { "All Messages", 2, "maximized" },
    },
  },

  ["com.binarynights.ForkLift-3"] = {
    bundleID = "com.binarynights.ForkLift-3",
    name = "ForkLift",
    -- key = "f",
    rules = {
      { "", 1, "centeredMedium" },
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
  ["com.pop.pop.app"] = {
    bundleID = "com.pop.pop.app",
    name = "Pop",
    key = "z",
    -- launcher = function()
    --   if hs.application.find("us.zoom.xos") then
    --     hs.application.launchOrFocusByBundleID("us.zoom.xos")
    --   else
    --     require("lib.browser").jump("meet.google.com|hangouts.google.com.call")
    --   end
    -- end,
    launchMode = "focus",
  },
  ["us.zoom.xos"] = {
    bundleID = "us.zoom.xos",
    name = "zoom.us",
    key = "z",
    -- launcher = function()
    --   if hs.application.find("us.zoom.xos") then
    --     hs.application.launchOrFocusByBundleID("us.zoom.xos")
    --   else
    --     require("lib.browser").jump("meet.google.com|hangouts.google.com.call")
    --   end
    -- end,
    launchMode = "focus",
  },

  ["com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan"] = {
    bundleID = "com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",
    name = "Google Meet",
    key = "z",
    -- launcher = function()
    --   if hs.application.find("us.zoom.xos") then
    --     hs.application.launchOrFocusByBundleID("us.zoom.xos")
    --   else
    --     require("lib.browser").jump("meet.google.com|hangouts.google.com.call")
    --   end
    -- end,
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
  ["com.electron.postbird"] = {
    bundleID = "com.electron.postbird",
    name = "Postbird",
    key = "p",
    mods = mods.caSc,
    hideAfter = 1,
    rules = {
      { "", 1, "centeredLarge" },
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
    tags = { "chat" },
    rules = {
      { "", 2, "right50" },
    },
  },
  ["com.agilebits.onepassword7"] = {
    bundleID = "com.1password.1password",
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
    productID = 4675,
    productName = "Audioengine HD3",
    vendorID = 2578,
    vendorName = "Audioengine",
  },
  ["keyboard"] = {
    productID = 24926,
    productName = "Leeloo",
    vendorID = 7504,
    vendorName = "ZMK Project",
    -- productID = 24674,
    -- productName = "Atreus62",
    -- vendorID = 65261,
    -- vendorName = "Profet",
  },
  ["docked"] = {
    wifi = "off", -- wifi status
    profile = "leeloo", -- Karabiner-Elements profile name
    input = "Samson GoMic", -- microphone source
    -- https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/headphones.lua
    output = "R-Phonak hearing aid", -- speaker source
  },
  ["undocked"] = {
    wifi = "on",
    profile = "internal",
    input = "R-Phonak hearing aid",
    output = "R-Phonak hearing aid",
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
