local Window = require("hs.window")
local ipc = require("hs.ipc")
local load = require("utils.loader").load
local unload = require("utils.loader").unload
local FNUtils = require("hs.fnutils")
local hs = hs

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

-- [ CONSOLE SETTINGS ] ---------------------------------------------------------

hs.console.darkMode(true)
hs.console.consoleFont({ name = "JetBrainsMono Nerd Font", size = 16 })
hs.console.alpha(0.985)

-- [ LOADERS ] ------------------------------------------------------------------

load("config")
load("lib/watchers/")

hs.shutdownCallback = function()
  unload("config")
  unload("lib/watchers/")
end

-- [ LEGACY ] ------------------------------------------------------------------

-- [ SPOONS ] ------------------------------------------------------------------

-- hs.loadSpoon("SpoonInstall")
-- hs.loadSpoon("EmmyLua")

-- local iterFn, dirObj = FS.dir("Spoons/")
-- if iterFn then
--   for file in iterFn, dirObj do
--     if string.sub(file, -5) == "spoon" then
--       local spoonName = string.sub(file, 1, -7)
--       hs.loadSpoon(spoonName)
--     end
--   end
-- end

-- -- TODO: figure out why we need to re-assign?
-- -- must appear only after loadSpoon was called at least once?
-- local spoon = spoon

-- -- start (ORDER MATTERS!)
-- spoon.AppQuitter:start(appQuitterConfig)
-- spoon.AppShortcuts:start(transientApps)
-- spoon.ConfigWatcher:start()
-- spoon.DownloadsWatcher:start()
-- spoon.WifiWatcher:start(knownNetworks)
-- spoon.StatusBar:start()
-- spoon.KeyboardLayoutManager:start(layoutSwitcherIgnored, "ABC")
-- spoon.GlobalShortcuts:bindHotKeys(globalShortcuts.globals)
-- spoon.WindowManager:bindHotKeys(globalShortcuts.windowManager)
-- spoon.NotificationCenter:bindHotKeys(globalShortcuts.notificationCenter)
