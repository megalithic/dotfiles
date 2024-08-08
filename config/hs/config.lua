local enum = require("hs.fnutils")
local window = require("hs.window")
local ipc = require("hs.ipc")

-- [ HAMMERSPOON SETTINGS ] ----------------------------------------------------

hs.allowAppleScript(true)
hs.application.enableSpotlightForNameSearches(false)
hs.autoLaunch(true)
hs.consoleOnTop(false)
hs.automaticallyCheckForUpdates(true)
hs.menuIcon(true)
hs.dockIcon(true)
hs.logger.defaultLogLevel = "error"
hs.hotkey.setLogLevel("error")
hs.keycodes.log.setLogLevel("error")

window.animationDuration = 0
window.highlight.ui.overlay = false
window.setShadows(false)

ipc.cliUninstall()
ipc.cliInstall()

hs.grid.setGrid("60x20")
hs.grid.setMargins("0x0")

-- [ CONSOLE SETTINGS ] --------------------------------------------------------

local con = require("hs.console")
con.darkMode(true)
con.consoleFont(DefaultFont)
con.alpha(0.985)
local darkGrayColor = { red = 26 / 255, green = 28 / 255, blue = 39 / 255, alpha = 1.0 }
local whiteColor = { white = 1.0, alpha = 1.0 }
local lightGrayColor = { white = 1.0, alpha = 0.9 }
local grayColor = { red = 24 * 4 / 255, green = 24 * 4 / 255, blue = 24 * 4 / 255, alpha = 1.0 }
con.outputBackgroundColor(darkGrayColor)
con.consoleCommandColor(whiteColor)
con.consoleResultColor(lightGrayColor)
con.consolePrintColor(grayColor)

-- [ ALERT SETTINGS ] ----------------------------------------------------------
--
hs.alert.defaultStyle["textSize"] = 24
hs.alert.defaultStyle["radius"] = 20
hs.alert.defaultStyle["strokeColor"] = {
  white = 1,
  alpha = 0,
}
hs.alert.defaultStyle["fillColor"] = {
  red = 9 / 255,
  green = 8 / 255,
  blue = 32 / 255,
  alpha = 0.9,
}
hs.alert.defaultStyle["textColor"] = {
  red = 209 / 255,
  green = 236 / 255,
  blue = 240 / 255,
  alpha = 1,
}
hs.alert.defaultStyle["textFont"] = "JetBrainsMono Nerd Font"

HYPER = "F19"

BROWSER = "com.brave.Browser.nightly"
TERMINAL = "com.mitchellh.ghostty"

DISPLAYS = {
  internal = "Built-in Retina Display",
  laptop = "Built-in Retina Display",
  external = "LG UltraFine",
}

-- bundleID, global, { local }, {pos, screen}
APPS = {
  { "com.brave.Browser.nightly", "j", nil },
  { "com.mitchellh.ghostty", "k", nil },
  { "com.apple.MobileSMS", "m", nil },
  { "com.apple.finder", "f", nil },
  { "com.spotify.client", "p", nil },
  { "com.freron.MailMate", "e", nil },
  { "com.flexibits.fantastical2.mac", "y", { "'" } },
  { "com.raycast.macos", "space", { "c", "space" } },
  { "com.superultra.Homerow", nil, { ";" } },
  { "com.dexterleng.Homerow", nil, { ";" } },
  { "com.tinyspeck.slackmacgap", "s" },
  { "org.hammerspoon.Hammerspoon", "r" },
}

LAYOUTS = {}

QUITTERS = {
  "org.chromium.Thorium",
  "org.chromium.Chromium",
  "Brave Browser Nightly",
  "com.pop.pop.app",
  "com.kagi.kagimacOS",
  "com.brave.Browser.nightly",
  "com.brave.Browser.dev",
  "com.brave.Browser",
  "com.raycast.macos",
  "com.runningwithcrayons.Alfred",
  "net.kovidgoyal.kitty",
  "org.mozilla.firefoxdeveloperedition",
  "com.apple.SafariTechnologyPreview",
  "com.apple.Safari",
  "com.mitchellh.ghostty",
  "com.github.wez.wezterm",
}

LOLLYGAGGERS = {
  { "org.hammerspoon.Hammerspoon", 1 },
  { "com.flexibits.fantastical2.mac", 1 },
  { "com.1password.1password", 1 },
  { "com.spotify.client", 1 },
}

POSITIONS = {
  full = "0,0 60x20",

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

DOCK = {
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
    output = "R-Phonak hearing aid", -- speaker source
  },
  undocked = {
    wifi = "on",
    input = "R-Phonak hearing aid",
    output = "R-Phonak hearing aid",
  },
}

info(fmt("[START] %s", "config"))
