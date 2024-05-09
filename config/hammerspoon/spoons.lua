local obj = {}
local C = require("config")

obj.__index = obj
obj.name = "spoons"

function obj:init(opts)
  opts = opts or {}

  hs.loadSpoon("SpoonInstall")
  spoon.SpoonInstall.use_syncinstall = true
  Install = spoon.SpoonInstall

  Install:andUse("EmmyLua")

  local defaultProfile = "Profile 1"
  local preferredBrowser = hs.application.get(C.preferred.browser)
  local currentBrowserBundleID = preferredBrowser:bundleID()

  local openWithPreferredBrowser = function(url, profile)
    local path = hs.application.pathForBundleID(currentBrowserBundleID)
    local name = preferredBrowser:name()

    -- "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    binPath = string.format("%s/Contents/MacOS/%s", path, name)
    local t = hs.task.new(binPath, nil, function() return false end, { "--profile-directory=" .. profile, url })
    t:start()
  end

  local sendToProfile = function(t)
    local fn = function(url) openWithPreferredBrowser(url, t[2]) end
    return { t[1], nil, fn }
  end

  Install:andUse("URLDispatcher", {
    -- TODO: https://github.com/hthuong09/dots/blob/master/.hammerspoon/HandleURLDispatch.lua
    start = true,
    loglevel = "debug",
    config = {
      set_system_handler = true,
      default_handler = currentBrowserBundleID, --hs.application.get(require("hs.settings").get(CONFIG_KEY).preferred.browser),
      url_patterns = {
        { "https?://slack.com/openid/*", currentBrowserBundleID },
        -- { "https?://meet.google.com", "com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan" },
        { "https?://figma.com", "com.figma.Desktop" },
        { "https?://open.spotify.com", "com.spotify.client" },
        { "spotify:", "com.spotify.client" },
        { "https?://github.com", currentBrowserBundleID },
        { "https?://%w+.github.com/", currentBrowserBundleID },
        -- { "https?://github.com/[mM]iroapp.*", "com.google.Chrome" },
        -- { "https?://[mM]iro.*", "com.google.Chrome" },
        -- { "https?://dev.*.com", "com.google.Chrome" },
        -- { "https?://localhost:*", "com.google.Chrome" },
        -- { "https?://.*devrtb.com", "com.google.Chrome" },
        -- { "https?://www.notion.so", "com.spotify.client" },
        -- { "https?://accounts.bellhop.test", "com.apple.Safari" },
        -- { "https?://admin.bellhop.test", "com.apple.Safari" },
        -- { "https?://*", currentBrowser },
        {
          ".*",
          nil,
          function(url, senderPID)
            local triggerApp = hs.application.applicationForPID(senderPID)
            if triggerApp then
              hs.notify.new({ title = triggerApp:name(), subTitle = url })

              if triggerApp:name() == "Safari" then
                openWithPreferredBrowser(url, defaultProfile)
                return
              end
              if triggerApp:name() == "Slack" then
                openWithPreferredBrowser(url, defaultProfile)
                return
              end
              if triggerApp:name() == "Raycast" and url:find("https://meet.google.com", 1, true) == 1 then
                openWithPreferredBrowser(url, defaultProfile)
                return
              end
            end
            sendToProfile({ ".*", defaultProfile })
          end,
        },
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

  hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
    hs.urlevent.openURLWithBundle(fullURL, currentBrowserBundleID)
  end

  return self
end

function obj:stop() return self end

return obj
