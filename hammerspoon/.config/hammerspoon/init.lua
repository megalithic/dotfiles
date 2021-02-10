-- logging configuration
require("hs.logger").idLength(24)

local log = hs.logger.new("[init]", "warning")

-- global stuff
require("console").init()

-- ensure IPC is there
hs.ipc.cliInstall()

-- lower logging level for hotkeys
require("hs.hotkey").setLogLevel("warning")

-- misc configuration
-- hs.window.animationDuration = 0.0
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)
hs.allowAppleScript(true)

-- global requires
Config = require("config")
Bindings = require("bindings")
Controlplane = require("utils.controlplane")
Watchables = require("utils.watchables")
Watchers = require("utils.watchers")
Wm = require("utils.wm")

-- controlplane
Controlplane.enabled = {"dock", "office", "vpn"}

-- watchers
watchers.enabled = {"urlevent"}
watchers.urlPreference = Config.preferred.browsers

-- bindings
Bindings.enabled = {"ptt", "quitguard", "tabjump", "hyper", "apps", "snap", "media", "airpods", "misc", "browser"}

-- start/stop modules
local modules = {Wm, Bindings, Controlplane, Watchables, Watchers}

hs.fnutils.each(
  modules,
  function(module)
    if module then
      module.start()
    end
  end
)

-- stop modules on shutdown
hs.shutdownCallback = function()
  hs.fnutils.each(
    modules,
    function(module)
      if module then
        module.stop()
      end
    end
  )
end
