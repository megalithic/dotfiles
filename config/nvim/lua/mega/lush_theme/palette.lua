local ok, lush = pcall(require, "lush")
if not ok then return end

local hsluv = lush.hsluv
local hsl = lush.hsl

M = {}

M.clrs = {}

M.clrs.nord0 = hsl(220, 16, 22) -- #2F3541
M.clrs.nord1 = hsl(222, 16, 28) -- #3C4353
M.clrs.nord2 = hsl(220, 17, 32) -- #444D5F
M.clrs.nord3 = hsl(220, 16, 36) -- #4D576A
M.clrs.nord3_bright = hsl(220, 17, 46) -- #616F89
M.clrs.nord4 = hsl(219, 28, 88) -- #D8DEE9
M.clrs.nord5 = hsl(218, 27, 92) -- #E5E9F0
M.clrs.nord6 = hsl(218, 27, 94) -- #ECEFF4
M.clrs.nord7 = hsl(179, 25, 65) -- #8FBCBB
M.clrs.nord8 = hsl(193, 43, 67) -- #87BFCF
M.clrs.nord9 = hsl(210, 34, 63) -- #81A1C1
M.clrs.nord10 = hsl(213, 32, 52) -- #5D81AC
M.clrs.nord11 = hsl(354, 42, 56) -- #BE6069
M.clrs.nord12 = hsl(14, 51, 63) -- #D18771
M.clrs.nord13 = hsl(40, 71, 73) -- #EBCA89
M.clrs.nord14 = hsl(92, 28, 65) -- #A4BF8D
M.clrs.nord15 = hsl(311, 20, 63) -- #B48EAD

local bg_thicc = "#273433"
local bg_hard = "#2b3339"
local bg_medium = "#2b3339"
local bg_soft = "#323d43"

M.clrs.bg0 = hsluv(bg_soft)
M.clrs.bg1 = M.clrs.bg0.lighten(5) -- #3c474d
M.clrs.bg2 = M.clrs.bg0.lighten(10) -- #465258
M.clrs.bg3 = M.clrs.bg0.lighten(15) -- #505a60
M.clrs.bg4 = M.clrs.bg0.lighten(20) -- #576268
M.clrs.bg5 = M.clrs.bg0.lighten(25) -- #626262

M.clrs.bg_dark_raw = bg_hard
M.clrs.bg_dark = hsluv(bg_hard)
M.clrs.bg_visual = hsluv("#4e6053")
M.clrs.bg_red = hsluv("#614b51")
M.clrs.bg_green = hsluv("#4e6053")
M.clrs.bg_blue = hsluv("#415c6d")
M.clrs.bg_yellow = hsluv("#5d5c50")
M.clrs.bg_purple = hsluv("#402F37")
M.clrs.bg_cyan = hsluv("#54816B")

M.clrs.fg = hsluv("#d8caac")
M.clrs.white = hsluv("#ffffff")

M.clrs.dark_grey = hsluv("#3E4556")
M.clrs.light_grey = hsluv("#5c6370")
-- C.grey = '#3E4556'
M.clrs.grey0 = hsluv("#7c8377")
M.clrs.grey1 = hsluv("#868d80")
M.clrs.grey2 = hsluv("#999f93")

M.clrs.red = hsluv("#e67e80")
M.clrs.orange = hsluv("#e39b7b")
M.clrs.yellow = hsluv("#d9bb80")
M.clrs.green = hsluv("#a7c080")
M.clrs.cyan = hsluv("#87c095").darken(5)
M.clrs.blue = hsluv("#7fbbb3")
M.clrs.aqua = M.clrs.cyan
M.clrs.purple = hsluv("#d39bb6")
M.clrs.brown = hsluv("#db9c5e").darken(20)
M.clrs.magenta = M.clrs.purple.darken(15) -- #c678dd
M.clrs.teal = hsluv("#15AABF")

M.clrs.pale_red = hsluv("#E06C75")

M.clrs.bright_blue = M.clrs.blue.lighten(5)
M.clrs.bright_blue_alt = "#51afef"
M.clrs.bright_green = hsluv("#6bc46d")
M.clrs.bright_yellow = hsluv("#FAB005")

M.clrs.light_yellow = hsluv("#e5c07b")
M.clrs.light_red = hsluv("#c43e1f")

