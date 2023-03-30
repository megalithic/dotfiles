local ok, lush = pcall(require, "lush")
if not ok then return end

local hsluv = lush.hsluv
local hsl = lush.hsl

local C = {
  lsp = {},
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
C.cfg = cfg

local gui = {
  bold = cfg.theme_bold == 1 and "bold" or "",
  italic = cfg.theme_italic == 1 and "italic" or "",
  underline = cfg.theme_underline == 1 and "underline" or "",
  inverse = "inverse",
  undercurl = "undercurl",
}
gui["italicize_comments"] = cfg.theme_italic_comments == 1 and gui.italic or ""
C.gui = gui

C.guic = function(gui)
  for i = 1, #gui do
    if gui[i] == "" then table.remove(gui, i) end
  end
  return table.concat(gui, ",")
end

local bg_thicc = "#273433"
local bg_hard = "#2b3339"
local bg_medium = "#2b3339"

C.transparent = nil
C.bg0 = hsluv("#323d43")
C.bg1 = C.bg0.lighten(5) -- #3c474d
C.bg2 = C.bg0.lighten(10) -- #465258
C.bg3 = C.bg0.lighten(15) -- #505a60
C.bg4 = C.bg0.lighten(20) -- #576268
C.bg5 = C.bg0.lighten(25) -- #626262

C.bg_dark_raw = bg_hard
C.bg_dark = hsluv(bg_hard)
C.bg_visual = hsluv("#5d5c50")
C.bg_red = hsluv("#614b51")
C.bg_green = hsluv("#4e6053")
C.bg_blue = hsluv("#415c6d")
C.bg_yellow = hsluv("#5d5c50")
C.bg_purple = hsluv("#402F37")
C.bg_cyan = hsluv("#54816B")

C.fg = hsluv("#d8caac")
C.white = hsluv("#ffffff")

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

C.bright_blue = C.blue.lighten(5)
C.bright_blue_alt = "#51afef"
C.bright_green = hsluv("#6bc46d")
C.bright_yellow = hsluv("#FAB005")

C.light_yellow = hsluv("#e5c07b")
C.light_red = hsluv("#c43e1f")

C.dark_blue = C.blue.darken(25)
C.dark_blue_alt = "#4e88ff"
C.dark_orange = hsluv("#FF922B")
C.dark_red = hsluv("#be5046")
C.dark_green = hsluv("#6bc46d").darken(20)

C.lsp.error = C.pale_red
C.lsp.warn = C.dark_orange
C.lsp.hint = C.bright_blue
C.lsp.info = C.teal

return C
