-- [ GLOBALS ] ------------------------------------------------------------------

_G.debug_enabled = true

-- [ BOOTSTRAP/PRELOAD ] ------------------------------------------------------------------

require("preflight")

-- [ LOCALS ] ------------------------------------------------------------------

local Window = require("hs.window")
local FNUtils = require("hs.fnutils")
local ipc = require("hs.ipc")
local hs = hs

-- [ HAMMERSPOON SETTINGS ] ----------------------------------------------------

hs.allowAppleScript(true)
hs.application.enableSpotlightForNameSearches(false)
hs.autoLaunch(true)
hs.consoleOnTop(false)
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

-- [ LOADERS ] -----------------------------------------------------------------

_G.C = L.load("config")

--  NOTE: order matters
L.load("lib.bindings"):start()
L.load("lib.menubar.ptt"):start()
L.load("lib.menubar.spotify"):start()
L.load("lib.menubar.keyshowr")
L.load("lib.watchers"):start()
L.load("lib.wm"):start()
L.load("lib.quitter"):start({ mode = "double" })
L.req("lib.clipboard")
-- L.req("lib.scrot")
L.req("_scratch")
L.load("spoons")

-- [ UNLOADERS ] ---------------------------------------------------------------

hs.shutdownCallback = function()
  local loaders = { "config", "lib.watchers", "lib.wm", "lib.menubar.ptt", "lib.menubar.spotify", "lib.quitter" }
  FNUtils.each(loaders, function(l) L.unload(l) end)
  _G.mega = nil
end

hs.notify.new({ title = "Hammerspoon", subTitle = "Configuration successfully loaded" }):send()

require("_banner")

-- DEBUGGING things:
-- axbrowse
-- b = hs.axuielement.systemElementAtPosition(hs.mouse.absolutePosition())
-- hs.inspect(b:attributeNames())
-- hs.inspect(b:actionNames())
-- hs.inspect(b:parameterizedAttributeNames())
-- b:attributeValue("AXRoleDescription")
--
-- https://github.com/asmagill/hammerspoon/wiki/Variable-Scope-and-Garbage-Collection
