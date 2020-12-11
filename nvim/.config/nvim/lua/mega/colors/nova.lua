-- local icons = {
--statusline_checking = "\uf110",   --"
--statusline_ok = "\uf00c",         --"
--statusline_error = "\uf05e",      --"
--statusline_warning = "\uf071",    --"
--statusline_information = "\uf7fc",--"
--statusline_hint = "\uf835",       --"
--modified_symbol = "\uf085",       --" vcs_symbol = "\uf418",            --"
--readonly_symbol = "\uf023",       --"
--ln_sep = "\ue0a1",                --"
--col_sep = "\uf6da",               --"
--perc_sep = "\uf44e",              --"
--right_sep = "\ue0b4",             --" nf-ple-*
--left_sep = "\ue0b6",              --"
--term_mode = "\ufcb5",             --"\ue7a2  ﲵ

--sign_error = "\uf655",
--sign_warning = "\ufa36",          --"喝
--sign_information = "\uf7fc",   --"\uf0da
--sign_hint = "\uf835",    --"\uf105

--virtual_text_symbol = "\uf63d",   --"

--spinner_frames = {'⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'},
-- }

local cu = require("mega.colors.utils")

local icons = {
  sign_error = mega.utf8(0xf655), --"",
  sign_warning = "喝", --"\ufa36 喝
  sign_information = "", --\uf7fc \uf0da 
  sign_hint = "", --"\uf835" \uf105
  virtual_text = mega.utf8(0xf63d)
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
  lightest_gray = "#afafaf",
  lighter_gray = "#dddddd",
  light_gray = "#afafaf",
  gray = "#aaaaaa",
  dark_gray = "#667796",
  darker_gray = "#333333",
  darkest_gray = "#2f3c44",
  visual_gray = "#6A7D89",
  special_gray = "#1E272C",
  section_bg = "#333333",
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
  active_bg = base.visual_gray,
  inactive_bg = base.special_gray
}

return {
  icons = icons,
  colors = mega.table_merge(base, status),
  activate = function()
    -- (set nova colorscheme) --
    vim.o.background = "dark"
    vim.g.nova_transparent = 1
    vim.api.nvim_exec([[ colorscheme nova ]], true)

    -- (highlights) --
    vim.api.nvim_exec([[match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$']], true)

    cu.hi("HighlightedyankRegion", status.highlighted_yank, "NONE", "bold")
    cu.hi("HighlightedYankRegion", status.highlighted_yank, "NONE", "bold")
    cu.hi("IncSearch", status.incsearch, "NONE", "bold")
    cu.hi("SignColumn", nil, "NONE", nil)
    cu.hi("CursorLineNr", status.cursorlinenr, status.special_bg, "italic")
    cu.hi("VertSplit", status.separator, "NONE", "NONE")
    cu.hi("Visual", status.bg, status.selection, "NONE")
    cu.hi("Normal", status.normal_text, "NONE", "NONE")
    cu.hi("htmlArg", nil, nil, "italic")
    cu.hi("xmlAttrib", nil, nil, "italic")
    cu.hi("Type", nil, nil, "italic")
    cu.hi("Comment", nil, nil, "italic")
    cu.hi("MatchWord", nil, nil, "underline,undercurl,italic")
    cu.hi("MatchParen", nil, nil, "underline,undercurl,italic")
    cu.hi("CleverFDefaultLabel", status.cursorlinenr, status.special_bg, nil)
    cu.hi("CleverFDefaultLabel", status.cursorlinenr, status.special_bg, nil)

    cu.hi("ErrorMsg", status.error_status, nil, "underline,undercurl,italic")
    cu.hi("WarningMsg", status.warning_status, nil, "italic")
    cu.hi("InformationMsg", status.information_status, nil, "italic")
    cu.hi("HintMsg", status.hint_status, nil, "italic")

    cu.hi("Debug", status.error_status, nil, "underline,undercurl,italic")
    cu.hi("Exception", status.error_status, nil, "underline,undercurl,italic")

    cu.hi("SpellBad", status.error_status, status.bg, "underline,undercurl,italic")
    cu.hi("SpellCap", status.error_status, status.bg, "underline,undercurl,italic")
    cu.hi("SpellRare", status.error_status, status.bg, "underline,undercurl,italic")
    cu.hi("SpellLocal", status.error_status, status.bg, "underline,undercurl,italic")

    cu.hi("ModifiedColor", status.error_status, "NONE", "bold")
    cu.hi("gitCommitOverflow", status.special_bg, status.error_status, "underline,undercurl")

    cu.hi("DiffAdd", status.added, status.bg, "NONE")
    cu.hi("DiffDelete", status.removed, status.bg, "NONE")
    cu.hi("DiffChange", status.changed, status.bg, "NONE")

    local lsp_highlights = {
      ["Error"] = "error_status",
      ["Warning"] = "warning_status",
      ["Information"] = "information_status",
      ["Hint"] = "hint_status"
    }

    for group, id in pairs(lsp_highlights) do
      cu.hi("LspDiagnosticsVirtualText" .. group, status[id], nil, "undercurl,italic")
      cu.hi("LspDiagnosticsUnderline" .. group, status[id], nil, "undercurl,italic")
      cu.hi("LspDiagnosticsDefault" .. group, status[id], nil, "undercurl,italic")
      cu.hi("LspDiagnosticsFloating" .. group, status[id], nil, "italic")
      cu.hi("LspDiagnosticsSign" .. group, status[id], nil, nil)
    end
  end
}
