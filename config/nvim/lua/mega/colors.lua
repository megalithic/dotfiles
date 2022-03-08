local vcmd, api, g, set = vim.cmd, vim.api, vim.g, vim.opt
local hi, link, utf8 = mega.hi, mega.hi_link, mega.utf8

-- local hsl = require("lush").hsl

local lush = require("lush")
-- local hsluv = lush.hsluv
local hsluv = lush.hsl

-- local M = {}
-- M.red = hsl("#e68183")
-- M.orange = hsl("#e39b7b")
-- M.yellow = hsl("#d9bb80")
-- M.green = hsl("#a7c080")
-- M.cyan = hsl("#87c095")
-- M.aqua = M.cyan
-- M.blue = hsl("#83b6af")
-- M.purple = hsl("#d39bb6")

-- M.bg0 = hsl("#273433")
-- M.bg1 = M.bg0.lighten(10)
-- M.bg2 = M.bg0.lighten(15)
-- M.bg3 = M.bg0.lighten(20)
-- M.bg4 = M.bg0.lighten(25)

-- M.bg_visual = hsl("#5d4251")
-- M.bg_red = hsl("#614b51")
-- M.bg_green = hsl("#4e6053")
-- M.bg_blue = hsl("#415c6d")
-- M.bg_yellow = hsl("#5d5c50")
-- M.bg_purple = hsl("#402F37")
-- M.bg_cyan = hsl("#54816B")

-- M.fg = hsl("#d8caac")

-- M.grey0 = hsl("#7c8377")
-- M.grey1 = hsl("#868d80")
-- M.grey2 = hsl("#999f93")

local cs = {}

cs.bg0 = hsluv("#323d43")
cs.bg1 = cs.bg0.lighten(5) -- #3c474d
cs.bg2 = cs.bg0.lighten(10) -- #465258
cs.bg3 = cs.bg0.lighten(15) -- #505a60
cs.bg4 = cs.bg0.lighten(20) -- #576268
cs.bg5 = cs.bg0.lighten(25) -- #626262

cs.bg_dark = hsluv("#273433")
cs.bg_visual = hsluv("#4e6053")
cs.bg_red = hsluv("#614b51")
cs.bg_green = hsluv("#4e6053")
cs.bg_blue = hsluv("#415c6d")
cs.bg_yellow = hsluv("#5d5c50")
cs.bg_purple = hsluv("#402F37")
cs.bg_cyan = hsluv("#54816B")

cs.fg = hsluv("#d8caac")

cs.dark_grey = "#3E4556"
cs.light_grey = "#5c6370"
cs.grey0 = hsluv("#7c8377")
cs.grey1 = hsluv("#868d80")
cs.grey2 = hsluv("#999f93")

cs.red = hsluv("#e68183")
cs.orange = hsluv("#e39b7b")
cs.yellow = hsluv("#d9bb80")
cs.green = hsluv("#a7c080")
cs.cyan = hsluv("#87c095").darken(5)
cs.blue = hsluv("#83b6af")
cs.aqua = cs.cyan
cs.purple = hsluv("#d39bb6")
cs.brown = hsluv("#db9c5e")
cs.magenta = cs.purple.darken(15) -- #c678dd
cs.teal = "#15AABF"

cs.pale_red = "#E06C75"

cs.bright_blue = cs.blue.lighten(5) -- #51afef
cs.bright_green = hsluv("#6bc46d")
cs.bright_yellow = "#FAB005"

cs.light_yellow = "#e5c07b"
cs.light_red = "#c43e1f"

cs.dark_blue = cs.blue.darken(25) -- #4e88ff
cs.dark_orange = "#FF922B"
cs.dark_red = "#be5046"

local style = {
  lsp = {
    colors = {
      error = cs.pale_red,
      warn = cs.dark_orange,
      hint = cs.blue,
      info = cs.cyan,
    },
    kinds = {
      Text = "",
      Method = "",
      Function = "",
      Constructor = "",
      Field = "ﰠ",
      Variable = "",
      Class = "ﴯ",
      Interface = "",
      Module = "",
      Property = "ﰠ",
      Unit = "塞",
      Value = "",
      Enum = "",
      Keyword = "",
      Snippet = "",
      Color = "",
      File = "",
      Reference = "",
      Folder = "",
      EnumMember = "",
      Constant = "",
      Struct = "פּ",
      Event = "",
      Operator = "",
      TypeParameter = "",
    },
  },
}

local base = {
  black = cs.bg0,
  white = cs.fg,
  fg = cs.fg,
  red = cs.red,
  light_red = cs.red,
  dark_red = "#d75f5f",
  green = cs.green,
  bright_green = "#6bc46d",
  blue = cs.blue,
  cyan = cs.cyan,
  magenta = cs.purple,
  yellow = cs.yellow,
  light_yellow = "#dada93",
  dark_yellow = cs.bg_yellow,
  orange = cs.orange,
  brown = "#db9c5e",
  lightest_gray = cs.grey2,
  lighter_gray = cs.grey1,
  light_gray = cs.grey0,
  gray = cs.bg4,
  dark_gray = cs.bg3,
  darker_gray = cs.bg2,
  darkest_gray = cs.bg1,
  visual_gray = cs.bg_blue,
  special_gray = "#1E272C",
  section_bg = cs.bg1,
}

local status = {
  normal_text = base.white,
  bg = base.black,
  dark_bg = base.darkest_gray,
  special_bg = base.darker_gray,
  default = base.blue,
  selection = base.cyan,
  ok_status = base.green,
  error_status = base.light_red,
  warning_status = base.yellow,
  hint_status = base.lighter_gray,
  information_status = base.gray,
  cursorlinenr = base.brown,
  added = base.bright_green,
  removed = base.light_red,
  changed = "#ecc48d",
  separator = "#666666",
  incsearch = "#fffacd",
  highlighted_yank = "#13354A",
  comment_gray = base.white,
  gutter_gray = cs.bg_green,
  cursor_gray = base.black,
  visual_gray = base.visual_gray,
  menu_gray = base.visual_gray,
  special_gray = base.special_gray,
  vertsplit = "#181a1f",
  tab_color = base.blue,
  normal_color = base.blue,
  insert_color = base.green,
  replace_color = base.light_red,
  visual_color = base.light_yellow,
  terminal_color = "#6f6f6f",
  active_bg = base.visual_gray,
  inactive_bg = base.special_gray,
}

return {
  cs = cs,
  base = base,
  status = status,
  colors = mega.table_merge(mega.table_merge(base, status), cs),
  style = style,
}
