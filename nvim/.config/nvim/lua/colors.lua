local cmd = vim.cmd
local au, hi, utf8 = mega.au, mega.highlight, mega.utf8

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
  vcs_symbol = utf8(0xf418),
  readonly_symbol = utf8(0xf023),
  statusline_error = utf8(0xf05e),
  statusline_warning = utf8(0xf071),
  statusline_information = utf8(0xf7fc),
  statusline_hint = utf8(0xf835),
  statusline_ok = utf8(0xf00c),
  prompt_symbol = utf8(0xf460)
}

-- TODO: thieve @mhanberg's lush theme that wraps everforest/forest_night:
-- https://github.com/mhanberg/.dotfiles/blob/main/config/nvim/lua/lush_theme/thicc_forest.lua
local cs = {
  bg0 = "#323d43",
  bg1 = "#3c474d",
  bg2 = "#465258",
  bg3 = "#505a60",
  bg4 = "#576268",
  bg_visual = "#4e6053",
  -- bg_visual = "#5d4251",
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
  colors = mega.table_merge(mega.table_merge(base, status), cs),
  setup = function()
    mega.everforest_overrides = function()
      -- hi("SpellBad", {guifg = status.error_status, guibg = status.bg, gui = "undercurl,italic", force = true})
      -- -- hi("SpellCap", status.error_status, status.bg, "underline,undercurl,italic")
      -- -- hi("SpellRare", status.error_status, status.bg, "underline,undercurl,italic")
      -- -- hi("SpellLocal", status.error_status, status.bg, "underline,undercurl,italic")
      hi("CursorLineNr", {guifg = status.cursorlinenr, guibg = status.special_bg, gui = "bold,italic", force = true})
      hi("OrgDone", {guifg = status.green, guibg = "NONE", gui = "bold", force = true})
      hi("OrgAgendaScheduled", {guifg = status.cyan, guibg = "NONE", gui = "NONE", force = true})
      -- hi("DiffAdd", {guifg = status.added, guibg = "NONE", force = true})
      -- hi("DiffDelete", {guifg = status.removed, guibg = "NONE", force = true})
      -- hi("DiffChange", {guifg = status.changed, guibg = "NONE", force = true})
      -- hi("markdownHeadline", {guifg = status.normal_text, guibg = status.vertsplit, force = true})
      -- hi("markdownFirstHeadline", {guifg = status.bg, guibg = status.added, force = true})
      -- hi("markdownSecondHeadline", {guifg = status.bg, guibg = status.changed, force = true})
      -- vim.api.nvim_exec([[match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$']], true)
      -- vim.g.indentLine_color_gui = status.cursorlinenr
      -- vim.g.limelight_conceal_guifg = cs.bg2
    end
    mega.augroup_cmds(
      "EverforestOverrides",
      {
        {
          events = {"VimEnter", "ColorScheme"},
          targets = {"everforest"},
          command = "lua mega.everforest_overrides()"
        }
      }
    )

    vim.opt.termguicolors = true
    vim.g.everforest_enable_italic = true
    vim.g.everforest_enable_bold = true
    vim.g.everforest_transparent_background = true
    -- vim.g.everforest_diagnostic_text_highlight = true
    -- vim.g.everforest_diagnostic_line_highlight = true
    -- vim.g.everforest_sign_column_background = "none"
    vim.g.everforest_background = "soft"
    vim.g.everforest_cursor = "auto"
    vim.g.everforest_better_performance = true
    cmd("colorscheme everforest")
  end
}
