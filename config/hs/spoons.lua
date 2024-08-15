-- [ SPOONS ] ------------------------------------------------------------------

-- Load SpoonInstall, so we can easily load our other Spoons
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install = spoon.SpoonInstall

-- Direct URLs automatically based on patterns
Install:andUse("URLDispatcher", {
  config = {
    set_system_handler = true,
    default_handler = BROWSER,
  },
  start = true,
})

-- Load Seal - This is a pretty simple implementation of something like Alfred
-- Install:andUse("Seal", {
--   hotkeys = {
--     show = { { "cmd", "ctrl", "alt", "shift" }, "space" },
--   },
--   fn = function(s)
--     s:loadPlugins({
--       "apps",
--       "vpn",
--       "screencapture",
--       "safari_bookmarks",
--       "calc",
--       "useractions",
--       "pasteboard",
--       "filesearch",
--     })
--     s.plugins.pasteboard.historySize = 4000
--     -- s.plugins.useractions.actions = useractions_actions
--     --        s:toggleToolbar()
--   end,
--   start = true,
-- })
Install:andUse("EmmyLua")

-- Install:andUse("ptt", {
--   hotkeys = {
--     toggle = { { "cmd", "alt" }, "p" },
--     momentary = { "cmd", "alt", nil },
--   },
-- })

-- hs.loadSpoon("ptt")
-- hs.loadSpoon("ptt"):start({
--   toggle = { { "cmd", "alt" }, "p" },
--   momentary = { "cmd", "alt", nil },
-- })
-- hs.loadSpoon("Hyper")
-- hs.loadSpoon("HyperModal")

info(fmt("[START] %s", "spoons"))
