local ok, lush = pcall(require, "lush")
if not ok then
  print("lush not found, not loading theme")
  return
end

local C = require("mega.lush_theme.colors")
local colors = C
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

local norm_fg = C.fg
local norm_bg = C.bg0

local dark_red = C.dark_red
local orange = C.orange
local brown = "#CE9178"
local yellow = C.yellow
local yellow_orange = "#D7BA7D"
local green = C.green
local blue_green = "#4EC9B0"
local light_green = "#B5CEA8"
local blue = "#4fc1ff"
local light_blue = "#9CDCFE"
local dark_blue = "#569CD6"
local cornflower_blue = "#6796E6"
local dark_pink = "#C586C0"
local bright_pink = "#f92672"
local purple = C.purple

local white = "#ffffff"
local gray = "#51504f"
local gray2 = "#858585" -- LineNr (editorLineNumber.foreground)
local gray3 = "#808080"
local black = "#2d2d2d" -- TabLine
local black2 = "#252526" -- Statusline, TabLineFill, Pmenu
local black3 = "#2a2d2e" -- CursorLine (list.hoverBackground from VSCode)

local error_red = C.lsp.error
local warn_yellow = C.lsp.warn
local info_blue = C.lsp.info
local hint_gray = C.lsp.hint
local ok_green = "#89d185" -- color for success, so I use notebookStatusSuccessIcon.foreground

local comment = C.light_grey
local selected_item_bg = "#04395e"
local matched_chars = "#2aaaff"
local folded_blue = "#202d39" -- editor.foldBackground
local float_border_fg = "#454545"
local indent_guide_fg = "#404040"
local indent_guide_scope_fg = "#707070"
local label_fg = "#c8c8c8"

