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
hs.window.animationDuration = 0.1
hs.window.setShadows(false)
hs.application.enableSpotlightForNameSearches(true)
hs.allowAppleScript(true)

-- global requires
Config = require("config")
-- TODO: replace lowercase references of `config` to `Config`
config = Config
bindings = require("bindings")
controlplane = require("utils.controlplane")
watchables = require("utils.watchables")
watchers = require("utils.watchers")
wm = require("utils.wm")

-- controlplane
controlplane.enabled = {"dock", "office", "vpn"}

-- watchers
watchers.enabled = {"urlevent"} -- urlevent
watchers.urlPreference = Config.preferred.browsers

-- bindings
bindings.enabled = {"ptt", "quitguard", "tabjump", "hyper", "apps", "snap", "media", "airpods", "misc", "browser"}

-- start/stop modules
local modules = {wm, bindings, controlplane, watchables, watchers}

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
