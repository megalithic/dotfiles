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

--- @class QuitterOpts
--- @field [1] string
local quitters = {
  "com.brave.Browser.dev",
  "com.brave.Browser",
  "com.raycast.macos",
  "com.runningwithcrayons.Alfred",
  "net.kovidgoyal.kitty",
  -- "com.github.wez.wezterm", -- stuck with wezterm's built in confirm, need to remove this
}

--- @class WindowRuleOpts
--- @field [1] string Window title
--- @field [2] number Screen number
--- @field [3] string Window position

--- @class TargetOpts
--- @field [1] string Target identifier; an application bundleID, a url pattern
--- @field locals? string[] Keys for local bindings
--- @field rules WindowRuleOpts[] Rules for how/where to place windows for a target

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
    target = {
      {
        "com.obsproject.obs-studio",
        locals = {},
        rules = {
          { "", 2, "maximized" },
        },
      },
    },
  },
  {
    "net.kovidgoyal.kitty",
    -- key = "k",
    target = {
      {
        "net.kovidgoyal.kitty",
        locals = {},
        rules = {
          { "", 1, "maximized" },
        },
      },
    },
  },
  {
    key = "k",
    target = {
      {
        "com.github.wez.wezterm",
        locals = {},
        rules = {
          { "", 1, "maximized" },
        },
      },
    },
  },
}

-- FIXME: separate launchers keybindings from apps layouts
local apps = {
  ["com.runningwithcrayons.Alfred"] = {
    name = "Alfred",
    bundleID = "com.runningwithcrayons.Alfred",
    -- key = "space",
  },
  ["com.raycast.macos"] = {
    name = "Raycast",
    bundleID = "com.raycast.macos",
    key = "space",
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
    localBindings = {},
    tags = { "browsers" },
    rules = {
      { "", 1, "maximized" },
    },
  },
  ["com.brave.Browser"] = {
    bundleID = "com.brave.Browser",
    name = "Brave Browser",
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
  ["com.obsproject.obs-studio"] = {
    bundleID = "com.obsproject.obs-studio",
    name = "OBS Studio",
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
  -- ["com.pop.pop.app"] = {
  --   bundleID = "com.pop.pop.app",
  --   name = "Pop",
  --   key = "z",
  --   -- launcher = function()
  --   --   if hs.application.find("us.zoom.xos") then
  --   --     hs.application.launchOrFocusByBundleID("us.zoom.xos")
  --   --   else
  --   --   end
  --   -- end,
  --   launchMode = "focus",
  -- },
  -- ["us.zoom.xos"] = {
  --   bundleID = "us.zoom.xos",
  --   name = "zoom.us",
  --   key = "z",
  --   -- launcher = function()
  --   --   if hs.application.find("us.zoom.xos") then
  --   --     hs.application.launchOrFocusByBundleID("us.zoom.xos")
  --   --   else
  --   --     require("lib.browser").jump("meet.google.com|hangouts.google.com.call")
  --   --   end
  --   -- end,
  --   launchMode = "focus",
  -- },

  -- ["com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan"] = {
  --   bundleID = "com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",
  --   name = "Google Meet",
  --   key = "z",
  --   -- launcher = function()
  --   --   if hs.application.find("us.zoom.xos") then
  --   --     hs.application.launchOrFocusByBundleID("us.zoom.xos")
  --   --   else
  --   --     require("lib.browser").jump("meet.google.com|hangouts.google.com.call")
  --   --   end
  --   -- end,
  --   launchMode = "focus",
  -- },

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
    key = "s",
    mods = mods.caSc,
    distraction = true,
    -- tags = { "chat" },
    rules = {
      { "", 2, "right50" },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    -- tags = { "chat" },
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
    -- key = "f",
    -- mods = mods.caSc,
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
    input = "MacBook Pro Microphone",
    output = "R-Phonak hearing aid",
  },
}

return {
  ["bindings"] = {
    ["apps"] = apps,
    ["utils"] = utils,
    ["launchers"] = launchers,
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
  ["quitters"] = quitters,
}
