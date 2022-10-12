---@diagnostic disable: undefined-global

-- # REFS:
-- - https://github.com/svitax/fennec-gruvbox.nvim/blob/master/lua/lush_theme/fennec-gruvbox.lua
-- - https://github.com/mcchrish/zenbones.nvim/blob/main/lua/zenbones/specs/dark.lua
-- FIXME:

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

local C = mega.colors

local bg_dark = C.bg_dark
local bg0 = C.bg0
local bg1 = C.bg1
local bg2 = C.bg2
local bg3 = C.bg3
local bg4 = C.bg4
local bg5 = C.bg5
local bg_visual = C.bg_visual
local bg_red = C.bg_red
local bg_green = C.bg_green
local bg_blue = C.bg_blue
local bg_yellow = C.bg_yellow
local bg_purple = C.bg_purple
local dark_grey = C.dark_grey
local light_grey = C.light_grey
local grey0 = C.grey0
local grey1 = C.grey1
local grey2 = C.grey2
local fg = C.fg
local red = C.red
local dark_red = C.dark_red
local dark_blue = C.dark_blue
local pale_red = C.pale_red
local light_red = C.light_red
local orange = C.orange
local dark_orange = C.dark_orange
local bright_yellow = C.bright_yellow
local bright_blue = C.bright_blue
local bright_blue_alt = C.bright_blue_alt
local yellow = C.yellow
local green = C.green
local bright_green = C.bright_green
local dark_green = C.dark_green
local cyan = C.cyan
local teal = C.teal
local aqua = C.aqua
local blue = C.blue
local purple = C.purple
local brown = C.brown
local magenta = C.magenta
local white = C.white

