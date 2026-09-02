local M = {}

HYPER = "F19"
BROWSER = "net.imput.helium"
-- BROWSER = "com.nix.brave-browser-nightly"
-- BROWSER = "com.brave.Browser.nightly"
TERMINAL = "com.mitchellh.ghostty"

-- Bundle ID aliases: wrapper bundle ID -> actual running app bundle ID
-- Used by summon.lua to find running apps launched via wrappers
M.bundleIdAliases = {
  ["com.nix.brave-browser-nightly"] = "com.brave.Browser.nightly",
}

M.displays = {
  internal = "Built-in Retina Display",
  laptop = "Built-in Retina Display",
  external = "LG UltraFine",
}

-- Pixel inset applied to every Hammerspoon-managed window frame.
M.windowGap = 5

M.grid = {
  full = "0,0 60x20",
  preview = "0,0 60x2",

  center = {
    large = "6,1 48x18",
    medium = "12,1 36x18",
    small = "16,2 28x16",
    tiny = "18,3 24x12",
    mini = "22,4 16x10",
  },

  sixths = {
    left = "0,0 10x20",
    right = "50,0 10x20",
  },

  thirds = {
    left = "0,0 20x20",
    center = "20,0 20x20",
    right = "40,0 20x20",
  },

  halves = {
    left = "0,0 30x20",
    right = "30,0 30x20",
  },

  twoThirds = {
    left = "0,0 40x20",
    right = "20,0 40x20",
  },

  fiveSixths = {
    left = "0,0 50x20",
    right = "10,0 50x20",
  },
}

