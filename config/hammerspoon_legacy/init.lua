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
hs.window.highlight.ui.overlay = true
hs.application.enableSpotlightForNameSearches(true)
hs.allowAppleScript(true)

-- spoons to load
hs.loadSpoon("SpoonInstall")
hs.loadSpoon("EmmyLua")
-- hs.loadSpoon("VimMode")

-- global requires
Config = require("config")

-- local requires
local bindings = require("bindings")
local controlplane = require("controlplane")
local watchables = require("watchables")
local watchers = require("watchers")
local wm = require("wm")

-- modules to load/configure
local modules = { wm, bindings, controlplane, watchables, watchers }

-- start modules
hs.fnutils.each(modules, function(module)
  if module then
    module.start()
  end
end)

-- stop modules on hs shutdown
hs.shutdownCallback = function()
  hs.fnutils.each(modules, function(module)
    if module then
      module.stop()
    end
  end)
end
