-- [ GLOBALS ] -----------------------------------------------------------------

_G.mega = _G.mega or {
  __loaded_modules = {},
}
_G.fmt = string.format
_G.P = print
_G.I = hs.inspect

-- [ CONSOLE SETTINGS ] ---------------------------------------------------------

local con = require("hs.console")
con.darkMode(true)
con.consoleFont({ name = "JetBrainsMono Nerd Font", size = 16 })
con.alpha(0.985)
local darkGrayColor = { red = 26 / 255, green = 28 / 255, blue = 39 / 255, alpha = 1.0 }
local whiteColor = { white = 1.0, alpha = 1.0 }
local lightGrayColor = { white = 1.0, alpha = 0.9 }
local purpleColor = { red = 171 / 255, green = 126 / 255, blue = 251 / 255, alpha = 1.0 }
local grayColor = { red = 24 * 4 / 255, green = 24 * 4 / 255, blue = 24 * 4 / 255, alpha = 1.0 }
local blackColor = { white = 0.0, alpha = 1.0 }
con.outputBackgroundColor(darkGrayColor)
con.consoleCommandColor(whiteColor)
con.consoleResultColor(lightGrayColor)
con.consolePrintColor(purpleColor)

-- [ LOCALS ] ------------------------------------------------------------------

local Window = require("hs.window")
local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")
local ipc = require("hs.ipc")
local hs = hs
local load = require("utils.loader").load
local unload = require("utils.loader").unload

-- [ HAMMERSPOON SETTINGS ] ----------------------------------------------------

hs.allowAppleScript(true)
hs.application.enableSpotlightForNameSearches(true)
hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
hs.menuIcon(true)
hs.dockIcon(true)
hs.hotkey.setLogLevel("error")
hs.keycodes.log.setLogLevel("error")
hs.logger.defaultLogLevel = "error"

Window.animationDuration = 0
Window.highlight.ui.overlay = true
Window.setShadows(false)

ipc.cliUninstall()
ipc.cliInstall()

-- [ SPOONS ] ------------------------------------------------------------------

hs.loadSpoon("SpoonInstall")
hs.loadSpoon("EmmyLua")

-- [ LOADERS ] -----------------------------------------------------------------

--  NOTE: order matters
Config = load("config")
load("lib.hyper", { opt = true })
load("lib.watchers")
load("lib.wm")

-- [ UNLOADERS ] ---------------------------------------------------------------

hs.shutdownCallback = function()
  local loaders = { "config", "lib.watchers", "lib.wm", "lib.hyper" }
  FNUtils.each(loaders, function(l) unload(l) end)
  _G.mega = nil
end