M.layouts = {
  --- [bundleID] = { name, bundleID, {{ winTitle, screenNum, gridPosition }} }
  ["com.raycast.macos"] = {
    name = "Raycast",
    bundleID = "com.raycast.macos",
    rules = {
      { nil, 1, M.grid.center.large },
    },
  },
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.github.wez.wezterm"] = {
    bundleID = "com.github.wez.wezterm",
    name = "wezterm",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.mitchellh.ghostty"] = {
    bundleID = "com.mitchellh.ghostty",
    name = "ghostty",
    rules = {
      { "Software Update", 1, M.grid.center.small },
      { "!daily note" }, -- Exclude floating daily note windows
      { "!capture" }, -- Exclude floating capture windows
      { "", 1, M.grid.full },
    },
  },
  ["com.kagi.kagimacOS"] = {
    bundleID = "com.kagi.kagimacOS",
    name = "Orion",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["org.mozilla.floorp"] = {
    bundleID = "org.mozilla.floorp",
    name = "Floorp",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.brave.Browser.nightly"] = {
    bundleID = "com.brave.Browser.nightly",
    name = "Brave Browser Nightly",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.brave.Browser.dev"] = {
    bundleID = "com.brave.Browser.dev",
    name = "Brave Browser Dev",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.apple.Safari"] = {
    bundleID = "com.apple.Safari",
    name = "Safari",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["com.apple.SafariTechnologyPreview"] = {
    bundleID = "com.apple.SafariTechnologyPreview",
    name = "Safari Technology Preview",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["org.chromium.Thorium"] = {
    bundleID = "org.chromium.Thorium",
    name = "Thorium",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["org.chromium.Chromium"] = {
    bundleID = "org.chromium.Chromium",
    name = "Chromium",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["org.mozilla.firefoxdeveloperedition"] = {
    bundleID = "org.mozilla.firefoxdeveloperedition",
    name = "Firefox Developer Edition",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["com.kapeli.dashdoc"] = {
    bundleID = "com.kapeli.dashdoc",
    name = "Dash",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.obsproject.obs-studio"] = {
    bundleID = "com.obsproject.obs-studio",
    name = "OBS Studio",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["co.detail.mac"] = {
    bundleID = "co.detail.mac",
    name = "Detail",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["io.canarymail.mac"] = {
    bundleID = "io.canarymail.mac",
    name = "Canary Mail",
    rules = {
      -- Named windows take precedence over the catch-all below.
      { "Inbox - All", 2, M.grid.full },
      -- Compose windows, individual message viewers, etc.
      { "", 2, M.grid.halves.right },
    },
  },
  ["com.freron.MailMate"] = {
    bundleID = "com.freron.MailMate",
    name = "MailMate",
    rules = {
      -- Named windows take precedence over the catch-all below.
      { "Inbox", 2, M.grid.full },
      { "Unread", 2, M.grid.full },
      { "All Messages", 2, M.grid.full },
      -- Compose windows, individual message viewers, etc.
      { "", 2, M.grid.halves.right },
    },
  },
  ["com.apple.finder"] = {
    bundleID = "com.apple.finder",
    name = "Finder",
    rules = {
      { "", 1, M.grid.center.medium },
    },
  },
  ["com.apple.Music"] = {
    bundleID = "com.apple.Music",
    name = "Music",
    rules = {
      { "", 2, M.grid.halves.right },
    },
  },
  -- ["com.spotify.client"] = {
  --   bundleID = "com.spotify.client",
  --   name = "Spotify",
  --   rules = {
  --     { "", 2, M.grid.halves.right },
  --   },
  -- },
  ["com.electron.postbird"] = {
    bundleID = "com.electron.postbird",
    name = "Postbird",
    rules = {
      { "", 1, M.grid.center.large },
    },
  },
  ["com.apple.MobileSMS"] = {
    bundleID = "com.apple.MobileSMS",
    name = "Messages",
    rules = {
      -- { "", 2, M.grid.full },
      -- { "", 2, M.grid.thirds.left },
      { "", 2, M.grid.halves.left },
    },
  },
  ["org.whispersystems.signal-desktop"] = {
    bundleID = "org.whispersystems.signal-desktop",
    name = "Signal",
    rules = {
      { "", 2, M.grid.halves.right },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    rules = {
      { nil, 2, M.grid.halves.right },
    },
  },
  ["com.agilebits.onepassword7"] = {
    bundleID = "com.1password.1password",
    name = "1Password",
    rules = {
      { nil, 1, M.grid.center.medium },
    },
  },
  ["org.hammerspoon.Hammerspoon"] = {
    bundleID = "org.hammerspoon.Hammerspoon",
    name = "Hammerspoon",
    rules = {
      { nil, 1, M.grid.full },
    },
  },
  -- ["com.dexterleng.Homerow"] = {
  --   bundleID = "com.dexterleng.Homerow",
  --   name = "Homerow",
  --   rules = {
  --     { nil, 1, M.grid.center.large },
  --   },
  -- },
  ["com.flexibits.fantastical2.mac"] = {
    bundleID = "com.flexibits.fantastical2.mac",
    name = "Fantastical",
    rules = {
      { nil, 1, M.grid.center.large },
    },
  },
  ["com.apple.iCal"] = {
    bundleID = "com.apple.iCal",
    name = "Calendar",
    rules = {
      { nil, 1, M.grid.center.large },
    },
  },
  ["com.figma.Desktop"] = {
    bundleID = "com.figma.Desktop",
    name = "Figma",
    rules = {
      { nil, 1, M.grid.full },
    },
  },
  ["com.apple.iphonesimulator"] = {
    bundleID = "com.apple.iphonesimulator",
    name = "iPhone Simulator",
    rules = {
      { nil, 1, M.grid.halves.right },
    },
  },
  ["com.softfever3d.orca-slicer"] = {
    bundleID = "com.softfever3d.orca-slicer",
    name = "OrcaSlicer",
    rules = {
      { "", 1, M.grid.full },
    },
  },
}

-- Quitter Configuration
-- Prevents accidental Cmd+Q quits for important apps
-- Modes:
--   "single" = one Cmd+Q quits (use with nuke=true for instant death)
--   "double" = press Cmd+Q twice within 1s to quit
--   "long"   = hold Cmd+Q for 1s to quit
-- Options:
--   nuke = true means use kill9() (SIGKILL) instead of graceful kill()
M.quitters = {
  ["us.zoom.xos"] = { mode = "single", nuke = true },

  ["com.brave.Browser.nightly"] = { mode = "double" },
  ["com.brave.Browser.dev"] = { mode = "double" },
  ["com.brave.Browser"] = { mode = "double" },
  ["net.imput.helium"] = { mode = "double" },
  ["org.chromium.Thorium"] = { mode = "double" },
  ["org.chromium.Chromium"] = { mode = "double" },
  ["com.kagi.kagimacOS"] = { mode = "double" },
  ["org.mozilla.firefoxdeveloperedition"] = { mode = "double" },
  ["com.apple.SafariTechnologyPreview"] = { mode = "double" },
  ["com.apple.Safari"] = { mode = "double" },
  ["com.mitchellh.ghostty"] = { mode = "double" },
  ["net.kovidgoyal.kitty"] = { mode = "double" },
  ["com.github.wez.wezterm"] = { mode = "double" },
  -- ["com.raycast.macos"] = { mode = "double" },
  ["com.runningwithcrayons.Alfred"] = { mode = "double" },
  ["com.pop.pop.app"] = { mode = "double" },
}

-- Reserved Hyper Keys
-- Keys that are globally reserved and cannot be bound to other actions
-- Used to prevent future binding conflicts (e.g., HYPER+Q for force quit)
M.reservedHyperKeys = {
  q = "Force Quit (NUKE IT!)",
}

M.lollygaggers = {
  --- [bundleID] = { hideAfter, quitAfter }
  ["org.hammerspoon.Hammerspoon"] = { 1, nil },
  ["com.flexibits.fantastical2.mac"] = { 1, nil },
  ["com.1password.1password"] = { 1, nil },
  -- ["com.spotify.client"] = { 1, nil },
  ["com.apple.Music"] = { 1, nil },
}

M.launchers = {
  -- launchCommand: cold-start only. It loads avwatchweb and keeps CDP 9223
  -- for chrome-devtools-attach. Running app keeps normal cycle/focus behavior.
  { BROWSER, "j", { cycleWindows = true, launchCommand = os.getenv("HOME") .. "/bin/helium-launch" } },
  { TERMINAL, "k", { passThrough = { "`" } } },
  -- { "net.kovidgoyal.kitty", "k" },
  { "com.apple.MobileSMS", "m" }, -- NOOP for now.. TODO: implement a binding feature that let's us require n-presses before we execute
  { "com.apple.finder", "f" },
  -- { "com.spotify.client", "p" },
  { "com.apple.Music", "p" },
  { "com.freron.MailMate", "e" },
  { "io.canarymail.mac", "e", { cycleWindows = true } },
  {
    "com.flexibits.fantastical2.mac",
    "y",
    {
      urlSchemes = {
        { "'", "x-fantastical3://parse?sentence=" },
        { { { "shift" }, "'" }, "x-fantastical3://parse?reminder=1&sentence=" },
      },
    },
  },
  -- { "com.apple.iCal", "y", { passThrough = { "'" } } },
  -- { "com.raycast.macos", "space", { passThrough = { "c" } } },
  {
    "com.brnbw.Tuna",
    nil,
    { urlSchemes = { { "space", "tuna://search" } } },
  },
  -- { "com.superultra.Homerow", nil, { passThrough = { ";" } } },
  { "com.tinyspeck.slackmacgap", "s" },
  { "com.tdesktop.Telegram", "t" },
  { "org.hammerspoon.Hammerspoon", "r" },
  -- { "com.kapeli.dashdoc", { { "shift" }, "d" }, { passThrough = { "d" } } },
  -- { "com.electron.postbird", { { "shift" }, "p" } },
  { "com.1password.1password", "1" },
  -- { "commonplace.canonize.app", nil, { passThrough = { { { "shift" }, "s" } } } },
  { "com.apple.dt.Xcode", "x", { focusOnly = true } },
  -- { "com.obsproject.obs-studio", "o", { focusOnly = true } },
  { "com.microsoft.VSCode", "v", { focusOnly = true } },
  -- { "com.culturedcode.ThingsMac", nil, { passThrough = { "return" } } },
}

M.dock = {
  target = {
    productID = 39536,
    productName = "LG UltraFine Display Controls",
    vendorID = 1086,
    vendorName = "LG Electronics Inc.",
  },
  target_alt = {
    productID = 21760,
    productName = "TS4 USB3.2 Gen2 HUB",
    vendorID = 8584,
    vendorName = "CalDigit, Inc",
  },
  keyboard = {
    connected = "leeloo",
    disconnected = "internal",
    productID = 24926,
    productName = "Leeloo",
    vendorID = 7504,
    vendorName = "ZMK Project",
    bluetoothAddress = "f3-d9-8d-01-16-54",
    bluetoothPollInterval = 5, -- seconds between BT connection checks
  },
  kanata = {
    enabled = true,
    connected = "macbook-disabled.kbd", -- Disable internal when Leeloo connected
    disconnected = "macbook.kbd", -- Normal config when Leeloo disconnected
    configPath = os.getenv("HOME") .. "/.config/kanata",
    -- INTENTIONAL divergence from the old nix twin (now removed from the
    -- repo): mise prefixes bootstrap launchd labels with `dev.mise.` (see
    -- mise/tasks/kanata-setup); nix-darwin's label was bare
    -- `org.kanata.daemon`. Keep the prefixed label.
    daemonLabel = "dev.mise.org.kanata.daemon",
  },
  docked = {
    wifi = "off",
    input = "Samson GoMic",
    output = "megabose",
  },
  undocked = {
    wifi = "on",
    input = "megabose",
    output = "megabose",
  },
}

M.notifier = {
  -- Shared HUD/remote routing used by N.send() and bin/ntfy.
  urgencyDisplay = {
    critical = { position = "center", dim = true, phone = true },
    high = { position = "center", dim = true, phone = false },
    normal = { position = "corner", dim = false, phone = false },
  },

  -- Dismiss active HUD notifications with F19+escape.
  dismissBindings = { {}, "escape" },

  agent = {
    durations = {
      normal = 5,
      high = 10,
      critical = 15,
    },

    questionRetry = {
      enabled = true,
      intervalSeconds = 300,
      maxRetries = 3,
      escalateOnRetry = true,
    },

    phone = {
      enabled = true,
      cacheTTL = 604800,
    },
  },
}

-- Pi Gateway Configuration
-- Manages a dedicated pi agent via RPC for Telegram orchestration
M.piGateway = {
  -- Enable/disable the gateway
  enabled = false,

  -- Default pi profile (auth cascade: tries this first, then fallbacks)
  defaultProfile = "mega",

  -- Queue behavior
  prioritySignal = "!!", -- Messages starting with this jump queue + steer if busy
  abortPhrases = { "abort!", "stop!", "kill!", "cancel!" }, -- Emergency abort triggers
  -- Additional commands (hardcoded, not configurable):
  --   status? / queue? / q? = Show queue status
  --   clear! / flush!       = Clear all queued messages

  -- Reliability
  taskTimeoutMinutes = 15, -- Hard timeout (extends if activity detected)
  activityTimeoutSeconds = 60, -- No activity for this long = stuck
  circuitBreakerThreshold = 5, -- Consecutive failures before cooldown
  circuitBreakerCooldownSeconds = 60, -- Cooldown duration
  healthCheckIntervalSeconds = 30, -- Health check frequency
  healthCheckTimeoutSeconds = 10, -- Response timeout for health ping

  -- History (XDG_DATA_HOME)
  historyRotation = "monthly", -- "daily" | "weekly" | "monthly" | "yearly"
  historyPath = os.getenv("HOME") .. "/.local/share/pi/telegram/history",
  archivePath = os.getenv("HOME") .. "/.local/share/pi/telegram/archives",

  -- Logs (XDG_STATE_HOME)
  logPath = os.getenv("HOME") .. "/.local/state/pi/telegram/orchestrator.log",
}

local extra_config = {}

local success, _ = pcall(function() extra_config = require("extra_config") end)

if success then
  for key, _ in pairs(M) do
    if extra_config[key] then M[key] = extra_config[key] end
    if M[key] == "" then M[key] = nil end
  end
end

return M
