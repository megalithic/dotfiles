-- Megaforest theme for nvim_next
-- Ported from ~/.dotfiles/config/nvim/colors/megaforest.lua (everforest-inspired)
-- Following nightfox/gruvbox numbered conventions for palette organization
--
-- Palette organization:
--   1. Background colors (bg0-4, bg_dim) - numbered dark to light
--   2. Foreground colors (fg0-3, comment) - numbered bright to dim
--   3. Selection colors (sel0, sel1)
--   4. Accent colors (standard: red, orange, yellow, green, cyan, blue, magenta)
--   5. Semantic colors (git, diff, diagnostics)
--   6. Terminal colors
--
-- Original everforest mapping:
--   C.bg0 = #2e353c → bg0
--   C.bg1 = bg0.lighten(5) → bg1
--   C.bg2 = bg0.lighten(10) → bg2
--   C.bg3 = bg0.lighten(15) → bg3

mega.t.megaforest = {
  palette = {
    -- ══════════════════════════════════════════════════════════════════════════
    -- BACKGROUNDS (numbered 0-4, dark to light)
    -- bg0 = primary, bg1 = elevated, bg2 = float, bg3 = lines, bg4 = prominent
    -- ══════════════════════════════════════════════════════════════════════════
    bg_dim = "#2b3339", -- Deepest background (C.bg_hard)
    bg0 = "#272b30", -- Primary background (C.bg0 everforest)
    bg1 = "#3c474d", -- Elevated (statusline, tabline) (C.bg1)
    bg2 = "#3c474d", -- Float backgrounds, popups (C.bg1)
    bg3 = "#465258", -- Subtle lines, indent guides (C.bg2)
    bg4 = "#505a60", -- More prominent surfaces (C.bg3)
    bg5 = "#465258", -- Borders (subtle) (C.bg2)

    -- ══════════════════════════════════════════════════════════════════════════
    -- FOREGROUNDS (numbered 0-3, bright to dim)
    -- fg0 = primary text, fg1 = secondary, fg2 = tertiary, fg3 = very muted
    -- ══════════════════════════════════════════════════════════════════════════
    fg0 = "#d8caac", -- Primary text (C.fg - warm beige)
    fg1 = "#868d80", -- Secondary text (C.grey1)
    fg2 = "#7c8377", -- Tertiary/muted text (C.grey0)
    fg3 = "#5c6370", -- Very muted (line numbers) (C.light_grey)
    comment = "#7c8377", -- Comments, disabled text (C.grey0)

    -- Statusline uses slightly brighter text
    fg_bright = "#999f93", -- Statusline text (C.grey2)

    -- ══════════════════════════════════════════════════════════════════════════
    -- SELECTION
    -- ══════════════════════════════════════════════════════════════════════════
    sel0 = "#4a555b", -- Visual selection background
    sel1 = "#7c8377", -- Search/prominent highlight borders (C.grey0)

    -- ══════════════════════════════════════════════════════════════════════════
    -- ACCENT COLORS (standard names)
    -- These are the "hue" colors used for syntax and UI accents
    -- ══════════════════════════════════════════════════════════════════════════
    red = "#e67e80", -- Errors, diff deleted (C.red)
    orange = "#e39b7b", -- Numbers, booleans, constants (C.orange)
    yellow = "#d9bb80", -- Classes, warnings, search bg (C.yellow)
    green = "#a7c080", -- Strings, success, diff inserted (C.green)
    cyan = "#83b799", -- Support, regex, escape chars (C.cyan/aqua)
    blue = "#7fbbb3", -- Functions, info (C.blue)
    magenta = "#d39bb6", -- Keywords, storage (C.purple)
    purple = "#b4879e", -- Alternate/darker magenta (C.magenta)

    -- Theme-specific extras
    teal = "#15AABF", -- Accent for special elements (C.teal - vivid)
    silver = "#999f93", -- Constants, special (C.grey2)
    beige = "#d8caac", -- Identifiers, warm text (C.fg)

    -- ══════════════════════════════════════════════════════════════════════════
    -- SEMANTIC COLORS (git, diff)
    -- ══════════════════════════════════════════════════════════════════════════
    git_add = "#a7c080", -- green (C.green)
    git_change = "#7fbbb3", -- blue (C.blue)
    git_delete = "#e67e80", -- red (C.red)
    git_untracked = "#15AABF", -- teal (C.teal)
    git_staged = "#d39bb6", -- magenta (C.purple)

    diff_add = "#4e6053", -- Muted green background (C.bg_green)
    diff_delete = "#614b51", -- Muted red background (C.bg_red)
    diff_change = "#415c6d", -- Muted blue background (C.bg_blue)

    -- ══════════════════════════════════════════════════════════════════════════
    -- TERMINAL COLORS (0-15)
    -- ══════════════════════════════════════════════════════════════════════════
    terminal_black = "#2e353c", -- bg0
    terminal_red = "#e67e80", -- red
    terminal_green = "#a7c080", -- green
    terminal_yellow = "#d9bb80", -- yellow
    terminal_blue = "#7fbbb3", -- blue
    terminal_magenta = "#d39bb6", -- magenta
    terminal_cyan = "#83b799", -- cyan
    terminal_white = "#ffffff", -- white

    terminal_bright_black = "#505a60", -- bg4
    terminal_bright_red = "#c4696b", -- red darkened
    terminal_bright_green = "#8a9e6a", -- green darkened
    terminal_bright_yellow = "#c7a46d", -- yellow darkened
    terminal_bright_blue = "#6a9e97", -- blue darkened
    terminal_bright_magenta = "#b3849e", -- magenta darkened
    terminal_bright_cyan = "#6f9e7d", -- cyan darkened
    terminal_bright_white = "#7c8377", -- comment (muted white)
  },
}

