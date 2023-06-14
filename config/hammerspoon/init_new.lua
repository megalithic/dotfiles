local M = {
  config = {},
  reloader = {},
}

local window = require("hs.window")
local application = require("hs.window")
local fnutils = require("hs.fnutils")
local ipc = require("hs.ipc")

-- [ HAMMERSPOON SETTINGS ] ----------------------------------------------------

hs.allowAppleScript(true)
hs.autoLaunch(true)
hs.consoleOnTop(false)
hs.automaticallyCheckForUpdates(true)
hs.menuIcon(true)
hs.dockIcon(true)

application.enableSpotlightForNameSearches(false)
-- Window.highlight.ui.overlay = true
window.animationDuration = 0
window.setShadows(false)

ipc.cliUninstall()
ipc.cliInstall()

hs.hotkey.setLogLevel("error")
hs.keycodes.log.setLogLevel("error")
hs.logger.defaultLogLevel = "error"
hs.console.clearConsole()

-- [ CONFIG ] ----------------------------------------------------

M.config.preferred = {
  terms = { "wezterm", "kitty", "wezterm", "alacritty", "iTerm", "Terminal.app" },
  browsers = {
    hs.urlevent.getDefaultHandler("https"),
    "Chromium",
    "Brave Browser Dev",
    "Firefox",
    "Vivaldi",
    "Firefox Developer Edition",
    "Brave Browser",
    "Brave Browser Beta",
    "Google Chrome",
    "Safari",
  },
  personal = { "Messages" },
  chat = { "Slack", "Signal" },
  media = { "Spotify" },
  vpn = { "Cloudflare WARP" },
}
M.config.networks = { "shaolin", "Ginger-Guest" }
M.config.displays = {
  laptop = "Built-in Retina Display",
  external = "LG UltraFine",
}
M.config.displays["internal"] = M.config.displays.laptop
-- stylua: ignore start
--- REF: https://github.com/asmagill/hammerspoon_asm/blob/master/extras/init.lua
M.config.mods = {
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

M.config.hyper = "F19"
M.config.ptt = M.config.mods.CAsc

--- @class QuitterOpts
--- @field [1] string
M.config.quitters = {
  "com.brave.Browser.dev",
  "com.brave.Browser",
  "com.raycast.macos",
  "com.runningwithcrayons.Alfred",
  "net.kovidgoyal.kitty",
  "org.mozilla.firefoxdeveloperedition",
  "com.apple.SafariTechnologyPreview",
  "com.apple.Safari",
  -- "com.github.wez.wezterm", -- stuck with wezterm's built in confirm, need to remove this
}

--- @class TargetOpts
--- @field [1] string Target identifier; an application bundleID, a url pattern
--- @field locals? string[] Keys for local bindings

--- @class LauncherOpts
--- @field key string Keyboard key for focusing/launching this target
--- @field mods? string[]|string Keyboard modifiers (cmd, alt/opt, shift, ctrl)
--- @field mode? "focus"|"launch" The mode that we use to launch; focus-only or launch if not opened
--- @field target? TargetOpts[]|string List of possible targets this keybinding would cycle through (NOTE: only works with mode set to "focus" order matters).
M.config.launchers = {
  {
    key = "z",
    mode = "focus",
    target = {
      { "com.brave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan" },
      { "us.zoom.xos" },
      { "com.pop.pop.app" },
      { "https://whereby.com" },
      { "https://meet.google.com" },
    },
  },
  {
    key = "o",
    mode = "focus",
    target = "com.obsproject.obs-studio",
  },
  {
    key = "o",
    mode = "focus",
    target = "co.detail.mac",
  },
  {
    key = "f",
    mods = M.config.mods.caSc,
    mode = "focus",
    target = "com.figma.Desktop",
  },
  {
    key = "k",
    target = "com.github.wez.wezterm",
  },
  {
    key = "space",
    target = "com.raycast.macos",
  },
  {
    key = "j",
    mods = M.config.mods.caSc,
    target = "org.mozilla.firefoxdeveloperedition",
  },
}

-- [ HS CONFIG RELOAD WATCHER ] ----------------------------------------------------

M.reloader.watcher = nil
function M.reloader.start()
  if M.reloader.watcher then return end
  M.reloader.watcher = hs.pathwatcher.new(hs.configdir, function() hs.timer.doAfter(0.25, hs.reload) end)
  print(hs.configdir)
  M.reloader.watcher:start()
end
function M.reloader.stop()
  if not M.reloader.watcher then return end
  M.reloader.watcher:stop()
  M.reloader.watcher = nil
end

return M
