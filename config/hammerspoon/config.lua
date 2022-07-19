local Settings = require("hs.settings")

local obj = {}

obj.__index = obj

obj.settings = {}
obj.settingsKey = "_mega_config"

local preferred = {
  terms = { "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = { "Brave Browser", "Brave Browser Dev", "Firefox", "Google Chrome", "Safari" },
  personal = { "Messages", "Signal" },
  chat = { "Slack" },
  media = { "Spotify" },
  vpn = { "Cloudflare WARP" },
}

local watchers = { "dock", "bluetooth", "audio", "wifi", "url" }

local transientApps = {
  ["LaunchBar"] = { allowRoles = "AXSystemDialog" },
  ["1Password 7"] = { allowTitles = "1Password mini" },
  ["Spotlight"] = { allowRoles = "AXSystemDialog" },
  ["Paletro"] = { allowRoles = "AXSystemDialog" },
  ["Contexts"] = false,
  ["Emoji & Symbols"] = true,
}

local networks = { "shaolin" }

local displays = {
  laptop = "Color LCD",
  external = "LG UltraFine",
}

local dirs = {
  screenshots = os.getenv("HOME") .. "/screenshots",
}

local quitter = {
  launchdRunInterval = 600, --- 10 minutes
  -- rules = require("appquitter_rules"),
  defaultQuitInterval = 14400, -- 4 hours
  defaultHideInterval = 1800, -- 30 minutes
}

local grid = {
  screen_edge_margins = {
    top = 32, -- px
    left = 0,
    right = 0,
    bottom = 0,
  },
  partition_margins = {
    x = 0, -- px
    y = 0,
  },
  -- Partitions --
  split_screen_partitions = {
    x = 0.5, -- %
    y = 0.5,
  },
  quarter_screen_partitions = {
    x = 0.5, -- %
    y = 0.5,
  },
}

local hyper = "F19"

-- stylua: ignore start
--- REF: https://github.com/asmagill/hammerspoon_asm/blob/master/extras/init.lua
local mods = {
  casc = {                     }, casC = {                       "ctrl"},
  caSc = {              "shift"}, caSC = {              "shift", "ctrl"},
  cAsc = {       "alt"         }, cAsC = {       "alt",          "ctrl"},
  cASc = {       "alt", "shift"}, cASC = {       "alt", "shift", "ctrl"},
  Casc = {"cmd"                }, CasC = {"cmd",                 "ctrl"},
  CaSc = {"cmd",        "shift"}, CaSC = {"cmd",        "shift", "ctrl"},
  CAsc = {"cmd", "alt"         }, CAsC = {"cmd", "alt",          "ctrl"},
  CASc = {"cmd", "alt", "shift"}, CASC = {"cmd", "alt", "shift", "ctrl"},
}
-- stylua: ignore end

local wm = {
  pushLeft = { hyper, "h" },
  pushRight = { hyper, "l" },
  pushUp = { hyper, "k" },
  pushDown = { hyper, "j" },
  maximize = { hyper, "return" },
  center = { hyper, "space" },
}

local apps = {
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    hyper_key = "k",
    quitGuard = false,
    rules = {
      -- { nil, 1, M.layout.fullScreen },
    },
  },
  ["com.brave.Browser"] = {
    bundleID = "com.brave.Browser",
    name = "Brave Browser",
    quitGuard = true,
    hyper_key = "j", -- FIXME: move these to hyperGroups in hyper.lua
    tags = { "browsers" },
    rules = {
      -- { nil, 1, M.layout.fullScreen },
    },
  },
}

function obj:init(opts)
  opts = opts or {}
  P(fmt("config:init(%s) loaded.", hs.inspect(opts)))

  obj.settings = {
    ["apps"] = apps,
    ["dirs"] = dirs,
    ["displays"] = displays,
    ["grid"] = grid,
    ["keys"] = {
      ["hyper"] = hyper,
      ["mods"] = mods,
      ["wm"] = wm,
    },
    ["networks"] = networks,
    ["preferred"] = preferred,
    ["quitter"] = quitter,
    ["transientApps"] = transientApps,
    ["watchers"] = watchers,
  }

  Settings.set(obj.settingsKey, obj.settings)

  return self
end

function obj:stop()
  P(fmt("config:stop() executed."))

  Settings.clear(obj.settingsKey)
  obj.settings = {}

  return self
end

return obj