function mega.t.megaforest.apply()
  vim.opt.termguicolors = true

  if vim.g.colors_name then
    vim.cmd("hi clear")
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "megaforest"

  local lush = require("lush")
  local p = mega.t.megaforest.palette

  vim.o.background = "dark"

  -- Terminal colors
  vim.g.terminal_color_0 = p.terminal_black
  vim.g.terminal_color_1 = p.terminal_red
  vim.g.terminal_color_2 = p.terminal_green
  vim.g.terminal_color_3 = p.terminal_yellow
  vim.g.terminal_color_4 = p.terminal_blue
  vim.g.terminal_color_5 = p.terminal_magenta
  vim.g.terminal_color_6 = p.terminal_cyan
  vim.g.terminal_color_7 = p.terminal_white
  vim.g.terminal_color_8 = p.terminal_bright_black
  vim.g.terminal_color_9 = p.terminal_bright_red
  vim.g.terminal_color_10 = p.terminal_bright_green
  vim.g.terminal_color_11 = p.terminal_bright_yellow
  vim.g.terminal_color_12 = p.terminal_bright_blue
  vim.g.terminal_color_13 = p.terminal_bright_magenta
  vim.g.terminal_color_14 = p.terminal_bright_cyan
  vim.g.terminal_color_15 = p.terminal_bright_white

  local color = {}

  for key, value in pairs(p) do
    color[key] = lush.hsl(value)
  end

  ---@diagnostic disable: undefined-global
  -- stylua: ignore start
  local theme = lush(function(fn)
    local sym = fn.sym

    return {
      -- ════════════════════════════════════════════════════════════════════
      -- EDITOR
      -- ════════════════════════════════════════════════════════════════════
      Normal { fg = color.fg0, bg = color.bg0 },
      NormalNC { bg = Normal.bg.darken(7) }, -- Inactive window: slightly darker

      -- ════════════════════════════════════════════════════════════════════
      -- SYNTAX (standard vim :h group-name)
      -- ════════════════════════════════════════════════════════════════════
      Comment { fg = color.comment, gui = "italic" },

      Constant { fg = color.silver },
      String { fg = color.green },
      Character { fg = color.teal },
      Number { fg = color.orange },
      Boolean { fg = color.orange },
      Float { fg = color.orange },

      Identifier { fg = color.beige },
      Function { fg = color.cyan },

      Statement { fg = color.purple },
      Conditional { Statement },
      Repeat { Statement },
      Label { fg = color.orange },
      Operator { fg = Normal.fg },
      Keyword { fg = color.magenta },
      Exception { Statement },

      PreProc { fg = color.magenta },
      Include { fg = color.blue, bold = true },
      Define { PreProc },
      PreCondit { PreProc },
      Macro { fg = color.orange },

      Type { fg = color.cyan },
      StorageClass { Type },
      Structure { Type },
      Typedef { Type },

      Special { fg = color.silver },
      SpecialChar { fg = color.cyan },
      Tag { fg = color.orange },
      Delimiter { fg = color.fg0 },
      SpecialComment { fg = color.comment, gui = "italic" },
      Debug { fg = color.orange },

      Underlined { fg = color.blue, gui = "underline" },
      Ignore { fg = color.comment },
      Error { fg = color.red, gui = "bold" },
      Todo { fg = color.magenta, gui = "bold" },

      -- Title (needed before treesitter @markup.heading)
      Title { fg = color.magenta, bold = true },

      -- Debug markers
      debugPC { fg = color.bg0, bg = color.green },
      debugBreakpoint { fg = color.bg0, bg = color.red },

      -- ════════════════════════════════════════════════════════════════════
      -- TREESITTER (standard :h treesitter-highlight-groups)
      -- Order matters! Groups must be defined before they can be referenced.
      -- ════════════════════════════════════════════════════════════════════

      -- Comments (defined first - many groups link to @comment)
      sym"@comment" { Comment },
      sym"@comment.documentation" { Comment },
      sym"@comment.error" { fg = color.red, gui = "bold" },
      sym"@comment.warning" { fg = color.yellow, gui = "bold" },
      sym"@comment.todo" { fg = color.magenta, gui = "bold" },
      sym"@comment.note" { fg = color.blue, gui = "bold" },

      -- Identifiers
      sym"@variable" { Identifier },
      sym"@variable.builtin" { fg = color.magenta, gui = "italic" },
      sym"@variable.parameter" { fg = color.orange },
      sym"@variable.parameter.builtin" { sym"@variable.parameter" },
      sym"@variable.member" { fg = color.cyan },

      -- Constants
      sym"@constant" { Constant },
      sym"@constant.builtin" { Constant, gui = "bold" },
      sym"@constant.macro" { Macro },

      -- Modules
      sym"@module" { fg = color.blue },
      sym"@module.builtin" { sym"@module", gui = "italic" },
      sym"@label" { Label },

      -- Strings
      sym"@string" { String },
      sym"@string.documentation" { sym"@comment" },
      sym"@string.regexp" { fg = color.orange },
      sym"@string.escape" { fg = color.cyan },
      sym"@string.special" { SpecialChar },
      sym"@string.special.symbol" { fg = color.cyan },
      sym"@string.special.path" { Underlined },
      sym"@string.special.url" { fg = color.blue, gui = "underline" },

      -- Characters
      sym"@character" { Character },
      sym"@character.special" { SpecialChar },

      -- Numbers
      sym"@number" { Number },
      sym"@number.float" { Float },
      sym"@boolean" { Boolean },

      -- Types
      sym"@type" { Type },
      sym"@type.builtin" { Type, gui = "italic" },
      sym"@type.definition" { Typedef },

      -- Attributes/Annotations
      sym"@attribute" { fg = color.cyan },
      sym"@attribute.builtin" { sym"@attribute", gui = "italic" },
      sym"@property" { fg = color.cyan },

      -- Functions
      sym"@function" { Function },
      sym"@function.builtin" { fg = color.green, gui = "italic" },
      sym"@function.call" { Function },
      sym"@function.macro" { Macro },
      sym"@function.method" { Function },
      sym"@function.method.call" { sym"@function.method" },
      sym"@constructor" { Special },

      -- Keywords
      sym"@keyword" { Keyword },
      sym"@keyword.coroutine" { Keyword },
      sym"@keyword.function" { fg = color.magenta, gui = "italic" },
      sym"@keyword.operator" { fg = color.magenta },
      sym"@keyword.import" { Include },
      sym"@keyword.type" { fg = color.magenta },
      sym"@keyword.modifier" { fg = color.magenta },
      sym"@keyword.repeat" { Keyword },
      sym"@keyword.return" { fg = color.magenta, gui = "italic" },
      sym"@keyword.debug" { Debug },
      sym"@keyword.exception" { Exception },
      sym"@keyword.conditional" { Conditional },
      sym"@keyword.conditional.ternary" { Operator },
      sym"@keyword.directive" { PreProc },
      sym"@keyword.directive.define" { Define },

      -- Operators/Punctuation
      sym"@operator" { Operator },
      sym"@punctuation.delimiter" { fg = color.fg0 },
      sym"@punctuation.bracket" { fg = color.fg0 },
      sym"@punctuation.special" { fg = color.fg1 },

      -- Markup (markdown, etc.)
      sym"@markup.strong" { gui = "bold" },
      sym"@markup.italic" { gui = "italic" },
      sym"@markup.strikethrough" { gui = "strikethrough" },
      sym"@markup.underline" { gui = "underline" },
      sym"@markup.heading" { Title },
      sym"@markup.heading.1" { fg = color.red, gui = "bold" },
      sym"@markup.heading.2" { fg = color.orange, gui = "bold" },
      sym"@markup.heading.3" { fg = color.yellow, gui = "bold" },
      sym"@markup.heading.4" { fg = color.green, gui = "bold" },
      sym"@markup.heading.5" { fg = color.blue, gui = "bold" },
      sym"@markup.heading.6" { fg = color.magenta, gui = "bold" },
      sym"@markup.quote" { fg = color.comment, gui = "italic" },
      sym"@markup.math" { fg = color.blue },
      sym"@markup.link" { fg = color.cyan },
      sym"@markup.link.label" { fg = color.cyan },
      sym"@markup.link.url" { fg = color.blue, gui = "underline" },
      sym"@markup.raw" { fg = color.green },
      sym"@markup.raw.block" { sym"@markup.raw" },
      sym"@markup.list" { fg = color.fg1 },
      sym"@markup.list.checked" { fg = color.green },
      sym"@markup.list.unchecked" { fg = color.comment },

      -- Diff (use colors directly - diffAdded defined later)
      sym"@diff.plus" { fg = color.git_add },
      sym"@diff.minus" { fg = color.git_delete },
      sym"@diff.delta" { fg = color.git_change },

      -- Tags (HTML/XML)
      sym"@tag" { fg = color.orange },
      sym"@tag.builtin" { sym"@tag" },
      sym"@tag.attribute" { fg = color.cyan },
      sym"@tag.delimiter" { fg = color.fg1 },

      -- Legacy mappings (some plugins still use these)
      sym"@include" { Include },
      sym"@macro" { Macro },
      sym"@float" { Float },

      -- ════════════════════════════════════════════════════════════════════
      -- LSP SEMANTIC TOKENS
      -- Link to treesitter groups - don't redefine colors
      -- ════════════════════════════════════════════════════════════════════

      -- Core types
      sym"@lsp.type.class" { sym"@type" },
      sym"@lsp.type.decorator" { sym"@attribute" },
      sym"@lsp.type.enum" { sym"@type" },
      sym"@lsp.type.enumMember" { sym"@constant" },
      sym"@lsp.type.function" { sym"@function" },
      sym"@lsp.type.interface" { sym"@type" },
      sym"@lsp.type.keyword" { sym"@keyword" },
      sym"@lsp.type.macro" { sym"@function.macro" },
      sym"@lsp.type.method" { sym"@function.method" },
      sym"@lsp.type.namespace" { sym"@module" },
      sym"@lsp.type.number" { sym"@number" },
      sym"@lsp.type.operator" { sym"@operator" },
      sym"@lsp.type.parameter" { sym"@variable.parameter" },
      sym"@lsp.type.property" { sym"@property" },
      sym"@lsp.type.string" { sym"@string" },
      sym"@lsp.type.struct" { sym"@type" },
      sym"@lsp.type.type" { sym"@type" },
      sym"@lsp.type.typeParameter" { sym"@type" },
      sym"@lsp.type.variable" { sym"@variable" },

      -- IMPORTANT: Disable LSP comment highlighting (let treesitter handle it)
      -- This prevents LSP from overriding treesitter's TODO/FIXME highlighting
      sym"@lsp.type.comment" {},

      -- Modifiers
      sym"@lsp.mod.deprecated" { gui = "strikethrough" },
      sym"@lsp.mod.readonly" { gui = "italic" },

      -- Builtin library overrides
      sym"@lsp.typemod.function.defaultLibrary" { sym"@function.builtin" },
      sym"@lsp.typemod.variable.defaultLibrary" { sym"@variable.builtin" },
      sym"@lsp.typemod.type.defaultLibrary" { sym"@type.builtin" },

      -- ════════════════════════════════════════════════════════════════════
      -- UI ELEMENTS (standard :h highlight-groups)
      -- ════════════════════════════════════════════════════════════════════
      Conceal { fg = color.comment },
      Cursor { reverse = true },
      lCursor { Cursor },
      CursorIM { Cursor },
      TermCursor { Cursor },
      TermCursorNC { fg = color.comment },
      CursorColumn { bg = Normal.bg.lighten(20) },
      CursorLine { bg = Normal.bg.lighten(6) },
      IblIndent { fg = color.bg3 },
      VirtColumn { fg = color.bg3 },
      ColorColumn { fg = color.bg3 },
      Directory { fg = color.fg0 },
      Visual { bg = color.sel0 },
      VisualNOS { Visual },

      -- Search
      Search { bg = Normal.bg.lighten(15) },
      CurSearch { fg = color.bg0, bg = color.cyan },
      IncSearch { fg = color.bg0, bg = color.red },
      Substitute { fg = color.bg0, bg = color.yellow, gui = "bold" },
      HlSearchLens { fg = color.comment, bg = Normal.bg.lighten(6) },

      -- Messages
      MsgArea { fg = color.fg1 },
      ModeMsg { MsgArea },
      MsgSeparator { fg = color.bg3 },
      MoreMsg { fg = color.yellow, gui = "bold" },
      ErrorMsg { fg = color.red, gui = "bold" },
      WarningMsg { fg = color.yellow, gui = "bold" },
      Question { fg = color.yellow },

      -- Spell
      SpellBad { sp = color.red, gui = "undercurl" },
      SpellCap { sp = color.yellow, gui = "undercurl" },
      SpellLocal { sp = color.cyan, gui = "undercurl" },
      SpellRare { sp = color.magenta, gui = "undercurl" },

      -- Quickfix
      QuickFixLine { bg = color.sel0, gui = "bold" },

      -- Health
      healthError { fg = color.red },
      healthSuccess { fg = color.green },
      healthWarning { fg = color.yellow },

      -- ════════════════════════════════════════════════════════════════════
      -- NVIM 0.12 NEW HIGHLIGHTS (experimental)
      -- ════════════════════════════════════════════════════════════════════
      DiffTextAdd { bg = color.diff_add.mix(Normal.bg, 50), fg = color.green },
      OkMsg { fg = color.green },
      StderrMsg { fg = color.red },
      StdoutMsg { fg = color.fg0 },
      ComplMatchIns { fg = color.cyan, gui = "bold" },
      SnippetTabstop { Visual },
      SnippetTabstopActive { bg = color.sel0.lighten(10), gui = "bold" },

      -- ════════════════════════════════════════════════════════════════════
      -- GIT
      -- ════════════════════════════════════════════════════════════════════
      GitAdded { fg = color.git_add },
      GitChanged { fg = color.git_change },
      GitDeleted { fg = color.git_delete },
      GitUntracked { fg = color.git_untracked },
      GitStaged { fg = color.git_staged },

      diffAdded { GitAdded },
      diffChanged { GitChanged },
      diffDeleted { GitDeleted },

      DiffAdd { bg = color.diff_add.mix(Normal.bg, 50) },
      DiffChange { bg = color.blue.saturate(20).mix(Normal.bg, 85) },
      DiffDelete { fg = color.comment, bg = color.bg0 },
      DiffText { bg = color.cyan.mix(Normal.bg, 70) },

      -- Diffview
      DiffviewDiffAdd { bg = color.diff_add },
      DiffviewDiffAddText { bg = color.diff_add.mix(color.green, 25).lighten(3) },
      DiffviewDiffDelete { bg = color.diff_delete },
      DiffviewDiffDeleteText { bg = color.diff_delete.mix(color.red, 35) },
      DiffviewDiffFill { fg = color.comment.mix(color.bg0, 50), bg = color.bg0 },

      -- Gitsigns
      GitSignsAdd { GitAdded },
      GitSignsChange { GitChanged },
      GitSignsDelete { GitDeleted },
      GitSignsUntracked { GitUntracked },

      GitSignsStagedAdd { fg = GitSignsAdd.fg.mix(Normal.bg, 70) },
      GitSignsStagedChange { fg = GitSignsChange.fg.mix(Normal.bg, 70) },
      GitSignsStagedDelete { fg = GitSignsDelete.fg.mix(Normal.bg, 70) },
      GitSignsStagedUntracked { fg = GitSignsUntracked.fg.mix(Normal.bg, 70) },

      GitSignsAddPreview { fg = color.green, DiffviewDiffAdd },
      GitSignsDeletePreview { fg = color.red, DiffviewDiffDelete },
      GitSignsAddInline { DiffviewDiffAddText },
      GitSignsDeleteInline { DiffviewDiffDeleteText },

      -- ════════════════════════════════════════════════════════════════════
      -- WINDOW ELEMENTS
      -- ════════════════════════════════════════════════════════════════════
      Folded { fg = color.bg0, bg = color.purple.mix(Normal.bg, 70) },
      FoldColumn { fg = color.fg0 },
      SignColumn { fg = color.fg0 },
      LineNr { fg = color.fg3 },
      CursorLineNr { fg = LineNr.fg.lighten(15), bold = true },
      MatchParen { fg = color.terminal_white, bg = color.cyan.darken(50) },
      NonText { fg = color.comment },
      NormalFloat { fg = color.fg0, bg = color.bg2 },
      Pmenu { fg = color.fg0, bg = color.bg2 },
      PmenuSel { Pmenu, bg = Pmenu.bg.lighten(6) },
      PmenuSbar { bg = Pmenu.bg.lighten(5) },
      PmenuThumb { bg = Pmenu.bg.lighten(15) },
      SpecialKey { fg = color.comment },
      StatusLine { bg = color.bg1 },
      StatusLineNC { StatusLine },
      StatusLineInactive { fg = Normal.bg.lighten(20), bg = color.bg_dim, gui = "italic" },
      TabLine { bg = color.bg1 },
      TabLineFill { bg = TabLine.bg },
      TabLineSel { bg = TabLine.bg.lighten(5) },
      VertSplit { fg = color.bg3 },
      Whitespace { fg = color.comment },
      Winseparator { VertSplit },

      WinBar { StatusLine, fg = Title.fg, gui = "italic" },
      WinBarNC { StatusLineInactive },

      -- Inactive statuscolumn
      StatusColumnInactiveBorder { bg = NormalNC.bg, fg = color.bg_dim.lighten(15) },
      StatusColumnInactiveLineNr { fg = color.bg_dim.lighten(10) },

      -- ════════════════════════════════════════════════════════════════════
      -- PANELS & TERMINALS (darkened backgrounds)
      -- 3-tier: Normal bg > NormalNC (7% darker) > Panel (15% darker)
      -- ════════════════════════════════════════════════════════════════════
      DarkenedPanel { bg = color.bg1 },
      DarkenedStatusline { bg = color.bg1 },
      DarkenedStatuslineNC { bg = color.bg1, gui = "italic" },

      PanelBackground { fg = color.fg0.darken(10), bg = Normal.bg.darken(15) },
      PanelBorder { fg = PanelBackground.bg.darken(10), bg = PanelBackground.bg },
      PanelHeading { PanelBackground, bold = true },
      PanelVertSplit { VertSplit, bg = Normal.bg.darken(8) },

      -- ════════════════════════════════════════════════════════════════════
      -- LSP
      -- ════════════════════════════════════════════════════════════════════
      LspReferenceText { bg = Visual.bg.darken(30) },
      LspReferenceRead { LspReferenceText },
      LspReferenceWrite { LspReferenceText },
      LspReferenceTarget { LspReferenceText, gui = "underline" },
      LspInlayHint { Comment, bold = true },
      LspCodeLens { LspInlayHint },
      LspSignatureActiveParameter { fg = color.cyan, gui = "bold" },

      -- ════════════════════════════════════════════════════════════════════
      -- DIAGNOSTICS (standard :h diagnostic-highlights)
      -- ════════════════════════════════════════════════════════════════════
      DiagnosticError { fg = color.red },
      DiagnosticWarn { fg = color.yellow },
      DiagnosticInfo { fg = color.blue },
      DiagnosticHint { fg = color.silver },
      DiagnosticOk { fg = color.green },

      -- Underlines
      DiagnosticUnderlineError { sp = DiagnosticError.fg, gui = "undercurl" },
      DiagnosticUnderlineWarn { sp = DiagnosticWarn.fg, gui = "undercurl" },
      DiagnosticUnderlineInfo { sp = DiagnosticInfo.fg, gui = "undercurl" },
      DiagnosticUnderlineHint { sp = DiagnosticHint.fg, gui = "undercurl" },
      DiagnosticUnderlineOk { sp = DiagnosticOk.fg, gui = "undercurl" },

      -- Signs
      DiagnosticSignError { DiagnosticError },
      DiagnosticSignWarn { DiagnosticWarn },
      DiagnosticSignInfo { DiagnosticInfo },
      DiagnosticSignHint { DiagnosticHint },
      DiagnosticSignOk { DiagnosticOk },

      -- Virtual text (dimmed)
      DiagnosticVirtualTextError { fg = color.red.darken(20) },
      DiagnosticVirtualTextWarn { fg = color.yellow.darken(20) },
      DiagnosticVirtualTextInfo { fg = color.blue.darken(20) },
      DiagnosticVirtualTextHint { fg = color.silver.darken(20) },
      DiagnosticVirtualTextOk { fg = color.green.darken(20) },

      -- Floating
      DiagnosticFloatingError { DiagnosticError },
      DiagnosticFloatingWarn { DiagnosticWarn },
      DiagnosticFloatingInfo { DiagnosticInfo },
      DiagnosticFloatingHint { DiagnosticHint },
      DiagnosticFloatingOk { DiagnosticOk },

      -- Custom floating labels (statusline)
      DiagnosticFloatingErrorLabel { fg = color.bg2, bg = DiagnosticError.fg },
      DiagnosticFloatingWarnLabel { fg = color.bg2, bg = DiagnosticWarn.fg },
      DiagnosticFloatingInfoLabel { fg = color.bg2, bg = DiagnosticInfo.fg },
      DiagnosticFloatingHintLabel { fg = color.bg2, bg = DiagnosticHint.fg },

      -- ════════════════════════════════════════════════════════════════════
      -- STATUSLINE/TABLINE
      -- ════════════════════════════════════════════════════════════════════
      StatusBarSegmentNormal { fg = color.fg_bright, bg = color.bg1 },
      StatusBarSegmentFaded { fg = color.fg2, bg = color.bg1 },
      StatusBarFilename { fg = color.fg2, bg = color.bg1, bold = true },
      StatusBarFilenameLoc { fg = color.fg2, bg = color.bg1 },
      StatusBarDiagnosticError { fg = DiagnosticError.fg, bg = color.bg1 },
      StatusBarDiagnosticWarn { fg = DiagnosticWarn.fg, bg = color.bg1 },
      StatusBarDiagnosticInfo { fg = DiagnosticInfo.fg, bg = color.bg1 },
      StatusBarDiagnosticHint { fg = DiagnosticHint.fg, bg = color.bg1 },

      -- St* highlights (for lualine/statusline components)
      -- Mode highlights
      StModeNormal { bg = color.bg1, fg = color.fg2 },
      StModeInsert { bg = color.bg1, fg = color.green, gui = "bold" },
      StModeVisual { bg = color.bg1, fg = color.magenta, gui = "bold" },
      StModeReplace { bg = color.bg1, fg = color.red, gui = "bold" },
      StModeCommand { bg = color.bg1, fg = color.yellow, gui = "bold" },
      StModeOther { bg = color.bg1, fg = color.fg2 },
      StModeTermNormal { StModeNormal },
      StModeTermInsert { bg = color.bg1, fg = color.green, gui = "bold,italic" },

      -- Text style highlights
      StBright { fg = color.fg0.lighten(10), bg = color.bg1 },
      StBrightItalic { fg = color.fg0.lighten(5), bg = color.bg1, gui = "italic" },
      StMetadata { fg = color.comment, bg = color.bg1 },
      StMetadataPrefix { fg = color.fg0, bg = color.bg1 },
      StLspMessages { fg = color.fg0.darken(20), bg = color.bg1, gui = "italic" },
      StComment { fg = color.comment, bg = color.bg1 },

      -- File path highlights
      StDirectory { bg = color.bg1, fg = color.fg2, gui = "italic" },
      StParentDirectory { bg = color.bg1, fg = color.blue, gui = "italic" },
      StFilename { bg = color.bg1, fg = color.fg0, gui = "bold" },
      StFilenameInactive { fg = color.fg3, bg = color.bg1, gui = "italic,bold" },
      StTitle { bg = color.bg1, fg = color.fg_bright, gui = "bold" },

      -- Git highlights
      StGitSymbol { fg = color.red, bg = color.bg1 },
      StGitBranch { fg = color.blue, bg = color.bg1 },
      StGitSigns { fg = color.blue, bg = color.bg1 },
      StGitSignsAdd { fg = color.git_add },
      StGitSignsDelete { fg = color.git_delete },
      StGitSignsChange { fg = color.git_change },

      -- Jujutsu (jj) highlights
      StJjIcon { fg = color.magenta, bg = color.bg1 },
      StJjChangeId { fg = color.cyan, bg = color.bg1 },
      StJjBookmark { fg = color.blue, bg = color.bg1, gui = "italic" },
      StJjConflict { fg = color.red, bg = color.bg1, gui = "bold" },

      -- Line info highlights
      StLineNumber { fg = color.fg_bright, gui = "bold" },
      StLineSep { fg = color.fg2 },
      StLineTotal { fg = color.fg1 },
      StLineColumn { fg = color.fg_bright },

      -- Status highlights
      StModified { fg = color.red, bg = color.bg1, gui = "bold,italic" },
      StModifiedIcon { fg = color.red, bg = color.bg1, gui = "bold" },
      StIndicator { fg = color.blue, bg = color.bg1 },
      StClient { bg = color.bg1, fg = color.fg0, gui = "bold" },
      StBufferCount { fg = color.blue },
      StSeparator { fg = color.bg0, bg = color.bg1 },

      -- Diagnostics (statusline specific)
      StError { fg = DiagnosticError.fg },
      StWarn { fg = DiagnosticWarn.fg },
      StInfo { fg = DiagnosticInfo.fg },
      StHint { fg = DiagnosticHint.fg },

      -- Misc
      StNumber { fg = color.purple },
      StCount { fg = color.bg0, bg = color.blue, gui = "bold" },
      StPrefix { fg = color.fg0, bg = color.bg2 },
      StIdentifier { fg = color.blue, bg = color.bg1 },

      -- ════════════════════════════════════════════════════════════════════
      -- FLOATS
      -- ════════════════════════════════════════════════════════════════════
      FloatTitle { fg = color.comment, bg = color.bg2, bold = true },
      FloatBorder { fg = color.comment, bg = color.bg2 },

      -- ════════════════════════════════════════════════════════════════════
      -- INDENT/BLANK LINE
      -- ════════════════════════════════════════════════════════════════════
      IndentBlanklineChar { fg = color.bg3 },
      IndentBlanklineContextChar { fg = IndentBlanklineChar.fg.lighten(25) },

      -- ════════════════════════════════════════════════════════════════════
      -- TODO COMMENTS
      -- ════════════════════════════════════════════════════════════════════
      TodoComment { fg = color.purple },
      FixmeComment { fg = color.purple },
      HackComment { fg = color.yellow },
      PriorityComment { fg = color.orange },

      -- ════════════════════════════════════════════════════════════════════
      -- MINI
      -- ════════════════════════════════════════════════════════════════════
      MiniStarterSection { fg = color.fg0, bg = color.bg0, bold = true },
      MiniStarterFooter { Comment },

      -- ════════════════════════════════════════════════════════════════════
      -- NOICE
      -- ════════════════════════════════════════════════════════════════════
      NoiceCmdline { bg = color.bg1 },
      NoiceLspProgressTitle { fg = color.fg2, bg = color.bg1 },
      NoiceLspProgressClient { fg = color.fg1, bg = color.bg1 },
      NoiceLspProgressSpinner { fg = color.yellow.mix(color.bg1, 50), bg = color.bg1 },

      -- ════════════════════════════════════════════════════════════════════
      -- MULTI-CURSOR
      -- ════════════════════════════════════════════════════════════════════
      MultiCursorCursor { fg = color.silver.mix(color.bg0, 50), reverse = true },
      MultiCursorVisual { bg = color.comment },
      MultiCursorSign { fg = color.silver.mix(color.bg0, 50) },
      MultiCursorDisabledCursor { bg = color.red },
      MultiCursorDisabledVisual { bg = color.comment },
      MultiCursorDisabledSign { bg = color.red },

      -- ════════════════════════════════════════════════════════════════════
      -- MISC
      -- ════════════════════════════════════════════════════════════════════
      ZenBg { fg = color.fg0, bg = color.bg0 },
      WinShiftMove { bg = Normal.bg.lighten(7) },
      TabsVsSpaces { fg = color.comment, underline = true },

      -- ════════════════════════════════════════════════════════════════════
      -- FLASH
      -- ════════════════════════════════════════════════════════════════════
      FlashCurrent { fg = Normal.bg, bg = color.green, bold = true },
      FlashMatch { fg = Normal.bg, bg = color.cyan },
      FlashLabel { fg = Normal.bg, bg = color.purple, bold = true },
      FlashPrompt { bg = color.bg1 },
      FlashPromptIcon { bg = color.bg1 },

      -- ════════════════════════════════════════════════════════════════════
      -- MINI CURSORWORD
      -- ════════════════════════════════════════════════════════════════════
      MiniCursorword { bg = Normal.bg.lighten(10) },

      -- ════════════════════════════════════════════════════════════════════
      -- NVIM-SURROUND
      -- ════════════════════════════════════════════════════════════════════
      NvimSurroundHighlight { fg = Normal.bg, bg = color.cyan },

      -- ════════════════════════════════════════════════════════════════════
      -- SNACKS
      -- ════════════════════════════════════════════════════════════════════
      SnacksIndent { fg = color.comment.mix(color.bg0, 80) },
      SnacksIndentScope { fg = color.comment },

      SnacksInputNormal { bg = color.bg2 },
      SnacksInputBorder { fg = color.bg2, bg = color.bg2 },
      SnacksInputTitle { fg = color.comment, bg = color.bg2 },

      SnacksPickerTitle { fg = color.comment, bg = color.bg2 },
      SnacksPickerBorder { fg = color.bg3.lighten(5), bg = color.bg2 },
      SnacksPickerTotals { fg = color.comment },
      SnacksPickerBufNr { fg = color.comment },
      SnacksPickerDir { fg = color.comment },
      SnacksPickerRow { fg = color.comment },
      SnacksPickerCol { fg = color.comment },
      SnacksPickerTree { fg = color.bg5 },
      SnacksPickerSelected { fg = color.cyan },
      SnacksPickerListCursorLine { bg = color.bg2.lighten(6) },
      SnacksPickerPreviewCursorLine { bg = color.bg2.lighten(6) },
      SnacksPickerMatch { fg = Normal.bg, bg = color.cyan },
      SnacksPickerPathHidden { fg = color.fg0 },

      SnacksPickerGitStatusAdded { GitAdded },
      SnacksPickerGitStatusModified { GitChanged },
      SnacksPickerGitStatusStaged { GitStaged },
      SnacksPickerGitStatusUntracked { GitUntracked },

      SnacksTerminal { bg = PanelBackground.bg, fg = color.fg0 },
      SnacksTerminalHeader { bg = color.orange, fg = color.fg3, bold = true },
      SnacksTerminalHeaderNC { bg = PanelBackground.bg, fg = color.fg1, bold = true },
      SnacksTerminalFloatBorder { fg = color.sel1, bg = PanelBackground.bg },

      MegaNotification { bg = color.bg2 },
      MegaNotificationMeta { fg = color.comment },
      SnacksNotifierTrace { MegaNotification },
      SnacksNotifierTitleTrace { MegaNotification, fg = MegaNotificationMeta.fg },
      SnacksNotifierBorderTrace { MegaNotification, fg = MegaNotificationMeta.fg },
      SnacksNotifierDebug { MegaNotification },
      SnacksNotifierTitleDebug { MegaNotification, fg = MegaNotificationMeta.fg },
      SnacksNotifierBorderDebug { MegaNotification, fg = MegaNotificationMeta.fg },
      SnacksNotifierInfo { MegaNotification },
      SnacksNotifierTitleInfo { MegaNotification, fg = DiagnosticInfo.fg },
      SnacksNotifierBorderInfo { MegaNotification, fg = DiagnosticInfo.fg },
      SnacksNotifierWarn { MegaNotification, fg = DiagnosticWarn.fg },
      SnacksNotifierTitleWarn { MegaNotification, fg = DiagnosticWarn.fg },
      SnacksNotifierBorderWarn { MegaNotification, fg = DiagnosticWarn.fg },
      SnacksNotifierError { MegaNotification, fg = DiagnosticError.fg },
      SnacksNotifierTitleError { MegaNotification, fg = DiagnosticError.fg },
      SnacksNotifierBorderError { MegaNotification, fg = DiagnosticError.fg },

      SnacksNotifierHistory { bg = color.bg2 },
      SnacksNotifierHistoryDateTime { fg = color.cyan },

      -- ════════════════════════════════════════════════════════════════════
      -- TROUBLE
      -- ════════════════════════════════════════════════════════════════════
      TroubleNormal { PanelBackground },
      TroubleNormalNC { PanelBackground },
      TroubleDirectory { fg = color.fg1 },
      TroubleFilename { fg = color.fg1, bold = true },

      -- ════════════════════════════════════════════════════════════════════
      -- BLINK.CMP
      -- ════════════════════════════════════════════════════════════════════
      BlinkCmpLabel { fg = color.fg0 },
      BlinkCmpLabelMatch { fg = color.blue, gui = "bold,italic" },
      BlinkCmpLabelDeprecated { fg = color.fg1, gui = "strikethrough" },
      BlinkCmpLabelDetail { fg = color.comment, gui = "italic" },
      BlinkCmpLabelDescription { fg = color.comment },
      BlinkCmpSource { fg = color.comment, gui = "italic" },

      BlinkCmpMenu { Pmenu },
      BlinkCmpMenuBorder { FloatBorder },
      BlinkCmpMenuSelection { bg = color.sel0, gui = "bold" },
      BlinkCmpScrollBarThumb { PmenuThumb },
      BlinkCmpScrollBarGutter { PmenuSbar },
      BlinkCmpGhostText { NonText },

      BlinkCmpDoc { NormalFloat },
      BlinkCmpDocBorder { FloatBorder },
      BlinkCmpDocSeparator { FloatBorder },
      BlinkCmpDocCursorLine { Visual },

      BlinkCmpSignatureHelp { NormalFloat },
      BlinkCmpSignatureHelpBorder { FloatBorder },
      BlinkCmpSignatureHelpActiveParameter { LspSignatureActiveParameter },

      -- Kind icons
      BlinkCmpKind { fg = color.blue },
      BlinkCmpKindText { fg = color.green },
      BlinkCmpKindMethod { fg = color.blue },
      BlinkCmpKindFunction { fg = color.blue },
      BlinkCmpKindConstructor { fg = color.cyan },
      BlinkCmpKindField { fg = color.fg0 },
      BlinkCmpKindVariable { fg = color.red },
      BlinkCmpKindClass { fg = color.yellow },
      BlinkCmpKindInterface { fg = color.yellow },
      BlinkCmpKindModule { fg = color.blue },
      BlinkCmpKindProperty { fg = color.red },
      BlinkCmpKindUnit { fg = color.green },
      BlinkCmpKindValue { fg = color.orange },
      BlinkCmpKindEnum { fg = color.yellow },
      BlinkCmpKindKeyword { fg = color.magenta },
      BlinkCmpKindSnippet { fg = color.green },
      BlinkCmpKindColor { fg = color.red },
      BlinkCmpKindFile { fg = color.blue },
      BlinkCmpKindReference { fg = color.red },
      BlinkCmpKindFolder { fg = color.blue },
      BlinkCmpKindEnumMember { fg = color.teal },
      BlinkCmpKindConstant { fg = color.orange },
      BlinkCmpKindStruct { fg = color.blue },
      BlinkCmpKindEvent { fg = color.blue },
      BlinkCmpKindOperator { fg = color.cyan },
      BlinkCmpKindTypeParameter { fg = color.magenta },
      BlinkCmpKindCopilot { fg = color.teal },

      -- ════════════════════════════════════════════════════════════════════
      -- OIL
      -- ════════════════════════════════════════════════════════════════════
      OilDir { Directory },
      OilDirIcon { Directory },
      OilLink { fg = color.cyan },
      OilLinkTarget { Comment },
      OilCopy { fg = color.green, gui = "bold" },
      OilMove { fg = color.yellow, gui = "bold" },
      OilChange { fg = color.yellow, gui = "bold" },
      OilCreate { fg = color.green, gui = "bold" },
      OilDelete { fg = color.red, gui = "bold" },
      OilPermissionNone { NonText },
      OilPermissionRead { fg = color.yellow },
      OilPermissionWrite { fg = color.red },
      OilPermissionExecute { fg = color.green },
      OilTypeDir { Directory },
      OilTypeFile { NonText },
      OilTypeLink { fg = color.cyan },

      -- ════════════════════════════════════════════════════════════════════
      -- RAINBOW DELIMITERS
      -- ════════════════════════════════════════════════════════════════════
      RainbowDelimiterRed { fg = color.red },
      RainbowDelimiterYellow { fg = color.yellow },
      RainbowDelimiterBlue { fg = color.blue },
      RainbowDelimiterOrange { fg = color.orange },
      RainbowDelimiterGreen { fg = color.green },
      RainbowDelimiterViolet { fg = color.magenta },
      RainbowDelimiterCyan { fg = color.cyan },

      -- ════════════════════════════════════════════════════════════════════
      -- TREESITTER-CONTEXT
      -- ════════════════════════════════════════════════════════════════════
      TreesitterContext { bg = color.bg1 },
      TreesitterContextLineNumber { fg = color.fg3, bg = color.bg1 },
      TreesitterContextSeparator { fg = color.bg3 },

      -- ════════════════════════════════════════════════════════════════════
      -- DAP (nvim-dap)
      -- ════════════════════════════════════════════════════════════════════
      DapBreakpoint { fg = color.red },
      DapStopped { fg = color.green },
      DapLogPoint { fg = color.blue },
      DapBreakpointCondition { fg = color.yellow },
      DapBreakpointRejected { fg = color.comment },

      -- ════════════════════════════════════════════════════════════════════
      -- WHICH-KEY
      -- ════════════════════════════════════════════════════════════════════
      WhichKey { fg = color.cyan },
      WhichKeyGroup { fg = color.blue },
      WhichKeyDesc { fg = color.fg0 },
      WhichKeySeparator { fg = color.comment },
      WhichKeyFloat { NormalFloat },
      WhichKeyBorder { FloatBorder },
      WhichKeyValue { Comment },

      -- ════════════════════════════════════════════════════════════════════
      -- DIFF FILE HEADERS (standard)
      -- ════════════════════════════════════════════════════════════════════
      diffOldFile { fg = color.yellow },
      diffNewFile { fg = color.orange },
      diffFile { fg = color.cyan },
      diffLine { fg = color.comment },
      diffIndexLine { fg = color.magenta },

      -- ════════════════════════════════════════════════════════════════════
      -- PMENU ENHANCEMENTS (nvim 0.12)
      -- ════════════════════════════════════════════════════════════════════
      PmenuBorder { fg = color.comment, bg = color.bg2 },
      PmenuShadow { bg = color.bg0 },
      PmenuShadowThrough { bg = color.bg_dim },

      -- ════════════════════════════════════════════════════════════════════
      -- LINE NUMBER ENHANCEMENTS (nvim 0.10+)
      -- ════════════════════════════════════════════════════════════════════
      LineNrAbove { LineNr },
      LineNrBelow { LineNr },
      CursorLineFold { FoldColumn },
      CursorLineSign { SignColumn },
    }
  end)
  -- stylua: ignore end

  lush(theme)

  vim.api.nvim_exec_autocmds("User", { pattern = "ThemeApplied" })
end
