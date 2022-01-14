---@diagnostic disable: undefined-global

-- # REFS:
-- - https://github.com/svitax/fennec-gruvbox.nvim/blob/master/lua/lush_theme/fennec-gruvbox.lua

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

local set = vim.g

local lush = require("lush")
local palette = require("colors")
local C = palette.cs
local H = require("utils/highlights")

local bg_dark = C.bg_dark
local bg0 = C.bg0
local bg1 = C.bg1
local bg2 = C.bg2
local bg3 = C.bg3
local bg4 = C.bg4
local bg_visual = C.bg_visual
local bg_red = C.bg_red
local bg_green = C.bg_green
local bg_blue = C.bg_blue
local bg_yellow = C.bg_yellow
local grey0 = C.grey0
local grey1 = C.grey1
local grey2 = C.grey2
local fg = C.fg
local red = C.red
local orange = C.orange
local yellow = C.yellow
local green = C.green
local bright_green = C.bright_green
local cyan = C.cyan
local aqua = C.aqua
local blue = C.blue
local purple = C.purple
local brown = C.brown

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

set.terminal_color_0 = tostring(tc.black)
set.terminal_color_1 = tostring(tc.red)
set.terminal_color_2 = tostring(tc.green)
set.terminal_color_3 = tostring(tc.yellow)
set.terminal_color_4 = tostring(tc.blue)
set.terminal_color_5 = tostring(tc.purple)
set.terminal_color_6 = tostring(tc.cyan)
set.terminal_color_7 = tostring(tc.white)
set.terminal_color_8 = tostring(tc.black)
set.terminal_color_9 = tostring(tc.red)
set.terminal_color_10 = tostring(tc.green)
set.terminal_color_11 = tostring(tc.yellow)
set.terminal_color_12 = tostring(tc.blue)
set.terminal_color_13 = tostring(tc.purple)
set.terminal_color_14 = tostring(tc.cyan)
set.terminal_color_15 = tostring(tc.white)
set.terminal_color_background = tostring(tc.black)
set.terminal_color_foreground = tostring(tc.white)

