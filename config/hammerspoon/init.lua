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

-- [ LOADERS ] -----------------------------------------------------------------

--  NOTE: order matters
L.load("config")
-- L.load("console") -- see preflight
L.load("lib.bindings"):start()
L.load("lib.menubar.ptt"):start()
L.load("lib.menubar.spotify"):start()
L.load("lib.menubar.keyshowr")
L.load("lib.watchers"):start()
-- TODO: integrate yabai with hammerspoon? https://github.com/apoxa/dotfiles/commit/bc9fe021cf56102d092eea9b98ba04030b3037c7
L.load("lib.wm"):start()
L.load("lib.quitter"):start({ mode = "double" })
L.req("lib.clipboard")
L.req("lib.scrot")
L.req("_scratch")

-- [ UNLOADERS ] ---------------------------------------------------------------

hs.shutdownCallback = function()
  local loaders = { "config", "lib.watchers", "lib.wm", "lib.menubar.ptt", "lib.menubar.spotify", "lib.quitter" }
  FNUtils.each(loaders, function(l) unload(l) end)
  _G.mega = nil
end

-- [ SPOONS ] ------------------------------------------------------------------

hs.loadSpoon("SpoonInstall")
Install = spoon.SpoonInstall

Install:andUse("EmmyLua")
-- @trial URLDispatcher: https://github.com/ahmedelgabri/dotfiles/commit/2c5c9f96bdf5e800f9932b7ba025a9aabb235de3#diff-13ac59e8e0af48d2afe1d4904f4c8d8705f12886b70dda63a31044284748a96aR18-R37
Install:andUse("URLDispatcher", {
  start = true,
  loglevel = "debug",
  config = {
    default_handler = "com.brave.Browser.dev", --hs.application.get(require("hs.settings").get(CONFIG_KEY).preferred.browser),
    url_patterns = {
      -- { "https?://slack.com/openid/*", "com.google.Chrome" },
      -- { "https?://github.com/[mM]iroapp.*", "com.google.Chrome" },
      -- { "https?://[mM]iro.*", "com.google.Chrome" },
      -- { "https?://dev.*.com", "com.google.Chrome" },
      -- { "https?://localhost:*", "com.google.Chrome" },
      -- { "https?://.*devrtb.com", "com.google.Chrome" },
      -- { "https?://www.notion.so", "com.spotify.client" },
      { "https?://meet.google.com", "com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan" },
      { "https?://www.figma.com", "com.figma.Desktop" },
      { "https?://open.spotify.com", "com.spotify.client" },
      { "spotify:", "com.spotify.client" },
    },
    url_redir_decoders = {
      {
        "MS Teams links",
        function(_, _, params)
          print(hs.inspect(params))
          return params.url
        end,
        nil,
        true,
        "Microsoft Teams",
      },
      { "Spotify URLs", "https://open.spotify.com/(.*)/(.*)", "spotify:%1:%2" },
      { "Fix broken Preview anchor URLs", "%%23", "#", false, "Preview" },
    },
  },
})

hs.notify.new({ title = "Hammerspoon", subTitle = "Configuration successfully loaded" }):send()

require("_banner")
