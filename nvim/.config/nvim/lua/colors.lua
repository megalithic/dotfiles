local vcmd, api, g, set = vim.cmd, vim.api, vim.g, vim.opt
local hi, link, utf8 = mega.hi, mega.hi_link, mega.utf8

local hsl = require("lush").hsl

local icons = {
  sign_error = utf8(0xf655),
  sign_warning = utf8(0xfa36),
  sign_information = utf8(0xf7fc),
  sign_hint = utf8(0xf835),
  virtual_text = utf8(0xf63d),
  mode_term = utf8(0xfcb5),
  ln_sep = utf8(0xe0a1),
  col_sep = utf8(0xf6da),
  perc_sep = utf8(0xf44e),
  right_sep = utf8(0xe0b4),
  left_sep = utf8(0xe0b6),
  modified_symbol = utf8(0xf085),
  mode_symbol = utf8(0xf101),
  vcs_symbol = utf8(0xf418),
  git_symbol = utf8(0xe725),
  readonly_symbol = utf8(0xf023),
  statusline_error = utf8(0xf05e),
  statusline_warning = utf8(0xf071),
  statusline_information = utf8(0xf7fc),
  statusline_hint = utf8(0xf835),
  statusline_ok = utf8(0xf00c),
  prompt_symbol = "", -- utf8(0xf460),
}

local cs = {}
cs.bg_dark = hsl("#273433")
cs.bg0 = hsl("#323d43")
cs.bg1 = hsl("#3c474d")
cs.bg2 = hsl("#465258")
cs.bg3 = hsl("#505a60")
cs.bg4 = hsl("#576268")
cs.bg5 = hsl("#626262")
cs.bg_visual = hsl("#4e6053")
-- theme.bg_visual = "#5d4251"
cs.bg_red = hsl("#614b51")
cs.bg_green = hsl("#4e6053")
cs.bg_blue = hsl("#415c6d")
cs.bg_yellow = hsl("#5d5c50")
cs.grey0 = hsl("#7c8377")
cs.grey1 = hsl("#868d80")
cs.grey2 = hsl("#999f93")
cs.fg = hsl("#d8caac")
cs.red = hsl("#e68183")
cs.orange = hsl("#e39b7b")
cs.yellow = hsl("#d9bb80")
cs.green = hsl("#a7c080")
cs.bright_green = hsl("#6bc46d")
cs.cyan = hsl("#87c095").darken(5)
cs.blue = hsl("#83b6af")
cs.bright_blue = cs.blue.lighten(5)
cs.dark_blue = cs.blue.darken(25)
cs.aqua = cs.blue
cs.purple = hsl("#d39bb6")
cs.brown = hsl("#db9c5e")
-- fiddling with these colours:
cs.magenta = "#c678dd"
cs.comment_grey = "#5c6370"
cs.grey = "#3E4556"
cs.teal = "#15AABF"
cs.bright_yellow = "#FAB005"
cs.light_yellow = "#e5c07b"
cs.dark_orange = "#FF922B"
cs.pale_red = "#E06C75"
cs.dark_red = "#be5046"
cs.light_red = "#c43e1f"
-- cs.dark_blue = "#4e88ff"
-- cs.bright_blue = "#51afef"

local style = {
  icons = {
    error = "✗",
    warn = "",
    info = "",
    hint = "",
  },
  lsp = {
    colors = {
      error = cs.pale_red,
      warn = cs.dark_orange,
      hint = cs.bright_yellow,
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

-- FIXME: deprecate alllllll these things and migrate to a base palette
return {
  icons = icons,
  cs = cs,
  base = base,
  status = status,
  colors = mega.table_merge(mega.table_merge(base, status), cs),
  style = style,
  setup = function(theme)
    -- mega.color_overrides = function()
    --   hi("Group", {guifg = cs.fg, guibg = cs.bg, gui = "", force = true})
    -- end
    -- mega.augroup("colorscheme_overrides", {
    --   {
    --     events = { "ColorScheme" },
    --     targets = { theme },
    --     command = "lua mega.color_overrides()",
    --   },
    -- })

    set.termguicolors = true
    vcmd("colorscheme " .. theme)
  end,
}
