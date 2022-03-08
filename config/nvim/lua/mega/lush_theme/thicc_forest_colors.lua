local lush = require("lush")
local hsl = lush.hsl

local M = {}

-- looks like since Lush does a hex -> hsl -> hex conversion,
-- we get a different color rendered than what is specificed here.
-- I might look into using ColorBuddy instead of Lush, as I don't
-- really care about HSL over hex, and I would rather have the colors
-- be exactly as I've specified.
--
-- but ¯\_(ツ)_/¯

M.red = hsl("#e68183")
M.orange = hsl("#e39b7b")
M.yellow = hsl("#d9bb80")
M.green = hsl("#a7c080")
M.cyan = hsl("#87c095")
M.aqua = M.cyan
M.blue = hsl("#83b6af")
M.purple = hsl("#d39bb6")

M.bg0 = hsl("#273433")
M.bg1 = M.bg0.lighten(10)
M.bg2 = M.bg0.lighten(15)
M.bg3 = M.bg0.lighten(20)
M.bg4 = M.bg0.lighten(25)

M.bg_visual = hsl("#5d4251")
M.bg_red = hsl("#614b51")
M.bg_green = hsl("#4e6053")
M.bg_blue = hsl("#415c6d")
M.bg_yellow = hsl("#5d5c50")
M.bg_purple = hsl("#402F37")
M.bg_cyan = hsl("#54816B")

M.fg = hsl("#d8caac")

M.grey0 = hsl("#7c8377")
M.grey1 = hsl("#868d80")
M.grey2 = hsl("#999f93")

return M
