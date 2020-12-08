-- local icons = {
--statusline_checking = "\uf110",   --"
--statusline_ok = "\uf00c",         --"
--statusline_error = "\uf05e",      --"
--statusline_warning = "\uf071",    --"
--statusline_information = "\uf7fc",--"
--statusline_hint = "\uf835",       --"
--modified_symbol = "\uf085",       --"
--vcs_symbol = "\uf418",            --"
--readonly_symbol = "\uf023",       --"
--ln_sep = "\ue0a1",                --"
--col_sep = "\uf6da",               --"
--perc_sep = "\uf44e",              --"
--right_sep = "\ue0b4",             --" nf-ple-*
--left_sep = "\ue0b6",              --"
--term_mode = "\ufcb5",             --"\ue7a2  ﲵ

-- sign_error = "\uf655",
--sign_warning = "\ufa36",          --"喝
--sign_information = "\uf7fc",   --"\uf0da
--sign_hint = "\uf835",    --"\uf105

--virtual_text_symbol = "\uf63d",   --"

--spinner_frames = {'⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'},
-- }

local icons = {
  sign_error = "",
  sign_warning = "喝", --"\ufa36 喝
  sign_information = "", --\uf7fc \uf0da 
  sign_hint = "" --"\uf835" \uf105
}

local base = {
  black = "#3c4c55",
  white = "#c5d4dd",
  light_red = "#df8c8c",
  dark_red = "#d75f5f",
  green = "#a8ce93",
  blue = "#83afe5",
  cyan = "#7fc1ca",
  magenta = "#9a93e1",
  light_yellow = "#dada93",
  dark_yellow = "#f2c38f",
  brown = "#db9c5e",
  lightest_gray = "#afafaf",
  lighter_gray = "#dddddd",
  light_gray = "#afafaf",
  gray = "#aaaaaa",
  dark_gray = "#667796",
  darker_gray = "#333333",
  darkest_gray = "#2f3c44",
  visual_gray = "#6A7D89",
  special_gray = "#1E272C"
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
  active_bg = base.visual_gray,
  inactive_bg = base.special_gray
}

return {
  icons = icons,
  colors = mega.table_merge(base, status)
}