---@diagnostic disable
local theme = lush(function(injected_functions)
  local sym = injected_functions.sym

  return {
    --
    -- Preset
    --
    TabBorder({ fg = black2 }), -- tab.border, border to separate tabs from each other
    FloatBorder({ fg = float_border_fg }),
    SelectionHighlightBackground({ bg = "#333a40" }),
    LightBulb({ fg = "#ffcc00" }),
    CodeLens({ fg = "#999999" }),
    GutterGitAdded({ fg = "#487e02" }),
    GutterGitDeleted({ fg = "#f14c4c" }),
    GutterGitModified({ fg = "#1b81a8" }),
    Breadcrumb({ fg = "#a9a9a9", bg = norm_bg }),
    ScrollbarSlider({ bg = "#424242" }),
    PeekViewBorder({ fg = "#3794ff" }),
    PeekViewNormal({ bg = "#001f33" }),
    PeekViewTitle({ fg = white }), -- peekViewTitleLabel.foreground
    PeekViewCursorLine({ bg = "#002f4e" }),
    PeekViewMatchHighlight({ bg = "#996214" }), -- peekViewEditor.matchHighlightBackground
    GhostText({ fg = "#6b6b6b" }),
    Icon({ fg = "#c5c5c5" }),
    Description({ fg = "#989898" }), -- descriptionForeground
    ProgressBar({ fg = "#0e70c0" }), -- progressBar.background
    MatchedCharacters({ fg = matched_chars }), -- editorSuggestWidget.highlightForeground
    Hint({ MatchedCharacters }), -- for the hint letter in options, e.g., the q in [q]uickfix
    -- For the unused code, use Identifier's fg (9cdcfe) as the base color,
    -- editorUnnecessaryCode.opacity is 000000aa (the alpha value is aa),
    -- so the color will be 9cdcfeaa. Converting hexa to hex gets 729db4.
    UnnecessaryCode({ fg = "#729db4" }),
    -- Git diff
    DiffTextAdded({ bg = "#386229" }),
    DiffTextDeleted({ bg = "#781212" }),
    DiffTextChanged({ bg = "#0000ff" }),
    DiffLineAdded({ bg = "#373d29" }),
    DiffLineDeleted({ bg = "#4b1818" }),
    DiffLineChanged({ bg = "#0e2f44" }),
    -- Quickfix list (can be used to define qf syntax, e.g.,
    -- ~/.config/nvim/syntax/qf.vim)
    QfFileName({ fg = white }),
    QfSelection({ bg = "#3a3d41" }), -- terminal.inactiveSelectionBackground
    QfText({ fg = "#bbbbbb" }), -- normal text in quickfix list
    -- Inline hints
    InlayHint({ fg = "#969696", bg = "#232323" }), -- editorInlayHint.foreground/background
    InlayHintType({ InlayHint }), -- editorInlayHint.typeBackground/typeForeground

    --
    -- Editor
    --
    CursorLine({ bg = black3 }),
    CursorColumn({ bg = black3 }),
    ColorColumn({ bg = black2 }), -- #5a5a5a in VSCode (editorRuler.foreground) it's too bright
    Conceal({ fg = gray2 }),
    Cursor({ fg = gray, bg = "#aeafad" }),
    -- lCursor { },
    -- CursorIM { },
    Directory({ fg = dark_blue }),
    DiffAdd({ DiffLineAdded }),
    DiffDelete({ DiffLineDeleted }),
    DiffChange({ DiffLineChanged }),
    DiffText({ DiffTextChanged }),
    EndOfBuffer({ fg = norm_bg }),
    -- TermCursor { },
    -- TermCursorNC { },
    ErrorMsg({ fg = error_red }),
    WinSeparator({ fg = "#444444" }), -- editorGroup.border
    VirtSplit({ WinSeparator }), -- deprecated and use WinSeparator instead
    LineNr({ fg = gray2 }),
    CursorLineNr({ fg = "#c6c6c6" }),
    Folded({ bg = folded_blue }),
    CursorLineFold({ CursorLineNr }),
    FoldColumn({ LineNr }), -- #c5c5c5 in VSCode (editorGutter.foldingControlForeground) and it's too bright
    SignColumn({ bg = norm_bg }),
    IncSearch({ bg = "#515c6a" }),
    -- Substitute { },
    MatchParen({ bg = gray, gui = "bold, underline" }),
    ModeMsg({ fg = norm_fg }),
    MsgArea({ fg = norm_fg }),
    -- MsgSeparator { },
    MoreMsg({ fg = norm_fg }),
    NonText({ fg = gray2 }),
    Normal({ fg = norm_fg, bg = norm_bg }),
    -- NormalNC { },
    Pmenu({ fg = norm_fg, bg = black2 }),
    PmenuSel({ fg = white, bg = selected_item_bg }),
    -- PmenuKind = {},
    -- PmenuKindSel = {},
    -- PmenuExtra = {},
    -- PmenuExtraSel = {},
    PmenuSbar({ bg = black2 }),
    PmenuThumb({ bg = "#474747" }),
    PmenuMatch = { fg = matched_chars, bg = norm_bg },
    PmenuMatchSel = { fg = matched_chars, bg = selected_item_bg, bold = true },
    NormalFloat({ Pmenu }),
    Question({ fg = dark_blue }),
    QuickFixLine({ QfSelection }),
    Search({ bg = "#613214" }),
    SpecialKey({ NonText }),
    SpellBad({ gui = "undercurl", sp = error_red }),
    SpellCap({ gui = "undercurl", sp = warn_yellow }),
    SpellLocal({ gui = "undercurl", sp = info_blue }),
    SpellRare({ gui = "undercurl", sp = info_blue }),
    StatusLine({ bg = black2 }),
    StatusLineNC({ fg = gray, bg = black2 }),
    TabLine({ fg = "#8f8f8f", bg = black }),
    TabLineFill({ fg = "NONE", bg = black2 }),
    TabLineSel({ fg = white, bg = norm_bg }),
    Title({ fg = dark_blue, gui = "bold" }),
    Visual({ bg = "#264F78" }),
    -- VisualNOS { },
    WarningMsg({ fg = warn_yellow }),
    Whitespace({ fg = "#3e3e3d" }),
    WildMenu({ PmenuSel }),
    Winbar({ Breadcrumb }),
    WinbarNC({ Breadcrumb }),

    --
    -- Syntax
    --
    Comment({ fg = comment, gui = "italic" }),

    Constant({ fg = dark_blue }),
    String({ fg = brown }),
    Character({ Constant }),
    Number({ fg = light_green }),
    Boolean({ Constant }),
    Float({ Number }),

    Identifier({ fg = light_blue }),
    Function({ fg = yellow }),

    Statement({ fg = dark_pink }),
    Conditional({ Statement }),
    Repeat({ Statement }),
    Label({ Statement }),
    Operator({ fg = norm_fg }),
    Keyword({ fg = dark_blue }),
    Exception({ Statement }),

    PreProc({ fg = dark_pink }),
    Include({ PreProc }),
    Define({ PreProc }),
    Macro({ PreProc }),
    PreCondit({ PreProc }),

    Type({ fg = dark_blue }),
    StorageClass({ Type }),
    Structure({ Type }),
    Typedef({ Type }),

    Special({ fg = yellow_orange }),
    SpecialChar({ Special }),
    Tag({ Special }),
    Delimiter({ Special }),
    SpecialComment({ Special }),
    Debug({ Special }),

    Underlined({ gui = "underline" }),
    -- Ignore { },
    Error({ fg = error_red }),
    Todo({ fg = norm_bg, bg = yellow_orange, gui = "bold" }),

    --
    -- diff
    --
    -- VSCode doesn't have foreground for git added/removed/changed, so here I
    -- use the corresponding colors for gutter instead.
    diffAdded({ GutterGitAdded }),
    diffRemoved({ GutterGitDeleted }),
    diffChanged({ GutterGitModified }),

    --
    -- LSP
    --
    LspReferenceText({ SelectionHighlightBackground }),
    LspReferenceRead({ SelectionHighlightBackground }),
    LspReferenceWrite({ SelectionHighlightBackground }),
    LspCodeLens({ CodeLens }),
    -- LspCodeLensSeparator { }, -- Used to color the separator between two or more code lens.
    LspSignatureActiveParameter({ MatchedCharacters }),
    LspInlayHint({ InlayHint }),

    --
    -- Diagnostics
    --
    DiagnosticError({ fg = error_red }),
    DiagnosticWarn({ fg = warn_yellow }),
    DiagnosticInfo({ fg = info_blue }),
    DiagnosticHint({ fg = hint_gray }),
    DiagnosticOk({ fg = ok_green }),
    DiagnosticVirtualTextError({ DiagnosticError, bg = "#332323" }),
    DiagnosticVirtualTextWarn({ DiagnosticWarn, bg = "#2f2c1b" }),
    DiagnosticVirtualTextInfo({ DiagnosticInfo, bg = "#212a35" }),
    DiagnosticVirtualTextHint({ DiagnosticHint, bg = black }),
    DiagnosticVirtualTextOk({ DiagnosticOk, bg = "#233323" }),
    DiagnosticUnderlineError({ gui = "undercurl", sp = error_red }),
    DiagnosticUnderlineWarn({ gui = "undercurl", sp = warn_yellow }),
    DiagnosticUnderlineInfo({ gui = "undercurl", sp = info_blue }),
    DiagnosticUnderlineHint({ gui = "undercurl", sp = hint_gray }),
    DiagnosticUnderlineOk({ gui = "undercurl", sp = ok_green }),
    DiagnosticFloatingError({ DiagnosticError }),
    DiagnosticFloatingWarn({ DiagnosticWarn }),
    DiagnosticFloatingInfo({ DiagnosticInfo }),
    DiagnosticFloatingHint({ DiagnosticHint }),
    DiagnosticFloatingOk({ DiagnosticOk }),
    DiagnosticSignError({ DiagnosticError }),
    DiagnosticSignWarn({ DiagnosticWarn }),
    DiagnosticSignInfo({ DiagnosticInfo }),
    DiagnosticSignHint({ DiagnosticHint }),
    DiagnosticSignOk({ DiagnosticOk }),
    DiagnosticUnnecessary({ UnnecessaryCode, gui = "underdashed" }),
    DiagnosticDeprecated({ fg = gray3, gui = "strikethrough" }),

    --
    -- Treesitter
    --
    -- Use the capture names directly as the highlight groups.
    -- To find all the capture names, see https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md#highlights)

    -- Identifiers
    sym("@variable")({ fg = light_blue }), -- various variable names
    sym("@variable.builtin")({ fg = dark_blue }), -- built-in variable names (e.g. `this`)
    sym("@variable.parameter")({ fg = orange }), -- parameters of a function, use a conspicuous color (VSCode uses the common light_blue)
    sym("@variable.parameter.builtin")({ sym("@variable.parameter") }), -- special parameters (e.g. `_`, `it`)
    sym("@variable.member")({ fg = light_blue }), -- object and struct fields

    sym("@constant")({ Constant }), -- constant identifiers
    sym("@constant.builtin")({ Constant }), -- built-in constant values
    sym("@constant.macro")({ Constant }), -- constants defined by the preprocessor

    sym("@module")({ fg = blue_green }), -- modules or namespaces
    sym("@module.builtin")({ sym("@module") }), -- built-in modules or namespaces
    sym("@label")({ fg = label_fg }), -- GOTO and other labels (e.g. `label:` in C), including heredoc labels

    -- Literals
    sym("@string")({ String }), -- string literals
    sym("@string.documentation")({ fg = brown }), -- string documenting code (e.g. Python docstrings)
    sym("@string.regexp")({ fg = dark_red }), -- regular expressions
    sym("@string.escape")({ fg = yellow_orange }), -- escape sequences
    sym("@string.special")({ SpecialChar }), -- other special strings (e.g. dates)
    sym("@string.special.symbol")({ sym("@string.special") }), -- symbols or atoms
    sym("@string.special.url")({ sym("@string.special") }), -- URIs (e.g. hyperlinks), it's url outside markup
    sym("@string.special.path")({ sym("@string.special") }), -- filenames

    sym("@character")({ Character }), -- character literals
    sym("@character.special")({ SpecialChar }), -- special characters (e.g. wildcards)

    sym("@boolean")({ Boolean }), -- boolean literals
    sym("@number")({ Number }), -- numeric literals
    sym("@number.float")({ Float }), -- floating-point number literals

    -- Types
    sym("@type")({ fg = blue_green }), -- type or class definitions and annotations
    sym("@type.builtin")({ fg = dark_blue }), -- built-in types
    sym("@type.definition")({ fg = blue_green }), -- identifiers in type definitions (e.g. `typedef <type> <identifier>` in C)

    sym("@attribute")({ fg = blue_green }), -- attribute annotations (e.g. Python decorators)
    sym("@attribute.builtin")({ sym("@attribute") }), -- builtin annotations (e.g. `@property` in Python)
    sym("@property")({ sym("@variable.member") }), -- the key in key/value pairs

    -- Function
    sym("@function")({ Function }), -- function definitions
    sym("@function.builtin")({ Function }), -- built-in functions
    sym("@function.call")({ Function }), -- function calls
    sym("@function.macro")({ Function }), -- preprocessor macros

    sym("@function.method")({ sym("@function") }), -- method definitions
    sym("@function.method.call")({ sym("@function.call") }), -- method calls

    sym("@constructor")({ fg = blue_green }), -- constructor calls and definitions
    sym("@operator")({ Operator }), -- symbolic operators (e.g. `+` / `*`)

    -- Keyword
    sym("@keyword")({ Keyword }), -- keywords not fitting into specific categories
    sym("@keyword.coroutine")({ fg = dark_pink }), -- keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)
    sym("@keyword.function")({ fg = dark_blue }), -- keywords that define a function (e.g. `func` in Go, `def` in Python)
    sym("@keyword.operator")({ sym("@operator") }), -- operators that are English words (e.g. `and` / `or`)
    sym("@keyword.import")({ Include }), -- keywords for including modules (e.g. `import` / `from` in Python)
    sym("@keyword.type")({ fg = dark_blue }), -- keywords describing composite types (e.g. `struct`, `enum`)
    sym("@keyword.modifier")({ fg = dark_blue }), -- keywords modifying other constructs (e.g. `const`, `static`, `public`)
    sym("@keyword.repeat")({ Repeat }), -- keywords related to loops (e.g. `for` / `while`)
    sym("@keyword.return")({ fg = dark_pink }), --  keywords like `return` and `yield`
    sym("@keyword.debug")({ Debug }), -- keywords related to debugging
    sym("@keyword.exception")({ Exception }), -- keywords related to exceptions (e.g. `throw` / `catch`)

    sym("@keyword.conditional")({ Conditional }), -- keywords related to conditionals (e.g. `if` / `else`)
    sym("@keyword.conditional.ternary")({ sym("@operator") }), -- ternary operator (e.g. `?` / `:`)

    sym("@keyword.directive")({ PreProc }), -- various preprocessor directives & shebangs
    sym("@keyword.directive.define")({ sym("@keyword.directive") }), -- preprocessor definition directives

    -- Punctuation
    sym("@punctuation.delimiter")({ fg = norm_fg }), -- delimiters (e.g. `;` / `.` / `,`)
    sym("@punctuation.bracket")({ fg = norm_fg }), -- brackets (e.g. `()` / `{}` / `[]`)
    sym("@punctuation.special")({ fg = dark_blue }), -- special symbols (e.g. `{}` in string interpolation)

    -- Comments
    sym("@comment")({ Comment }), -- line and block comments
    sym("@comment.documentation")({ sym("@comment") }), -- comments documenting code

    sym("@comment.error")({ fg = error_red }), -- error-type comments (e.g., `DEPRECATED:`)
    sym("@comment.warning")({ fg = warn_yellow }), -- warning-type comments (e.g., `WARNING:`, `FIX:`)
    sym("@comment.hint")({ fg = hint_gray }), -- note-type comments (e.g., `NOTE:`)
    sym("@comment.info")({ fg = info_blue }), -- info-type comments
    sym("@comment.todo")({ Todo }), -- todo-type comments (e.g-, `TODO:`, `WIP:`)

    -- Markup
    sym("@markup.strong")({ fg = norm_fg, gui = "bold" }), -- bold text
    sym("@markup.italic")({ fg = norm_fg, gui = "italic" }), -- text with emphasis
    sym("@markup.strikethrough")({ fg = norm_fg, gui = "strikethrough" }), -- strikethrough text
    sym("@markup.underline")({ fg = norm_fg, gui = "underline" }), -- underlined text (only for literal underline markup!)

    sym("@markup.heading")({ Title }), -- headings, titles (including markers)
    sym("@markup.heading.1")({ sym("@markup.heading") }),
    sym("@markup.heading.2")({ sym("@markup.heading") }),
    sym("@markup.heading.3")({ sym("@markup.heading") }),
    sym("@markup.heading.4")({ sym("@markup.heading") }),
    sym("@markup.heading.5")({ sym("@markup.heading") }),
    sym("@markup.heading.6")({ sym("@markup.heading") }),

    sym("@markup.quote")({ fg = green }), -- block quotes
    sym("@markup.math")({ fg = blue_green }), -- math environments (e.g. `$ ... $` in LaTeX)

    sym("@markup.link")({ fg = brown }), -- text references, footnotes, citations, etc.
    sym("@markup.link.label")({ sym("@markup.link") }), -- non-url links
    sym("@markup.link.url")({ sym("@markup.link") }), -- url links in markup

    sym("@markup.raw")({ fg = brown }), -- literal or verbatim text (e.g., inline code)
    sym("@markup.raw.block")({ fg = norm_fg }), -- literal or verbatim text as a stand-alone block

    sym("@markup.list")({ fg = cornflower_blue }), -- list markers
    -- sym("@markup.list.checked") { }, -- checked todo-style list markers
    -- sym("@markup.list.unchecked") { }, -- unchecked todo-style list markers

    sym("@diff.plus")({ DiffTextAdded }), -- added text (for diff files)
    sym("@diff.minus")({ DiffTextDeleted }), -- deleted text (for diff files)
    sym("@diff.delta")({ DiffTextChanged }), -- changed text (for diff files)

    sym("@tag")({ fg = dark_blue }), -- XML tag names
    sym("@tag.builtin")({ sym("@tag") }), -- builtin tag names (e.g. HTML5 tags)
    sym("@tag.attribute")({ fg = light_blue }), -- XML tag attributes
    sym("@tag.delimiter")({ fg = gray3 }), -- XML tag delimiters

    -- Language specific
    -- Lua
    sym("@variable.member.lua")({ fg = blue_green }),

    --
    -- LSP semantic tokens
    --
    -- The help page :h lsp-semantic-highlight
    -- A short guide: https://gist.github.com/swarn/fb37d9eefe1bc616c2a7e476c0bc0316
    -- Token types and modifiers are described here: https://code.visualstudio.com/api/language-extensions/semantic-highlight-guide
    sym("@lsp.type.namespace")({ sym("@module") }),
    sym("@lsp.type.type")({ sym("@type") }),
    sym("@lsp.type.class")({ sym("@type") }),
    sym("@lsp.type.enum")({ sym("@keyword.type") }),
    sym("@lsp.type.interface")({ sym("@type") }),
    sym("@lsp.type.struct")({ sym("@type") }),
    sym("@lsp.type.typeParameter")({ sym("@type.definition") }),
    sym("@lsp.type.parameter")({ sym("@variable.parameter") }),
    sym("@lsp.type.variable")({ sym("@variable") }),
    sym("@lsp.type.property")({ sym("@property") }),
    sym("@lsp.type.enumMember")({ fg = blue }),
    sym("@lsp.type.event")({ sym("@type") }),
    sym("@lsp.type.function")({ sym("@function") }),
    sym("@lsp.type.method")({ sym("@function") }),
    sym("@lsp.type.macro")({ sym("@constant.macro") }),
    sym("@lsp.type.keyword")({ sym("@keyword") }),
    sym("@lsp.type.comment")({ sym("@comment") }),
    sym("@lsp.type.string")({ sym("@string") }),
    sym("@lsp.type.number")({ sym("@number") }),
    sym("@lsp.type.regexp")({ sym("@string.regexp") }),
    sym("@lsp.type.operator")({ sym("@operator") }),
    sym("@lsp.type.decorator")({ sym("@attribute") }),
    sym("@lsp.type.escapeSequence")({ sym("@string.escape") }),
    sym("@lsp.type.formatSpecifier")({ fg = light_blue }),
    sym("@lsp.type.builtinType")({ sym("@type.builtin") }),
    sym("@lsp.type.typeAlias")({ sym("@type.definition") }),
    sym("@lsp.type.unresolvedReference")({ gui = "undercurl", sp = error_red }),
    sym("@lsp.type.lifetime")({ sym("@keyword.modifier") }),
    sym("@lsp.type.generic")({ sym("@variable") }),
    sym("@lsp.type.selfKeyword")({ sym("@variable.builtin") }),
    sym("@lsp.type.selfTypeKeyword")({ sym("@variable.builtin") }),
    sym("@lsp.type.deriveHelper")({ sym("@attribute") }),
    sym("@lsp.type.modifier")({ sym("@keyword.modifier") }),
    sym("@lsp.typemod.type.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.typeAlias.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.class.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.variable.defaultLibrary")({ sym("@variable.builtin") }),
    sym("@lsp.typemod.function.defaultLibrary")({ sym("@function.builtin") }),
    sym("@lsp.typemod.method.defaultLibrary")({ sym("@function.builtin") }),
    sym("@lsp.typemod.macro.defaultLibrary")({ sym("@function.builtin") }),
    sym("@lsp.typemod.struct.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.enum.defaultLibrary")({ sym("@type.builtin") }),
    sym("@lsp.typemod.enumMember.defaultLibrary")({ sym("@constant.builtin") }),
    sym("@lsp.typemod.variable.readonly")({ fg = blue }),
    sym("@lsp.typemod.variable.callable")({ sym("@function") }),
    sym("@lsp.typemod.variable.static")({ sym("@constant") }),
    sym("@lsp.typemod.property.readonly")({ fg = blue }),
    sym("@lsp.typemod.keyword.async")({ sym("@keyword.coroutine") }),
    sym("@lsp.typemod.keyword.injected")({ sym("@keyword") }),
    -- Set injected highlights. Mainly for Rust doc comments and also works for
    -- other lsps that inject tokens in comments.
    -- Ref: https://github.com/folke/tokyonight.nvim/pull/340
    sym("@lsp.typemod.operator.injected")({ sym("@operator") }),
    sym("@lsp.typemod.string.injected")({ sym("@string") }),
    sym("@lsp.typemod.variable.injected")({ sym("@variable") }),

    -- Language specific
    -- Lua
    sym("@lsp.type.property.lua")({ sym("@variable.member.lua") }),

    --
    -- nvim-lspconfig
    --
    -- LspInfoTitle { },
    -- LspInfoList { },
    -- LspInfoFiletype { },
    -- LspInfoTip { },
    LspInfoBorder({ FloatBorder }),

    --
    -- nvim-cmp
    --
    CmpItemAbbrDeprecated({ fg = gray3, bg = "NONE", gui = "strikethrough" }),
    CmpItemAbbrMatch({ fg = matched_chars, bg = "NONE" }),
    CmpItemAbbrMatchFuzzy({ CmpItemAbbrMatch }),
    CmpItemMenu({ Description }),
    CmpItemKindText({ fg = "#cccccc", bg = "NONE" }),
    CmpItemKindMethod({ fg = "#b180d7", bg = "NONE" }),
    CmpItemKindFunction({ CmpItemKindMethod }),
    CmpItemKindConstructor({ CmpItemKindFunction }),
    CmpItemKindField({ fg = "#75beff", bg = "NONE" }),
    CmpItemKindVariable({ CmpItemKindField }),
    CmpItemKindClass({ fg = "#ee9d28", bg = "NONE" }),
    CmpItemKindInterface({ CmpItemKindField }),
    CmpItemKindModule({ CmpItemKindText }),
    CmpItemKindProperty({ CmpItemKindText }),
    CmpItemKindUnit({ CmpItemKindText }),
    CmpItemKindValue({ CmpItemKindText }),
    CmpItemKindEnum({ CmpItemKindClass }),
    CmpItemKindKeyword({ CmpItemKindText }),
    CmpItemKindSnippet({ CmpItemKindText }),
    CmpItemKindColor({ CmpItemKindText }),
    CmpItemKindFile({ CmpItemKindText }),
    CmpItemKindReference({ CmpItemKindText }),
    CmpItemKindFolder({ CmpItemKindText }),
    CmpItemKindEnumMember({ CmpItemKindField }),
    CmpItemKindConstant({ CmpItemKindText }),
    CmpItemKindStruct({ CmpItemKindText }),
    CmpItemKindEvent({ CmpItemKindClass }),
    CmpItemKindOperator({ CmpItemKindText }),
    CmpItemKindTypeParameter({ CmpItemKindText }),
    -- Predefined for the winhighlight config of cmp float window
    SuggestWidgetBorder({ FloatBorder }),
    SuggestWidgetSelect({ bg = selected_item_bg }),

    --
    -- Aerial
    --
    AerialTextIcon({ CmpItemKindText }),
    AerialMethodIcon({ CmpItemKindMethod }),
    AerialFunctionIcon({ CmpItemKindFunction }),
    AerialConstructorIcon({ CmpItemKindConstructor }),
    AerialFieldIcon({ CmpItemKindField }),
    AerialVariableIcon({ CmpItemKindVariable }),
    AerialClassIcon({ CmpItemKindClass }),
    AerialInterfaceIcon({ CmpItemKindInterface }),
    AerialModuleIcon({ CmpItemKindModule }),
    AerialPropertyIcon({ CmpItemKindProperty }),
    AerialUnitIcon({ CmpItemKindUnit }),
    AerialValueIcon({ CmpItemKindValue }),
    AerialEnumIcon({ CmpItemKindEnum }),
    AerialKeywordIcon({ CmpItemKindKeyword }),
    AerialSnippetIcon({ CmpItemKindSnippet }),
    AerialColorIcon({ CmpItemKindColor }),
    AerialFileIcon({ CmpItemKindFile }),
    AerialReferenceIcon({ CmpItemKindReference }),
    AerialFolderIcon({ CmpItemKindFolder }),
    AerialEnumMemberIcon({ CmpItemKindEnumMember }),
    AerialConstantIcon({ CmpItemKindConstant }),
    AerialStructIcon({ CmpItemKindStruct }),
    AerialEventIcon({ CmpItemKindEvent }),
    AerialOperatorIcon({ CmpItemKindOperator }),
    AerialTypeParameterIcon({ CmpItemKindTypeParameter }),

    --
    -- nvim-navic
    --
    NavicText({ Winbar }),
    NavicIconsFile({ CmpItemKindFile }),
    NavicIconsModule({ CmpItemKindModule }),
    NavicIconsNamespace({ NavicText }),
    NavicIconsPackage({ NavicText }),
    NavicIconsClass({ CmpItemKindClass }),
    NavicIconsMethod({ CmpItemKindMethod }),
    NavicIconsProperty({ CmpItemKindProperty }),
    NavicIconsField({ CmpItemKindField }),
    NavicIconsConstructor({ CmpItemKindConstructor }),
    NavicIconsEnum({ CmpItemKindEnum }),
    NavicIconsInterface({ CmpItemKindInterface }),
    NavicIconsFunction({ CmpItemKindFunction }),
    NavicIconsVariable({ CmpItemKindVariable }),
    NavicIconsConstant({ CmpItemKindConstant }),
    NavicIconsString({ NavicText }),
    NavicIconsNumber({ NavicText }),
    NavicIconsBoolean({ NavicText }),
    NavicIconsArray({ NavicText }),
    NavicIconsObject({ NavicText }),
    NavicIconsKey({ NavicText }),
    NavicIconsNull({ NavicText }),
    NavicIconsEnumMember({ CmpItemKindEnumMember }),
    NavicIconsStruct({ CmpItemKindStruct }),
    NavicIconsEvent({ CmpItemKindEvent }),
    NavicIconsOperator({ CmpItemKindOperator }),
    NavicIconsTypeParameter({ CmpItemKindTypeParameter }),
    NavicSeparator({ NavicText }),

    --
    -- Gitsigns
    --
    GitSignsAdd({ GutterGitAdded }),
    GitSignsChange({ GutterGitModified }),
    GitSignsDelete({ GutterGitDeleted }),
    GitSignsAddNr({ GitSignsAdd }),
    GitSignsChangeNr({ GitSignsChange }),
    GitSignsDeleteNr({ GitSignsDelete }),
    GitSignsAddLn({ DiffAdd }),
    GitSignsChangeLn({ DiffChange }),
    GitSignsDeleteLn({ DiffDelete }),
    GitSignsAddInline({ DiffTextAdded }),
    GitSignsChangeInline({ DiffTextChanged }),
    GitSignsDeleteInline({ DiffTextDeleted }),

    --
    -- vim-illuminate
    --
    IlluminatedWordText({ SelectionHighlightBackground }),
    IlluminatedWordRead({ SelectionHighlightBackground }),
    IlluminatedWordWrite({ SelectionHighlightBackground }),

    --
    -- Telescope
    --
    TelescopeBorder({ FloatBorder }),
    TelescopePromptBorder({ TelescopeBorder }),
    TelescopeResultsBorder({ TelescopePromptBorder }),
    TelescopePreviewBorder({ TelescopePromptBorder }),
    TelescopeSelection({ PmenuSel }),
    TelescopeSelectionCaret({ TelescopeSelection }),
    TelescopeMultiIcon({ fg = blue_green }),
    TelescopeMatching({ CmpItemAbbrMatch }),
    TelescopeNormal({ Normal }),
    TelescopePromptPrefix({ Icon }),

    --
    -- Harpoon
    --
    HarpoonBorder({ TelescopeBorder }),
    HarpoonWindow({ TelescopeNormal }),

    --
    -- fFHighlight
    --
    fFHintWords({ gui = "underline", sp = "yellow" }),
    fFHintCurrentWord({ gui = "undercurl", sp = "yellow" }),

    --
    -- indent-blankline
    --
    IblIndent({ fg = indent_guide_fg }),
    IblScope({ fg = indent_guide_scope_fg }),

    --
    -- hlslens
    --
    HlSearchNear({ IncSearch }),
    HlSearchLens({ Description }),
    HlSearchLensNear({ HlSearchLens }),

    --
    -- nvim-ufo
    --
    UfoPreviewBorder({ PeekViewBorder }),
    UfoPreviewNormal({ PeekViewNormal }),
    UfoPreviewCursorLine({ PeekViewCursorLine }),
    UfoFoldedFg({ fg = norm_fg }),
    UfoFoldedBg({ bg = folded_blue }),
    UfoCursorFoldedLine({ bg = "#2F3C48", gui = "bold, italic" }),
    UfoPreviewSbar({ PeekViewNormal }),
    UfoPreviewThumb({ bg = "#394a4b" }),
    UfoFoldedEllipsis({ fg = "#989ca0" }),

    --
    -- nvim-bqf
    --
    BqfPreviewFloat({ PeekViewNormal }),
    BqfPreviewBorder({ PeekViewBorder }),
    BqfPreviewTitle({ PeekViewTitle }),
    BqfPreviewSbar({ PmenuSbar }),
    BqfPreviewThumb({ PmenuThumb }),
    BqfPreviewCursor({ Cursor }),
    BqfPreviewCursorLine({ PeekViewCursorLine }),
    BqfPreviewRange({ PeekViewMatchHighlight }),
    BqfPreviewBufLabel({ Description }),
    BqfSign({ fg = blue_green }),

    --
    -- mg979/tabline.nvim
    --
    TSelect({ TabLineSel }),
    TVisible({ TabLine }),
    THidden({ TabLine }),
    TExtra({ TabLine }),
    TSpecial({ TabLine }),
    TFill({ TabLineFill }),
    TCorner({ fg = white, bg = black2 }),
    TNumSel({ TSelect }),
    TNum({ TabLine }),
    TSelectMod({ TSelect }),
    TVisibleMod({ TVisible }),
    THiddenMod({ THidden }),
    TExtraMod({ TExtra }),
    TSpecialMod({ TSpecial }),
    TSelectDim({ TSelect }),
    TVisibleDim({ TVisible }),
    THiddenDim({ THidden }),
    TExtraDim({ TExtra }),
    TSpecialDim({ TSpecial }),
    TSelectSep({ TabBorder }),
    TVisibleSep({ TabBorder }),
    THiddenSep({ TabBorder }),
    TExtraSep({ TabBorder }),
    TSpecialSep({ TabBorder }),

    --
    -- git-messenger.vim
    --
    gitmessengerHeader({ fg = "#3794ff" }), -- textLink.activeForeground
    gitmessengerPopupNormal({ NormalFloat }),
    gitmessengerHash({ NormalFloat }),
    gitmessengerHistory({ NormalFloat }),
    gitmessengerEmail({ NormalFloat }),

    --
    -- nvim-treesitter-context
    --
    -- TreesitterContext { bg = black4 },
    TreesitterContextLineNumber({ fg = "#5d5d5d" }), -- 30% darker based on LineNr
    TreesitterContextBottom({ gui = "underline", sp = FloatBorder.fg }),

    --
    -- nvim-scrollview
    --
    ScrollView({ ScrollbarSlider }),
    ScrollViewRestricted({ ScrollView }),
    ScrollViewConflictsTop({ DiffAdd }),
    ScrollViewConflictsMiddle({ DiffAdd }),
    ScrollViewConflictsBottom({ DiffAdd }),
    ScrollViewCursor({ CursorLineNr }),
    ScrollViewDiagnosticsError({ DiagnosticError }),
    ScrollViewDiagnosticsWarn({ DiagnosticWarn }),
    ScrollViewDiagnosticsHint({ DiagnosticHint }),
    ScrollViewDiagnosticsInfo({ DiagnosticInfo }),
    ScrollViewSearch({ fg = "#9e6a03" }),

    --
    -- vim-floaterm
    --
    Floaterm({ Normal }),
    FloatermBorder({ FloatBorder }),

    --
    -- quick-scope
    --
    QuickScopePrimary({ fg = bright_pink, gui = "underline", sp = bright_pink }),
    QuickScopeSecondary({ fg = purple, gui = "underline", sp = purple }),
  }
end)
---@diagnostic enable

return theme
