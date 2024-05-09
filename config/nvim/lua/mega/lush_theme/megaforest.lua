local ok, lush = pcall(require, "lush")
if not ok then
  print("lush not found, not loading theme")
  return
end

local C = require("mega.lush_theme.colors")
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

vim.g.VM_Mono_hl = "Cursor"
vim.g.VM_Extend_hl = "Visual"
vim.g.VM_Cursor_hl = "Cursor"
vim.g.VM_Insert_hl = "Cursor"

---@diagnostic disable: undefined-global
local theme = lush(function(injected_functions)
  local sym = injected_functions.sym

  return {
    Normal({ fg = C.fg, bg = C.transparent }), -- normal text
    NormalNC({ bg = C.bg0.da(7) }), -- inactive window split
    NonText({ fg = C.bg4, bg = C.transparent }), -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Pmenu({ fg = C.fg, bg = C.bg2 }), -- Popup menu: normal item.
    PmenuSel({ fg = C.green, bg = C.bg3 }), -- Popup menu: selected item.
    PmenuSbar({ fg = C.transparent, bg = C.bg2 }), -- Popup menu: scrollbar.
    PmenuThumb({ fg = C.transparent, bg = C.grey1 }), -- Popup menu: Thumb of the scrollbar.
    Background({ bg = C.bg0 }),
    BackgroundLight({ bg = C.bg1 }),
    BackgroundExtraLight({ bg = C.bg2 }),
    Visual({ bg = C.bg_visual }), -- Visual mode selection
    VisualNOS({ fg = C.transparent, bg = C.bg_visual }), -- Visual mode selection when vim is "Not Owning the Selection".
    VisualYank({ Visual, bg = C.bg_visual.li(10) }), -- Visual mode selection
    WarningMsg({ fg = C.yellow, bg = C.transparent }), -- warning messages
    Whitespace({ fg = C.bg3, bg = C.transparent }), -- "nbsp", "space", "tab" and "trail" in 'listchars'
    ColorColumn({ fg = C.transparent, bg = C.bg0 }), -- used for the columns set with 'colorcolumn'
    Conceal({ fg = C.grey1, bg = C.transparent }), -- placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor({ fg = C.transparent, bg = C.transparent, gui = "reverse" }), -- character under the cursor
    Cursor2({ fg = C.bg_red, bg = C.bg_red, gui = "reverse" }),
    TermCursor({ Cursor, bg = C.yellow }), -- cursor in a focused terminal
    TermCursorNC({ Cursor }), -- cursor in an unfocused terminal
    lCursor({ Cursor }), -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    iCursor({ Cursor, bg = C.bg_blue }),
    vCursor({ Cursor }),
    CursorIM({ Cursor }), -- like Cursor, but used when in IME mode |CursorIM|
    CursorColumn({ fg = C.transparent, bg = C.bg2 }), -- Screen-column at the cursor, when 'cursorcolumn' is set.
    CursorWord({ fg = C.transparent, bg = C.transparent, gui = "bold,underline" }),
    CursorLine({ bg = C.bg2 }), -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR fg) is not set.
    LineNr({ fg = C.grey0, bg = C.transparent }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    CursorLineNr({ CursorLine, fg = C.brown, bg = C.bg0.li(5), gui = "bold,italic" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    -- CursorLineNrNC({ CursorLine, fg = C.transparent, bg = C.bg2 }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    -- CursorLineSign({ bg = C.red }),
    VertSplit({ fg = C.bg4, bg = C.transparent }), -- the column separating vertically split windows
    WinSeparator({ fg = C.bg_dark.li(15), bg = C.bg_dark.li(1), gui = "bold" }),

    Comment({ fg = C.grey1, bg = C.transparent, gui = "italic" }),
    Directory({ fg = C.green, bg = C.transparent }), -- directory names (and other special names in listings)
    ErrorMsg({ fg = C.red, bg = C.transparent, gui = "bold,underline" }), -- error messages on the command line
    Folded({ Normal }), -- line used for closed folds
    -- Folded({ Comment, gui = "bold,italic" }), -- line used for closed folds
    FoldColumn({ fg = C.grey1, bg = C.bg1 }), -- 'foldcolumn'
    -- Neither the sign column or end of buffer highlights require an explicit background
    -- they should both just use the background that is in the window they are in.
    -- if either are specified this can lead to issues when a winhighlight is set
    SignColumn({ fg = C.fg, bg = C.transparent }), -- column where |signs| are displayed
    EndOfBuffer({ fg = C.bg2, bg = C.transparent }), -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    IncSearch({ fg = C.bg0, bg = C.red }), -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    CurSearch({ IncSearch }),
    Search({ fg = C.bg0, bg = C.green, gui = "italic,bold" }), -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    Substitute({ fg = C.bg0, bg = C.yellow, gui = "strikethrough,bold" }), -- |:substitute| replacement text highlighting
    MatchParen({ fg = C.transparent, bg = C.bg4 }), -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg({ fg = C.fg, bg = C.transparent, gui = "bold" }), -- 'showmode' message (e.g., "-- INSERT -- ")
    MsgArea({ bg = C.bg0 }), -- Area for messages and cmdline
    MsgSeparator({ bg = C.bg0 }), -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg({ fg = C.yellow, bg = C.transparent, gui = "bold" }), -- |more-prompt|
    FoldMoreMsg({ Comment, gui = "italic,bold" }), -- |more-prompt|
    WildMenu({ PmenuSel }), -- current match in 'wildmenu' completion
    NormalFloat({ Pmenu }), -- Normal text in floating windows.
    FloatBorder({ Pmenu, fg = C.bg2.darken(10) }),
    NotifyBackground({ bg = C.bg2.darken(10) }),
    NotifyFloat({ NotifyBackground, fg = C.bg2.darken(10) }),
    FloatTitle({ Visual }),
    Question({ fg = C.yellow, bg = C.transparent }), -- |hit-enter| prompt and yes/no questions
    -- QuickFixLine({ fg = transparent, bg = PmenuSbar.bg, gui = "bold,italic" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- QuickFixLine({ fg = transparent, bg = bg_visual.darken(20), gui = "bold,italic" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- QuickFixLine({ fg = purple, bg = transparent, gui = "bold" }), -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    SpecialKey({ fg = C.bg3, bg = C.transparent }), -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.

    ---- :help spell -------------------------------------------

    SpellBad({ fg = C.red, bg = C.transparent, gui = "bold,underline", sp = C.red }),
    SpellCap({ fg = C.blue, bg = C.transparent, gui = "underline", sp = C.blue }),
    SpellLocal({ fg = C.cyan, bg = C.transparent, gui = "underline", sp = C.cyan }),
    SpellRare({ fg = C.purple, bg = C.transparent, gui = "underline", sp = C.purple }), -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.

    -- These groups are not listed as default vim groups,
    -- but they are defacto standard group names for syntax highlighting.
    -- commented out groups should chain up to their "preferred" group by
    -- default,
    -- Uncomment and edit if you want more specific syntax highlighting.
    Boolean({ fg = C.purple, bg = C.transparent }),
    Number({ fg = C.purple, bg = C.transparent }),
    Float({ fg = C.purple, bg = C.transparent }),
    PreProc({ fg = C.purple, bg = C.transparent, gui = "italic" }),
    PreCondit({ fg = C.purple, bg = C.transparent, gui = C.transparent }),
    Include({ fg = C.purple, bg = C.transparent, gui = "italic" }),
    Define({ fg = C.purple, bg = C.transparent, gui = "italic" }),
    Conditional({ fg = C.red, bg = C.transparent, gui = "italic" }),
    Repeat({ fg = C.red, bg = C.transparent, gui = C.transparent }),
    Keyword({ fg = C.red, bg = C.transparent, gui = "italic" }),
    Typedef({ fg = C.red, bg = C.transparent, gui = "italic" }),
    Exception({ fg = C.red, bg = C.transparent, gui = "italic" }),
    Statement({ fg = C.red, bg = C.transparent, gui = "italic" }),
    Error({ fg = C.red, bg = C.transparent }),
    StorageClass({ fg = C.orange, bg = C.transparent }),
    Tag({ fg = C.orange, bg = C.transparent }),
    Label({ fg = C.orange, bg = C.transparent }),
    Structure({ fg = C.orange, bg = C.transparent }),
    Operator({ fg = C.orange, bg = C.transparent }),
    Title({ fg = C.orange, bg = C.transparent, gui = "bold" }),
    Special({ fg = C.fg.darken(20), bg = C.transparent, gui = "bold" }),
    SpecialChar({ fg = C.yellow, bg = C.transparent }),
    Type({ fg = C.yellow, bg = C.transparent }),
    Class({ fg = C.orange }),
    Module({ fg = C.green, bg = C.transparent }),
    Method({ fg = C.purple }),
    Function({ fg = C.green, bg = C.transparent }),
    String({ fg = C.green, bg = C.transparent }),
    Character({ fg = C.green, bg = C.transparent }),
    Constant({ fg = C.aqua, bg = C.transparent }),
    Macro({ fg = C.aqua, bg = C.transparent }),
    Identifier({ fg = C.blue, bg = C.transparent }),
    SpecialComment({ fg = C.grey1, bg = C.transparent, gui = "italic" }),
    Todo({ fg = C.purple, bg = C.transparent, gui = "italic" }),
    Delimiter({ fg = C.fg, bg = C.transparent }),
    Ignore({ fg = C.grey1, bg = C.transparent }),
    Debug({ fg = C.orange, bg = C.transparent }), --    debugging statements
    debugPC({ fg = C.bg0, bg = C.green }), --    debugging statements
    debugBreakpoint({ fg = C.bg0, bg = C.red }), --    debugging statements
    Bold({ gui = "bold" }),
    Italic({ gui = "italic" }),
    Underlined({ fg = C.transparent, bg = "NONE", gui = "underline" }),
    CurrentWord({ bg = C.fg, fg = C.bg0 }),
    Fg({ fg = C.fg, bg = C.transparent }),
    Grey({ fg = C.grey1, bg = C.transparent }),
    Red({ fg = C.red, bg = C.transparent }),
    Orange({ fg = C.orange, bg = C.transparent }),
    Yellow({ fg = C.yellow, bg = C.transparent }),
    Green({ fg = C.green, bg = C.transparent }),
    Aqua({ fg = C.aqua, bg = C.transparent }),
    Blue({ fg = C.blue, bg = C.transparent }),
    Purple({ fg = C.purple, bg = C.transparent }),
    RedItalic({ fg = C.red, bg = C.transparent, gui = "italic" }),
    OrangeItalic({ fg = C.orange, bg = C.transparent, gui = "italic" }),
    YellowItalic({ fg = C.yellow, bg = C.transparent, gui = "italic" }),
    GreenItalic({ fg = C.green, bg = C.transparent, gui = "italic" }),
    AquaItalic({ fg = C.cyan, bg = C.transparent, gui = "italic" }),
    BlueItalic({ fg = C.blue, bg = C.transparent, gui = "italic" }),
    PurpleItalic({ fg = C.purple, bg = C.transparent, gui = "italic" }),
    PurpleBold({ fg = C.purple, bg = C.transparent, gui = "bold" }),

    RedSign({ fg = C.red, bg = C.bg1 }),
    OrangeSign({ fg = C.orange, bg = C.bg1 }),
    YellowSign({ fg = C.yellow, bg = C.bg1 }),
    GreenSign({ fg = C.green, bg = C.bg1 }),
    AquaSign({ fg = C.cyan, bg = C.bg1 }),
    BlueSign({ fg = C.blue, bg = C.bg1 }),
    PurpleSign({ fg = C.purple, bg = C.bg1 }),

    ---- :help diagnostic-highlight ----------------------------

    DiagnosticOk({ fg = C.green, bg = C.transparent }),
    DiagnosticError({ fg = C.red, bg = C.transparent }),
    DiagnosticWarn({ fg = C.orange, bg = C.transparent }),
    DiagnosticInfo({ fg = C.cyan, bg = C.transparent }),
    DiagnosticHint({ fg = C.grey2, bg = C.transparent }),

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

    DiagnosticSignOk({ DiagnosticOk }),
    DiagnosticSignError({ DiagnosticError }),
    DiagnosticSignWarn({ DiagnosticWarn }),
    DiagnosticSignInfo({ DiagnosticInfo }),
    DiagnosticSignHint({ DiagnosticHint }),

    -- DiagnosticSignErrorText({ DiagnosticError, bg = C.bg_dark, sp = C.red, gui = "italic,undercurl,bold" }),
    -- DiagnosticSignWarnText({ DiagnosticWarn, bg = C.bg_dark, sp = C.orange, gui = "italic,bold" }),
    -- DiagnosticSignInfoText({ gui = "italic,bold" }),
    -- DiagnosticSignHintText({ gui = "italic,bold" }),

    DiagnosticSignErrorText({ DiagnosticError }),
    DiagnosticSignWarnText({ DiagnosticWarn }),
    DiagnosticSignInfoText({}),
    DiagnosticSignHintText({}),
    -- DiagnosticSignHintText({ fg = C.red, bg = C.red, sp = C.red, gui = "underline" }),

    DiagnosticSignErrorLine({ DiagnosticSignErrorText }),
    DiagnosticSignWarnLine({ DiagnosticSignWarnText }),
    DiagnosticSignInfoLine({ DiagnosticSignInfoText }),
    DiagnosticSignHintLine({ DiagnosticSignHintText }),
    -- DiagnosticSignHintLine({ fg = C.red, bg = C.bg_dark, sp = C.red, gui = "" }),

    DiagnosticSignErrorNum({ DiagnosticError }),
    DiagnosticSignWarnNum({ DiagnosticWarn }),
    DiagnosticSignInfoNum({ DiagnosticInfo }),
    DiagnosticSignHintNum({ DiagnosticHint }),
    -- DiagnosticSignHintNum({ fg = C.red, bg = C.bg_dark, sp = C.red, gui = "" }),

    DiagnosticSignErrorCursorLine({ fg = DiagnosticError.fg, gui = "bold" }),
    DiagnosticSignWarnCursorLine({ fg = DiagnosticWarn.fg, gui = "bold" }),
    DiagnosticSignInfoCursorLine({ fg = DiagnosticInfo.fg, gui = "bold" }),
    DiagnosticSignHintCursorLine({ fg = DiagnosticHint.fg, gui = "bold" }),
    -- DiagnosticSignHintCursorLine({ fg = C.red, bg = C.bg_dark, sp = C.red, gui = "underline" }),

    DiagnosticErrorBorder({ DiagnosticError }),
    DiagnosticWarnBorder({ DiagnosticWarn }),
    DiagnosticInfoBorder({ DiagnosticInfo }),
    DiagnosticHintBorder({ DiagnosticHint }),

    -- affects individual bits of code that are errored:
    DiagnosticUnderlineError({
      fg = C.transparent,
      bg = C.bg_dark,
      sp = DiagnosticError.fg,
      gui = "undercurl,bold,italic",
    }),
    DiagnosticUnderlineWarn({ fg = C.transparent, bg = C.bg_dark, sp = DiagnosticWarn.fg, gui = "italic,bold" }),
    DiagnosticUnderlineInfo({ fg = C.transparent, bg = C.bg_dark, sp = DiagnosticInfo.fg, gui = "italic" }),
    DiagnosticUnderlineHint({ fg = C.transparent, bg = C.bg_dark, sp = DiagnosticHint.fg, gui = "italic" }),

    ---- :help lsp-highlight -----------------------------------

    LspReferenceText({ bg = C.transparent, gui = "underline" }),
    LspReferenceRead({ bg = C.transparent, gui = "underline" }),
    LspReferenceWrite({ DiagnosticInfo, bg = C.bg_dark, gui = "underline,bold,italic" }),

    LspCodeLens({ DiagnosticInfo, fg = C.bg2 }), -- Used to color the virtual text of the codelens,
    LspCodeLensSeparator({ DiagnosticHint }),

    LspInlayHint({ NonText }),
    LspInfoBorder({ FloatBorder }),
    LspSignatureActiveParameter({ Visual }),
    SnippetTabstop({ Visual }),

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

    ---- :help mini.notify -----------------------------------------------------

    MiniNotifyNormal({ NotifyFloat, fg = C.grey2 }),

    ---- :help health ----------------------------------------------------------

    healthError({ Red }),
    healthSuccess({ Green }),
    healthWarning({ Yellow }),

    ---- :help headlines.txt -------------------------------------------

    Headline1({ fg = C.green, bg = C.bg_green, gui = "bold,italic" }),
    Headline2({ fg = C.yellow, bg = C.bg_yellow, gui = "bold" }),
    Headline3({ fg = C.red, bg = C.bg_red, gui = "italic" }),
    Headline4({ fg = C.purple, bg = C.bg0, gui = "bold,italic" }),
    Headline5({ fg = C.blue, bg = C.bg0, gui = "bold" }),
    Headline6({ fg = C.orange, bg = C.bg0, gui = "italic" }),
    Dash({ fg = C.bg3, gui = "bold" }),
    CodeBlock({ bg = C.bg1 }),

    ---- :help nvim-treesitter-highlights (external plugin) ----
    -- https://github.com/folke/tokyonight.nvim/blob/main/lua/tokyonight/treesitter.lua#L20
    -- REF: https://github.com/rose-pine/neovim/blob/main/lua/rose-pine/theme.lua#L205-L261

    sym("@headline1")({ Headline1 }),
    sym("@headline2")({ Headline2 }),
    sym("@headline3")({ Headline3 }),
    sym("@headline4")({ Headline4 }),
    sym("@headline5")({ Headline5 }),
    sym("@headline6")({ Headline6 }),
    sym("@dash")({ Dash }),
    sym("@codeblock")({ CodeBlock }),

    sym("@text.title.1.markdown")({ Headline1 }),
    sym("@text.title.2.markdown")({ Headline2 }),
    sym("@text.title.3.markdown")({ Headline3 }),
    sym("@text.title.4.markdown")({ Headline4 }),
    sym("@text.title.5.markdown")({ Headline5 }),
    sym("@text.title.6.markdown")({ Headline6 }),

    -- sym("@attribute")({ Cyan }),
    -- sym("@attribute.typescript")({ Blue }),
    -- sym("@boolean")({ link = "Boolean" }),
    -- sym("@character")({ link = "Character" }),
    -- sym("@comment")({ fg = C.bg_yellow, fmt = cfg.code_style.comments }),
    -- sym("@keyword.conditional")({ link = "Conditional" }),
    -- sym("@keyword.conditional.ternary")({ link = "Operator" }),
    -- sym("@constant")({ link = "Constant" }),
    -- sym("@constant.builtin")({ link = "Constant" }),
    -- sym("@constant.macro")({ link = "Constant" }),
    -- sym("@constructor")({ fg = C.yellow, fmt = "bold" }),
    -- sym("@constructor.lua")({ fg = C.yellow, fmt = "none" }),
    -- sym("@error")({ link = "Error" }),
    -- sym("@keyword.exception")({ link = "Exception" }),
    -- sym("@variable.member")({ Cyan }),
    -- sym("@number.float")({ link = "Float" }),
    -- sym("@function")({ link = "Function" }),
    -- sym("@function.builtin")({ fg = C.orange, fmt = cfg.code_style.functions }),
    -- sym("@function.macro")({
    --   fg = const_purple,
    --   fmt = cfg.code_style.functions,
    -- }),
    -- sym("@keyword.import")({ link = "Include" }),
    -- sym("@keyword")({ link = "Keyword" }),
    -- sym("@keyword.coroutine")({ link = "Keyword" }),
    -- sym("@keyword.operator")({ link = "Keyword" }),
    -- sym("@label")({ link = "Label" }),
    -- sym("@function.method")({ link = "Function" }),
    -- sym("@module")({ fg = light_blue, fmt = cfg.code_style.namespaces }),
    -- sym("@module.builtin")({ link = "@variable.builtin" }),
    -- sym("@number")({ link = "Number" }),
    -- sym("@operator")({ link = "Operator" }),
    -- sym("@variable.parameter")({ fg = C.coral, fmt = cfg.code_style.parameters }),
    -- sym("@variable.parameter.builtin")({
    --   fg = C.red,
    --   fmt = cfg.code_style.parameters,
    -- }),
    -- sym("@keyword.directive")({ link = "PreProc" }),
    -- sym("@property")({ link = "@variable.member" }),
    -- sym("@punctuation.delimiter")({ link = "Delimiter" }),
    -- sym("@punctuation.bracket")({ link = "Delimiter" }),
    -- sym("@punctuation.special")({ link = "Special" }),
    -- sym("@keyword.repeat")({ link = "Repeat" }),
    -- sym("@keyword.storage")({ link = "StorageClass" }),
    -- sym("@string")({ link = "String" }),
    -- sym("@string.documentation")({ link = "@comment" }),
    -- sym("@string.regexp")({ fg = C.orange }),
    -- sym("@string.escape")({ fg = C.coral }),
    -- sym("@string.special")({ link = "Special" }),
    -- sym("@string.special.symbol")({ link = "@variable.member" }),
    -- sym("@tag")({ Purple }),
    -- sym("@tag.attribute")({ link = "@variable.member" }),
    -- sym("@tag.delimiter")({ link = "Delimiter" }),
    -- sym("@none")({ Fg }),
    -- sym("@markup.strong.markdown_inline")({ fg = C.orange, fmt = "bold" }),
    -- sym("@markup.italic.markdown_inline")({ fg = C.orange, fmt = "italic" }),
    -- sym("@markup.quote")({ fg = util.blend(C.fg, C.light_grey, 0.5) }),
    -- sym("@string.special.url")({ fg = C.cyan, fmt = "underline,italic" }),
    -- sym("@comment.error")({ fg = C.black, bg = C.red, fmt = "bold" }),
    -- sym("@comment.warning")({ fg = C.black, bg = C.orange, fmt = "bold" }),
    -- sym("@comment.todo")({ link = "Todo" }),
    -- sym("@comment.note")({ fg = C.black, bg = C.blue, fmt = "bold" }),
    -- sym("@diff.plus")({ link = "DiffAdd" }),
    -- sym("@diff.minus")({ link = "DiffDelete" }),
    -- sym("@diff.delta")({ link = "DiffChange" }),
    -- sym("@type")({ link = "Type" }),
    -- sym("@type.builtin")({ link = "Type" }),
    -- sym("@type.qualifier")({ fg = C.purple, fmt = "italic" }),
    -- sym("@variable")({ fg = C.fg, fmt = cfg.code_style.variables }),
    -- sym("@variable.builtin")({ fg = C.red, fmt = cfg.code_style.variables }),
    -- sym("@variable.global")({
    --   fg = util.lighten(C.red, 0.375),
    --   fmt = cfg.code_style.variables,
    -- }),

    sym("@annotation")({ Purple }),
    sym("@attribute")({ Purple }),
    sym("@boolean")({ fg = C.magenta.li(5) }),
    sym("@character")({ Yellow }),
    sym("@class")({ Blue }),
    sym("@character.special")({ Yellow }),
    sym("@conditional")({ Red }),
    sym("@constant")({ PurpleItalic }),
    sym("@constant.builtin")({ PurpleItalic }),
    sym("@constant.macro")({ Purple }),
    sym("@constructor")({ Fg }),
    sym("@emphasis")({ fg = C.transparent, bg = "NONE", gui = "italic" }),
    sym("@exception")({ Red }),
    sym("@field")({ fg = C.green }),
    sym("@float")({ Purple }),
    sym("@function")({ Blue }),
    sym("@function.builtin")({ Green }),
    sym("@function.macro")({ Green }),
    sym("@function.call")({ fg = C.cyan }),
    sym("@include")({ PurpleItalic }),
    sym("@interface")({ Purple }),
    sym("@keyword")({ Red, gui = "" }),
    sym("@keyword.function")({ fg = C.pale_red, gui = "bold,italic" }),
    sym("@keyword.return")({ fg = C.pale_red, gui = "bold,italic" }),
    sym("@keyword.operator")({ fg = C.red }),
    sym("@label")({ Orange }),
    sym("@macro")({ Green, gui = "italic" }),

    sym("@markup.list")({ Special }),
    sym("@markup.link.label")({ Tag }),
    sym("@markup.strong")({ fg = C.fg, gui = "bold" }),
    sym("@markup.italic")({ fg = C.fg, gui = "italic" }),
    sym("@markup.underline")({ fg = C.fg, gui = "underline" }),
    sym("@markup.strikethrough")({ fg = C.fg, gui = "strikethrough" }),
    sym("@markup.heading")({ fg = C.orange, gui = "bold" }),
    sym("@markup.heading.1")({ fg = C.red, gui = "bold" }),
    sym("@markup.heading.1.marker")({ sym("@markup.heading") }),
    sym("@markup.heading.2")({ fg = C.yellow, gui = "bold" }),
    sym("@markup.heading.2.marker")({ sym("@markup.heading") }),
    sym("@markup.heading.3")({ fg = C.green, gui = "bold" }),
    sym("@markup.heading.3.marker")({ sym("@markup.heading") }),
    sym("@markup.heading.4")({ fg = C.cyan, gui = "bold" }),
    sym("@markup.heading.4.marker")({ sym("@markup.heading") }),
    sym("@markup.heading.5")({ fg = C.blue, gui = "bold" }),
    sym("@markup.heading.5.marker")({ sym("@markup.heading") }),
    sym("@markup.heading.6")({ fg = C.purple, gui = "bold" }),
    sym("@markup.heading.6.marker")({ sym("@markup.heading") }),
    sym("@markup.raw")({ Green }),
    sym("@markup.raw.delimiter")({ fg = C.light_grey }),
    sym("@markup.link.url")({ fg = C.cyan, gui = "underline,italic" }),
    sym("@markup.list.checked")({ fg = C.yellow, gui = "bold" }),
    sym("@markup.list.unchecked")({ fg = C.light_grey, gui = "bold" }),
    sym("@markup.math")({ fg = C.light_blue }),
    sym("@markup.link")({ Tag }),
    sym("@markup.environment")({ fg = C.cyan, gui = "bold" }),
    sym("@markup.environment.name")({ Type }),
    sym("@markup.strikethrough.markdown_inline")({
      fg = C.orange,
      gui = "strikethrough",
    }),
    sym("@method")({ Green }),
    sym("@namespace")({ BlueItalic, fg = C.bright_blue }),
    sym("@number")({ Purple }),
    sym("@operator")({ Orange }),
    sym("@parameter")({ fg = C.orange.li(25) }),
    sym("@parameter.reference")({ Fg }),
    sym("@property")({ fg = C.cyan.li(5) }),
    sym("@punctuation")({ Fg }),
    sym("@punctuation.bracket")({ sym("@punctuation") }),
    sym("@punctuation.delimiter")({ sym("@punctuation") }),
    sym("@punctuation.special")({ sym("@punctuation") }),
    sym("@punctuation.tilda")({ Dash, fg = Dash.fg.li(10) }),
    sym("@repeat")({ Red }),
    sym("@regex")({ Yellow }),
    sym("@string")({ Yellow }),
    sym("@string.regex")({ Blue }),
    sym("@string.escape")({ Purple }),
    sym("@string.special")({ Purple }),
    sym("@strong")({ fg = C.transparent, bg = "NONE", gui = "bold" }),
    sym("@structure")({ Orange }),
    sym("@symbol")({ Green }),
    sym("@tag")({ Orange }),
    sym("@tag.delimiter")({ Green }),
    sym("@tag.attribute")({ Green }),
    sym("@text")({ Green }),
    sym("@text.strong")({ gui = "bold" }),
    sym("@text.emphasis")({ gui = "italic" }),
    sym("@text.underline")({ gui = "underline" }),
    sym("@text.strike")({ gui = "strikethrough" }),
    sym("@text.math")({ Green }),
    sym("@text.environment")({ Green }),
    sym("@text.environment.name")({ Green }),
    sym("@text.title")({ sym("@text.underline") }),
    sym("@text.uri")({ fg = C.blue }),
    sym("@text.quote")({ fg = C.fg.da(30), gui = "italic" }),
    sym("@text.reference")({ fg = C.cyan }),
    sym("@type")({ Aqua }),
    sym("@type.builtin")({ BlueItalic }),
    sym("@underline")({ fg = C.transparent, bg = "NONE", gui = "underline" }),
    sym("@uri")({ fg = C.blue, bg = C.transparent, gui = "underline" }),
    sym("@variable")({ fg = C.fg }),
    sym("@variable.builtin")({ PurpleItalic }),
    sym("@variable.lua")({ fg = C.fg }),
    sym("@variable.member")({ fg = C.purple }),
    sym("@variable.member.lua")({ fg = C.cyan }),
    sym("@comment")({ fg = C.light_grey, gui = "italic" }),
    sym("@error")({ gui = "undercurl", sp = C.red }),
    sym("@error.heex")({ gui = C.transparent, sp = C.transparent }),
    sym("@error.elixir")({ gui = C.transparent, sp = C.transparent }),

    -- highlight WARN:/FIXME:/TODO:/NOTE:/REF: comments

    sym("@comment.fix")({ bg = C.red, fg = C.bg_dark, gui = "bold,underline" }),
    sym("@comment.error")({ bg = C.red, fg = C.bg_dark, gui = "bold" }),
    sym("@comment.warn")({ bg = C.orange, fg = C.bg1, gui = "bold" }),
    sym("@comment.todo")({ fg = C.orange, bg = C.bg1, gui = nil }),
    sym("@comment.note")({ fg = C.grey0, bg = C.bg_dark, gui = "italic" }),
    sym("@comment.ref")({ fg = C.bright_blue, bg = C.bg_dark, gui = "italic" }),

    sym("@text.danger")({ sym("@comment.fix") }),
    sym("@text.warn")({ sym("@comment.warn") }),
    sym("@text.todo")({ sym("@comment.todo") }),
    sym("@text.note")({ sym("@comment.note") }),
    sym("@text.ref")({ sym("@comment.ref") }),

    sym("@text.gitcommit")({ fg = C.fg, gui = nil }),
    sym("@text.title.gitcommit")({ fg = C.green, gui = nil }),
    sym("@keyword.gitcommit")({ bg = C.red, fg = C.bg_dark, gui = nil }),

    -- lsp semantic tokens highlights ------------------------------------------
    -- sym("@lsp.type.enum")({ sym("@type") }),
    -- sym("@lsp.type.keyword")({ sym("@keyword") }),
    -- sym("@lsp.type.interface")({ Identifier }),
    -- sym("@lsp.type.namespace")({ sym("@namespace") }),
    -- sym("@lsp.type.parameter")({ sym("@parameter") }),
    -- sym("@lsp.type.property")({ sym("@property") }),
    -- sym("@lsp.typemod.function.defaultLibrary")({ Special }),
    -- sym("@lsp.typemod.variable.defaultLibrary")({ sym("@variable.builtin") }),

    -- Neovim LSP semantic tokens.
    -- LSP Semantic token highlights
    sym("@lsp.mod.deprecated")({ sym("@constant") }),
    sym("@lsp.mod.readonly")({ sym("@constant") }),
    sym("@lsp.mod.typeHint")({ sym("@type") }),
    sym("@lsp.type.boolean")({ sym("@boolean") }),
    sym("@lsp.type.builtinConstant")({ sym("@constant.builtin") }),
    sym("@lsp.type.builtinType")({ sym("@type.builtin") }),
    sym("@lsp.type.class")({ sym("@type") }),
    -- disable comment highlighting, see the following issue:
    -- https://github.com/LuaLS/lua-language-server/issues/1809
    sym("@lsp.type.comment")({}),
    -- sym("@lsp.type.comment")({ sym("@comment") }),
    sym("@lsp.type.decorator")({ sym("@function") }),
    sym("@lsp.type.derive")({ sym("@constructor") }),
    sym("@lsp.type.deriveHelper")({ sym("@attribute") }),
    sym("@lsp.type.enum")({ sym("@type") }),
    sym("@lsp.type.enumMember")({ sym("@property") }),
    sym("@lsp.type.escapeSequence")({ sym("@string.escape") }),
    sym("@lsp.type.formatSpecifier")({ sym("@punctuation.special") }),
    sym("@lsp.type.function")({ sym("@function") }),
    sym("@lsp.type.generic")({ sym("@text") }),
    sym("@lsp.type.interface")({ sym("@type") }),
    sym("@lsp.type.keyword")({ sym("@keyword") }),
    -- sym("@lsp.type.lifetime")({ sym("@storageclass.lifetime") }),
    sym("@lsp.type.macro")({ sym("@constant.macro") }),
    sym("@lsp.type.magicFunction")({ sym("@function.builtin") }),
    sym("@lsp.type.method")({ sym("@method") }),
    -- sym("@lsp.type.modifier")({ sym("@type.qualifier") }),
    sym("@lsp.type.namespace")({ sym("@namespace") }),
    -- sym("@lsp.type.namespace.go")({ sym("@namespace.go") }),
    sym("@lsp.type.number")({ sym("@number") }),
    sym("@lsp.type.operator")({ sym("@operator") }),
    sym("@lsp.type.parameter")({ sym("@parameter") }),
    sym("@lsp.type.property")({ sym("@property") }),
    sym("@lsp.type.regexp")({ sym("@string.regex") }),
    sym("@lsp.type.selfKeyword")({ sym("@variable.builtin") }),
    sym("@lsp.type.selfParameter")({ sym("@variable.builtin") }),
    sym("@lsp.type.selfTypeKeyword")({ sym("@type") }),
    sym("@lsp.type.string")({ sym("@string") }),
    sym("@lsp.type.struct")({ sym("@type") }),
    sym("@lsp.type.type")({ sym("@type") }),
    -- sym("@lsp.type.typeAlias")({ sym("@type.definition") }),
    -- sym("@lsp.type.typeParameter")({ sym("@type.definition") }),
    sym("@lsp.type.variable")({ sym("@variable") }),
    sym("@lsp.typemod.class.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.enum.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.enumMember.defaultLibrary")({ sym("@constant.builtin") }),
    sym("@lsp.typemod.function.defaultLibrary")({ sym("@function.builtin") }),
    sym("@lsp.typemod.function.readonly")({ sym("@method") }),
    sym("@lsp.typemod.keyword.async")({ sym("@keyword") }),
    sym("@lsp.typemod.keyword.injected")({ sym("@keyword") }),
    sym("@lsp.typemod.macro.defaultLibrary")({ sym("@function.builtin") }),
    sym("@lsp.typemod.method.defaultLibrary")({ sym("@function.builtin") }),
    -- sym("@lsp.typemod.method.readonly")({ "@method" }),
    sym("@lsp.typemod.operator.injected")({ sym("@operator") }),
    sym("@lsp.typemod.string.injected")({ sym("@string") }),
    sym("@lsp.typemod.struct.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.type.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.typeAlias.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.variable.callable")({ sym("@function") }),
    sym("@lsp.typemod.variable.constant.rust")({ sym("@constant") }),
    sym("@lsp.typemod.variable.defaultLibrary")({ sym("@variable.builtin") }),
    -- sym("@lsp.typemod.variable.defaultLibrary.go")({ sym("@constant.builtin.go") }),
    sym("@lsp.typemod.variable.defaultLibrary.javascript")({ sym("@constant.builtin") }),
    sym("@lsp.typemod.variable.defaultLibrary.javascriptreact")({ sym("@constant.builtin") }),
    sym("@lsp.typemod.variable.defaultLibrary.typescript")({ sym("@constant.builtin") }),
    sym("@lsp.typemod.variable.defaultLibrary.typescriptreact")({ sym("@constant.builtin") }),
    sym("@lsp.typemod.variable.global")({ sym("@constant") }),
    sym("@lsp.typemod.variable.injected")({ sym("@variable") }),
    sym("@lsp.typemod.variable.readonly")({ sym("@constant") }),
    -- sym("@lsp.typemod.variable.static")({ sym("@constant") }),
    sym("@lsp.typemod.variable.static")({ Red }),

    -- @constant.elixir links to PurpleItalic elixir
    -- @comment.documentation.elixir links to @comment elixir
    -- @constant.elixir links to PurpleItalic elixir
    -- @string.elixir links to Yellow elixir
    -- @comment.documentation.elixir links to @comment elixir
    -- @markup.raw.block.markdown links to Special markdown

    sym("@markup.raw.block.markdown")({ sym("@comment") }),

    ---- :help treesitter-context ----------------------------------------------

    TreesitterContext({ bg = C.bg1 }),
    -- TreesitterContextLineNumber({ CursorLineNr, bg = TreesitterContext.bg, gui = C.transparent }),
    TreesitterContextSeparator({ fg = C.bg_dark, bg = TreesitterContext.bg }),

    -- TS: Markdown
    -- sym("@markdown.punct.special") {Special},
    -- sym("@markdown.punct.special") { Special },
    -- sym("@markdown.string.escape") { SpecialKey },
    -- sym("@markdown.text.reference") { Identifier, gui = "underline" },
    -- sym("@markdown.emphasis") { fg = grey1, bg = transparent, gui = "italic" },
    sym("@markdown.title")({ Statement, bg = C.bg1, fg = C.red }),
    -- sym("@markdown.literal") { Type },
    -- sym("@markdown.uri") { sym("@uri") },

    markdownCode({ fg = C.grey1, bg = C.bg1 }),
    -- markdownLinkText({ sym("@markdown.text.reference") }),

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

    DiffAdd({ fg = C.transparent, bg = C.bg_green }), -- diff mode: Added line |diff.txt|
    DiffChange({ fg = C.transparent, bg = C.bg_yellow }), -- diff mode: Changed line |diff.txt|
    DiffDelete({ fg = C.transparent, bg = C.bg_red }), -- diff mode: Deleted line |diff.txt|
    DiffText({ fg = C.transparent, bg = C.bg_blue }), -- diff mode: Changed text within a changed line |diff.txt|
    DiffBase({ fg = C.transparent, bg = C.bg_dark.li(10) }), -- diff mode: Changed text within a changed line |diff.txt|

    GitConflictCurrent({ DiffAdd }),
    GitConflictIncoming({ DiffText }),
    GitConflictAncestor({ DiffBase }),
    GitConflictCurrentLabel({ DiffAdd, bg = C.green.da(20) }),
    GitConflictIncomingLabel({ DiffText, bg = C.blue.da(20) }),
    GitConflictAncestorLabel({ DiffBase, bg = C.grey1.da(20) }),

    sym("@text.diff.add")({ DiffAdd }),
    sym("@text.diff.change")({ DiffChange }),
    sym("@text.diff.delete")({ DiffDelete }),
    sym("@text.diff.text")({ DiffText }),
    sym("@text.diff.base")({ DiffBase }),

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

    helpNote({ fg = C.purple, gui = "bold" }),
    helpHeadline({ fg = C.red, gui = "bold" }),
    helpHeader({ fg = C.orange, gui = "bold" }),
    helpURL({ fg = C.green, gui = "underline" }),
    helpHyperTextEntry({ fg = C.yellow, gui = "bold" }),
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
    CmpItemAbbrDeprecated({ fg = C.grey1, gui = "strikethrough" }),

    CmpDocumentation({ fg = C.fg, bg = C.bg1 }),
    CmpDocumentationBorder({ fg = C.fg, bg = C.bg1 }),

    CmpItemAbbr({ fg = C.fg }),
    CmpItemAbbrMatch({ fg = C.cyan, gui = "bold,italic" }),
    CmpItemAbbrMatchFuzzy({ fg = C.yellow, gui = "italic" }),
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

    SimpleF({ fg = C.magenta, bg = C.bg_dark, gui = "bold,underline" }),

    ---- :help indent-blankline ------------------------------------------------

    IndentBlanklineChar({ fg = C.bg1.li(3), bg = C.transparent }),
    IndentBlanklineContextChar({ fg = C.bg_blue, bg = C.transparent }),
    IndentBlanklineContextStart({ sp = C.bg_blue.li(10), bg = C.transparent, gui = "underline" }),

    ---- :help mini.indentscope ------------------------------------------------
    MiniIndentscopeSymbol({ fg = C.teal.lighten(10) }),

    ---- :help mini.jump.txt / mini.jump2d.txt  --------------------------------

    MiniJump({ fg = C.blue, bg = C.bg_blue, gui = "bold,underline" }),
    MiniJump2dSpot({ fg = C.purple, bg = C.bg_purple, gui = "bold,underline" }),
    MiniJump2dSpotAhead({ fg = C.green, bg = C.bg_green, gui = "bold,underline" }),
    MiniJump2dSpotUnique({ fg = C.red, bg = C.bg_red, gui = "bold,underline" }),
    MiniJump2dDim({ Comment }),

    ---- :help mini.hipatterns -------------------------------------------------

    MiniHipatternsFixme({ sym("@comment.fix") }),
    MiniHipatternsError({ sym("@comment.error") }),
    MiniHipatternsWarn({ sym("@comment.warn") }),
    MiniHipatternsHack({ sym("@comment.warn") }),
    MiniHipatternsTodo({ sym("@comment.todo") }),
    MiniHipatternsNote({ sym("@comment.note") }),
    MiniHipatternsRef({ sym("@comment.ref"), gui = "bold" }),

    ---- :help leap.txt --------------------------------------------------------

    LeapBackdrop({ fg = "#707070" }),
    LeapLabelPrimary({ bg = C.transparent, fg = "#ccff88", gui = "italic" }),
    LeapLabelSecondary({ bg = C.transparent, fg = "#99ccff" }),
    LeapLabelSelected({ bg = C.transparent, fg = "Magenta" }),

    ---- :help tabline ---------------------------------------------------------

    TabLine({ fg = "#abb2bf", bg = C.bg_dark }),
    TabLineHead({ fg = C.bg_dark, bg = C.bg_dark }),
    -- TabLineHead({ fg = C.bg1, bg = C.bg2 }),
    TabLineTabActive({ fg = C.green, bg = C.bg0, gui = "bold" }),
    TabLineWinActive({ fg = C.green, bg = C.bg0, gui = "italic" }),
    TabLineInactive({ fg = C.grey2, bg = C.bg1 }),
    TabFill({ bg = C.bg_dark }),
    NavicSeparator({ bg = C.bg_dark }),

    ---- :help megaterm  -----------------------------------------------------

    DarkenedPanel({ bg = C.bg1 }),
    DarkenedStatusline({ bg = C.bg1 }),
    DarkenedStatuslineNC({ gui = "italic", bg = C.bg1 }),

    ---- sidebar  -----------------------------------------------------

    PanelBackground({ fg = C.fg.darken(10), bg = C.bg0.darken(15) }),
    PanelBorder({ fg = PanelBackground.bg.darken(10), bg = PanelBackground.bg }),
    PanelHeading({ PanelBackground, gui = "bold" }),
    PanelVertSplit({ VertSplit, bg = C.bg0.darken(8) }),
    PanelStNC({ PanelVertSplit }),
    PanelSt({ bg = C.bg_blue.darken(20) }),

    ---- megaline -- :help statusline ------------------------------------------

    StatusLine({ fg = C.grey1, bg = C.bg1 }), -- status line of current window
    StatusLineNC({ fg = C.grey1, bg = C.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    StInactive({ fg = C.bg_dark.lighten(20), bg = C.bg_dark, gui = "italic" }),
    StModeNormal({ bg = C.bg2, fg = C.bg5, gui = C.transparent }),
    StModeInsert({ bg = C.bg2, fg = C.green, gui = "bold" }),
    StModeVisual({ bg = C.bg2, fg = C.magenta, gui = "bold" }),
    StModeReplace({ bg = C.bg2, fg = C.dark_red, gui = "bold" }),
    StModeCommand({ bg = C.bg2, fg = C.green, gui = "bold" }),
    StModeTermNormal({ StModeNormal, bg = C.bg1 }),
    StModeTermInsert({ StModeTermNormal, fg = C.green, gui = "bold,italic", sp = C.green }),
    StMetadata({ Comment, bg = C.bg1 }),
    StMetadataPrefix({ Comment, bg = C.bg1 }),
    StIndicator({ fg = C.dark_blue, bg = C.bg1 }),
    StModified({ fg = C.pale_red, bg = C.bg1, gui = "bold,italic" }),
    StModifiedIcon({ fg = C.pale_red, bg = C.bg1, gui = "bold" }),
    StGitSymbol({ fg = C.light_red, bg = C.bg1 }),
    StGitBranch({ fg = C.blue, bg = C.bg1 }),
    StGitSigns({ fg = C.dark_blue, bg = C.bg1 }),
    StGitSignsAdd({ GreenSign, bg = C.bg1 }),
    StGitSignsDelete({ RedSign, bg = C.bg1 }),
    StGitSignsChange({ OrangeSign, bg = C.bg1 }),
    StNumber({ fg = C.purple, bg = C.bg1 }),
    StCount({ fg = C.bg0, bg = C.blue, gui = "bold" }),
    StPrefix({ fg = C.fg, bg = C.bg2 }),
    StDirectory({ bg = C.bg1, fg = C.grey0, gui = "italic" }),
    StParentDirectory({ bg = C.bg1, fg = C.blue, gui = "" }),
    StFilename({ bg = C.bg1, fg = C.fg, gui = "bold" }),
    StFilenameInactive({ fg = C.light_grey, bg = C.bg1, gui = "italic,bold" }),
    StIdentifier({ fg = C.blue, bg = C.bg1 }),
    StTitle({ bg = C.bg1, fg = C.grey2, gui = "bold" }),
    StComment({ Comment, bg = C.bg1 }),
    StLineNumber({ fg = C.grey2, bg = C.bg1, gui = "bold" }),
    StLineSep({ fg = C.grey1, bg = C.bg1, gui = "" }),
    StLineTotal({ fg = C.grey1, bg = C.bg1 }),
    StLineColumn({ fg = C.grey1, bg = C.bg1, gui = "italic" }),
    StClient({ bg = C.bg1, fg = C.fg, gui = "bold" }),
    StError({ DiagnosticError, bg = C.bg1 }),
    StWarn({ DiagnosticWarn, bg = C.bg1 }),
    StInfo({ DiagnosticInfo, bg = C.bg1, gui = "bold" }),
    StHint({ DiagnosticHint, bg = C.bg1 }),

    ---- :help statuscolumn  ---------------------------------------------------------

    StatusColumnActiveBorder({ bg = C.bg1, fg = "#7c8378" }),
    StatusColumnActiveLineNr({ fg = "#7c8378" }),
    StatusColumnInactiveBorder({ bg = NormalNC.bg, fg = C.bg_dark.li(15) }),
    StatusColumnInactiveLineNr({ fg = C.bg_dark.li(10) }),
    -- StatusColumnBuffer({}),
    --
    -- [[%#StatusColumnBorder#]], -- HL

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

    ---- :help rainbow-delimiters  ---------------------------------------------

    RainbowDelimiterRed({ fg = C.red }),
    RainbowDelimiterYellow({ fg = C.yellow }),
    RainbowDelimiterBlue({ fg = C.blue }),
    RainbowDelimiterOrange({ fg = C.orange }),
    RainbowDelimiterGreen({ fg = C.green }),
    RainbowDelimiterViolet({ fg = C.purple }),
    RainbowDelimiterCyan({ fg = C.cyan }),

    ---- :help telescope -------------------------------------------------------

    TelescopeNormal({ fg = C.fg, bg = C.bg3.darken(25) }),
    TelescopeBorder({ fg = C.bg0, bg = C.bg3.darken(25) }),
    TelescopeMatching({ Title }),
    TelescopeTitle({ Normal, gui = "bold" }),

    TelescopePreviewTitle({ fg = C.fg, bg = C.bg_blue, gui = "italic" }),
    -- darkens the whole preview panel + my faux-no-border
    TelescopePreviewBorder({ bg = PanelBackground.bg, fg = C.transparent }),
    TelescopePreviewNormal({ bg = PanelBackground.bg, fg = C.transparent }),

    TelescopePrompt({ bg = C.bg2.darken(10) }),
    TelescopePromptPrefix({ fg = C.orange, bg = C.bg2.darken(10) }),
    TelescopePromptBorder({ fg = C.bg2.darken(10), bg = C.bg2.darken(10) }),
    TelescopePromptNormal({ fg = C.fg, bg = C.bg2.darken(10) }),
    TelescopePromptTitle({ fg = C.bg0, bg = C.bg_cyan }),

    TelescopeSelection({ bg = C.bg3, gui = "bold,italic" }),
    TelescopeSelectionCaret({ fg = C.fg, bg = C.bg3 }),
    TelescopeResults({ bg = C.transparent }),
    TelescopeResultsTitle({ fg = C.bg0, bg = C.fg, gui = "bold" }),

    EgrepifySuffix({ fg = C.bright_blue.darken(20), bg = C.bg_dark.lighten(5) }),

    ---- :help fzf-lua ---------------------------------------------------------
    -- REF: https://github.com/ibhagwan/fzf-lua#highlights

    FzfLuaNormal({ fg = C.fg }),
    FzfLuaBorder({}),
    FzfLuaTitle({ fg = C.orange }),
    FzfLuaInfo({ fg = C.bg4 }),
    FzfLuaHeader({ fg = C.orange }),
    FzfLuaPrompt({ fg = C.cyan, gui = "italic" }),
    FzfLuaSeparator({ FzfLuaInfo }),

    FzfLuaScrollBorderFull({ TelescopePromptNormal }),
    FzfLuaScrollBorderEmpty({ TelescopePromptNormal }),

    FzfLuaPreviewNormal({ TelescopePreviewNormal }),
    FzfLuaPreviewBorder({ TelescopePreviewBorder }),
    FzfLuaPreviewTitle({ TelescopePreviewTitle }),

    ---- :help: trouble.txt ----------------------------------------------------

    TroubleNormal({ PanelBackground }),
    TroubleText({ PanelBackground }),
    TroubleIndent({ PanelVertSplit }),
    TroubleFoldIcon({ fg = C.yellow, gui = "bold" }),
    TroubleLocation({ fg = Comment.fg }),
    TroublePreview({ bg = C.bg_visual, gui = "bold,italic,underline" }),

    ---- :help: dap ------------------------------------------------------------

    DapBreakpoint({ fg = C.light_red }),
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
    BqfPreviewTitle({ bg = C.bg_dark, fg = C.brown }), -- or WinSeparator
    BqfPreviewBorder({ bg = C.bg_dark, fg = C.bg_blue }), -- or WinSeparator

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

    GitSignsAdd({ fg = C.bright_green }),
    GitSignsDelete({ fg = C.red }),
    GitSignsChange({ fg = C.orange }),

    GitSignsAddCursorLine({ fg = C.bright_green, bg = C.bg_dark }),
    GitSignsDeleteCursorLine({ fg = C.red, bg = C.bg_dark }),
    GitSignsChangeCursorLine({ fg = C.orange, bg = C.bg_dark }),

    GitSignsAddNum({ fg = C.bright_green }),
    GitSignsDeleteNum({ fg = C.red }),
    GitSignsChangeNum({ fg = C.orange }),

    ---- tmux-popup ------------------------------------------------------------

    TmuxPopupNormal({ bg = C.bg1 }),

    ---- virt-column -----------------------------------------------------------

    VirtColumn({ Whitespace, bg = C.bg0 }),

    ---- flash.nvim.txt --------------------------------------------------------

    FlashBackdrop({ Comment }),
    FlashMatch({ Search }),
    FlashCurrent({ IncSearch }),
    FlashLabel({ fg = C.bright_blue_alt, bg = C.bg_blue, gui = "bold,underline" }),

    ---- neorg -----------------------------------------------------------------

    sym("@neorg.headings.1.title")({ gui = "italic" }),
    sym("@neorg.headings.2.title")({ gui = "italic" }),
    sym("@neorg.headings.3.title")({ gui = "italic" }),
    sym("@neorg.headings.4.title")({ gui = "italic" }),
    sym("@neorg.headings.5.title")({ gui = "italic" }),
    sym("@neorg.headings.6.title")({ gui = "italic" }),

    ---- symbol-usage ----------------------------------------------------------
    SymbolUsageRounding({ CursorLine, gui = "italic" }),
    SymbolUsageContent({ fg = C.bg_dark.li(18), gui = "italic" }),
    SymbolUsageRef({ fg = Function.fg, bg = C.transparent, gui = "italic" }),
    SymbolUsageDef({ fg = Type.fg, bg = C.transparent, gui = "italic" }),
    SymbolUsageImpl({ fg = Keyword.fg, bg = C.transparent, gui = "italic" }),

    ---- oil -------------------------------------------------------------------
    OilDir({ Directory }),
    OilDirIcon({ Directory }),
    OilLink({ Constant }),
    OilLinkTarget({ Comment }),
    OilCopy({ DiagnosticSignHint, gui = "bold" }),
    OilMove({ DiagnosticSignWarn, gui = "bold" }),
    OilChange({ DiagnosticSignWarn, gui = "bold" }),
    OilCreate({ DiagnosticSignInfo, gui = "bold" }),
    OilDelete({ DiagnosticSignError, gui = "bold" }),
    OilPermissionNone({ NonText }),
    OilPermissionRead({ DiagnosticSignWarn }),
    OilPermissionWrite({ DiagnosticSignError }),
    OilPermissionExecute({ DiagnosticSignOk }),
    OilTypeDir({ Directory }),
    OilTypeFifo({ Special }),
    OilTypeFile({ NonText }),
    OilTypeLink({ Constant }),
    OilTypeSocket({ Keyword }),
  }
end)

return theme
