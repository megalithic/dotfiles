-- [ GLOBALS ] -----------------------------------------------------------------

_G.mega = _G.mega or {
  __loaded_modules = {},
}
_G.L = require("utils.loader")
_G.U = require("utils")
_G.ts = function(date)
  date = date or hs.timer.secondsSinceEpoch()
  -- return os.date("%Y-%m-%d %H:%M:%S " .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  return os.date("%Y-%m-%d %H:%M:%S", math.floor(date))
end
_G.fmt = string.format
_G.P = function(...)
  if ... == nil then
    hs.rawprint("")
    print("")
    return
  end

  local contents = ...

  if type(...) == "table" then
    contents = tostring(...)
  else
    contents = fmt(...)
  end

  hs.rawprint(...)
  hs.console.printStyledtext(ts() .. " -> " .. contents)
end
_G.I = hs.inspect
_G.defaultFont = { name = "JetBrainsMono Nerd Font", size = 18 }

local stext = require("hs.styledtext").new
local getInfo = function()
  local info = debug.getinfo(2, "Sl")
  local lineinfo = fmt("%s:%s: ", info.short_src, info.currentline)
  return ""
end
function _G.info(msg, tag)
  tag = tag and "[INFO] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#51afef", alpha = 0.65 },
    font = defaultFont,
  }))
end

function _G.success(msg, tag)
  tag = tag and "[OK] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#a7c080", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.error(msg, tag)
  tag = tag and "[ERROR] " or ""

  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. getInfo() .. msg, {
    color = { hex = "#c43e1f", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.warn(msg, tag)
  tag = tag and "[WARN] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#FF922B", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.dbg(msg, tag)
  tag = tag and "[DEBUG] " or "[DEBUG] "
  msg = type(msg) == "table" and I(msg) or msg

  -- hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. getInfo() .. msg, {
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#dddddd", alpha = 1 },
    backgroundColor = { hex = "#222222", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.note(msg, tag)
  tag = tag and "[NOTE] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#444444", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.windows()
  local app
  if type(app) == "string" then app = hs.application.get(app) end
  local windows = app == nil and hs.window.allWindows() or app:allWindows()

  hs.fnutils.each(windows, function(win)
    info(fmt("[WIN] %s (%s)", win:title(), win:application():bundleID()))
    note(I({
      id = win:id(),
      title = win:title(),
      app = win:application():name(),
      bundleID = win:application():bundleID(),
      role = win:role(),
      subrole = win:subrole(),
      frame = win:frame(),
      isFullScreen = win:isFullScreen(),
      isStandard = win:isStandard(),
      isMinimized = win:isMinimized(),
      -- buttonZoom       = axuiWindowElement(win):attributeValue('AXZoomButton'),
      -- buttonFullScreen = axuiWindowElement(win):attributeValue('AXFullScreenButton'),
      -- isResizable      = axuiWindowElement(win):isAttributeSettable('AXSize')
    }))
  end)
end

_G.CONFIG_KEY = "_mega_config"

-- [ CONSOLE SETTINGS ] ---------------------------------------------------------

local con = require("hs.console")
con.darkMode(true)
con.consoleFont(defaultFont)
con.alpha(0.985)
local darkGrayColor = { red = 26 / 255, green = 28 / 255, blue = 39 / 255, alpha = 1.0 }
local whiteColor = { white = 1.0, alpha = 1.0 }
local lightGrayColor = { white = 1.0, alpha = 0.9 }
local grayColor = { red = 24 * 4 / 255, green = 24 * 4 / 255, blue = 24 * 4 / 255, alpha = 1.0 }
con.outputBackgroundColor(darkGrayColor)
con.consoleCommandColor(whiteColor)
con.consoleResultColor(lightGrayColor)
con.consolePrintColor(grayColor)

-- [ LOCALS ] ------------------------------------------------------------------

local Window = require("hs.window")
local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")
local ipc = require("hs.ipc")
local hs = hs
local load = L.load
local unload = L.unload

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
load("config")
load("lib.bindings"):start()
load("lib.menubar.ptt"):start()
load("lib.menubar.spotify"):start()
load("lib.watchers"):start()
load("lib.wm"):start()

-- [ UNLOADERS ] ---------------------------------------------------------------

hs.shutdownCallback = function()
  local loaders = { "config", "lib.watchers", "lib.wm" }
  FNUtils.each(loaders, function(l) unload(l) end)
  _G.mega = nil
end

-- [ BANNER ] ------------------------------------------------------------------

P()
info("----------------------------------------------------")
info("░  Application Path: " .. hs.processInfo.bundlePath)
info("░  Accessibility: " .. tostring(hs.accessibilityState()))
if hs.processInfo.debugBuild then
  local gitbranchfile = hs.processInfo.resourcePath .. "/gitbranch"
  local gfile = io.open(gitbranchfile, "r")
  if gfile then
    GITBRANCH = gfile:read("l")
    gfile:close()
  else
    GITBRANCH = "<" .. gitbranchfile .. " missing>"
  end
  success("░  Debug Version: " .. hs.processInfo.version .. ", " .. hs.processInfo.buildTime)
  success("░  Build: " .. GITBRANCH)
else
  info("░  Release Version: " .. hs.processInfo.version)
end
info("----------------------------------------------------")
P()

hs.notify.new({ title = "Hammerspoon", subTitle = "Configuration successfully loaded" }):send()
