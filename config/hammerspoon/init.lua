-- [ GLOBALS ] -----------------------------------------------------------------

_G.mega = _G.mega or {
  __loaded_modules = {},
}
_G.ts = function(date)
  date = date or hs.timer.secondsSinceEpoch()
  -- return os.date("%Y-%m-%d %H:%M:%S " .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  return os.date("%Y-%m-%d %H:%M:%S", math.floor(date))
end
_G.fmt = string.format
_G.P = function(...)
  local rest = ...
  if rest == nil then rest = "" end
  hs.rawprint(rest)
  hs.console.printStyledtext(ts() .. " -> " .. fmt(rest))
end
_G.I = hs.inspect
_G.defaultFont = { name = "JetBrainsMono Nerd Font", size = 16 }
local stext = require("hs.styledtext").new
function _G.info(msg)
  hs.console.printStyledtext(stext(ts() .. " -> " .. msg, {
    color = { hex = "#51afef", alpha = 0.7 },
    font = defaultFont,
  }))
end

function _G.success(msg)
  hs.console.printStyledtext(stext(ts() .. " -> " .. msg, {
    color = { hex = "#a7c080", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.error(msg)
  hs.console.printStyledtext(stext(ts() .. " -> " .. msg, {
    color = { hex = "#c43e1f", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.warn(msg)
  hs.console.printStyledtext(stext(ts() .. " -> " .. msg, {
    color = { hex = "#FF922B", alpha = 1 },
    font = defaultFont,
  }))
end

-- [ CONSOLE SETTINGS ] ---------------------------------------------------------

local con = require("hs.console")
con.darkMode(true)
con.consoleFont({ name = "JetBrainsMono Nerd Font", size = 16 })
con.alpha(0.985)
local darkGrayColor = { red = 26 / 255, green = 28 / 255, blue = 39 / 255, alpha = 1.0 }
local whiteColor = { white = 1.0, alpha = 1.0 }
local lightGrayColor = { white = 1.0, alpha = 0.9 }
local grayColor = { red = 24 * 4 / 255, green = 24 * 4 / 255, blue = 24 * 4 / 255, alpha = 1.0 }
con.outputBackgroundColor(darkGrayColor)
con.consoleCommandColor(whiteColor)
con.consoleResultColor(lightGrayColor)
con.consolePrintColor(grayColor)

-- [ BANNER ] ------------------------------------------------------------------

P("")
P("--------------------------------------------------")
P("++ Application Path: " .. hs.processInfo.bundlePath)
P("++    Accessibility: " .. tostring(hs.accessibilityState()))
if hs.processInfo.debugBuild then
  local gitbranchfile = hs.processInfo.resourcePath .. "/gitbranch"
  local gfile = io.open(gitbranchfile, "r")
  if gfile then
    GITBRANCH = gfile:read("l")
    gfile:close()
  else
    GITBRANCH = "<" .. gitbranchfile .. " missing>"
  end
  P("++    Debug Version: " .. hs.processInfo.version .. ", " .. hs.processInfo.buildTime)
  P("++            Build: " .. GITBRANCH)
else
  P("++  Release Version: " .. hs.processInfo.version)
end
P("--------------------------------------------------")
P("")

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
