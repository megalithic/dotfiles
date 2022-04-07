local lush = require("lush")
local hsluv = lush.hsluv

-- local palette = require("mega.colors")
-- local C = palette.cs
-- local H = require("mega.utils.highlights")

local C = {}

C.bg0 = hsluv("#323d43")
C.bg1 = C.bg0.lighten(5) -- #3c474d
C.bg2 = C.bg0.lighten(10) -- #465258
C.bg3 = C.bg0.lighten(15) -- #505a60
C.bg4 = C.bg0.lighten(20) -- #576268
C.bg5 = C.bg0.lighten(25) -- #626262

C.bg_dark = hsluv("#273433")
C.bg_visual = hsluv("#4e6053")
C.bg_red = hsluv("#614b51")
C.bg_green = hsluv("#4e6053")
C.bg_blue = hsluv("#415c6d")
C.bg_yellow = hsluv("#5d5c50")
C.bg_purple = hsluv("#402F37")
C.bg_cyan = hsluv("#54816B")

C.fg = hsluv("#d8caac")

C.dark_grey = hsluv("#3E4556")
C.light_grey = hsluv("#5c6370")
C.grey0 = hsluv("#7c8377")
C.grey1 = hsluv("#868d80")
C.grey2 = hsluv("#999f93")

C.red = hsluv("#e67e80")
C.orange = hsluv("#e39b7b")
C.yellow = hsluv("#d9bb80")
C.green = hsluv("#a7c080")
C.cyan = hsluv("#87c095").darken(5)
C.blue = hsluv("#7fbbb3")
C.aqua = C.cyan
C.purple = hsluv("#d39bb6")
C.brown = hsluv("#db9c5e").darken(20)
C.magenta = C.purple.darken(15) -- #c678dd
C.teal = hsluv("#15AABF")

C.pale_red = hsluv("#E06C75")

C.bright_blue = C.blue.lighten(5) -- #51afef
C.bright_green = hsluv("#6bc46d")
C.bright_yellow = hsluv("#FAB005")

C.light_yellow = hsluv("#e5c07b")
C.light_red = hsluv("#c43e1f")

C.dark_blue = C.blue.darken(25) -- #4e88ff
C.dark_orange = hsluv("#FF922B")
C.dark_red = hsluv("#be5046")

return C