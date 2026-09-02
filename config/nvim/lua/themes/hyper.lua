-- Hyper theme for nvim_next
-- Following nightfox/gruvbox numbered conventions for palette organization
--
-- Palette organization:
--   1. Background colors (bg0-4, bg_dim) - numbered dark to light
--   2. Foreground colors (fg0-3, comment) - numbered bright to dim
--   3. Selection colors (sel0, sel1)
--   4. Accent colors (standard: red, orange, yellow, green, cyan, blue, magenta)
--   5. Semantic colors (git, diff, diagnostics)
--   6. Terminal colors

mega.t.hyper = {
  palette = {
    -- ══════════════════════════════════════════════════════════════════════════
    -- BACKGROUNDS (numbered 0-4, dark to light)
    -- bg0 = primary, bg1 = elevated, bg2 = float, bg3 = lines, bg4 = prominent
    -- ══════════════════════════════════════════════════════════════════════════
    bg_dim = "#232629", -- Deepest background (unused, for completeness)
    bg0 = "#272b30", -- Primary background
    bg1 = "#2c323c", -- Elevated (statusline, tabline)
    bg2 = "#2b2f34", -- Float backgrounds, popups
    bg3 = "#2f3337", -- Subtle lines, indent guides
    bg4 = "#3e4452", -- More prominent surfaces
    bg5 = "#333740", -- Borders (subtle)

    -- ══════════════════════════════════════════════════════════════════════════
    -- FOREGROUNDS (numbered 0-3, bright to dim)
    -- fg0 = primary text, fg1 = secondary, fg2 = tertiary, fg3 = very muted
    -- ══════════════════════════════════════════════════════════════════════════
    fg0 = "#afb4c3", -- Primary text
    fg1 = "#80838f", -- Secondary text
    fg2 = "#70757d", -- Tertiary/muted text
    fg3 = "#464b50", -- Very muted (line numbers)
    comment = "#686d75", -- Comments, disabled text

    -- Statusline uses slightly brighter text
    fg_bright = "#b5bac8", -- Statusline text (brighter than fg0)

    -- ══════════════════════════════════════════════════════════════════════════
    -- SELECTION
    -- ══════════════════════════════════════════════════════════════════════════
    sel0 = "#3a3f47", -- Visual selection background
    sel1 = "#73787d", -- Search/prominent highlight borders

    -- ══════════════════════════════════════════════════════════════════════════
    -- ACCENT COLORS (standard names)
    -- These are the "hue" colors used for syntax and UI accents
    -- ══════════════════════════════════════════════════════════════════════════
    red = "#cc6666", -- Errors, diff deleted
    orange = "#de935f", -- Numbers, booleans, constants
    yellow = "#f0c674", -- Classes, warnings, search bg
    green = "#bdb968", -- Strings, success, diff inserted
    cyan = "#7fb2c8", -- Support, regex, escape chars
    blue = "#81a2be", -- Functions, info
    magenta = "#b193ba", -- Keywords, storage
    purple = "#b08cba", -- Alternative for magenta

    -- Theme-specific extras
    teal = "#749689", -- Accent for special elements
    silver = "#acbcc3", -- Constants, special
    beige = "#ebd2a7", -- Identifiers (warm text)

    -- ══════════════════════════════════════════════════════════════════════════
    -- SEMANTIC COLORS (git, diff)
    -- ══════════════════════════════════════════════════════════════════════════
    git_add = "#bdb968", -- green
    git_change = "#81a2be", -- blue
    git_delete = "#cc6666", -- red
    git_untracked = "#749689", -- teal
    git_staged = "#b193ba", -- magenta

    diff_add = "#3a413b", -- Muted green background
    diff_delete = "#443c3f", -- Muted red background
    diff_change = "#3a4550", -- Muted blue background

    -- ══════════════════════════════════════════════════════════════════════════
    -- TERMINAL COLORS (0-15)
    -- ══════════════════════════════════════════════════════════════════════════
    terminal_black = "#272b30",
    terminal_red = "#cc6666",
    terminal_green = "#bdb968",
    terminal_yellow = "#f0c674",
    terminal_blue = "#81a2be",
    terminal_magenta = "#b193ba",
    terminal_cyan = "#7fb2c8",
    terminal_white = "#ffffff",

    terminal_bright_black = "#636363",
    terminal_bright_red = "#a04041",
    terminal_bright_green = "#8b9440",
    terminal_bright_yellow = "#ec9c62",
    terminal_bright_blue = "#5d7f9a",
    terminal_bright_magenta = "#82658c",
    terminal_bright_cyan = "#5e8d87",
    terminal_bright_white = "#6d757d",
  },
}

