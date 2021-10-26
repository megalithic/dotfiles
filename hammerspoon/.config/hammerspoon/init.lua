-- logging configuration
-- require("hs.logger").idLength(24)

local log = hs.logger.new("[init]", "warning")

-- global stuff for console things
require("console").init()

-- ensure IPC is there
if not hs.ipc.cliStatus() then
  hs.ipc.cliInstall()
end

-- lower logging level for hotkeys
require("hs.hotkey").setLogLevel("warning")

-- misc configuration
hs.window.animationDuration = 0.0
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)
hs.allowAppleScript(true)

-- spoons
hs.loadSpoon("SpoonInstall")
hs.loadSpoon("EmmyLua")

-- FIXME: replace lowercase references of `foo` to `Foo`, e.g., `config` -> `Config`
-- global requires
Config = require("config")
config = Config
bindings = require("bindings")
controlplane = require("utils.controlplane")
watchables = require("utils.watchables")
watchers = require("utils.watchers")
wm = require("utils.wm")

-- controlplane
controlplane.enabled = { "dock", "office", "vpn" }

-- watchers
watchers.enabled = { "urlevent" } -- urlevent
watchers.urlPreference = Config.preferred.browsers

-- bindings
bindings.enabled = { "ptt", "quitguard", "tabjump", "hyper", "apps", "snap", "media", "airpods", "misc", "browser" }

-- start/stop modules
local modules = { wm, bindings, controlplane, watchables, watchers }

hs.fnutils.each(modules, function(module)
  if module then
    module.start()
  end
end)

-- stop modules on shutdown
hs.shutdownCallback = function()
  hs.fnutils.each(modules, function(module)
    if module then
      module.stop()
    end
  end)
end
