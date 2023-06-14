-- [ GLOBALS ] ------------------------------------------------------------------

_G.debug_enabled = true

-- [ BOOTSTRAP/PRELOAD ] ------------------------------------------------------------------

require("preflight")

-- [ LOCALS ] ------------------------------------------------------------------

local window = require("hs.window")
local fnutils = require("hs.fnutils")
local ipc = require("hs.ipc")

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

window.animationDuration = 0
-- window.highlight.ui.overlay = true
window.setShadows(false)

ipc.cliUninstall()
ipc.cliInstall()

-- [ LOADERS ] -----------------------------------------------------------------

_G.C = L.load("config")

--  NOTE: order matters
L.load("lib.bindings"):start()
L.load("lib.menubar.ptt"):start()
L.load("lib.menubar.spotify"):start()
L.load("lib.menubar.keycastr")
L.load("lib.watchers", { watchers = { "status", "bluetooth", "dock", "audio", "wifi", "url", "downloads" } }):start()
L.load("lib.wm"):start()
L.load("lib.quitter"):start({ mode = "double" })
L.load("lib.clipper")
L.load("spoons")

-- [ UNLOADERS ] ---------------------------------------------------------------

hs.shutdownCallback = function()
  local loaders = { "config", "lib.watchers", "lib.wm", "lib.menubar.ptt", "lib.menubar.spotify", "lib.quitter" }
  fnutils.each(loaders, function(l) L.unload(l) end)
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
