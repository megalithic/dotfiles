-- # REFS:
-- - https://github.com/svitax/fennec-gruvbox.nvim/blob/master/lua/lush_theme/fennec-gruvbox.lua
-- - https://github.com/mcchrish/zenbones.nvim/blob/main/lua/zenbones/specs/dark.lua
-- - https://github.com/rktjmp/lush.nvim/issues/109
-- # FIXME:
-- https://github.com/rktjmp/lush-template/blob/main/lua/lush_theme/lush_template.lua

-- `megaforest` built with,
--
--        ,gggg,
--       d8" "8I                         ,dPYb,
--       88  ,dP                         IP'`Yb
--    8888888P"                          I8  8I
--       88                              I8  8'
--       88        gg      gg    ,g,     I8 dPgg,
--  ,aa,_88        I8      8I   ,8'8,    I8dP" "8I
-- dP" "88P        I8,    ,8I  ,8'  Yb   I8P    I8
-- Yb,_,d88b,,_   ,d8b,  ,d8b,,8'_   8) ,d8     I8,
--  "Y8P"  "Y888888P'"Y88P"`Y8P' "YY8P8P88P     `Y8
--
-- @megalithic
--
-- credits:
--  * @sainnhe for everforest
--  * @mhanberg for thicc_forest

local lush = require("lush")

local C = require("mega.lush_theme.colors")

local palette = require("mega.lush_theme.palette")
-- local palette = mega.wrap_err(require, "mega.lush_theme.palette")
local spec = palette.spec
local gui = palette.gui_combine
local cfg = palette.cfg
local clrs = palette.clrs

local tc = {
  black = C.bg0,
  red = C.red,
  yellow = C.yellow,
  green = C.green,
  cyan = C.aqua,
  blue = C.blue,
  purple = C.purple,
  white = C.fg,
}

vim.g.terminal_color_0 = tostring(tc.black)
vim.g.terminal_color_1 = tostring(tc.red)
vim.g.terminal_color_2 = tostring(tc.green)
vim.g.terminal_color_3 = tostring(tc.yellow)
vim.g.terminal_color_4 = tostring(tc.blue)
vim.g.terminal_color_5 = tostring(tc.purple)
vim.g.terminal_color_6 = tostring(tc.cyan)
vim.g.terminal_color_7 = tostring(tc.white)
vim.g.terminal_color_8 = tostring(tc.black)
vim.g.terminal_color_9 = tostring(tc.red)
vim.g.terminal_color_10 = tostring(tc.green)
vim.g.terminal_color_11 = tostring(tc.yellow)
vim.g.terminal_color_12 = tostring(tc.blue)
vim.g.terminal_color_13 = tostring(tc.purple)
vim.g.terminal_color_14 = tostring(tc.cyan)
vim.g.terminal_color_15 = tostring(tc.white)
vim.g.terminal_color_background = tostring(tc.black)
vim.g.terminal_color_foreground = tostring(tc.white)

vim.g.fzf_colors = {
  fg = { "fg", "Normal" },
  bg = { "bg", "Normal" },
  hl = { "fg", "Green" },
  ["fg+"] = { "fg", "CursorLine", "CursorColumn", "Normal" },
  ["bg+"] = { "bg", "CursorLine", "CursorColumn" },
  ["hl+"] = { "fg", "Cyan" },
  info = { "fg", "Aqua" },
  prompt = { "fg", "Orange" },
  pointer = { "fg", "Blue" },
  marker = { "fg", "Yellow" },
  spinner = { "fg", "Yellow" },
  header = { "fg", "Grey" },
}

vim.g.VM_Mono_hl = "Cursor"
vim.g.VM_Extend_hl = "Visual"
vim.g.VM_Cursor_hl = "Cursor"
vim.g.VM_Insert_hl = "Cursor"

---@diagnostic disable: undefined-global
local theme = lush(function(injected_functions)
  local sym = injected_functions.sym

  return {
    -- +---------------+
    -- + UI Components +
    -- +---------------+
    -- +-- Attributes --+
    Bold({ gui = spec.bold }),
    Italic({ gui = spec.italic }),
    Underline({ gui = spec.underline }),

    -- +-- Editor --+
    ColorColumn({ bg = C.bg2 }),
    Cursor({ fg = C.bg0, bg = clrs.nord4 }),
    CursorLine({ bg = C.bg2 }),
    Error({ fg = clrs.nord4, bg = C.bg21 }),
    iCursor({ fg = C.bg0, bg = clrs.nord4 }),
    LineNr({ fg = clrs.nord3 }),
    MatchParen({ fg = clrs.nord8, bg = clrs.nord3 }),
    NonText({ fg = C.bg_visual }),
    Normal({ fg = clrs.nord4, bg = C.bg0 }),
    NormalFloat({ bg = Normal.bg.da(20) }),
    FloatBorder({ fg = clrs.nord3_bright, bg = Normal.bg.da(10) }),
    Pmenu({ NormalFloat }),
    PmenuSbar({ fg = C.bg_visual, bg = clrs.nord4 }),
    PmenuSel({ fg = clrs.nord8, bg = clrs.nord3 }),
    -- PmenuSel {fg = clrs.nord3, bg =clrs.nord8},
    PmenuThumb({ fg = clrs.nord8, bg = clrs.nord3 }),
    SpecialKey({ fg = clrs.nord3 }),
    SpellBad({
      -- fg = C.bg21.de(50).da(20),
      -- bg = C.bg0,
      gui = spec.undercurl,
      guisp = C.bg21.de(50).da(20),
      guifg = "NONE",
      guibg = "NONE",
    }),
    SpellCap({
      -- fg = C.bg23,
      -- bg = C.bg0,
      gui = spec.undercurl,
      guisp = C.bg23,
      guifg = "NONE",
      guibg = "NONE",
    }),
    SpellLocal({
      -- fg = clrs.nord5,
      -- bg = C.bg0,
      gui = spec.undercurl,
      guisp = clrs.nord5,
      guifg = "NONE",
      guibg = "NONE",
    }),
    SpellRare({
      -- fg = clrs.nord6,
      -- bg = C.bg0,
      gui = spec.undercurl,
      guisp = clrs.nord6,
      guifg = "NONE",
      guibg = "NONE",
    }),
    Visual({ bg = C.bg_visual }),
    VisualNOS({ bg = C.bg_visual }),

    -- +-- Gutter --+
    CursorColumn({ bg = C.bg2 }),
    CursorLineNr({
      fg = clrs.nord4.da(10),
      bg = cfg.theme_cursor_line_number_background == 1 and nil or C.bg2,
    }),
    Folded({ fg = clrs.nord3.li(7), bg = C.bg2, gui = spec.bold }),
    FoldColumn({ fg = C.bg24.de(50).da(30), bg = C.bg0 }),
    SignColumn({ fg = C.bg2.li(2), bg = C.bg0 }),

    -- +-- Navigation --+
    Directory({ fg = clrs.nord8 }),

    -- +--- Prompt/Status ---+
    EndOfBuffer({ fg = C.bg2 }),
    ErrorMsg({ fg = clrs.nord4.da(10), bg = C.bg21.da(20).de(15) }),
    ModeMsg({ fg = clrs.nord4 }),
    MoreMsg({ fg = clrs.nord8 }),
    Question({ fg = clrs.nord4 }),
    StatusLine({ bg = C.bg0.da(50), gui = "NONE" }),
    StatusLineNC({
      fg = clrs.nord4,
      bg = cfg.theme_uniform_status_lines == 0 and C.bg2 or crls.nord3,
      gui = "NONE",
    }),
    StatusLineTerm({ fg = clrs.nord8, bg = clrs.nord3, gui = "NONE" }),
    StatusLineTermNC({
      fg = clrs.nord4,
      bg = cfg.theme_uniform_status_lines == 0 and C.bg2 or crls.nord3,
      gui = "NONE",
    }),
    WarningMsg({ fg = C.bg0, bg = C.bg23.da(20).de(15) }),
    WildMenu({ fg = clrs.nord8, bg = C.bg2 }),

    -- +--- Search ---+
    IncSearch({ fg = clrs.nord6, bg = C.bg20, gui = spec.underline }),
    Search({ fg = C.bg2, bg = clrs.nord8, gui = "NONE" }),

    -- +--- Tabs ---+
    TabLine({ fg = clrs.nord4, bg = C.bg2, gui = "NONE" }),
    TabLineFill({ fg = clrs.nord4, bg = C.bg2, gui = "NONE" }),
    TabLineSel({ fg = clrs.nord8, bg = clrs.nord3, gui = "NONE" }),

    -- +--- Window ---+
    Title({ fg = clrs.nord4, gui = "NONE" }),
    VertSplit({
      fg = C.bg_visual,
      bg = cfg.theme_bold_vertical_split_line == 0 and C.bg0 or C.bg2,
      gui = "NONE",
    }),

    -- +--- Floats ---+
    NormalFloat({ Pmenu }), -- Normal text in floating windows.
    FloatBorder({ Pmenu, fg = C.bg_dark }),
    NotifyFloat({ bg = C.bg2.darken(10), fg = C.bg2.darken(10) }),
    FloatTitle({ Visual }),

    -- +----------------------+
    -- + Language Base Groups +
    -- +----------------------+
    Boolean({ fg = clrs.nord9 }),
    Character({ fg = C.bg24 }),
    Comment({ fg = clrs.nord3_bright.sa(10), gui = spec.italicize_comments }),
    Conditional({ fg = clrs.nord9 }),
    Constant({ fg = clrs.nord4 }),
    Define({ fg = clrs.nord9 }),
    Delimiter({ fg = C.bg23.da(20) }),
    Exception({ fg = clrs.nord9 }),
    Float({ fg = C.bg25 }),
    Function({ fg = clrs.nord8 }),
    Identifier({ fg = clrs.nord4, gui = "NONE" }),
    Include({ fg = clrs.nord9 }),
    Keyword({ fg = clrs.nord9 }),
    Label({ fg = clrs.nord9 }),
    Number({ fg = C.bg25 }),
    Operator({ fg = clrs.nord9, gui = "NONE" }),
    PreProc({ fg = clrs.nord9, gui = "NONE" }),
    Repeat({ fg = clrs.nord9 }),
    Special({ fg = clrs.nord4 }),
    SpecialChar({ fg = C.bg23 }),
    SpecialComment({ fg = clrs.nord8, gui = spec.italicize_comments }),
    Statement({ fg = clrs.nord9 }),
    StorageClass({ fg = clrs.nord9 }),
    String({ fg = C.bg24, gui = spec.italic }),
    Structure({ fg = clrs.nord9 }),
    Tag({ fg = clrs.nord4 }),
    Todo({ fg = C.bg23, bg = nil }),
    Type({ fg = clrs.nord9, gui = "NONE" }),
    Typedef({ fg = clrs.nord9 }),
    Macro({ Define }),
    PreCondit({ PreProc }),
    Conceal({ bg = Normal.bg, fg = Normal.fg.ro(10) }),

    -- +-----------+
    -- + Languages +
    -- +-----------+
    DiffAdd({
      fg = C.bg24,
      bg = cfg.theme_uniform_diff_background == 0 and C.bg0 or C.bg2,
      gui = spec.inverse,
    }),
    DiffChange({
      fg = C.bg23,
      bg = cfg.theme_uniform_diff_background == 0 and C.bg0 or C.bg2,
      gui = spec.inverse,
    }),
    DiffDelete({
      fg = C.bg21,
      bg = cfg.theme_uniform_diff_background == 0 and C.bg0 or C.bg2,
      gui = spec.inverse,
    }),
    DiffText({
      fg = clrs.nord9,
      bg = cfg.theme_uniform_diff_background == 0 and C.bg0 or C.bg2,
      gui = spec.inverse,
    }),

    DiffBase({ fg = C.transarent, bg = C.bg_dark }), -- diff mode: Changed text within a changed line |diff.txt|

    --
    --     DiffAdd({ fg = C.transarent, bg = C.bg_green }), -- diff mode: Added line |diff.txt|
    --     DiffChange({ fg = C.transarent, bg = C.bg_yellow }), -- diff mode: Changed line |diff.txt|
    --     DiffDelete({ fg = C.transarent, bg = bg_red }), -- diff mode: Deleted line |diff.txt|
    --     DiffText({ fg = C.transarent, bg = bg_blue }), -- diff mode: Changed text within a changed line |diff.txt|
    --     DiffBase({ fg = C.transarent, bg = bg_dark }), -- diff mode: Changed text within a changed line |diff.txt|
    --

    DiagnosticWarn({ fg = C.bg23 }),
    DiagnosticError({ fg = C.bg21 }),
    DiagnosticInfo({ fg = clrs.nord8 }),
    DiagnosticHint({ fg = C.bg20 }),

    DiagnosticVirtualTextWarn({ fg = DiagnosticWarn.fg.da(20), gui = spec.italic }),
    DiagnosticVirtualTextError({
      fg = DiagnosticError.fg.de(20).li(10),
      gui = spec.italic,
    }),
    DiagnosticVirtualTextInfo({
      fg = DiagnosticInfo.fg.de(20).da(10),
      gui = spec.italic,
    }),
    DiagnosticVirtualTextHint({
      fg = DiagnosticHint.fg.de(20).li(10),
      gui = spec.italic,
    }),

    VirtColumn({ Whitespace }), -- FIXME: used with virt-column.nvim

    sym("@keyword.function")({ fg = C.bg22 }),
    sym("@keyword.return")({ fg = C.bg20.sa(10), gui = spec.bold }),
    sym("@keyword")({ fg = clrs.nord9 }),
    sym("@field")({ fg = clrs.nord7 }),
    sym("@function.builtin")({ fg = C.bg23 }),
    sym("@punctuation.bracket")({ fg = C.bg25.da(10) }),
    sym("@constructor")({ fg = C.bg25.da(10) }),
    sym("@puctuation.delimiter")({ fg = C.bg23 }),
    sym("@operator")({ fg = C.bg23.da(10) }),
    sym("@variable")({ fg = C.bg21 }),
    sym("@function")({ fg = clrs.nord8 }),
    sym("@property")({ fg = clrs.nord8 }),
    sym("@boolean")({ fg = Boolean.fg, gui = spec.italic }),
    sym("@number")({ fg = Boolean.fg, gui = spec.italic }),
    sym("@constant")({ fg = clrs.nord8, gui = spec.bold }),
    sym("@symbol")({ fg = clrs.nord8, gui = spec.italic }),

    -- highlight WARN/FIXME/TODO/NOTE/REF: comments
    sym("@comment.fix")({ bg = C.red, fg = bg_dark, gui = "bold,underline" }),
    sym("@comment.warn")({ fg = C.orange, gui = "bold" }),
    sym("@comment.note")({ fg = teal, gui = "italic" }),
    sym("@comment.todo")({ fg = dark_orange, gui = "bold" }),
    sym("@comment.ref")({ fg = bright_blue, bg = bg_dark, gui = "italic" }),
    sym("@text.danger")({ sym("@comment.fix") }),
    sym("@text.warning")({ sym("@comment.warn") }),
    sym("@text.todo")({ sym("@comment.todo") }),
    sym("@text.note")({ sym("@comment.note") }),
    sym("@text.ref")({ sym("@comment.ref") }),

    sym("@text.diff.add")({ DiffAdd }),
    sym("@text.diff.change")({ DiffChange }),
    sym("@text.diff.delete")({ DiffDelete }),
    sym("@text.diff.text")({ DiffText }),
    sym("@text.diff.base")({ DiffBase }),

    -- [ PLUGINS ] -----------------------------------------------------
    TmuxPopupNormal({ bg = "#3d494f" }),

    VirtColumn({ Whitespace }), -- FIXME: used with virt-column.nvim

    ---- :help nvim-cmp -------------------------------------------
    -- https://github.com/hrsh7th/nvim-cmp#highlights
    -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/types/lsp.lua#L108

    CmpItemKind({ Special }),
    CmpItemAttr({ Comment }),
    -- CmpItemMenu({ NonText }),
    -- CmpItemAbbrMatch({ PmenuSel, gui = "underline", sp = C.purple }),
    -- CmpItemAbbrMatchFuzzy({ fg = fg, gui = "italic" }),
    CmpItemAbbrDeprecated({ fg = C.grey1, gui = "strikethrough" }),

    CmpDocumentation({ fg = C.fg, bg = C.bg1 }),
    CmpDocumentationBorder({ fg = C.fg, bg = C.bg1 }),

    CmpItemAbbr({ fg = C.fg }),
    CmpItemAbbrMatch({ fg = C.cyan, gui = "bold,italic" }),
    CmpItemAbbrMatchFuzzy({ fg = C.yellow }),
    CmpItemMenu({ NonText, gui = "italic" }),

    CmpItemKind({ fg = C.blue }),
    CmpItemKindText({ fg = C.fg }),
    CmpItemKindMethod({ fg = C.blue }),
    CmpItemKindFunction({ CmpItemKindMethod }),
    CmpItemKindConstructor({ fg = C.cyan }),
    CmpItemKindField({ fg = C.fg }),
    CmpItemKindVariable({ fg = C.red }),
    CmpItemKindClass({ fg = C.yellow }),
    CmpItemKindInterface({ CmpItemKindClass }),
    -- CmpItemKindModule({ Include }),
    CmpItemKindProperty({ fg = C.red }),
    -- CmpItemKindUnit({ Constant }),
    CmpItemKindValue({ fg = C.orange }),
    -- CmpItemKindEnum({ Type }),
    CmpItemKindKeyword({ fg = C.purple }),
    CmpItemKindSnippet({ fg = C.green }),
    -- CmpItemKindVColor({}),
    -- CmpItemKindFile({ Dictionary }),
    -- CmpItemKindReference({ PreProc }),
    -- CmpItemKindFolder({}),
    -- CmpItemKindEnumMember({}),
    CmpItemKindConstant({ fg = C.green }),
    -- CmpItemKindStruct({ Type }),
    -- CmpItemKindEvent({ Variable }),
    -- CmpItemKindOperator({ Operator }),
    -- CmpItemKindTypeParameter({ Type }),

    CmpBorderedWindow_Normal({ Normal, bg = C.bg1 }),
    CmpBorderedWindow_FloatBorder({ Normal, fg = C.bg1, bg = C.bg1 }),
    CmpBorderedWindow_CursorLine({ Visual, bg = C.bg1 }),

    ---- :help luasnip ---------------------------------------------------------

    -- Luasnip*Node{Active,Passive,SnippetPassive}

    SimpleF({ fg = C.magenta, bg = C.bg_dark, gui = "bold,underline" }),

    ---- :help indent-blankline ------------------------------------------------

    IndentBlanklineChar({ fg = C.bg2, bg = C.transarent }),
    IndentBlanklineContextChar({ fg = teal.darken(35), bg = C.transarent }),
    IndentBlanklineContextStart({ sp = teal.darken(35), bg = C.transarent, gui = "underline" }),

    ---- :help mini.indentscope ------------------------------------------------
    MiniIndentscopeSymbol({ fg = teal, bg = C.transarent }),

    ---- :help mini.jump.txt / mini.jump2d.txt  --------------------------------

    MiniJump({ fg = C.magenta, bg = C.bg_dark, gui = "bold,underline" }),
    MiniJump2dSpot({ fg = white, bg = C.bg_dark, gui = "bold" }),

    ---- :help leap.txt --------------------------------------------------------

    LeapBackdrop({ fg = "#707070" }),
    LeapLabelPrimary({ bg = C.transarent, fg = "#ccff88", gui = "italic" }),
    LeapLabelSecondary({ bg = C.transarent, fg = "#99ccff" }),
    LeapLabelSelected({ bg = C.transarent, fg = "Magenta" }),

    ---- :help tabline ---------------------------------------------------------

    -- TabLine({ fg = C.grey2, bg = C.bg3 }), -- tab pages line, not active tab page label
    -- TabLineFill({ fg = C.grey1, bg = C.bg1 }), -- tab pages line, where there are no labels
    -- TabLineSel({ fg = C.bg0, bg = C.green }), -- tab pages line, active tab page label

    ---- megaline -- :help statusline ------------------------------------------

    StatusLine({ fg = C.grey1, bg = C.bg1 }), -- status line of current window
    StatusLineNC({ fg = C.grey1, bg = C.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    StInactive({ fg = C.bg_dark.lighten(20), bg = C.bg_dark, gui = "italic" }),
    StModeNormal({ bg = C.bg1, fg = bg5, gui = C.transarent }),
    StModeInsert({ bg = C.bg1, fg = C.green, gui = "bold" }),
    StModeVisual({ bg = C.bg1, fg = C.magenta, gui = "bold" }),
    StModeReplace({ bg = C.bg1, fg = dark_red, gui = "bold" }),
    StModeCommand({ bg = C.bg1, fg = C.green, gui = "bold" }),
    StModeTermNormal({ StModeNormal }),
    StModeTermInsert({ bg = C.green, fg = PanelBackground.bg, gui = "underline", sp = C.green }),
    StMetadata({ Comment, bg = C.bg1 }),
    StMetadataPrefix({ Comment, bg = C.bg1, gui = C.transarent }),
    StIndicator({ fg = dark_blue, bg = C.bg1 }),
    StModified({ fg = pale_red, bg = C.bg1, gui = "bold,italic" }),
    StGitSymbol({ fg = light_red, bg = C.bg1 }),
    StGitBranch({ fg = C.blue, bg = C.bg1 }),
    StGitSigns({ fg = dark_blue, bg = C.bg1 }),
    StGitSignsAdd({ GreenSign, bg = C.bg1 }),
    StGitSignsDelete({ RedSign, bg = C.bg1 }),
    StGitSignsChange({ OrangeSign, bg = C.bg1 }),
    StNumber({ fg = C.purple, bg = C.bg1 }),
    StCount({ fg = C.bg0, bg = C.blue, gui = "bold" }),
    StPrefix({ fg = C.fg, bg = C.bg2 }),
    StDirectory({ bg = C.bg1, fg = grey0, gui = "italic" }),
    StParentDirectory({ bg = C.bg1, fg = C.blue, gui = "" }),
    StFilename({ bg = C.bg1, fg = C.fg, gui = "bold" }),
    StFilenameInactive({ fg = light_grey, bg = C.bg1, gui = "italic,bold" }),
    StIdentifier({ fg = C.blue, bg = C.bg1 }),
    StTitle({ bg = C.bg1, fg = C.grey2, gui = "bold" }),
    StComment({ Comment, bg = C.bg1 }),
    StClient({ bg = C.bg1, fg = C.fg, gui = "bold" }),
    StError({ fg = pale_red, bg = C.bg1 }),
    StWarn({ fg = C.orange, bg = C.bg1 }),
    StInfo({ fg = C.cyan, bg = C.bg1, gui = "bold" }),
    StHint({ fg = bg5, bg = C.bg1 }),
    ---- hydra
    --HydraRedSt({ HydraRed, gui = "reverse" }),
    --HydraBlueSt({ HydraBlue, gui = "reverse" }),
    --HydraAmaranthSt({ HydraAmaranth, gui = "reverse" }),
    --HydraTealSt({ HydraTeal, gui = "reverse" }),
    --HydraPinkSt({ HydraPink, gui = "reverse" }),

    ---- :help winbar  ---------------------------------------------------------

    WinBar({ StatusLine, gui = "italic" }),
    WinBarNC({ StInactive }),

    ---- :help ts-rainbow  -----------------------------------------------------

    rainbowcol1({ fg = C.red }),
    rainbowcol2({ fg = C.yellow }),
    rainbowcol3({ fg = C.green }),
    rainbowcol4({ fg = C.blue }),
    rainbowcol5({ fg = C.cyan }),
    rainbowcol6({ fg = C.magenta }),
    rainbowcol7({ fg = C.purple }),

    ---- :help telescope -------------------------------------------------------

    TelescopeNormal({ bg = C.bg3.darken(25) }),
    TelescopeBorder({ fg = C.bg0, bg = C.bg3.darken(25) }),
    TelescopeMatching({ Title }),
    TelescopeTitle({ Normal, gui = "bold" }),

    TelescopePreviewTitle({ fg = C.bg0, bg = dark_green, gui = "italic" }),
    -- darkens the whole preview panel + my faux-no-border
    TelescopePreviewBorder({ bg = PanelBackground.bg, fg = C.transarent }),
    TelescopePreviewNormal({ bg = PanelBackground.bg, fg = C.transarent }),

    TelescopePrompt({ bg = C.bg2.darken(10) }),
    TelescopePromptPrefix({ Statement, bg = C.bg2.darken(10) }),
    TelescopePromptBorder({ fg = C.bg2.darken(10), bg = C.bg2.darken(10) }),
    TelescopePromptNormal({ fg = C.fg, bg = C.bg2.darken(10) }),
    TelescopePromptTitle({ fg = C.bg0, bg = dark_red }),

    TelescopeSelection({ bg = C.bg3, gui = "bold,italic" }),
    TelescopeSelectionCaret({ fg = C.fg, bg = C.bg3 }),
    TelescopeResults({ bg = C.transarent }),
    TelescopeResultsTitle({ fg = C.bg0, bg = C.fg, gui = "bold" }),

    ---- :help fzf-lua ---------------------------------------------------------

    FzfLuaNormal({ TelescopePreviewNormal }),
    FzfLuaBorder({ TelescopeBorder }),
    FzfLuaCursor({ TelescopeNormal }),
    FzfLuaCursorLine({ TelescopeNormal }),
    FzfLuaCursorLineNr({ TelescopeNormal }),
    FzfLuaSearch({ TelescopePrompt }),
    FzfLuaTitle({ fg = C.bg0, bg = C.bg_cyan, gui = "italic" }),
    FzfLuaScrollBorderEmpty({}),
    FzfLuaScrollBorderFull({}),
    FzfLuaScrollFloatEmpty({}),
    FzfLuaScrollFloatFull({}),
    FzfLuaHelpNormal({ TelescopePreviewNormal }),
    FzfLuaHelpBorder({ TelescopePreviewBorder }),

    ---- :help: trouble.txt ----------------------------------------------------

    TroubleNormal({ PanelBackground }),
    TroubleText({ PanelBackground }),
    TroubleIndent({ PanelVertSplit }),
    TroubleFoldIcon({ fg = C.yellow, gui = "bold" }),
    TroubleLocation({ fg = Comment.fg }),
    TroublePreview({ bg = bg_visual, gui = "bold,italic,underline" }),

    ---- :help: dap ------------------------------------------------------------

    DapBreakpoint({ fg = light_red }),
    DapStopped({ fg = C.green }),

    ---- :help: fidget.txt -----------------------------------------------------

    FidgetTitle({ fg = C.orange }),
    FidgetTask({ fg = C.grey2, bg = C.bg1.darken(10) }),

    ---- :help: notifier.nvim  -------------------------------------------------

    NotifierTitle({ fg = C.orange }),
    NotifierContent({ NormalFloat }),
    NotifierContentDim({ fg = C.grey1, bg = C.bg1.darken(10), gui = "italic" }),

    ---- :help: bqf.txt --------------------------------------------------------

    BqfPreviewFloat({ PanelBackground }), -- or WinSeparator
    BqfPreviewBorder({ PanelBackground, fg = bg_blue }), -- or WinSeparator
    -- hi BqfPreviewBorder guifg=#50a14f ctermfg=71
    -- hi link BqfPreviewRange Search

    qfPosition({ Todo }),

    ---- :help neo-tree.txt ----------------------------------------------------

    NeoTreeIndentMarker({ Comment }),
    NeoTreeNormal({ PanelBackground }),
    NeoTreeNormalNC({ PanelBackground }),
    NeoTreeRootName({ fg = C.cyan, gui = "bold,italic,underline" }),
    NeoTreeFileNameOpened({ bg = C.fg, fg = C.fg, gui = "underline,bold" }),
    NeoTreeCursorLine({ Visual }),
    NeoTreeStatusLine({ PanelSt }),
    NeoTreeTitleBar({ fg = C.red, bg = C.bg_dark }),
    NeoTreeFloatBorder({ PanelBackground, fg = C.bg0 }),
    NeoTreeFloatTitle({ fg = Comment.fg, bg = C.bg2 }),
    NeoTreeTabActive({ bg = PanelBackground.bg, gui = "bold" }),
    NeoTreeTabInactive({ bg = PanelBackground.bg.darken(15), fg = Comment.fg }),
    NeoTreeTabSeparatorInactive({ bg = PanelBackground.bg.darken(15), fg = PanelBackground.bg }),
    NeoTreeTabSeparatorActive({ PanelBackground, fg = Comment.fg }),

    ---- :help git-signs.txt ---------------------------------------------------

    GitSignsAdd({ GreenSign, bg = C.transarent }),
    GitSignsDelete({ RedSign, bg = C.transarent }),
    GitSignsChange({ OrangeSign, bg = C.transarent }),

    ---- :help notify ----------------------------------------------------------

    NotifyERRORBorder({ NotifyFloat }),
    NotifyWARNBorder({ NotifyFloat }),
    NotifyINFOBorder({ NotifyFloat }),
    NotifyDEBUGBorder({ NotifyFloat }),
    NotifyERRORBody({ NotifyFloat, fg = C.grey2 }),
    NotifyWARNBody({ NotifyFloat, fg = C.grey2 }),
    NotifyINFOBody({ NotifyFloat, fg = C.grey2 }),
    NotifyDEBUGBody({ NotifyFloat, fg = C.grey2 }),
    NotifyERRORIcon({ fg = C.red }),
    NotifyWARNIcon({ fg = C.orange }),
    NotifyINFOIcon({ fg = C.green }),
    NotifyDEBUGIcon({ fg = C.grey2 }),
    NotifyERRORTitle({ fg = C.red }),
    NotifyWARNTitle({ fg = C.orange }),
    NotifyINFOTitle({ fg = C.green }),
    NotifyDEBUGTitle({ fg = C.grey2 }),

    ---- :help health ----------------------------

    healthError({ C.red }),
    healthSuccess({ C.green }),
    healthWarning({ C.yellow }),

    ---- :help headlines.txt -------------------------------------------

    Headline1({ fg = C.green, bg = C.bg_green, gui = "bold,italic,underline" }),
    Headline2({ fg = C.yellow, bg = C.bg_yellow, gui = "bold,italic" }),
    Headline3({ fg = C.red, bg = C.bg1, gui = "bold" }),
    Headline4({ fg = C.purple, bg = C.bg1, gui = "bold" }),
    Headline5({ fg = C.blue, bg = C.bg0, gui = "italic" }),
    Headline6({ fg = C.orange, bg = C.bg0, gui = C.transarent }),
    Dash({ fg = C.bg2, gui = "bold" }),
    sym("@dash")({ Dash }),
    CodeBlock({ bg = C.bg1 }),
  }
end)

return theme
