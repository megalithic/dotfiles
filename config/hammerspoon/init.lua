require("preflight")

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
-- @trial URLDispatcher: https://github.com/ahmedelgabri/dotfiles/commit/2c5c9f96bdf5e800f9932b7ba025a9aabb235de3#diff-13ac59e8e0af48d2afe1d4904f4c8d8705f12886b70dda63a31044284748a96aR18-R37

-- [ LOADERS ] -----------------------------------------------------------------

--  NOTE: order matters
L.load("config")
-- L.load("lib.vim")
L.load("lib.bindings"):start()
L.load("lib.menubar.ptt"):start()
L.load("lib.menubar.spotify"):start()
L.load("lib.watchers"):start()
L.load("lib.wm"):start()
L.load("lib.quitter"):start({ mode = "double" })
L.req("_scratch")

-- [ UNLOADERS ] ---------------------------------------------------------------

hs.shutdownCallback = function()
  local loaders = { "config", "lib.watchers", "lib.wm", "lib.menubar.ptt", "lib.menubar.spotify", "lib.quitter" }
  FNUtils.each(loaders, function(l) unload(l) end)
  _G.mega = nil
end

hs.notify.new({ title = "Hammerspoon", subTitle = "Configuration successfully loaded" }):send()

require("_banner")
