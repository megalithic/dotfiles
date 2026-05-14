-- after/plugin/pi.lua
-- Fresh pinvim loader.
-- Keep loader thin. Runtime logic lives in lua/pinvim.lua.

if not Plugin_enabled("pinvim") then return end

mega.p.pinvim = require("pinvim").setup()
