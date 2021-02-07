local highlight = mega.set_highlight

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
-- TODO: should really look at switching to "standard" color names/enums
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

    vim.g.forest_night_background = "soft"
    vim.g.forest_night_enable_italic = 1
    vim.g.forest_night_enable_bold = 1
    vim.g.forest_night_transparent_background = 1
    vim.g.forest_night_sign_column_background = "default"

    -- (highlights) --
    vim.api.nvim_exec([[match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$']], true)

    -- mega.augroup_cmds(
    --   "colorscheme_overrides",
    --   {
    --     {
    --       events = {"ColorScheme"},
    --       targets = {"*"},
    --       command = [[ v:lua.mega.set_highlight("SpellBad", status.error_status, status.bg, "undercurl,italic") ]]
    --     },
    --     {
    --       events = {"ColorScheme"},
    --       targets = {"*"},
    --       command = [[ v:lua.mega.set_highlight("SpellCap", status.error_status, status.bg, "undercurl,italic") ]]
    --     },
    --     {
    --       events = {"ColorScheme"},
    --       targets = {"*"},
    --       command = [[ v:lua.mega.set_highlight("SpellRare", status.error_status, status.bg, "undercurl,italic") ]]
    --     },
    --     {
    --       events = {"ColorScheme"},
    --       targets = {"*"},
    --       command = [[ v:lua.mega.set_highlight("SpellLocal", status.error_status, status.bg, "undercurl,italic") ]]
    --     },
    --   }
    -- )

    -- mega.augroup(
    --   "lc.format",
    --   function()
    --     vim.api.nvim_command [[autocmd! * <buffer>]]
    --     vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting(nil, 1000)]]
    --     -- vim.api.nvim_command [[autocmd BufWritePost plugins.lua PackerCompile]]
    --   end
    -- )

    -- vim.api.nvim_exec([[
    --     function! Forest_night_custom() abort
    --     " Link a highlight group to a predefined highlight group.
    --     " See `colors/forest-night.vim` for all predefined highlight groups.
    --     " highlight! link groupA groupB
    --     " highlight! link groupC groupD
      
    --     " Initialize the color palette.
    --     let l:palette = forest_night#get_palette()

    --     " Define a highlight group.
    --     " The first parameter is the name of a highlight group,
    --     " the second parameter is the foreground color,
    --     " the third parameter is the background color,
    --     " the fourth parameter is for UI highlighting which is optional,
    --     " and the last parameter is for `guisp` which is also optional.
    --     " See `autoload/forest_night.vim` for the format of `l:palette`.

    --     call forest_night#highlight('SpellBad', l:palette.red, l:palette.none, 'undercurl', l:palette.red)
    --     call forest_night#highlight('SpellCap', l:palette.red, l:palette.none, 'undercurl', l:palette.red)
    --     call forest_night#highlight('SpellRare', l:palette.red, l:palette.none, 'undercurl', l:palette.red)
    --     call forest_night#highlight('SpellLocal', l:palette.red, l:palette.none, 'undercurl', l:palette.red)
    --   endfunction
      
    --   augroup ForestNightCustom
    --     autocmd!
    --     autocmd ColorScheme forest-night call Forest_night_custom()
    --   augroup END
    -- ]], false)

    highlight("default GalaxyStatusline", "NONE", status.bg, "NONE")
    highlight("default GalaxyStatuslineNC", "NONE", status.bg, "NONE")
    highlight("default LspLinesDiagBorder", cs.bg_green, "NONE", "NONE")

    mega.load("statusline", "mega.statusline").load("forest_night")

    vim.api.nvim_exec([[ colorscheme forest-night ]], true)
  end
}
