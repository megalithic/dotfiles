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
spoon.SpoonInstall.use_syncinstall = true
Install = spoon.SpoonInstall

Install:andUse("Seal", {
  -- NOTE: see bindings module for hotkey binding
  fn = function(s)
    s:loadPlugins({ "apps", "calc", "screencapture", "useractions", "urlformats", "safari_bookmarks" })
    s.plugins.safari_bookmarks.always_open_with_safari = false
    s.plugins.useractions.actions = {
      ["Hammerspoon docs webpage"] = {
        url = "http://hammerspoon.org/docs/",
        icon = hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon),
      },
      ["github"] = { url = "https://github.com/search?q=${query}", keyword = "!gh", icon = "favicon" },
      ["hexdocs"] = { url = "https://hexdocs.pm/${query}", keyword = "!hd", icon = "favicon" },
      ["hex"] = {
        url = "https://hex.pm/packages?search=${query}&sort=recent_downloads",
        keyword = "!hex",
        icon = "favicon",
      },
      ["devdocs"] = { url = "https://devdocs.io/?q=%{query}", keyword = "!dev", icon = "favicon" },
      ["youtube"] = {
        url = "https://www.youtube.com/results?search_query=${query}&page={startPage?}",
        keyword = "!yt",
        icon = "favicon",
      },
    }
    s:refreshAllCommands()
  end,
  start = true,
})
Install:andUse("EmmyLua")
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
