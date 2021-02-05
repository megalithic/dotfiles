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

local base = {
  black = "#3c4c55",
  white = "#c5d4dd",
  fg = "#c5d4dd",
  red = "#df8c8c",
  light_red = "#df8c8c",
  dark_red = "#d75f5f",
  green = "#a8ce93",
  blue = "#83afe5",
  cyan = "#7fc1ca",
  magenta = "#9a93e1",
  light_yellow = "#dada93",
  dark_yellow = "#f2c38f",
  orange = "#f2c38f",
  brown = "#db9c5e",
  lightest_gray = "#dddddd",
  lighter_gray = "#afafaf",
  light_gray = "#afafaf",
  gray = "#aaaaaa",
  dark_gray = "#667796",
  darker_gray = "#333333",
  darkest_gray = "#2f3c44",
  visual_gray = "#6A7D89",
  special_gray = "#1E272C",
  section_bg = "#333333"
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
  gutter_gray = "#899ba6",
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
    cu.hi("GalaxyStatusline", "NONE", status.bg, "NONE")
    cu.hi("GalaxyStatuslineNC", "NONE", status.bg, "NONE")
  end
}