local tc = {
  black = bg0,
  red = red,
  yellow = yellow,
  green = green,
  cyan = aqua,
  blue = blue,
  purple = purple,
  white = fg,
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

local lushify_custom_ts = function()
  -- highlight WARN/FIXME/TODO/NOTE/REF: comments

  -- TSCommentRef({ fg = red, gui = "underline" }),
  -- TSCommentFix({ bg = dark_red }),
  -- TSCommentTodo({ bg = dark_orange }),
  -- TSCommentNote({ commentTSNote }),

  -- NOTE: custom treesitter highlight/queries nodes:
  local hlmap = {}

  hlmap["@comment.fix"] = { bg = red, fg = bg_dark, gui = "bold,underline" }
  hlmap["@comment.todo"] = { fg = dark_orange, gui = "bold" }
  hlmap["@comment.warn"] = { fg = orange, gui = "bold" }
  hlmap["@comment.note"] = { fg = teal, gui = "italic" }
  hlmap["@comment.ref"] = { fg = bright_blue, gui = "italic" }

  -- hlmap["@comment.hack"] = { bg = red, fg = bg_dark, gui = "bold" }
  -- hlmap["@comment.user"] = { bg = red, fg = bg_dark, gui = "bold" }
  -- hlmap["@comment.issue"] = { bg = red, fg = bg_dark, gui = "bold" }
  -- hlmap["@comment.test"] = { bg = red, fg = bg_dark, gui = "bold" }

  for group, colors in pairs(hlmap) do
    vim.cmd(
      string.format(
        "highlight %s guifg=%s guibg=%s guisp=%s gui=%s blend=%s",
        group,
        colors.fg or "none",
        colors.bg or "none",
        colors.sp or "none",
        colors.style or colors.gui or "none",
        colors.blend or 0
      )
    )
  end
end

return lush(function()
  -- lushify_custom_ts()

  return {
    ---- :help highlight-default -------------------------------

    Background({ bg = bg0 }),
    BackgroundLight({ bg = bg1 }),
    BackgroundExtraLight({ bg = bg2 }),
    Visual({ fg = "NONE", bg = bg_visual }), -- Visual mode selection
    VisualNOS({ fg = "NONE", bg = bg_visual }), -- Visual mode selection when vim is "Not Owning the Selection".
    WarningMsg({ fg = yellow, bg = "NONE" }), -- warning messages
    Whitespace({ fg = bg3, bg = "NONE" }), -- "nbsp", "space", "tab" and "trail" in 'listchars'
    ColorColumn({ fg = "NONE", bg = bg2 }), -- used for the columns set with 'colorcolumn'
    VirtColumn({ fg = bg2 }), -- used with virt-column.nvim
    Conceal({ fg = grey1, bg = "NONE" }), -- placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor({ fg = "NONE", bg = "NONE", gui = "reverse" }), -- character under the cursor
    lCursor({ Cursor }), -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    iCursor({ Cursor }),
    vCursor({ Cursor }),
    CursorIM({ Cursor }), -- like Cursor, but used when in IME mode |CursorIM|
    CursorColumn({ fg = "NONE", bg = bg1 }), -- Screen-column at the cursor, when 'cursorcolumn' is set.
    CursorLine({ fg = "NONE", bg = bg1 }), -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR fg) is not set.
    CursorWord({ fg = "NONE", bg = "NONE", gui = "bold,underline" }),
    CursorLineNr({ fg = brown, bg = bg2, gui = "bold,italic" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    CursorLineNrNC({ fg = "NONE", bg = bg1, gui = "" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    CursorLineSign({ CursorLineNr }),
    Directory({ fg = green, bg = "NONE" }), -- directory names (and other special names in listings)

    Comment({ fg = grey1, bg = "NONE", gui = "italic" }),
    TermCursor({ Cursor }), -- cursor in a focused terminal
    TermCursorNC({ Cursor }), -- cursor in an unfocused terminal
    ErrorMsg({ fg = red, bg = "NONE", gui = "bold,underline" }), -- error messages on the command line
    VertSplit({ fg = bg4, bg = "NONE" }), -- the column separating vertically split windows
    WinSeparator({ VertSplit, fg = bg2, gui = "bold" }),
    Folded({ Comment, gui = "bold,italic" }), -- line used for closed folds
    FoldColumn({ fg = grey1, bg = bg1 }), -- 'foldcolumn'
    -- Neither the sign column or end of buffer highlights require an explicit background
    -- they should both just use the background that is in the window they are in.
    -- if either are specified this can lead to issues when a winhighlight is set
    SignColumn({ fg = fg, bg = "NONE" }), -- column where |signs| are displayed
    EndOfBuffer({ fg = bg2, bg = "NONE" }), -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    IncSearch({ fg = bg0, bg = red }), -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    CurSearch({ IncSearch }),
    Search({ fg = bg0, bg = green, gui = "italic,bold" }), -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    Substitute({ fg = bg0, bg = yellow, guid = "strikethrough,bold" }), -- |:substitute| replacement text highlighting
    Beacon({ bg = blue }),
    LineNr({ fg = grey0, bg = "NONE" }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    MatchParen({ fg = "NONE", bg = bg4 }), -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg({ fg = fg, bg = "NONE", gui = "bold" }), -- 'showmode' message (e.g., "-- INSERT -- ")
    MsgArea({ bg = bg0 }), -- Area for messages and cmdline
    MsgSeparator({ bg = bg0 }), -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg({ fg = yellow, bg = "NONE", gui = "bold" }), -- |more-prompt|
    FoldMoreMsg({ Comment, gui = "italic,bold" }), -- |more-prompt|
    NonText({ fg = bg4, bg = "NONE" }), -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Normal({ fg = fg, bg = "NONE" }), -- normal text
    -- NormalNC     { }, -- normal text in non-current windows
    Pmenu({ fg = fg, bg = bg2 }), -- Popup menu: normal item.
    PmenuSel({ fg = green, bg = bg3 }), -- Popup menu: selected item.
    PmenuSbar({ fg = "NONE", bg = bg2 }), -- Popup menu: scrollbar.
    PmenuThumb({ fg = "NONE", bg = grey1 }), -- Popup menu: Thumb of the scrollbar.
    WildMenu({ PmenuSel }), -- current match in 'wildmenu' completion
    NormalFloat({ Pmenu }), -- Normal text in floating windows.
    FloatBorder({ Pmenu, fg = bg_dark }),
    NotifyFloat({ bg = bg2.darken(10), fg = bg2.darken(10) }),
    FloatTitle({ Visual }),
    Question({ fg = yellow, bg = "NONE" }), -- |hit-enter| prompt and yes/no questions
    -- QuickFixLine({ fg = "NONE", bg = PmenuSbar.bg, gui = "bold,italic" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- QuickFixLine({ fg = "NONE", bg = bg_visual.darken(20), gui = "bold,italic" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- QuickFixLine({ fg = purple, bg = "NONE", gui = "bold" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    SpecialKey({ fg = bg3, bg = "NONE" }), -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.

    ---- :help spell -------------------------------------------

    SpellBad({ fg = red, bg = "NONE", gui = "underdouble", sp = red }),
    SpellCap({ fg = blue, bg = "NONE", gui = "undercurl", sp = blue }),
    SpellLocal({ fg = cyan, bg = "NONE", gui = "undercurl", sp = cyan }),
    SpellRare({ fg = purple, bg = "NONE", gui = "undercurl", sp = purple }), -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.

    ---- :help toggleterm  -----------------------------------------------------

    DarkenedPanel({ bg = bg1 }),
    DarkenedStatusline({ bg = bg1 }),
    DarkenedStatuslineNC({ gui = "italic", bg = bg1 }),

    ---- sidebar  -----------------------------------------------------

    PanelBackground({ fg = fg.darken(10), bg = bg0.darken(8) }),
    PanelHeading({ PanelBackground, gui = "bold" }),
    PanelVertSplit({ VertSplit, bg = bg0.darken(8) }),
    PanelStNC({ PanelVertSplit }),
    PanelSt({ bg = bg_blue.darken(20) }),

    -- { "PanelBackground", { background = bg_color } },
    -- { "PanelHeading", { background = bg_color, bold = true } },
    -- { "PanelVertSplit", { foreground = split_color, background = bg_color } },
    -- { "PanelStNC", { background = bg_color, foreground = split_color } },
    -- { "PanelSt", { background = st_color } },

    -- These groups are not listed as default vim groups,
    -- but they are defacto standard group names for syntax highlighting.
    -- commented out groups should chain up to their "preferred" group by
    -- default,
    -- Uncomment and edit if you want more specific syntax highlighting.
    Boolean({ fg = purple, bg = "NONE" }),
    Number({ fg = purple, bg = "NONE" }),
    Float({ fg = purple, bg = "NONE" }),
    PreProc({ fg = purple, bg = "NONE", gui = "italic" }),
    PreCondit({ fg = purple, bg = "NONE", gui = "italic" }),
    Include({ fg = purple, bg = "NONE", gui = "italic" }),
    Define({ fg = purple, bg = "NONE", gui = "italic" }),
    Conditional({ fg = red, bg = "NONE", gui = "italic" }),
    Repeat({ fg = red, bg = "NONE", gui = "italic" }),
    Keyword({ fg = red, bg = "NONE", gui = "italic" }),
    Typedef({ fg = red, bg = "NONE", gui = "italic" }),
    Exception({ fg = red, bg = "NONE", gui = "italic" }),
    Statement({ fg = red, bg = "NONE", gui = "italic" }),
    Error({ fg = red, bg = "NONE" }),
    StorageClass({ fg = orange, bg = "NONE" }),
    Tag({ fg = orange, bg = "NONE" }),
    Label({ fg = orange, bg = "NONE" }),
    Structure({ fg = orange, bg = "NONE" }),
    Operator({ fg = orange, bg = "NONE" }),
    Title({ fg = orange, bg = "NONE", gui = "bold" }),
    Special({ fg = fg.darken(20), bg = "NONE", gui = "bold" }),
    SpecialChar({ fg = yellow, bg = "NONE" }),
    Type({ fg = yellow, bg = "NONE" }),
    Class({ fg = orange }),
    Module({ fg = green, bg = "NONE" }),
    Method({ fg = purple }),
    Function({ fg = green, bg = "NONE" }),
    String({ fg = green, bg = "NONE" }),
    Character({ fg = green, bg = "NONE" }),
    Constant({ fg = aqua, bg = "NONE" }),
    Macro({ fg = aqua, bg = "NONE" }),
    Identifier({ fg = blue, bg = "NONE" }),
    SpecialComment({ fg = grey1, bg = "NONE", gui = "italic" }),
    Todo({ fg = purple, bg = "NONE", gui = "italic" }),
    Delimiter({ fg = fg, bg = "NONE" }),
    Ignore({ fg = grey1, bg = "NONE" }),
    Debug({ fg = orange, bg = "NONE" }), --    debugging statements
    debugPC({ fg = bg0, bg = green }), --    debugging statements
    debugBreakpoint({ fg = bg0, bg = red }), --    debugging statements
    Bold({ gui = "bold" }),
    Italic({ gui = "italic" }),
    Underlined({ fg = "NONE", bg = "NONE", gui = "underline" }),
    CurrentWord({ bg = fg, fg = bg0 }),
    Fg({ fg = fg, bg = "NONE" }),
    Grey({ fg = grey1, bg = "NONE" }),
    Red({ fg = red, bg = "NONE" }),
    Orange({ fg = orange, bg = "NONE" }),
    Yellow({ fg = yellow, bg = "NONE" }),
    Green({ fg = green, bg = "NONE" }),
    Aqua({ fg = aqua, bg = "NONE" }),
    Blue({ fg = blue, bg = "NONE" }),
    Purple({ fg = purple, bg = "NONE" }),
    RedItalic({ fg = red, bg = "NONE", gui = "italic" }),
    OrangeItalic({ fg = orange, bg = "NONE", gui = "italic" }),
    YellowItalic({ fg = yellow, bg = "NONE", gui = "italic" }),
    GreenItalic({ fg = green, bg = "NONE", gui = "italic" }),
    AquaItalic({ fg = cyan, bg = "NONE", gui = "italic" }),
    BlueItalic({ fg = blue, bg = "NONE", gui = "italic" }),
    PurpleItalic({ fg = purple, bg = "NONE", gui = "italic" }),
    PurpleBold({ fg = purple, bg = "NONE", gui = "bold" }),

    RedSign({ fg = red, bg = bg1 }),
    OrangeSign({ fg = orange, bg = bg1 }),
    YellowSign({ fg = yellow, bg = bg1 }),
    GreenSign({ fg = green, bg = bg1 }),
    AquaSign({ fg = cyan, bg = bg1 }),
    BlueSign({ fg = blue, bg = bg1 }),
    PurpleSign({ fg = purple, bg = bg1 }),

    ---- :help diagnostic-highlight ----------------------------

    DiagnosticError({ fg = red, bg = "NONE" }),
    DiagnosticWarn({ fg = orange, bg = "NONE" }),
    DiagnosticInfo({ fg = cyan, bg = "NONE" }),
    DiagnosticHint({ fg = grey2, bg = "NONE" }),

    -- REF: https://github.com/neovim/neovim/pull/15585
    DiagnosticFloatingError({ DiagnosticError }),
    DiagnosticFloatingWarn({ DiagnosticWarn }),
    DiagnosticFloatingInfo({ DiagnosticInfo }),
    DiagnosticFloatingHint({ DiagnosticHint }),

    DiagnosticDefaultError({ DiagnosticError }),
    DiagnosticDefaultWarn({ DiagnosticWarn }),
    DiagnosticDefaultInfo({ DiagnosticInfo }),
    DiagnosticDefaultHint({ DiagnosticHint }),

    DiagnosticVirtualTextError({ DiagnosticError, fg = DiagnosticError.fg.darken(30) }),
    DiagnosticVirtualTextWarn({ DiagnosticWarn, fg = DiagnosticWarn.fg.darken(30) }),
    DiagnosticVirtualTextInfo({ DiagnosticInfo, fg = DiagnosticInfo.fg.darken(40) }),
    DiagnosticVirtualTextHint({ DiagnosticHint, fg = DiagnosticHint.fg.darken(40) }),

    DiagnosticSignError({ DiagnosticError }),
    DiagnosticSignWarn({ DiagnosticWarn }),
    DiagnosticSignInfo({ DiagnosticInfo }),
    DiagnosticSignHint({ DiagnosticHint }),

    DiagnosticSignErrorLine({ DiagnosticError }),
    DiagnosticSignWarnLine({ DiagnosticWarn }),
    DiagnosticSignInfoLine({ DiagnosticInfo }),
    DiagnosticSignHintLine({ DiagnosticHint }),

    DiagnosticSignErrorNumLine({ bg = DiagnosticError.fg }),
    DiagnosticSignWarnNumLine({ bg = DiagnosticWarn.fg }),
    DiagnosticSignInfoNumLine({ bg = DiagnosticInfo.fg }),
    DiagnosticSignHintNumLine({ bg = DiagnosticHint.fg }),

    DiagnosticErrorBorder({ DiagnosticError }),
    DiagnosticWarnBorder({ DiagnosticWarn }),
    DiagnosticInfoBorder({ DiagnosticInfo }),
    DiagnosticHintBorder({ DiagnosticHint }),

    -- affects individual bits of code that are errored:
    DiagnosticUnderlineError({
      fg = "NONE",
      bg = bg_dark,
      sp = DiagnosticError.fg,
      gui = "undercurl,bold",
    }),
    DiagnosticUnderlineWarn({ fg = "NONE", bg = bg_dark, sp = DiagnosticWarn.fg, gui = "undercurl" }),
    DiagnosticUnderlineInfo({ fg = "NONE", bg = bg_dark, sp = DiagnosticInfo.fg, gui = "undercurl" }),
    DiagnosticUnderlineHint({ fg = "NONE", bg = bg_dark, sp = DiagnosticHint.fg, gui = "undercurl" }),

    ---- :help lsp-highlight -----------------------------------

    LspReferenceText({ bg = "NONE", gui = "underline" }),
    LspReferenceRead({ bg = "NONE", gui = "underline" }),
    LspReferenceWrite({ DiagnosticInfo, gui = "underline,bold,italic" }),

    LspCodeLens({ DiagnosticInfo, fg = bg2 }), -- Used to color the virtual text of the codelens,
    LspCodeLensSeparator({ DiagnosticHint }),

    LspInfoBorder({ FloatBorder }),

    ---- :help notify ----------------------------------------------------------

    NotifyERRORBorder({ NotifyFloat }),
    NotifyWARNBorder({ NotifyFloat }),
    NotifyINFOBorder({ NotifyFloat }),
    NotifyDEBUGBorder({ NotifyFloat }),
    NotifyERRORBody({ NotifyFloat, fg = grey2 }),
    NotifyWARNBody({ NotifyFloat, fg = grey2 }),
    NotifyINFOBody({ NotifyFloat, fg = grey2 }),
    NotifyDEBUGBody({ NotifyFloat, fg = grey2 }),
    NotifyERRORIcon({ fg = red }),
    NotifyWARNIcon({ fg = orange }),
    NotifyINFOIcon({ fg = green }),
    NotifyDEBUGIcon({ fg = grey2 }),
    NotifyERRORTitle({ fg = red }),
    NotifyWARNTitle({ fg = orange }),
    NotifyINFOTitle({ fg = green }),
    NotifyDEBUGTitle({ fg = grey2 }),

    ---- :help health ----------------------------

    healthError({ Red }),
    healthSuccess({ Green }),
    healthWarning({ Yellow }),

    ---- :help headlines.txt -------------------------------------------

    Headline1({ fg = green, bg = bg_green, gui = "bold,italic,underline" }),
    Headline2({ fg = yellow, bg = bg_yellow, gui = "bold,italic" }),
    Headline3({ fg = red, bg = bg_red, gui = "bold" }),
    Headline4({ fg = purple, bg = bg1, gui = "bold" }),
    Headline5({ fg = blue, bg = bg0, gui = "italic" }),
    Headline6({ fg = orange, bg = bg0, gui = "NONE" }),
    Dash({ fg = bg2, gui = "bold" }),
    CodeBlock({ bg = bg1 }),

    ---- :help nvim-treesitter-highlights (external plugin) ----

    TSAnnotation({ Purple }),
    TSAttribute({ Purple }),
    TSBoolean({ Purple }),
    TSCharacter({ Yellow }),
    TSConditional({ Red }),
    TSConstBuiltin({ PurpleItalic }),
    TSConstMacro({ Purple }),
    TSConstant({ PurpleItalic }),
    TSConstructor({ Fg }),
    TSEmphasis({ fg = "NONE", bg = "NONE", gui = "italic" }),
    TSException({ Red }),
    TSField({ Green }),
    TSFloat({ Purple }),
    TSFuncBuiltin({ Green }),
    TSFuncMacro({ Green }),
    TSFunction({ Green }),
    TSInclude({ PurpleItalic }),
    TSKeyword({ Red, gui = "bold" }),
    TSKeywordFunction({ Red, gui = "bold,italic" }),
    TSLabel({ Orange }),
    TSMethod({ Green }),
    TSNamespace({ BlueItalic, fg = bright_blue }),
    TSNumber({ Purple }),
    TSOperator({ Orange }),
    TSParameter({ Fg }),
    TSParameterReference({ Fg }),
    TSProperty({ Green }),
    TSPunctBracket({ Fg }),
    TSPunctDelimiter({ Grey }),
    TSPunctSpecial({ Fg }),
    TSRepeat({ Red }),
    TSString({ Yellow }),
    TSStringRegex({ Blue }),
    TSStringEscape({ Purple }),
    TSStrong({ fg = "NONE", bg = "NONE", gui = "bold" }),
    TSStructure({ Orange }),
    TSTag({ Orange }),
    TSTagDelimiter({ Green }),
    TSText({ Green }),
    TSType({ Aqua }),
    TSTypeBuiltin({ BlueItalic }),
    TSUnderline({ fg = "NONE", bg = "NONE", gui = "underline" }),
    TSURI({ fg = blue, bg = "NONE", gui = "underline" }),
    TSVariable({ Fg }),
    TSVariableBuiltin({ PurpleItalic }),
    TSComment({ fg = light_grey, gui = "italic" }),
    TSError({ gui = "undercurl", sp = red }), -- ErrorText

    -- highlight WARN/FIXME/TODO/NOTE/REF: comments

    commentTSDanger({ bg = red, fg = bg_dark, gui = "bold,underline" }),
    commentTSWarning({ fg = orange, gui = "bold" }),
    commentTSNote({ fg = teal, gui = "italic" }),
    commentTSRef({ fg = cyan }),

    TSWarning({ commentTSWarning }),
    TSDanger({ commentTSDanger }),
    TSNote({ commentTSNote }),

    ---- :help treesitter-context ----------------------------------------------

    TreesitterContext({ bg = bg1 }),
    -- ContextBorder = { foreground = dim, background = dimmer },
    -- TreesitterContext = { inherit = 'Normal', background = dimmer },
    TreesitterContextLineNumber({ CursorLineNr, bg = TreesitterContext.bg }),
    TreesitterContextBorder({ fg = bg_dark, bg = TreesitterContext.bg }),

    -- TS: Markdown
    markdownTSPunctSpecial({ Special }),
    markdownTSStringEscape({ SpecialKey }),
    markdownTSTextReference({ Identifier, gui = "underline" }),
    markdownTSEmphasis({ fg = grey1, bg = "NONE", gui = "italic" }),
    markdownTSTitle({ Statement, bg = bg1 }),
    markdownTSLiteral({ Type }),
    markdownTSURI({ TSURI }),
    markdownCode({ fg = grey1, bg = bg1 }),
    markdownLinkText({ markdownTSTextReference }),

    ---- :help gitcommit -------------------------------------------

    -- M.highlight("gitcommitComment", { fg = M.colors.gutter_fg_grey, gui = "italic,bold" })
    -- M.highlight("gitcommitUnmerged", { fg = M.colors.green })
    -- M.highlight("gitcommitOnBranch", {})
    -- M.highlight("gitcommitBranch", { fg = M.colors.purple })
    -- M.highlight("gitcommitDiscardedType", { fg = M.colors.red })
    -- M.highlight("gitcommitSelectedType", { fg = M.colors.green })
    -- M.highlight("gitcommitHeader", {})
    -- M.highlight("gitcommitUntrackedFile", { fg = M.colors.cyan })
    -- M.highlight("gitcommitDiscardedFile", { fg = M.colors.red })
    -- M.highlight("gitcommitSelectedFile", { fg = M.colors.green })
    -- M.highlight("gitcommitUnmergedFile", { fg = M.colors.yellow })
    -- M.highlight("gitcommitFile", {})
    -- M.highlight("gitcommitSummary", { fg = M.colors.white })
    -- M.highlight("gitcommitOverflow", { fg = M.colors.red })
    -- M.link("gitcommitUntracked", "gitcommitComment")
    -- M.link("gitcommitDiscarded", "gitcommitComment")
    -- M.link("gitcommitSelected", "gitcommitComment")
    -- M.link("gitcommitDiscardedArrow", "gitcommitDiscardedFile")
    -- M.link("gitcommitSelectedArrow", "gitcommitSelectedFile")
    -- M.link("gitcommitUnmergedArrow", "gitcommitUnmergedFile")

    ---- :yaml -----------------------------------------------------------------

    yamlTodo({ Todo }),
    yamlComment({ Comment }),

    yamlDocumentStart({ PreProc }),
    yamlDocumentEnd({ PreProc }),

    yamlDirectiveName({ Keyword }),

    yamlTAGDirective({ yamlDirectiveName }),
    yamlTagHandle({ String }),
    yamlTagPrefix({ String }),

    yamlYAMLDirective({ yamlDirectiveName }),
    yamlReservedDirective({ Error }),
    yamlYAMLVersion({ Number }),

    yamlString({ String }),
    yamlFlowString({ yamlString }),
    yamlFlowStringDelimiter({ yamlString }),
    yamlEscape({ SpecialChar }),
    yamlSingleEscape({ SpecialChar }),

    yamlBlockCollectionItemStart({ Label }),
    yamlBlockMappingKey({ Identifier }),
    yamlBlockMappingMerge({ Special }),

    yamlFlowMappingKey({ Identifier }),
    yamlFlowMappingMerge({ Special }),

    yamlMappingKeyStart({ Special }),
    yamlFlowIndicator({ Special }),
    yamlKeyValueDelimiter({ Special }),

    yamlConstant({ Constant }),

    yamlNull({ yamlConstant }),
    yamlBool({ yamlConstant }),

    yamlAnchor({ Type }),
    yamlAlias({ Type }),
    yamlNodeTag({ Type }),

    yamlInteger({ Number }),
    yamlFloat({ Float }),
    yamlTimestamp({ Number }),

    ---- :help :diff -------------------------------------------

    diffAdded({ Green }),
    diffChanged({ Blue }),
    diffRemoved({ Red }),
    diffOldFile({ Yellow }),
    diffNewFile({ Orange }),
    diffFile({ Aqua }),
    diffLine({ Grey }),
    diffIndexLine({ Purple }),

    DiffAdd({ fg = "NONE", bg = bg_green }), -- diff mode: Added line |diff.txt|
    DiffChange({ fg = "NONE", bg = bg_yellow }), -- diff mode: Changed line |diff.txt|
    DiffDelete({ fg = "NONE", bg = bg_red }), -- diff mode: Deleted line |diff.txt|
    DiffText({ fg = "NONE", bg = bg_blue }), -- diff mode: Changed text within a changed line |diff.txt|
    DiffBase({ fg = "NONE", bg = bg_dark }), -- diff mode: Changed text within a changed line |diff.txt|

    --- netrw: there's no comprehensive list of highlights... --

    netrwDir({ Green }),
    netrwClassify({ Green }),
    netrwLink({ Grey }),
    netrwSymLink({ Fg }),
    netrwExe({ Yellow }),
    netrwComment({ Grey }),
    netrwList({ Aqua }),
    netrwHelpCmd({ Blue }),
    netrwCmdSep({ Grey }),
    netrwVersion({ Orange }),

    ---- :help elixir -------------------------------------------

    elixirStringDelimiter({ Green }),
    elixirKeyword({ Orange }),
    elixirInterpolation({ Yellow }),
    elixirInterpolationDelimiter({ Yellow }),
    elixirSelf({ Purple }),
    elixirPseudoVariable({ Purple }),
    elixirModuleDefine({ Red, gui = "italic,bold" }),
    elixirBlockDefinition({ RedItalic }),
    elixirDefine({ RedItalic }),
    elixirPrivateDefine({ PurpleItalic }),
    -- elixirPrivateFunctionDeclaration({ Purple }),
    elixirGuard({ RedItalic }),
    elixirPrivateGuard({ RedItalic }),
    elixirProtocolDefine({ RedItalic }),
    elixirImplDefine({ RedItalic }),
    elixirRecordDefine({ RedItalic }),
    elixirPrivateRecordDefine({ RedItalic }),
    elixirMacroDefine({ RedItalic }),
    elixirPrivateMacroDefine({ RedItalic }),
    elixirDelegateDefine({ RedItalic }),
    elixirOverridableDefine({ RedItalic }),
    elixirExceptionDefine({ RedItalic }),
    elixirCallbackDefine({ RedItalic }),
    elixirStructDefine({ RedItalic }),
    elixirExUnitMacro({ RedItalic }),

    ---- :help gitcommit -------------------------------------------

    gitcommitSummary({ Red }),
    gitcommitUntracked({ Grey }),
    gitcommitDiscarded({ Grey }),
    gitcommitSelected({ Grey }),
    gitcommitUnmerged({ Grey }),
    gitcommitOnBranch({ Grey }),
    gitcommitArrow({ Grey }),
    gitcommitFile({ Green }),

    ---- :help help -------------------------------------------

    helpNote({ fg = purple, gui = "bold" }),
    helpHeadline({ fg = red, gui = "bold" }),
    helpHeader({ fg = orange, gui = "bold" }),
    helpURL({ fg = green, gui = "underline" }),
    helpHyperTextEntry({ fg = yellow, gui = "bold" }),
    helpHyperTextJump({ Yellow }),
    helpCommand({ Aqua }),
    helpExample({ Green }),
    helpSpecial({ Blue }),
    helpSectionDelim({ Grey }),

    ---- :help nvim-cmp -------------------------------------------
    -- https://github.com/hrsh7th/nvim-cmp#highlights
    -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/types/lsp.lua#L108

    CmpItemKind({ Special }),
    CmpItemAttr({ Comment }),
    -- CmpItemMenu({ NonText }),
    -- CmpItemAbbrMatch({ PmenuSel, gui = "underline", sp = purple }),
    -- CmpItemAbbrMatchFuzzy({ fg = fg, gui = "italic" }),
    CmpItemAbbrDeprecated({ fg = grey1, gui = "strikethrough" }),

    CmpDocumentation({ fg = fg, bg = bg1 }),
    CmpDocumentationBorder({ fg = fg, bg = bg1 }),

    CmpItemAbbr({ fg = fg }),
    CmpItemAbbrMatch({ fg = cyan, gui = "bold,italic" }),
    CmpItemAbbrMatchFuzzy({ fg = yellow }),
    CmpItemMenu({ NonText, gui = "italic" }),

    CmpItemKind({ fg = blue }),
    CmpItemKindText({ fg = fg }),
    CmpItemKindMethod({ fg = blue }),
    CmpItemKindFunction({ CmpItemKindMethod }),
    CmpItemKindConstructor({ fg = cyan }),
    CmpItemKindField({ fg = fg }),
    CmpItemKindVariable({ fg = red }),
    CmpItemKindClass({ fg = yellow }),
    CmpItemKindInterface({ CmpItemKindClass }),
    -- CmpItemKindModule({ Include }),
    CmpItemKindProperty({ fg = red }),
    -- CmpItemKindUnit({ Constant }),
    CmpItemKindValue({ fg = orange }),
    -- CmpItemKindEnum({ Type }),
    CmpItemKindKeyword({ fg = purple }),
    CmpItemKindSnippet({ fg = green }),
    -- CmpItemKindVColor({}),
    -- CmpItemKindFile({ Dictionary }),
    -- CmpItemKindReference({ PreProc }),
    -- CmpItemKindFolder({}),
    -- CmpItemKindEnumMember({}),
    CmpItemKindConstant({ fg = green }),
    -- CmpItemKindStruct({ Type }),
    -- CmpItemKindEvent({ Variable }),
    -- CmpItemKindOperator({ Operator }),
    -- CmpItemKindTypeParameter({ Type }),

    CmpBorderedWindow_Normal({ Normal, bg = bg1 }),
    CmpBorderedWindow_FloatBorder({ Normal, fg = bg1, bg = bg1 }),
    CmpBorderedWindow_CursorLine({ Visual, bg = bg1 }),

    -- nvim-dap
    -- DebugBreakpoint({ fg = cs.red }),
    -- DebugBreakpointLine({ fg = cs.red, gui = "underline" }),
    -- DebugHighlight({ fg = cs.blue }),
    -- DebugHighlightLine({ fg = cs.purple, gui = "italic" }),
    -- NvimDapVirtualText({ fg = cs.cyan, gui = "italic" }),
    -- nvim-dap-ui
    -- DapUIScope({ bg = cs.blue, fg = cs.bg }),
    -- DapUIType({ fg = cs.blue }),
    -- DapUIDecoration({ fg = cs.blue }),
    -- DapUIThread({ fg = cs.purple }),
    -- DapUIStoppedThread({ bg = cs.purple, fg = cs.bg }),
    -- DapUIFrameName({ fg = cs.fg }),
    -- DapUISource({ fg = cs.purple }),
    -- DapUIBreakpointsPath({ bg = cs.yellow, fg = cs.bg }),
    -- DapUIBreakpointsInfo({ fg = cs.fg }),
    -- DapUIBreakpointsCurrentLine({ fg = cs.yellow, gui = "bold" }),
    -- DapUIBreakpointsLine({ DapUIBreakpointsCurrentLine }),
    -- DapUIWatchesEmpty({ bg = cs.red, fg = cs.bg }),
    -- DapUIWatchesValue({ fg = cs.red }),
    -- DapUIWatchesError({ fg = cs.red }),

    ---- :help luasnip ---------------------------------------------------------

    -- Luasnip*Node{Active,Passive,SnippetPassive}

    SimpleF({ fg = magenta, bg = bg_dark, gui = "bold,underline" }),

    ---- :help indent-blankline ------------------------------------------------

    IndentBlanklineChar({ fg = bg2, bg = "NONE" }),
    IndentBlanklineContextChar({ fg = teal.darken(35), bg = "NONE" }),
    IndentBlanklineContextStart({ sp = teal.darken(35), bg = "NONE", gui = "underline" }),

    ---- :help mini.indentscope ------------------------------------------------
    MiniIndentscopeSymbol({ fg = teal, bg = "NONE" }),

    ---- :help mini.jump.txt / mini.jump2d.txt  --------------------------------

    MiniJump({ fg = magenta, bg = bg_dark, gui = "bold,underline" }),
    MiniJump2dSpot({ fg = white, bg = bg_dark, gui = "bold" }),

    ---- :help tabline ---------------------------------------------------------

    -- TabLine({ fg = grey2, bg = bg3 }), -- tab pages line, not active tab page label
    -- TabLineFill({ fg = grey1, bg = bg1 }), -- tab pages line, where there are no labels
    -- TabLineSel({ fg = bg0, bg = green }), -- tab pages line, active tab page label

    ---- megaline -- :help statusline ------------------------------------------

    StatusLine({ fg = grey1, bg = bg1 }), -- status line of current window
    StatusLineNC({ fg = grey1, bg = bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    StInactive({ fg = bg_dark.lighten(20), bg = bg_dark, gui = "italic" }),
    StModeNormal({ bg = bg1, fg = bg5, gui = "NONE" }),
    StModeInsert({ bg = bg1, fg = green, gui = "bold" }),
    StModeVisual({ bg = bg1, fg = magenta, gui = "bold" }),
    StModeReplace({ bg = bg1, fg = dark_red, gui = "bold" }),
    StModeCommand({ bg = bg1, fg = green, gui = "bold" }),
    StMetadata({ Comment, bg = bg1 }),
    StMetadataPrefix({ Comment, bg = bg1, gui = "NONE" }),
    StIndicator({ fg = dark_blue, bg = bg1 }),
    StModified({ fg = pale_red, bg = bg1, gui = "bold,italic" }),
    StGitSymbol({ fg = light_red, bg = bg1 }),
    StGitBranch({ fg = blue, bg = bg1 }),
    StGitSigns({ fg = dark_blue, bg = bg1 }),
    StGitSignsAdd({ GreenSign, bg = bg1 }),
    StGitSignsDelete({ RedSign, bg = bg1 }),
    StGitSignsChange({ OrangeSign, bg = bg1 }),
    StNumber({ fg = purple, bg = bg1 }),
    StCount({ fg = bg0, bg = blue, gui = "bold" }),
    StPrefix({ fg = fg, bg = bg2 }),
    StDirectory({ bg = bg1, fg = grey0, gui = "italic" }),
    StParentDirectory({ bg = bg1, fg = blue, gui = "" }),
    StFilename({ bg = bg1, fg = fg, gui = "bold" }),
    StFilenameInactive({ fg = light_grey, bg = bg1, gui = "italic,bold" }),
    StIdentifier({ fg = blue, bg = bg1 }),
    StTitle({ bg = bg1, fg = grey2, gui = "bold" }),
    StComment({ Comment, bg = bg1 }),
    StClient({ bg = bg1, fg = fg, gui = "bold" }),
    StError({ fg = pale_red, bg = bg1 }),
    StWarn({ fg = orange, bg = bg1 }),
    StInfo({ fg = cyan, bg = bg1, gui = "bold" }),
    StHint({ fg = bg5, bg = bg1 }),
    ---- hydra
    --HydraRedSt({ HydraRed, gui = "reverse" }),
    --HydraBlueSt({ HydraBlue, gui = "reverse" }),
    --HydraAmaranthSt({ HydraAmaranth, gui = "reverse" }),
    --HydraTealSt({ HydraTeal, gui = "reverse" }),
    --HydraPinkSt({ HydraPink, gui = "reverse" }),

    ---- :help winbar  ---------------------------------------------------------

    WinBar({ fg = bg0, bg = yellow, gui = "italic" }),
    WinBarNC({ fg = fg, bg = bg_yellow, gui = "italic" }),

    ---- :help ts-rainbow  -----------------------------------------------------

    rainbowcol1({ fg = red }),
    rainbowcol2({ fg = yellow }),
    rainbowcol3({ fg = green }),
    rainbowcol4({ fg = blue }),
    rainbowcol5({ fg = cyan }),
    rainbowcol6({ fg = magenta }),
    rainbowcol7({ fg = purple }),

    ---- :help telescope -------------------------------------------------------

    TelescopeNormal({ bg = bg3.darken(25) }),
    TelescopeBorder({ fg = bg0, bg = bg3.darken(25) }),
    TelescopeMatching({ Title }),
    TelescopeTitle({ Normal, gui = "bold" }),

    TelescopePreviewTitle({ fg = bg0, bg = dark_green, gui = "italic" }),
    -- darkens the whole preview panel + my faux-no-border
    TelescopePreviewBorder({ bg = PanelBackground.bg, fg = "NONE" }),
    TelescopePreviewNormal({ bg = PanelBackground.bg, fg = "NONE" }),

    TelescopePrompt({ bg = bg2.darken(10) }),
    TelescopePromptPrefix({ Statement, bg = bg2.darken(10) }),
    TelescopePromptBorder({ fg = bg2.darken(10), bg = bg2.darken(10) }),
    TelescopePromptNormal({ fg = fg, bg = bg2.darken(10) }),
    TelescopePromptTitle({ fg = bg0, bg = dark_red }),

    TelescopeSelection({ bg = bg3, gui = "bold,italic" }),
    TelescopeSelectionCaret({ fg = fg, bg = bg3 }),
    TelescopeResults({ bg = "NONE" }),
    TelescopeResultsTitle({ fg = bg0, bg = fg, gui = "bold" }),

    ---- :help fzf-lua ---------------------------------------------------------

    FzfLuaNormal({ TelescopeNormal }),
    FzfLuaBorder({ TelescopeBorder }),
    FzfLuaCursor({}),
    FzfLuaCursorLine({}),
    FzfLuaCursorLineNr({}),
    FzfLuaSearch({}),
    FzfLuaTitle({ TelescopeTitle }),
    FzfLuaScrollBorderEmpty({}),
    FzfLuaScrollBorderFull({}),
    FzfLuaScrollFloatEmpty({}),
    FzfLuaScrollFloatFull({}),
    FzfLuaHelpNormal({}),
    FzfLuaHelpBorder({}),

    ---- :help: trouble.txt ----------------------------------------------------

    TroubleNormal({ PanelBackground }),
    TroubleText({ PanelBackground }),
    TroubleIndent({ PanelVertSplit }),
    TroubleFoldIcon({ fg = yellow, gui = "bold" }),
    TroubleLocation({ fg = Comment.fg }),
    TroublePreview({ bg = bg_visual, gui = "bold,italic,underline" }),

    ---- :help: dap ------------------------------------------------------------

    DapBreakpoint({ fg = light_red }),
    DapStopped({ fg = green }),

    ---- :help: fidget.txt -----------------------------------------------------

    FidgetTitle({ fg = orange }),
    FidgetTask({ fg = grey2, bg = bg1.darken(10) }),

    ---- :help: notifier.nvim  -------------------------------------------------

    NotifierTitle({ fg = orange }),
    NotifierContent({ fg = grey2, bg = bg1.darken(10) }),
    NotifierContentDim({ fg = grey1, bg = bg1.darken(10), gui = "italic" }),

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
    NeoTreeRootName({ fg = cyan, gui = "bold,italic,underline" }),
    NeoTreeFileNameOpened({ bg = fg, fg = fg, gui = "underline,bold" }),
    NeoTreeCursorLine({ Visual }),
    NeoTreeStatusLine({ PanelSt }),
    NeoTreeTitleBar({ fg = red, bg = bg_dark }),
    NeoTreeFloatBorder({ PanelBackground, fg = bg0 }),
    NeoTreeFloatTitle({ fg = Comment.fg, bg = bg2 }),
    NeoTreeTabActive({ bg = PanelBackground.bg, gui = "bold" }),
    NeoTreeTabInactive({ bg = PanelBackground.bg.darken(15), fg = Comment.fg }),
    NeoTreeTabSeparatorInactive({ bg = PanelBackground.bg.darken(15), fg = PanelBackground.bg }),
    NeoTreeTabSeparatorActive({ PanelBackground, fg = Comment.fg }),

    ---- :help git-signs.txt ---------------------------------------------------

    GitSignsAdd({ GreenSign, bg = "NONE" }),
    GitSignsDelete({ RedSign, bg = "NONE" }),
    GitSignsChange({ OrangeSign, bg = "NONE" }),

    ---- tmux-popup ------------------------------------------------------------

    TmuxPopupNormal({ bg = "#3d494f" }),

    ---- :hackkkks -------------------------------------------------------------

    Megaforest({ lush = C }),
  }
end)