function mega.t.hyper.apply()
  vim.opt.termguicolors = true

  if vim.g.colors_name then
    vim.cmd("hi clear")
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "hyper"

  local lush = require("lush")
  local p = mega.t.hyper.palette

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
      -- SYNTAX
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
      Operator { fg = Normal.fg },
      Keyword { fg = color.magenta },

      PreProc { fg = color.magenta },
      Include { fg = color.blue, bold = true },
      Macro { fg = color.orange },

      Type { fg = color.cyan },
      Typedef { Type },

      Special { fg = color.silver },

      Underlined { gui = "underline" },

      -- ════════════════════════════════════════════════════════════════════
      -- TREESITTER
      -- ════════════════════════════════════════════════════════════════════
      sym"@comment" { Comment },
      sym"@constant" { Constant },
      sym"@macro" { Macro },
      sym"@string" { String },
      sym"@character" { Character },
      sym"@number" { Number },
      sym"@boolean" { Boolean },
      sym"@float" { Float },
      sym"@function" { Function },
      sym"@constructor" { Special },
      sym"@operator" { Operator },
      sym"@keyword" { Keyword },
      sym"@variable" { Identifier },
      sym"@type" { Type },
      sym"@type.definition" { Typedef },
      sym"@include" { Include },

      -- ════════════════════════════════════════════════════════════════════
      -- UI ELEMENTS
      -- ════════════════════════════════════════════════════════════════════
      Conceal { fg = color.comment },
      Cursor { reverse = true },
      CursorColumn { bg = Normal.bg.lighten(20) },
      CursorLine { bg = Normal.bg.lighten(6) },
      IblIndent { fg = color.bg3 },
      VirtColumn { fg = color.bg3 },
      ColorColumn { fg = color.bg3 },
      Directory { fg = color.fg0 },

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
      MsgArea { fg = color.fg1 },
      ModeMsg { MsgArea },
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
      Title { fg = color.magenta, bold = true },
      VertSplit { fg = color.bg3 },
      Visual { bg = color.sel0 },
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

      Search { bg = Normal.bg.lighten(15) },
      CurSearch { fg = color.bg0, bg = color.cyan },
      HlSearchLens { fg = color.comment, bg = Normal.bg.lighten(6) },

      -- ════════════════════════════════════════════════════════════════════
      -- LSP
      -- ════════════════════════════════════════════════════════════════════
      LspReferenceText { bg = Visual.bg.darken(30) },
      LspReferenceRead { LspReferenceText },
      LspReferenceWrite { LspReferenceText },
      LspInlayHint { Comment, bold = true },
      LspCodeLens { LspInlayHint },

      -- ════════════════════════════════════════════════════════════════════
      -- DIAGNOSTICS
      -- ════════════════════════════════════════════════════════════════════
      DiagnosticError { fg = color.red },
      DiagnosticWarn { fg = color.yellow },
      DiagnosticInfo { fg = color.blue },
      DiagnosticHint { fg = color.silver },
      DiagnosticUnderlineError { DiagnosticError, undercurl = true },
      DiagnosticUnderlineWarn { DiagnosticWarn, undercurl = true },
      DiagnosticUnderlineInfo { DiagnosticInfo, undercurl = true },
      DiagnosticUnderlineHint { DiagnosticHint, undercurl = true },
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

      -- Line info highlights
      StLineNumber { fg = color.fg_bright, gui = "bold" },
      StLineSep { fg = color.fg2 },
      StLineTotal { fg = color.fg1 },
      StLineColumn { fg = color.fg_bright },
      
      -- Visual selection info
      VisualYank { fg = color.yellow, bg = color.bg_visual, gui = "bold" },

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
    }
  end)
  -- stylua: ignore end

  lush(theme)

  vim.api.nvim_exec_autocmds("User", { pattern = "ThemeApplied" })
end
