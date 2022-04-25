---@diagnostic disable: undefined-global

-- # REFS:
-- - https://github.com/svitax/fennec-gruvbox.nvim/blob/master/lua/lush_theme/fennec-gruvbox.lua
-- - https://github.com/mcchrish/zenbones.nvim/blob/main/lua/zenbones/specs/dark.lua

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
local colors = require("mega.lush_theme.colors")

local C = colors

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
local yellow = C.yellow
local green = C.green
local bright_green = C.bright_green
local cyan = C.cyan
local aqua = C.aqua
local blue = C.blue
local purple = C.purple
local brown = C.brown
local magenta = C.magenta

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

return lush(function()
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
    CursorLineNr({ fg = brown, bg = bg1, gui = "bold,italic" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    CursorLineNrNC({ fg = "NONE", bg = bg1, gui = "" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    Directory({ fg = green, bg = "NONE" }), -- directory names (and other special names in listings)
    TermCursor({ Cursor }), -- cursor in a focused terminal
    TermCursorNC({ Cursor }), -- cursor in an unfocused terminal
    ErrorMsg({ fg = red, bg = "NONE", gui = "bold,underline" }), -- error messages on the command line
    VertSplit({ fg = bg4, bg = "NONE" }), -- the column separating vertically split windows
    WinSeparator({ VertSplit, fg = bg2, gui = "bold" }),
    Folded({ fg = grey1, bg = bg1, gui = "bold,italic" }), -- line used for closed folds
    FoldColumn({ fg = grey1, bg = bg1 }), -- 'foldcolumn'
    -- Neither the sign column or end of buffer highlights require an explicit background
    -- they should both just use the background that is in the window they are in.
    -- if either are specified this can lead to issues when a winhighlight is set
    SignColumn({ fg = fg, bg = "NONE" }), -- column where |signs| are displayed
    EndOfBuffer({ fg = bg2, bg = "NONE" }), -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    IncSearch({ fg = bg0, bg = red }), -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    Search({ fg = bg0, bg = green, gui = "italic,bold" }), -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    Substitute({ fg = bg0, bg = yellow, guid = "strikethrough,bold" }), -- |:substitute| replacement text highlighting
    Beacon({ bg = blue }),
    LineNr({ fg = grey0, bg = "NONE" }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    MatchParen({ fg = "NONE", bg = bg4 }), -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg({ fg = fg, bg = "NONE", gui = "bold" }), -- 'showmode' message (e.g., "-- INSERT -- ")
    MsgArea({ bg = bg0 }), -- Area for messages and cmdline
    MsgSeparator({ bg = bg0 }), -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg({ fg = yellow, bg = "NONE", gui = "bold" }), -- |more-prompt|
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
    FloatTitle({ Visual }),
    Question({ fg = yellow, bg = "NONE" }), -- |hit-enter| prompt and yes/no questions
    QuickFixLine({ fg = "NONE", bg = PmenuSbar.bg, gui = "bold,italic" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- QuickFixLine({ fg = "NONE", bg = bg_visual.darken(20), gui = "bold,italic" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- QuickFixLine({ fg = purple, bg = "NONE", gui = "bold" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    SpecialKey({ fg = bg3, bg = "NONE" }), -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.

    ---- :help spell -------------------------------------------

    SpellBad({ fg = red, bg = "NONE", gui = "undercurl", sp = red }),
    SpellCap({ fg = blue, bg = "NONE", gui = "undercurl", sp = blue }),
    SpellLocal({ fg = cyan, bg = "NONE", gui = "undercurl", sp = cyan }),
    SpellRare({ fg = purple, bg = "NONE", gui = "undercurl", sp = purple }), -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.

    ---- :help toggleterm  -----------------------------------------------------

    DarkenedPanel({ bg = bg1 }),
    DarkenedStatusline({ bg = bg1 }),
    DarkenedStatuslineNC({ gui = "italic", bg = bg1 }),

    ---- sidebar  -----------------------------------------------------

    PanelBackground({ bg = bg0.darken(8) }),
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

    ErrorText({ bg = bg_red, gui = "undercurl", guisp = red }),
    WarningText({ bg = bg_yellow, gui = "undercurl", guisp = yellow }),
    InfoText({ bg = bg_blue, gui = "underline", guisp = blue }),
    HintText({ bg = bg_green.darken(20), gui = "underline", guisp = green }),
    ErrorLine({ fg = "NONE", bg = bg_red }),
    WarningLine({ fg = "NONE", bg = bg_yellow }),
    InfoLine({ fg = "NONE", bg = bg_blue }),
    HintLine({ fg = "NONE", bg = bg_green }),
    ErrorFloat({ fg = red, bg = bg2 }),
    WarningFloat({ fg = yellow, bg = bg2 }),
    InfoFloat({ fg = blue, bg = bg2 }),
    HintFloat({ fg = green, bg = bg2 }),

    -- REF: https://github.com/neovim/neovim/pull/15585
    DiagnosticFloatingError({ ErrorFloat }),
    DiagnosticFloatingWarn({ WarningFloat }),
    DiagnosticFloatingInfo({ InfoFloat }),
    DiagnosticFloatingHint({ HintFloat }),
    DiagnosticDefaultError({ ErrorText }),
    DiagnosticDefaultWarn({ WarningText }),
    DiagnosticDefaultInfo({ InfoText }),
    DiagnosticDefaultHint({ HintText }),
    DiagnosticVirtualTextError({ ErrorFloat }),
    DiagnosticVirtualTextWarn({ WarningFloat }),
    DiagnosticVirtualTextInfo({ InfoFloat }),
    DiagnosticVirtualTextHint({ HintFloat }),
    DiagnosticUnderlineError({ ErrorText }),
    DiagnosticUnderlineWarn({ WarningText }),
    DiagnosticUnderlineInfo({ InfoText }),
    DiagnosticUnderlineHint({ HintText }),

    DiagnosticSignError({ RedSign }),
    DiagnosticSignWarn({ OrangeSign }),
    DiagnosticSignInfo({ BlueSign }),
    DiagnosticSignHint({ AquaSign }),
    DiagnosticSignErrorLine({ fg = red, gui = "", guisp = red }),
    DiagnosticSignWarnLine({ fg = yellow, gui = "", guisp = yellow }),
    DiagnosticSignInfoLine({ fg = blue, gui = "", guisp = blue }),
    DiagnosticSignHintLine({ fg = aqua, gui = "", guisp = aqua }),
    DiagnosticSignErrorNumLine({ fg = red, gui = "", guisp = red }),
    DiagnosticSignWarnNumLine({ fg = yellow, gui = "", guisp = yellow }),
    DiagnosticSignInfoNumLine({ fg = blue, gui = "", guisp = blue }),
    DiagnosticSignHintNumLine({ fg = aqua, gui = "", guisp = aqua }),

    -- DiagnosticSource({ fg = bg2, bg = bg1 }),
    DiagnosticError({ Red, bg = bg2 }),
    DiagnosticWarn({ Orange, bg = bg2 }),
    DiagnosticInfo({ Blue, bg = bg2 }),
    DiagnosticHint({ Aqua, bg = bg2 }),

    DiagnosticErrorBorder({ Red }),
    DiagnosticWarnBorder({ Orange }),
    DiagnosticInfoBorder({ Blue }),
    DiagnosticHintBorder({ Aqua }),

    ---- :help lsp-highlight -----------------------------------

    LspReferenceText({ bg = "NONE", gui = "underline" }),
    LspReferenceRead({ bg = "NONE", gui = "underline" }),
    LspReferenceWrite({ InfoFloat, gui = "underline,bold,italic" }),
    LspCodeLens({ InfoFloat, fg = bg_dark }), -- Used to color the virtual text of the codelens,

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
    markdownH1({ fg = green, bg = bg_green, gui = "bold,italic,underline" }),
    markdownH2({ fg = yellow, bg = bg_yellow, gui = "bold,italic" }),
    markdownH3({ fg = red, bg = bg_red, gui = "bold" }),
    markdownH4({ fg = purple, bg = bg1, gui = "bold" }),
    markdownH5({ fg = blue, bg = bg0, gui = "italic" }),
    markdownH6({ fg = orange, bg = bg0, gui = "NONE" }),
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
    CodeBlock({ bg = bg1 }),
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
    mkdHeading({ bg = bg0 }),
    -- mkdListItem({}),
    -- mkdRule({}),
    -- mkdDelimiter({}),
    mkdId({ markdownId }),
    -- mkdLineBreak({}),
    -- mkdBlockquote({}),
    -- mkdFootnote({}),
    mkdCode({}),
    -- mkdCodeDelimiter({}),
    -- mkdListItem({}),
    -- mkdListItemLine({}),
    -- mkdNonListItemBlock({ bg = "NONE" }),
    -- mkdRule({}),
    -- htmlStrike({ mkdStrike }),
    -- htmlBoldItalic({}),

    htmlH1({ markdownH1 }),
    htmlH2({ markdownH2 }),
    htmlH3({ markdownH3 }),
    htmlH4({ markdownH4 }),
    htmlH5({ markdownH5 }),
    htmlH6({ markdownH6 }),
    htmlBold({ markdownBold }),
    htmlItalic({ markdownItalic }),

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
    TSKeyword({ Red }),
    TSKeywordFunction({ Red }),
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
    TSURI({ markdownUrl }),
    TSVariable({ Fg }),
    TSVariableBuiltin({ PurpleItalic }),
    TSComment({ fg = light_grey, gui = "italic" }),
    TSError({ gui = "undercurl", guisp = red }), -- ErrorText
    -- highlight FIXME/TODO/REF: comments
    commentTSWarning({ fg = orange, gui = "bold" }),
    commentTSDanger({ bg = red, fg = bg_dark, gui = "bold" }),
    commentTSNote({ fg = cyan, gui = "italic" }),
    TSWarning({ fg = commentTSWarning.fg }),
    TSDanger({}),
    TSNote({ fg = commentTSNote.fg }),
    TreesitterContext({ bg = bg1 }),

    -- { 'TSKeywordReturn', { italic = true, foreground = keyword_fg } },
    -- { 'TSParameter', { italic = true, bold = true, foreground = 'NONE' } },
    -- { 'TSError', { undercurl = true, sp = error_line, foreground = 'NONE' } },
    -- -- highlight FIXME comments
    -- { 'commentTSWarning', { background = P.light_red, foreground = 'fg', bold = true } },
    -- { 'commentTSDanger', { background = L.hint, foreground = '#1B2229', bold = true } },
    -- { 'commentTSNote', { background = L.info, foreground = '#1B2229', bold = true } },

    -- TS: Markdown
    markdownTSPunctSpecial({ Special }),
    markdownTSStringEscape({ SpecialKey }),
    markdownTSTextReference({ Identifier, gui = "underline" }),
    markdownTSEmphasis({ markdownItalic }),
    markdownTSTitle({ Statement, bg = bg1 }),
    markdownTSLiteral({ Type }),
    markdownTSURI({ markdownUrl }),
    markdownCode({ fg = grey1, bg = bg1 }),
    markdownLinkText({ markdownTSTextReference }),

    ---- :help git-signs -------------------------------------------

    GitSignsAdd({ GreenSign, bg = "NONE" }),
    GitSignsDelete({ RedSign, bg = "NONE" }),
    GitSignsChange({ OrangeSign, bg = "NONE" }),

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
    DiffText({ fg = "NONE", bg = bg_dark }), -- diff mode: Changed text within a changed line |diff.txt|

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

    ---- :help luasnip -------------------------------------------

    -- Luasnip*Node{Active,Passive,SnippetPassive}

    ---- :help indent-blankline -------------------------------------------

    IndentBlanklineChar({ fg = bg2, bg = "NONE" }),
    IndentBlanklineContextChar({ fg = blue, bg = "NONE" }),
    IndentBlanklineContextStart({ sp = blue, bg = "NONE", gui = "underline" }),

    ---- :help mini.indentscope -------------------------------------------
    MiniIndentscopeSymbol({ fg = bg_red, bg = "NONE" }),

    ---- :help hop-highlights -------------------------------------------

    -- vim.api.nvim_command('highlight default HopNextKey  guifg=#ff007c gui=bold ctermfg=198 cterm=bold')
    HopNextKey({ fg = magenta, gui = "bold" }),
    -- vim.api.nvim_command('highlight default HopNextKey1 guifg=#00dfff gui=bold ctermfg=45 cterm=bold')
    -- vim.api.nvim_command('highlight default HopNextKey2 guifg=#2b8db3 ctermfg=33')
    -- vim.api.nvim_command('highlight default HopUnmatched guifg=#666666 guibg="NONE" guisp=#666666 ctermfg=242')
    HopUnmatched({ fg = bg5, guisp = bg5 }),
    -- vim.api.nvim_command('highlight default link HopCursor Cursor')

    ---- :help lightspeed.nvim -------------------------------------------

    LightspeedCursor({ fg = bg0, bg = blue, gui = "bold, underline" }),
    LightspeedLabel({ fg = red, gui = "bold, underline" }),
    LightspeedLabelDistant({ fg = orange, gui = "bold, underline" }),
    LightspeedShortcut({
      fg = bg0,
      bg = yellow,
      gui = "bold",
    }),
    LightspeedMaskedChar({ fg = fg, gui = "bold" }),
    LightspeedGreyWash({ fg = bg3 }),
    LightspeedUnlabeledMatch({ fg = fg, gui = "italic, bold" }),
    LightspeedOneCharMatch({ fg = bg0, bg = yellow, gui = "bold" }),

    ---- :help tabline -------------------------------------------

    -- TabLine({ fg = grey2, bg = bg3 }), -- tab pages line, not active tab page label
    -- TabLineFill({ fg = grey1, bg = bg1 }), -- tab pages line, where there are no labels
    -- TabLineSel({ fg = bg0, bg = green }), -- tab pages line, active tab page label

    ---- megaline -- :help statusline -------------------------------------------

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
    StParentDirectory({ bg = bg1, fg = blue, gui = "bold" }),
    StFilename({ bg = bg1, fg = fg, gui = "bold" }),
    StFilenameInactive({ fg = light_grey, bg = bg1, gui = "italic,bold" }),
    StIdentifier({ fg = blue, bg = bg1 }),
    StTitle({ bg = bg1, fg = grey2, gui = "bold" }),
    StComment({ Comment, bg = bg1 }),
    StError({ fg = pale_red, bg = bg1 }),
    StWarn({ fg = orange, bg = bg1 }),
    StInfo({ fg = cyan, bg = bg1, gui = "bold" }),
    StHint({ fg = bg5, bg = bg1 }),

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

    TelescopePreviewTitle({ fg = bg0, bg = green, gui = "italic" }),

    TelescopePrompt({ bg = bg2.darken(10) }),
    TelescopePromptPrefix({ Statement, bg = bg2.darken(10) }),
    TelescopePromptBorder({ fg = bg2.darken(10), bg = bg2.darken(10) }),
    TelescopePromptNormal({ fg = fg, bg = bg2.darken(10) }),
    TelescopePromptTitle({ fg = bg0, bg = red }),

    TelescopeSelection({ bg = bg2.darken(10) }),
    TelescopeSelectionCaret({ fg = fg, bg = bg2.darken(10) }),
    TelescopeResults({ bg = "NONE" }),
    TelescopeResultsTitle({ fg = bg0, bg = fg, gui = "bold" }),

    ---- :help: trouble.txt ----------------------------------------------------

    TroubleNormal({ PanelBackground }),
    TroubleText({ PanelBackground }),
    TroubleIndent({ PanelVertSplit }),
    TroubleFoldIcon({ fg = yellow, gui = "bold" }),
    TroubleLocation({ fg = Comment.fg }),
    TroublePreview({ bg = bg_visual, gui = "bold,italic,underline" }),

    ---- :help: fidget.txt -----------------------------------------------------

    FidgetTitle({ fg = orange }),
    FidgetTask({ fg = grey2, bg = bg1.darken(10) }),

    ---- :help: bqf.txt --------------------------------------------------------

    BqfPreviewBorder({ fg = grey0 }),
    -- hi BqfPreviewBorder guifg=#50a14f ctermfg=71
    -- hi link BqfPreviewRange Search

    ---- :yaml -------------------------------------------------------------

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

    ---- :hackkkks -------------------------------------------------------------

    Megaforest({ lush = C }),
  }
end)
