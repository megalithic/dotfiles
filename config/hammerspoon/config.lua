--- === Config ===
---
local Settings = require("hs.settings")
local hyper = { "shift", "cmd", "alt", "ctrl" }

local obj = {}

obj.__index = obj

obj.settings = {}
obj.configKey = "_mega_config"

obj.settings.preferred = {
  terms = { "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = { "Brave Browser", "Brave Browser Dev", "Firefox", "Google Chrome", "Safari" },
  personal = { "Messages", "Signal" },
  chat = { "Slack" },
  media = { "Spotify" },
  vpn = { "Cloudflare WARP" },
  watchers = { "dock", "bluetooth", "audio", "wifi", "url" },
}

obj.settings.apps = {}

obj.settings.transientApps = {
  ["LaunchBar"] = { allowRoles = "AXSystemDialog" },
  ["1Password 7"] = { allowTitles = "1Password mini" },
  ["Spotlight"] = { allowRoles = "AXSystemDialog" },
  ["Paletro"] = { allowRoles = "AXSystemDialog" },
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true,
}

obj.settings.networks = { "shaolin" }

obj.settings.displays = {
  laptop = "Color LCD",
  external = "LG UltraFine",
}

obj.settings.dirs = {
  screenshots = os.getenv("HOME") .. "/screenshots",
}

obj.quitter = {
  launchdRunInterval = 600, --- 10 minutes
  -- rules = require("appquitter_rules"),
  defaultQuitInterval = 14400, -- 4 hours
  defaultHideInterval = 1800, -- 30 minutes
}

-- local globalShortcuts = {
--   globals = {
--     rightClick = { hyper, "o" },
--     focusDock = {
--       { "cmd", "alt" },
--       "d",
--     },
--   },
--   windowManager = {
--     pushLeft = { hyper, "left" },
--     pushRight = { hyper, "right" },
--     pushUp = { hyper, "up" },
--     pushDown = { hyper, "down" },
--     maximize = { hyper, "return" },
--     center = { hyper, "c" },
--   },
--   notificationCenter = {
--     firstButton = { hyper, "1" },
--     secondButton = { hyper, "2" },
--     thirdButton = { hyper, "3" },
--     toggle = { hyper, "n" },
--   },
-- }

function obj:init(opts)
  opts = opts or {}
  print(string.format("config:init(opts: %s) loaded.", hs.inspect(opts)))

  Settings.set(obj.configKey, obj.settings)
end

return obj
