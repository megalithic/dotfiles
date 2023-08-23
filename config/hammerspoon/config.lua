local preferred = {
  terms = { "wezterm", "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
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

local transientApps = {
  -- ["LaunchBar"] = { allowRoles = "AXSystemDialog" },
  ["1Password 7"] = { allowTitles = "1Password mini" },
  ["Spotlight"] = { allowRoles = "AXSystemDialog" },
  -- ["Paletro"] = { allowRoles = "AXSystemDialog" },
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true,
}

local networks = { "shaolin", "Ginger-Guest" }

local displays = {
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

--- @class QuitterOpts
--- @field [1] string
local quitters = {
  "com.brave.Browser.dev",
  "com.brave.Browser",
  "com.raycast.macos",
  "com.runningwithcrayons.Alfred",
  "net.kovidgoyal.kitty",
  "org.mozilla.firefoxdeveloperedition",
  "com.apple.SafariTechnologyPreview",
  "com.apple.Safari",
  -- "com.github.wez.wezterm", -- stuck with wezterm's built in confirm, need to remove this
}

--- @class TargetOpts
--- @field [1] string Target identifier; an application bundleID, a url pattern
--- @field locals? string[] Keys for local bindings

--- @class LauncherOpts
--- @field key string Keyboard key for focusing/launching this target
--- @field mods? string[]|string Keyboard modifiers (cmd, alt/opt, shift, ctrl)
--- @field mode? "focus"|"launch" The mode that we use to launch; focus-only or launch if not opened
--- @field target? TargetOpts[]|string List of possible targets this keybinding would cycle through (NOTE: only works with mode set to "focus" order matters).
local launchers = {
  {
    key = "z",
    mode = "focus",
    target = {
      { "com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan" },
      { "us.zoom.xos" },
      { "com.pop.pop.app" },
      { "https://whereby.com" },
      { "https://meet.google.com" },
    },
  },
  {
    key = "o",
    mode = "focus",
    target = "com.obsproject.obs-studio",
  },
  {
    key = "o",
    mode = "focus",
    target = "co.detail.mac",
  },
  {
    key = "f",
    mods = mods.caSc,
    mode = "focus",
    target = "com.figma.Desktop",
  },
  {
    key = "x",
    mode = "focus",
    target = {
      { "com.apple.dt.Xcode" },
      { "com.google.android.studio" },
    },
  },
  {
    key = "k",
    target = "com.github.wez.wezterm",
  },
  {
    key = "space",
    target = "com.raycast.macos",
  },
  {
    key = "j",
    mods = mods.caSc,
    target = "org.mozilla.firefoxdeveloperedition",
  },
}

local layouts = {
  ["com.runningwithcrayons.Alfred"] = {
    name = "Alfred",
    bundleID = "com.runningwithcrayons.Alfred",
  },
  ["com.raycast.macos"] = {
    name = "Raycast",
    bundleID = "com.raycast.macos",
    rules = {
      { "", 1, "centeredMedium" },
    },
  },
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.github.wez.wezterm"] = {
    bundleID = "com.github.wez.wezterm",
    name = "wezterm",
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.brave.Browser.dev"] = {
    bundleID = "com.brave.Browser.dev",
    name = "Brave Browser Dev",
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.apple.Safari"] = {
    bundleID = "com.apple.Safari",
    name = "Safari",
    tags = { "browsers" },
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["com.apple.SafariTechnologyPreview"] = {
    bundleID = "com.apple.SafariTechnologyPreview",
    name = "Safari Technology Preview",
    tags = { "browsers" },
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["org.chromium.Chromium"] = {
    bundleID = "org.chromium.Chromium",
    name = "Chromium",
    quitter = true,
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["org.mozilla.firefoxdeveloperedition"] = {
    bundleID = "org.mozilla.firefoxdeveloperedition",
    name = "Firefox Developer Edition",
    tags = { "browsers" },
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["com.kapeli.dashdoc"] = {
    bundleID = "com.kapeli.dashdoc",
    name = "Dash",
    mods = mods.caSc,
    key = "d",
    localBindings = { "d" },
    rules = {
      { "", 1, "centeredLarge" },
    },
  },
  ["com.obsproject.obs-studio"] = {
    bundleID = "com.obsproject.obs-studio",
    name = "OBS Studio",
    rules = {
      { "", 2, "maximized" },
    },
  },
  ["co.detail.mac"] = {
    bundleID = "co.detail.mac",
    name = "Detail",
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
  ["com.apple.finder"] = {
    bundleID = "com.apple.finder",
    name = "Finder",
    key = "f",
    rules = {
      { "", 1, "centeredMedium" },
    },
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
    key = "m",
    mods = mods.caSc,
    distraction = true,
    rules = {
      { "", 2, "right50" },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    key = "s",
    distraction = true,
    rules = {
      { "", 2, "maximized" },
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
  ["com.dexterleng.Homerow"] = {
    bundleID = "com.dexterleng.Homerow",
    name = "Homerow",
    localBindings = { ";" },
    quitter = true,
    rules = {
      { "", 1, "centeredLarge" },
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
    launchMode = "focus",
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
  target = {
    productID = 39536,
    productName = "LG UltraFine Display Controls",
    vendorID = 1086,
    vendorName = "LG Electronics Inc.",
  },
  keyboard = {
    connected = "leeloo",
    disconnected = "internal",
    productID = 24926,
    productName = "Leeloo",
    vendorID = 7504,
    vendorName = "ZMK Project",
  },
  docked = {
    wifi = "off", -- wifi status
    input = "Samson GoMic", -- microphone source
    -- input = "R-Phonak hearing aid",
    output = "R-Phonak hearing aid", -- speaker source
  },
  undocked = {
    wifi = "on",
    input = "R-Phonak hearing aid",
    output = "R-Phonak hearing aid",
  },
}

return {
  ["layouts"] = layouts,
  ["bindings"] = {
    ["apps"] = layouts,
    ["utils"] = utils,
    ["launchers"] = launchers,
  },
  ["dirs"] = dirs,
  ["displays"] = displays,
  ["screens"] = displays,
  ["keys"] = {
    ["hyper"] = hyper,
    ["ptt"] = ptt,
    ["mods"] = mods,
  },
  ["networks"] = networks,
  ["preferred"] = preferred,
  ["transientApps"] = transientApps,
  ["dock"] = dock,
  ["quitters"] = quitters,
}
