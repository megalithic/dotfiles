local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "spoons"

function obj:init(opts)
  opts = opts or {}

  hs.loadSpoon("SpoonInstall")
  spoon.SpoonInstall.use_syncinstall = true
  Install = spoon.SpoonInstall

-- local config = C

  -- Install:andUse("Seal", {
  --   -- NOTE: see bindings module for hotkey binding
  --   start = false,
  --   fn = function(s)
  --     s:loadPlugins({ "apps", "calc", "screencapture", "useractions", "urlformats", "safari_bookmarks" })
  --     s.plugins.safari_bookmarks.always_open_with_safari = false
  --     s.plugins.useractions.actions = {
  --       ["Hammerspoon docs webpage"] = {
  --         url = "http://hammerspoon.org/docs/",
  --         icon = hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon),
  --       },
  --       ["github"] = { url = "https://github.com/search?q=${query}", keyword = "!gh", icon = "favicon" },
  --       ["hexdocs"] = { url = "https://hexdocs.pm/${query}", keyword = "!hd", icon = "favicon" },
  --       ["hex"] = {
  --         url = "https://hex.pm/packages?search=${query}&sort=recent_downloads",
  --         keyword = "!hex",
  --         icon = "favicon",
  --       },
  --       ["devdocs"] = { url = "https://devdocs.io/?q=%{query}", keyword = "!dev", icon = "favicon" },
  --       ["youtube"] = {
  --         url = "https://www.youtube.com/results?search_query=${query}&page={startPage?}",
  --         keyword = "!yt",
  --         icon = "favicon",
  --       }
  --     }
  --     s:refreshAllCommands()
  --   end,
  -- })
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
        { "https?://www.github.com", "com.brave.Browser.dev" },
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

  return self
end

function obj:stop() return self end

return obj