set.fzf_colors = {
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

set.VM_Mono_hl = "Cursor"
set.VM_Extend_hl = "Visual"
set.VM_Cursor_hl = "Cursor"
set.VM_Insert_hl = "Cursor"

return lush(function()
  return {

    ---- :help highlight-default -------------------------------

    ColorColumn({ fg = "NONE", bg = bg1 }), -- used for the columns set with 'colorcolumn'
    Conceal({ fg = grey1, bg = "NONE" }), -- placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor({ fg = "NONE", bg = "NONE", gui = "reverse" }), -- character under the cursor
    lCursor({ Cursor }), -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    iCursor({ Cursor }),
    vCursor({ Cursor }),
    CursorIM({ Cursor }), -- like Cursor, but used when in IME mode |CursorIM|
    CursorColumn({ fg = "NONE", bg = bg1 }), -- Screen-column at the cursor, when 'cursorcolumn' is set.
    CursorLine({ fg = "NONE", bg = bg1 }), -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR fg) is not set.
    CursorWord({ fg = "NONE", bg = "NONE", gui = "bold,underline" }),
    CursorLineNr({ fg = brown, bg = bg1, gui = "bold,italic" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    Directory({ fg = green, bg = "NONE" }), -- directory names (and other special names in listings)
    DiffAdd({ fg = "NONE", bg = bg_green }), -- diff mode: Added line |diff.txt|
    DiffChange({ fg = "NONE", bg = bg_blue }), -- diff mode: Changed line |diff.txt|
    DiffDelete({ fg = "NONE", bg = bg_red }), -- diff mode: Deleted line |diff.txt|
    DiffText({ fg = bg0, bg = fg }), -- diff mode: Changed text within a changed line |diff.txt|
    EndOfBuffer({ fg = bg0, bg = bg0 }), -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    TermCursor({ Cursor }), -- cursor in a focused terminal
    TermCursorNC({ Cursor }), -- cursor in an unfocused terminal
    ErrorMsg({ fg = red, bg = "NONE", gui = "bold,underline" }), -- error messages on the command line
    VertSplit({ fg = bg4, bg = "NONE" }), -- the column separating vertically split windows
    Folded({ fg = grey1, bg = bg1 }), -- line used for closed folds
    FoldColumn({ fg = grey1, bg = bg1 }), -- 'foldcolumn'
    SignColumn({ fg = fg, bg = bg0 }), -- column where |signs| are displayed
    IncSearch({ fg = bg0, bg = red }), -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    Substitute({ fg = bg0, bg = yellow }), -- |:substitute| replacement text highlighting
    LineNr({ fg = grey0, bg = "NONE" }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    MatchParen({ fg = "NONE", bg = bg4 }), -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg({ fg = fg, bg = "NONE", gui = "bold" }), -- 'showmode' message (e.g., "-- INSERT -- ")
    -- MsgArea      { }, -- Area for messages and cmdline
    -- MsgSeparator { }, -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg({ fg = yellow, bg = "NONE", gui = "bold" }), -- |more-prompt|
    NonText({ fg = bg4, bg = "NONE" }), -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Normal({ fg = fg, bg = bg0 }), -- normal text
    NormalFloat({ fg = fg, bg = bg2 }), -- Normal text in floating windows.
    GreyFloat({ bg = grey1 }),
    GreyFloatBorder({ fg = grey1 }),
    -- NormalNC     { }, -- normal text in non-current windows
    Pmenu({ fg = fg, bg = bg2 }), -- Popup menu: normal item.
    PmenuSel({ fg = green, bg = bg3 }), -- Popup menu: selected item.
    PmenuSbar({ fg = "NONE", bg = bg2 }), -- Popup menu: scrollbar.
    PmenuThumb({ fg = "NONE", bg = grey1 }), -- Popup menu: Thumb of the scrollbar.
    Question({ fg = yellow, bg = "NONE" }), -- |hit-enter| prompt and yes/no questions
    QuickFixLine({ fg = purple, bg = "NONE", gui = "bold" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    Search({ fg = bg0, bg = green }), -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    SpecialKey({ fg = bg3, bg = "NONE" }), -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.

    ---- :help spell -------------------------------------------

    SpellBad({ fg = red, bg = "NONE", gui = "undercurl", sp = red }),
    SpellCap({ fg = blue, bg = "NONE", gui = "undercurl", sp = blue }),
    SpellLocal({ fg = cyan, bg = "NONE", gui = "undercurl", sp = cyan }),
    SpellRare({ fg = purple, bg = "NONE", gui = "undercurl", sp = purple }), -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.

    Visual({ fg = "NONE", bg = bg_visual }), -- Visual mode selection
    VisualNOS({ fg = "NONE", bg = bg_visual }), -- Visual mode selection when vim is "Not Owning the Selection".
    WarningMsg({ fg = yellow, bg = "NONE" }), -- warning messages
    Whitespace({ fg = bg3, bg = "NONE" }), -- "nbsp", "space", "tab" and "trail" in 'listchars'
    --
    WildMenu({ PmenuSel }), -- current match in 'wildmenu' completion
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
    Function({ fg = green, bg = "NONE" }),
    String({ fg = green, bg = "NONE" }),
    Character({ fg = green, bg = "NONE" }),
    Constant({ fg = aqua, bg = "NONE" }),
    Macro({ fg = aqua, bg = "NONE" }),
    Identifier({ fg = blue, bg = "NONE" }),
    Comment({ fg = grey1, bg = "NONE", gui = "italic" }),
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
    CurrentWord({ fg = "NONE", bg = "NONE" }),
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
    ErrorText({ fg = "NONE", bg = bg_red, gui = "undercurl", sp = red }),
    WarningText({ fg = "NONE", bg = bg_yellow, gui = "undercurl", sp = yellow }),
    InfoText({ fg = "NONE", bg = bg_blue, gui = "undercurl", sp = blue }),
    HintText({ fg = "NONE", bg = bg_green, gui = "undercurl", sp = green }),
    ErrorLine({ fg = "NONE", bg = bg_red }),
    WarningLine({ fg = "NONE", bg = bg_yellow }),
    InfoLine({ fg = "NONE", bg = bg_blue }),
    HintLine({ fg = "NONE", bg = bg_green }),
    ErrorFloat({ fg = red, bg = bg2 }),
    WarningFloat({ fg = yellow, bg = bg2 }),
    InfoFloat({ fg = blue, bg = bg2 }),
    HintFloat({ fg = green, bg = bg2 }),
    RedSign({ fg = red, bg = bg1 }),
    OrangeSign({ fg = orange, bg = bg1 }),
    YellowSign({ fg = yellow, bg = bg1 }),
    GreenSign({ fg = green, bg = bg1 }),
    AquaSign({ fg = cyan, bg = bg1 }),
    BlueSign({ fg = blue, bg = bg1 }),
    PurpleSign({ fg = purple, bg = bg1 }),

    ---- :help lsp-highlight -----------------------------------

    LspDiagnosticsFloatingError({ ErrorFloat }),
    LspDiagnosticsFloatingWarning({ WarningFloat }),
    LspDiagnosticsFloatingInformation({ InfoFloat }),
    LspDiagnosticsFloatingHint({ HintFloat }),
    LspDiagnosticsDefaultError({ ErrorText }),
    LspDiagnosticsDefaultWarning({ WarningText }),
    LspDiagnosticsDefaultInformation({ InfoText }),
    LspDiagnosticsDefaultHint({ HintText }),
    LspDiagnosticsVirtualTextError({ ErrorFloat }),
    LspDiagnosticsVirtualTextWarning({ WarningFloat }),
    LspDiagnosticsVirtualTextInformation({ InfoFloat }),
    LspDiagnosticsVirtualTextHint({ HintFloat }),
    LspDiagnosticsUnderlineError({ ErrorText }),
    LspDiagnosticsUnderlineWarning({ WarningText }),
    LspDiagnosticsUnderlineInformation({ InfoText }),
    LspDiagnosticsUnderlineHint({ HintText }),
    LspDiagnosticsSignError({ RedSign }),
    LspDiagnosticsSignWarning({ YellowSign }),
    LspDiagnosticsSignInformation({ BlueSign }),
    LspDiagnosticsSignHint({ AquaSign }),
    LspReferenceText({ CurrentWord }),
    LspReferenceRead({ CurrentWord }),
    LspReferenceWrite({ CurrentWord }),
    LspCodeLens({ InfoFloat }), -- Used to color the virtual text of the codelens,

    ---- :help diagnostic-highlight ----------------------------

    -- REF: https://github.com/neovim/neovim/pull/15585
    DiagnosticFloatingError({ ErrorFloat }),
    DiagnosticFloatingWarning({ WarningFloat }),
    DiagnosticFloatingWarn({ WarningFloat }),
    DiagnosticFloatingInformation({ InfoFloat }),
    DiagnosticFloatingInfo({ InfoFloat }),
    DiagnosticFloatingHint({ HintFloat }),
    DiagnosticDefaultError({ ErrorText }),
    DiagnosticDefaultWarning({ WarningText }),
    DiagnosticDefaultWarn({ WarningText }),
    DiagnosticDefaultInformation({ InfoText }),
    DiagnosticDefaultInfo({ InfoText }),
    DiagnosticDefaultHint({ HintText }),
    DiagnosticVirtualTextError({ ErrorFloat }),
    DiagnosticVirtualTextWarning({ WarningFloat }),
    DiagnosticVirtualTextWarn({ WarningFloat }),
    DiagnosticVirtualTextInformation({ InfoFloat }),
    DiagnosticVirtualTextInfo({ InfoFloat }),
    DiagnosticVirtualTextHint({ HintFloat }),
    DiagnosticUnderlineError({ ErrorText }),
    DiagnosticUnderlineWarning({ WarningText }),
    DiagnosticUnderlineWarn({ WarningText }),
    DiagnosticUnderlineInformation({ InfoText }),
    DiagnosticUnderlineInfo({ InfoText }),
    DiagnosticUnderlineHint({ HintText }),
    DiagnosticSignError({ RedSign }),
    DiagnosticSignWarning({ YellowSign }),
    DiagnosticSignWarn({ YellowSign }),
    DiagnosticSignInformation({ BlueSign }),
    DiagnosticSignInfo({ BlueSign }),
    DiagnosticSignHint({ AquaSign }),

    DiagnosticError({ RedSign }),
    DiagnosticWarn({ YellowSign }),
    DiagnosticInfo({ BlueSign }),
    DiagnosticHint({ AquaSign }),

    DiagnosticErrorBorder({ RedSign, bg = bg0 }),
    DiagnosticWarnBorder({ YellowSign, bg = bg0 }),
    DiagnosticInfoBorder({ BlueSign, bg = bg0 }),
    DiagnosticHintBorder({ AquaSign, bg = bg0 }),

    TermCursor({ Cursor }),

    ---- :help health ----------------------------

    healthError({ Red }),
    healthSuccess({ Green }),
    healthWarning({ Yellow }),
    -- These groups are for the neovim tree-sitter highlights.
    -- As of writing, tree-sitter support is a WIP, group names may change.
    -- By default, most of these groups link to an appropriate Vim group,
    -- TSError -> Error for example, so you do not have to define these unless
    -- you explicitly want to support Treesitter's improved syntax awareness.

    -- # built-in markdown
    markdownH1({ fg = bg0, bg = green, gui = "bold" }),
    markdownH2({ fg = orange, bg = "NONE", gui = "bold,italic,underline" }),
    markdownH3({ fg = purple, bg = "NONE", gui = "bold,italic" }),
    markdownH4({ fg = yellow, bg = "NONE", gui = "italic" }),
    markdownH5({ fg = cyan, bg = "NONE", gui = "bold" }),
    markdownH6({ fg = blue, bg = "NONE", gui = "NONE" }),
    Headline1({ markdownH1 }),
    Headline2({ markdownH2 }),
    Headline3({ markdownH3 }),
    Headline4({ markdownH4 }),
    Headline5({ markdownH5 }),
    Headline6({ markdownH6 }),
    markdownUrl({ fg = blue, bg = "NONE", gui = "underline" }),
    markdownItalic({ fg = grey1, bg = "NONE", gui = "italic" }),
    markdownBold({ fg = grey2, bg = "NONE", gui = "bold" }),
    markdownDash({ fg = bg2, gui = "bold" }),
    Dash({ markdownDash }),
    markdownItalicDelimiter({ fg = grey1, bg = "NONE", gui = "italic" }),
    markdownCode({ Green }),
    markdownCodeBlock({ Aqua }),
    markdownCodeDelimiter({ Aqua }),
    markdownBlockquote({ Grey }),
    markdownListMarker({ Red }),
    markdownOrderedListMarker({ Red }),
    markdownRule({ Purple }),
    markdownHeadingRule({ Grey }),
    markdownUrlDelimiter({ Grey }),
    markdownLinkDelimiter({ Grey }),
    markdownLinkTextDelimiter({ Grey }),
    markdownHeadingDelimiter({ Grey }),
    markdownLinkText({ Purple }),
    markdownUrlTitleDelimiter({ Green }),
    markdownIdDeclaration({ markdownLinkText }),
    markdownBoldDelimiter({ Grey }),
    markdownId({ Yellow }),

    -- # vim-markdown
    -- REF: https://github.com/plasticboy/vim-markdown/blob/master/syntax/markdown.vim
    mkdItalic({ markdownItalic }),
    mkdBold({ markdownBold }),
    mkdBoldItalic({ markdownBold }),
    mkdUnderline({ Underlined }),
    -- mkdStrike({}),
    mkdLink({ markdownBold }),
    mkdURL({ markdownUrl }),
    mkdInlineURL({ markdownUrl }),
    -- mkdLinkDef({}),
    -- mkdLinkDefTarget({}),
    -- mkdLinkTitle({}),
    -- mkdCodeDelimiter({}),
    -- mkdHeading({}),
    -- mkdListItem({}),
    -- mkdRule({}),
    -- mkdDelimiter({}),
    mkdId({ markdownId }),
    -- mkdLineBreak({}),
    -- mkdBlockquote({}),
    -- mkdFootnote({}),
    mkdCode({ markdownCode }),
    -- mkdCodeDelimiter({}),
    -- mkdListItem({}),
    -- mkdListItemLine({}),
    -- mkdNonListItemBlock({}),
    -- mkdRule({}),
    htmlH1({ markdownH1 }),
    htmlH2({ markdownH2 }),
    htmlH3({ markdownH3 }),
    htmlH4({ markdownH4 }),
    htmlH5({ markdownH5 }),
    htmlH6({ markdownH6 }),
    htmlBold({ markdownBold }),
    htmlItalic({ markdownItalic }),
    -- htmlStrike({ mkdStrike }),
    -- htmlBoldItalic({}),

    -- M.link("Dash", "markdownBold")
    -- M.highlight("CodeBlock", { bg = M.colors.dimm_black })
    -- M.highlight("HeadlineGreen", { bg = M.colors.diff_green })
    -- M.highlight("HeadlineYellow", { bg = M.colors.diff_yellow })
    -- M.highlight("HeadlineBlue", { bg = M.colors.dark_cursor_grey })
    -- M.highlight("HeadlineRed", { bg = M.colors.diff_red })
    -- M.highlight("HeadlinePurple", { bg = M.colors.diff_purple })
    -- vim.fn.sign_define("HeadlineGreen", { linehl = "HeadlineGreen" })
    -- vim.fn.sign_define("HeadlineYellow", { linehl = "HeadlineYellow" })
    -- vim.fn.sign_define("HeadlineBlue", { linehl = "HeadlineBlue" })
    -- vim.fn.sign_define("HeadlineRed", { linehl = "HeadlineRed" })
    -- vim.fn.sign_define("HeadlinePurple", { linehl = "HeadlinePurple" })

    ---- :help nvim-treesitter-highlights (external plugin) ----

    TSAnnotation({ Purple }),
    TSAttribute({ Purple }),
    TSBoolean({ Purple }),
    TSCharacter({ Yellow }),
    TSComment({ Grey, gui = "italic" }),
    TSConditional({ Red }),
    TSConstBuiltin({ PurpleItalic }),
    TSConstMacro({ Purple }),
    TSConstant({ PurpleItalic }),
    TSConstructor({ Fg }),
    TSEmphasis({ fg = "NONE", bg = "NONE", gui = "italic" }),
    TSError({ ErrorText }),
    TSException({ Red }),
    TSField({ Green }),
    TSFloat({ Purple }),
    TSFuncBuiltin({ Green }),
    TSFuncMacro({ Green }),
    TSFunction({ Green }),
    TSInclude({ PurpleItalic }),
    TSKeyword({ Red }),
    TSKeywordFunction({ Red }),
    TSLabel({ Orange }),
    TSMethod({ Green }),
    TSNamespace({ BlueItalic }),
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
    TSURI({ markdownUrl }),
    TSVariable({ Fg }),
    TSVariableBuiltin({ PurpleItalic }),
    -- highlight FIXME comments
    commentTSWarning({ fg = red, gui = "bold" }),
    commentTSDanger({ fg = orange, gui = "bold" }),
    TreesitterContext({ bg = C.bg1 }),

    -- TS: Markdown
    markdownTSPunctSpecial({ Special }),
    markdownTSStringEscape({ SpecialKey }),
    markdownTSTextReference({ Identifier, gui = "underline" }),
    markdownTSEmphasis({ markdownItalic }),
    markdownTSTitle({ Statement }),
    markdownTSLiteral({ Type }),
    markdownTSURI({ markdownUrl }),
    markdownCode({ markdownTSLiteral }),
    markdownLinkText({ markdownTSTextReference }),

    ---- :help git-signs -------------------------------------------

    GitSignsAdd({ GreenSign, bg = "NONE" }),
    GitSignsDelete({ RedSign, bg = "NONE" }),
    GitSignsChange({ BlueSign, bg = "NONE" }),

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

    ---- :help :diff -------------------------------------------

    diffAdded({ Green }),
    diffRemoved({ Red }),
    diffChanged({ Blue }),
    diffOldFile({ Yellow }),
    diffNewFile({ Orange }),
    diffFile({ Aqua }),
    diffLine({ Grey }),
    diffIndexLine({ Purple }),

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
    elixirModuleDefine({ PurpleItalic }),
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

    CmpDocumentation({ fg = C.fg, bg = C.bg1 }),
    CmpDocumentationBorder({ fg = C.fg, bg = C.bg1 }),

    CmpItemAbbr({ fg = C.fg }),
    CmpItemAbbrMatch({ fg = C.cyan, gui = "bold,italic" }),
    CmpItemAbbrMatchFuzzy({ fg = C.yellow }),
    CmpItemMenu({ fg = C.fg }),

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
    -- CmpItemKindReference({ Preproc }),
    -- CmpItemKindFolder({}),
    -- CmpItemKindEnumMember({}),
    CmpItemKindConstant({ fg = C.green }),
    -- CmpItemKindStruct({ Type }),
    -- CmpItemKindEvent({ Variable }),
    -- CmpItemKindOperator({ Operator }),
    -- CmpItemKindTypeParameter({ Type }),

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

    -- nvim-hlslens
    -- HlSearchNear({ bg = "#e2be7d", fg = cs.bg }),
    -- HlSearchLens({ bg = cs.grey1 }),
    -- HlSearchLensNear({ HlSearchNear }),
    -- HlSearchFloat({ HlSearchNear }),

    ---- :help luasnip -------------------------------------------

    -- Luasnip*Node{Active,Passive,SnippetPassive}

    ---- :help indent-blankline -------------------------------------------

    IndentBlanklineChar({ fg = bg2, bg = "NONE" }),
    IndentBlanklineContextChar({ fg = blue, bg = "NONE" }),
    IndentBlanklineContextStart({ sp = blue, bg = "NONE", gui = "underline" }),

    ---- :help orgmode.nvim -------------------------------------------

    OrgDone({ fg = bright_green, bg = "NONE" }),
    OrgDONE({ fg = bright_green, bg = "NONE" }),
    OrgAgendaScheduled({ fg = green, bg = "NONE" }),
    OrgAgendaDay({ Directory }),

    ---- :help lightspeed.nvim -------------------------------------------

    -- LightspeedCursor({ fg = cs.bg, bg = cs.blue, gui = "bold, underline" }),
    -- LightspeedLabel({ fg = cs.red, gui = "bold, underline" }),
    -- -- LightspeedLabelOverlapped {fg = cs.green_2, gui = "bold"},
    -- LightspeedLabelDistant({ fg = cs.orange, gui = "bold, underline" }),
    -- -- LightspeedLabelDistantOverlapped {fg = cs.orange, gui = "bold"},
    -- LightspeedShortcut({
    --   fg = cs.bg,
    --   bg = cs.yellow_2,
    --   gui = "bold",
    -- }),
    -- -- LightspeedShortcutOverlapped {fg = cs.bg, bg = cs.green_2, gui = "bold"},
    -- LightspeedMaskedChar({ fg = cs.fg, gui = "bold" }),
    -- LightspeedGreyWash({ fg = cs.bg3 }),
    -- LightspeedUnlabeledMatch({ fg = cs.fg, gui = "italic, bold" }),
    -- LightspeedOneCharMatch({ fg = cs.bg, bg = cs.yellow_2, gui = "bold" }),
    -- -- LightspeedUniqueChar {fg = cs.white, gui = "bold"},
    -- -- LightspeedPendingOpArea {fg = cs.fg, bg = cs.lightspeed.primary},
    -- -- LightspeedPendingChangeOpArea {fg = cs.lightspeed.primary, gui = "italic, strikethrough"},

    ---- :help tabline -------------------------------------------

    -- TabLine({ fg = grey2, bg = bg3 }), -- tab pages line, not active tab page label
    -- TabLineFill({ fg = grey1, bg = bg1 }), -- tab pages line, where there are no labels
    -- TabLineSel({ fg = bg0, bg = green }), -- tab pages line, active tab page label

    ---- :help statusline -------------------------------------------

    StatusLine({ fg = C.grey1, bg = C.bg1 }), -- status line of current window
    StatusLineNC({ fg = C.grey1, bg = C.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    -- StatusLine({ bg = bg1 }),
    -- StatusLineNC({ bg = bg1, gui = "NONE" }),
    -- StInactive({ bg = bg0, gui = "italic" }),
    StInactive({ fg = bg2, bg = bg0, gui = "italic" }),

    -- StatusLineTerm({ fg = cs.grey1, bg = cs.bg1 }), -- status line of current window
    -- StatusLineTermNC({ fg = cs.grey1, bg = cs.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    -- StItem1({ fg = cs.green, bg = cs.bg1 }),
    -- StItem2({ fg = cs.grey2, bg = cs.bg1 }),
    -- StItem3({ fg = cs.grey0, bg = cs.bg1 }),
    -- StItemInfo({ fg = cs.blue, bg = cs.bg1 }),
    -- StItemSearch({ fg = cs.bg0, bg = cs.blue }),
    -- StSep1({ fg = cs.bg1, bg = cs.green }),
    -- StSep2({ fg = cs.bg1, bg = cs.grey2 }),
    -- StSep3({ fg = cs.bg1, bg = cs.grey0 }),
    -- StError({ bg = cs.pale_red }),
    -- StWarn({ bg = cs.dark_orange }),

    StModeNormal({ bg = bg1, fg = C.bg5, gui = "NONE" }),
    StModeInsert({ bg = bg1, fg = C.green, gui = "bold" }),
    StModeVisual({ bg = bg1, fg = C.magenta, gui = "bold" }),
    StModeReplace({ bg = bg1, fg = C.dark_red, gui = "bold" }),
    StModeCommand({ bg = bg1, fg = H.get_hl("Search", "bg"), gui = "bold" }),

    StMetadata({ Comment, bg = bg1 }),
    StMetadataPrefix({ Comment, bg = bg1, gui = "NONE" }),
    StIndicator({ bg = bg1, fg = blue }),
    StModified({ fg = C.pale_red, bg = bg1, gui = "bold,italic" }),
    StGit({ fg = C.light_red, bg = bg1 }),
    StGreen({ fg = green, bg = bg1 }),
    StBlue({ fg = C.dark_blue, bg = bg1, gui = "bold" }),
    StNumber({ fg = purple, bg = bg1 }),
    StCount({ fg = bg0, bg = blue, gui = "bold" }),
    StPrefix({ fg = fg, bg = bg2 }),
    StDirectory({ bg = bg1, fg = "Gray", gui = "italic" }),
    StParentDirectory({ bg = bg1, fg = green, gui = "bold" }),
    StFilename({ bg = bg1, fg = "LightGray", gui = "bold" }),
    StFilenameInactive({ fg = C.comment_grey, bg = bg1, gui = "italic,bold" }),
    StIdentifier({ fg = blue, bg = bg1 }),
    StTitle({ bg = bg1, fg = "LightGray", gui = "bold" }),
    StComment({ Comment, bg = bg1 }),
    StInfo({ fg = C.cyan, bg = bg1, gui = "bold" }),
    StWarning({ fg = C.dark_orange, bg = bg1 }),
    StError({ fg = C.pale_red, bg = bg1 }),
    StHint({ fg = C.bright_yellow, bg = bg1 }),

    ---- :help telescope -------------------------------------------

    TelescopeMatching({ Title }),
    -- TelescopeBorder({ GreyFloatBorder }),
    TelescopePromptPrefix({ Statement }),
    TelescopeTitle({ Normal, gui = "bold" }),
    TelescopeSelectionCaret({ fg = fg, bg = "NONE" }),
    TelescopeBorder({ fg = bg4 }),

    -- TelescopeMatching({ Title }),
    -- TelescopeBorder({ GreyFloatBorder }),
    -- TelescopePromptPrefix({ Statement }),
    -- TelescopeTitle({ Normal, gui = "bold" }),
    -- TelescopeSelectionCaret({ fg = fg }),
    -- TelescopeNormal({ bg = bg1 }),
    -- TelescopePromptNormal({ bg = bg1 }),
    -- TelescopePromptBorder({ bg = bg1 }),
    -- TelescopePreviewBorder({ bg = bg1 }),
    -- TelescopeResultsBorder({ bg = bg1 }),

    -- { "TelescopeSelection", { bg = palette.dark1 } }, -- gitsigns
    -- { "TelescopeNormal", { fg = palette.light1, bg = palette.dark0_hard } },
    -- { "TelescopePromptNormal", { bg = palette.dark1 } }, -- gitsigns
    -- { "TelescopeResultsBorder", { fg = palette.bright_aqua, bg = palette.dark0_hard } },
    -- { "TelescopePreviewBorder", { fg = palette.bright_aqua, bg = palette.dark0_hard } },
    -- { "TelescopePromptBorder", { fg = palette.bright_blue, bg = palette.dark1 } },
    -- { "TelescopePromptTitle", { fg = palette.dark1, bg = palette.bright_blue } },
    -- { "TelescopeResultsTitle", { fg = palette.dark1, bg = palette.bright_aqua } },
    -- { "TelescopePreviewTitle", { fg = palette.dark1, bg = palette.bright_aqua } },

    -- { "TelescopeSelection", { bg = palette.dark1 } }, -- gitsigns
    -- { "TelescopeNormal", { fg = palette.light1, bg = palette.dark0_hard } },
    -- { "TelescopePromptNormal", { bg = palette.dark1 } }, -- gitsigns
    -- { "TelescopeResultsBorder", { fg = palette.bright_aqua, bg = palette.dark0_hard } },
    -- { "TelescopePreviewBorder", { fg = palette.bright_aqua, bg = palette.dark0_hard } },
    -- { "TelescopePromptBorder", { fg = palette.bright_blue, bg = palette.dark1 } },
    -- { "TelescopePromptTitle", { fg = palette.dark1, bg = palette.bright_blue } },
    -- { "TelescopeResultsTitle", { fg = palette.dark1, bg = palette.bright_aqua } },
    -- { "TelescopePreviewTitle", { fg = palette.dark1, bg = palette.bright_aqua } },
  }
end)