M.clrs.dark_blue = M.clrs.blue.darken(25)
M.clrs.dark_blue_alt = "#4e88ff"
M.clrs.dark_orange = hsluv("#FF922B")
M.clrs.dark_red = hsluv("#be5046")
M.clrs.dark_green = hsluv("#6bc46d").darken(20)

M.clrs.lsp.error = M.clrs.pale_red
M.clrs.lsp.warn = M.clrs.dark_orange
M.clrs.lsp.hint = M.clrs.bright_blue
M.clrs.lsp.info = M.clrs.teal

M.clrs.nord0 = hsl(220, 16, 22) -- #2F3541
M.clrs.nord1 = hsl(222, 16, 28) -- #3C4353
M.clrs.nord2 = hsl(220, 17, 32) -- #444D5F
M.clrs.nord3 = hsl(220, 16, 36) -- #4D576A
M.clrs.nord3_bright = hsl(220, 17, 46) -- #616F89
M.clrs.nord4 = hsl(219, 28, 88) -- #D8DEE9
M.clrs.nord5 = hsl(218, 27, 92) -- #E5E9F0
M.clrs.nord6 = hsl(218, 27, 94) -- #ECEFF4
M.clrs.nord7 = hsl(179, 25, 65) -- #8FBCBB
M.clrs.nord8 = hsl(193, 43, 67) -- #87BFCF
M.clrs.nord9 = hsl(210, 34, 63) -- #81A1C1
M.clrs.nord10 = hsl(213, 32, 52) -- #5D81AC
M.clrs.nord11 = hsl(354, 42, 56) -- #BE6069
M.clrs.nord12 = hsl(14, 51, 63) -- #D18771
M.clrs.nord13 = hsl(40, 71, 73) -- #EBCA89
M.clrs.nord14 = hsl(92, 28, 65) -- #A4BF8D
M.clrs.nord15 = hsl(311, 20, 63) -- #B48EAD

M.nord3_brightened = {
  M.clrs.nord3,
  hsl(221, 17, 37), -- #4E586E
  hsl(219, 17, 38), -- #505C71
  hsl(220, 17, 39), -- #535E74
  hsl(220, 16, 40), -- #566176
  hsl(221, 16, 41), -- #586279
  hsl(221, 16, 42), -- #5A657C
  hsl(220, 17, 43), -- #5B6780
  hsl(221, 17, 44), -- #5D6983
  hsl(219, 17, 45), -- #5F6D86
  hsl(220, 17, 46), -- #616F89
  hsl(219, 17, 47), -- #63728C
  hsl(221, 16, 48), -- #67738E
  hsl(221, 16, 49), -- #697691
  hsl(220, 17, 50), -- #6A7895
  hsl(221, 16, 51), -- #6E7B96
  hsl(220, 17, 52), -- #707E99
  hsl(219, 17, 53), -- #73819C
  hsl(220, 16, 54), -- #77839C
  hsl(219, 16, 55), -- #7A879F
  hsl(219, 17, 56), -- #7C89A2
}

local cfg = {
  theme_bold = vim.g.theme_bold or 1,
  theme_italic = vim.g.theme_italic or 0, -- TODO: Add other conditions
  theme_underline = vim.g.theme_underline or 0,
  theme_italic_comments = vim.g.theme_italic_comments or 0,
  theme_uniform_status_lines = vim.g.theme_uniform_status_lines or 0,
  theme_uniform_diff_background = vim.g.theme_uniform_diff_background or 0,
  theme_cursor_line_number_background = vim.g.theme_cursor_line_number_background or 0,
  theme_bold_vertical_split_line = vim.g.theme_bold_vertical_split_line or 0,
}
M.cfg = cfg

local spec = {
  bold = cfg.theme_bold == 1 and "bold" or "",
  italic = cfg.theme_italic == 1 and "italic" or "",
  underline = cfg.theme_underline == 1 and "underline" or "",
  inverse = "inverse",
  undercurl = "undercurl",
}
spec["italicize_comments"] = cfg.theme_italic_comments == 1 and spec.italic or ""
M.spec = spec

M.gui_combine = function(gui)
  for i = 1, #gui do
    if gui[i] == "" then table.remove(gui, i) end
  end
  return table.concat(gui, ",")
end

return M
