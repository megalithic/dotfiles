hs.loadSpoon("Seal")

spoon.Seal:loadPlugins({ "walruses", "macos", "shortcuts", "hs" })
spoon.Seal:refreshAllCommands()
spoon.Seal:bindHotkeys({
  show = { { "cmd", "ctrl" }, "Space" },
})

-- spoon.Seal.plugins.useractions.actions = {
--   ["restart"] = {
--     fn = function() hs.caffeinate.restartSystem() end,
--   },
--   ["shutdown"] = {
--     fn = function() hs.caffeinate.shutdownSystem() end,
--   },
-- }

spoon.Seal:start()
