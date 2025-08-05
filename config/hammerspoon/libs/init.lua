local utils = require("utils")

-- foundation_remapping
-- https://github.com/hetima/hammerspoon-foundation_remapping
if not pcall(require, "libs.foundation_remapping") then
  utils.download_lib(
    "foundation_remapping.lua",
    "https://raw.githubusercontent.com/hetima/hammerspoon-foundation_remapping/master/foundation_remapping.lua"
  )
end

-- hyperex
-- https://github.com/hetima/hammerspoon-hyperex
if not pcall(require, "libs.hyperex") then
  utils.download_lib("hyperex.lua", "https://raw.githubusercontent.com/hetima/hammerspoon-hyperex/master/hyperex.lua")
end
