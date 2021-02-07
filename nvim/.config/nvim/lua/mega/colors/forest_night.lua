local cu = require("mega.colors.utils")

local icons = {
  sign_error = mega.utf8(0xf655),
  sign_warning = mega.utf8(0xfa36),
  sign_information = mega.utf8(0xf7fc),
  sign_hint = mega.utf8(0xf835),
  virtual_text = mega.utf8(0xf63d),
  mode_term = mega.utf8(0xfcb5),
  ln_sep = mega.utf8(0xe0a1),
  col_sep = mega.utf8(0xf6da),
  perc_sep = mega.utf8(0xf44e),
  right_sep = mega.utf8(0xe0b4),
  left_sep = mega.utf8(0xe0b6),
  modified_symbol = mega.utf8(0xf085),
  vcs_symbol = mega.utf8(0xf418),
  readonly_symbol = mega.utf8(0xf023),
  statusline_error = mega.utf8(0xf05e),
  statusline_warning = mega.utf8(0xf071),
  statusline_information = mega.utf8(0xf7fc),
  statusline_hint = mega.utf8(0xf835)
}

-- https://github.com/sainnhe/forest-night/blob/master/autoload/lightline/colorscheme/forest_night.vim
local cs = {
  bg0 = "#323d43",
  bg1 = "#3c474d",
  bg2 = "#465258",
  bg3 = "#505a60",
  bg4 = "#576268",
  bg_visual = "#5d4251",
  bg_red = "#614b51",
  bg_green = "#4e6053",
  bg_blue = "#415c6d",
  bg_yellow = "#5d5c50",
  grey0 = "#7c8377",
  grey1 = "#868d80",
  grey2 = "#999f93",
  fg = "#d8caac",
  red = "#e68183",
  orange = "#e39b7b",
  yellow = "#d9bb80",
  green = "#a7c080",
  cyan = "#87c095",
  blue = "#83b6af",
  purple = "#d39bb6"
}

local base = {
  black = cs.bg0,
  white = cs.fg,
  fg = cs.fg,
  red = cs.red,
  light_red = cs.red,
  dark_red = "#d75f5f",
  green = cs.green,
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
  section_bg = cs.bg1
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
  warning_status = base.dark_yellow,
  hint_status = base.lighter_gray,
  information_status = base.gray,
  cursorlinenr = base.brown,
  added = base.green,
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
  inactive_bg = base.special_gray
}

return {
  icons = icons,
  colors = mega.table_merge(base, status),
  load = function()
    -- (set forest_night colorscheme) --
    vim.o.background = "dark"
    vim.api.nvim_exec([[ colorscheme forest-night ]], true)

    vim.g.forest_night_background = "soft"
    vim.g.forest_night_enable_italic = 1
    vim.g.forest_night_enable_bold = 1
    vim.g.forest_night_transparent_background = 1
    vim.g.forest_night_sign_column_background = "none"

    -- (highlights) --
    vim.api.nvim_exec([[match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$']], true)

    cu.hi("SpellBad", status.error_status, status.bg, "undercurl,underline,italic")
    cu.hi("SpellCap", status.error_status, status.bg, "undercurl,underline,italic")
    cu.hi("SpellRare", status.error_status, status.bg, "undercurl,underline,italic")
    cu.hi("SpellLocal", status.error_status, status.bg, "undercurl,underline,italic")


    cu.hi("GalaxyStatusline", "NONE", status.bg, "NONE")
    cu.hi("GalaxyStatuslineNC", "NONE", status.bg, "NONE")
    cu.hi("LspLinesDiagBorder", cs.bg_green, "NONE", "NONE")

    mega.load("statusline", "mega.statusline").load("forest_night")
  end
}
