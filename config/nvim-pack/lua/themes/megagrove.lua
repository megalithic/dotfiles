-- Megagrove theme for nvim_next
-- Ported from the original lush-based megagrove (everforest-inspired)
-- Following nightfox/gruvbox numbered conventions for palette organization

mega.t.megagrove = {
  palette = {
    -- ══════════════════════════════════════════════════════════════════════════
    -- BACKGROUNDS (numbered 0-4, dark to light)
    -- ══════════════════════════════════════════════════════════════════════════
    -- bg_dim = "#2b3339", -- bg_hard
    -- bg0 = "#323d43", -- bg_soft (primary)
    -- bg1 = "#3c474d", -- bg0.lighten(5)
    -- bg2 = "#465258", -- bg0.lighten(10)
    -- bg3 = "#505a60", -- bg0.lighten(15)
    -- bg4 = "#576268", -- bg0.lighten(20)
    -- bg5 = "#626262", -- bg0.lighten(25)

    bg_dim = "#232629", -- Deepest background (unused, for completeness)
    bg0 = "#272b30", -- Primary background
    bg1 = "#2c323c", -- Elevated (statusline, tabline)
    bg2 = "#2b2f34", -- Float backgrounds, popups
    bg3 = "#2f3337", -- Subtle lines, indent guides
    bg4 = "#3e4452", -- More prominent surfaces
    bg5 = "#333740", -- Borders (subtle)

    -- Special backgrounds
    bg_hard = "#2b3339",
    bg_medium = "#2b3339",
    bg_soft = "#323d43",
    bg_thicc = "#273433",
    bg_abyss = "#111111",
    bg_visual = "#5d5c50",
    bg_red = "#614b51",
    bg_green = "#4e6053",
    bg_blue = "#415c6d",
    bg_yellow = "#5d5c50",
    bg_purple = "#402F37",
    bg_cyan = "#54816B",

    -- ══════════════════════════════════════════════════════════════════════════
    -- FOREGROUNDS (numbered 0-3, bright to dim)
    -- ══════════════════════════════════════════════════════════════════════════
    fg0 = "#d8caac", -- Primary text (warm beige)
    fg1 = "#868d80", -- grey1
    fg2 = "#7c8377", -- grey0
    fg3 = "#5c6370", -- light_grey
    comment = "#7c8377", -- grey0 (used for comments)

    -- Extra greys
    dark_grey = "#3E4556",
    grey0 = "#7c8377",
    grey1 = "#868d80",
    grey2 = "#999f93",

    -- Statusline uses slightly brighter text
    fg_bright = "#999f93", -- grey2

    -- ══════════════════════════════════════════════════════════════════════════
    -- SELECTION
    -- ══════════════════════════════════════════════════════════════════════════
    sel0 = "#5d5c50", -- Visual selection background (bg_visual)
    sel1 = "#7c8377", -- Search/prominent highlight borders (grey0)

    -- ══════════════════════════════════════════════════════════════════════════
    -- ACCENT COLORS (standard names)
    -- ══════════════════════════════════════════════════════════════════════════
    red = "#e67e80",
    orange = "#e39b7b",
    yellow = "#d9bb80",
    green = "#a7c080",
    cyan = "#83b799", -- aqua (darken(5) applied in original)
    blue = "#7fbbb3",
    magenta = "#b4879e", -- purple.darken(15)
    purple = "#d39bb6",
    brown = "#b47f4a", -- db9c5e darken(20)

    -- Theme-specific extras
    teal = "#15AABF",
    aqua = "#83b799", -- same as cyan
    pale_red = "#E06C75",
    bright_blue = "#87c7bf", -- blue.lighten(5)
    bright_blue_alt = "#51afef",
    bright_green = "#6bc46d",
    bright_yellow = "#FAB005",
    light_yellow = "#e5c07b",
    light_red = "#c43e1f",
    dark_blue = "#5f8c85", -- blue.darken(25)
    dark_blue_alt = "#4e88ff",
    dark_orange = "#FF922B",
    dark_red = "#be5046",
    dark_green = "#569558", -- 6bc46d darken(20)
    dark_brown = "#795430",

    -- ══════════════════════════════════════════════════════════════════════════
    -- SEMANTIC COLORS (git, diff, diagnostics)
    -- ══════════════════════════════════════════════════════════════════════════
    git_add = "#6bc46d", -- bright_green
    git_change = "#e39b7b", -- orange
    git_delete = "#e67e80", -- red
    git_untracked = "#15AABF", -- teal
    git_staged = "#d39bb6", -- purple

    diff_add = "#4e6053", -- bg_green
    diff_delete = "#614b51", -- bg_red
    diff_change = "#415c6d", -- bg_blue

    -- LSP diagnostic colors
    lsp_error = "#E06C75", -- pale_red
    lsp_warn = "#FF922B", -- dark_orange
    lsp_hint = "#87c7bf", -- bright_blue
    lsp_info = "#15AABF", -- teal

    -- ══════════════════════════════════════════════════════════════════════════
    -- TERMINAL COLORS (0-15)
    -- ══════════════════════════════════════════════════════════════════════════
    terminal_black = "#323d43", -- bg0
    terminal_red = "#e67e80",
    terminal_green = "#a7c080",
    terminal_yellow = "#d9bb80",
    terminal_blue = "#7fbbb3",
    terminal_magenta = "#d39bb6",
    terminal_cyan = "#83b799",
    terminal_white = "#d8caac", -- fg

    terminal_bright_black = "#323d43",
    terminal_bright_red = "#e67e80",
    terminal_bright_green = "#a7c080",
    terminal_bright_yellow = "#d9bb80",
    terminal_bright_blue = "#7fbbb3",
    terminal_bright_magenta = "#d39bb6",
    terminal_bright_cyan = "#83b799",
    terminal_bright_white = "#d8caac",
  },
}

function mega.t.megagrove.apply()
  vim.opt.termguicolors = true

  if vim.g.colors_name then
    vim.cmd("hi clear")
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "megagrove"

  local lush = require("lush")
  local p = mega.t.megagrove.palette

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

  -- VM (visual multi) settings
  vim.g.VM_Mono_hl = "Cursor"
  vim.g.VM_Extend_hl = "Visual"
  vim.g.VM_Cursor_hl = "Cursor"
  vim.g.VM_Insert_hl = "Cursor"

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
      NormalNC { bg = color.bg0.darken(7) }, -- inactive window
      NonText { fg = color.bg4 },
      Pmenu { fg = color.fg0, bg = color.bg2 },
      PmenuSel { fg = color.green, bg = color.bg3 },
      PmenuSbar { bg = color.bg2 },
      PmenuThumb { bg = color.grey1 },

      Background { bg = color.bg0 },
      BackgroundLight { bg = color.bg1 },
      BackgroundExtraLight { bg = color.bg2 },

      Visual { bg = color.bg_visual },
      VisualNOS { bg = color.bg_visual },
      VisualYank { Visual, bg = color.bg_visual.lighten(10) },
      VisualYank2 { fg = color.fg0, bg = color.bg_red.darken(10) },

      WarningMsg { fg = color.yellow },
      Whitespace { fg = color.bg3 },
      ColorColumn { bg = color.bg0 },
      Conceal { fg = color.grey1 },

      Cursor { gui = "reverse" },
      Cursor2 { fg = color.bg_red, bg = color.bg_red, gui = "reverse" },
      TermCursor { Cursor, bg = color.yellow },
      TermCursorNC { Cursor },
      lCursor { Cursor },
      iCursor { Cursor, bg = color.bg_blue },
      vCursor { Cursor },
      CursorIM { Cursor },
      CursorColumn { bg = color.bg2 },
      CursorWord { gui = "bold,underline" },
      CursorLine { bg = color.bg2 },

      LineNr { fg = color.grey0 },
      CursorLineNr { CursorLine, fg = color.brown, bg = color.bg0.lighten(5), gui = "bold,italic" },

      -- VertSplit { fg = color.bg4 },
      -- WinSeparator { fg = color.bg_hard.lighten(15), bg = color.bg_hard.lighten(1), gui = "bold" },

      VertSplit { fg = color.bg3 },
      Winseparator { VertSplit },

      Comment { fg = color.grey1, gui = "italic" },
      Directory { fg = color.green },
      ErrorMsg { fg = color.red, gui = "bold,underline" },
      Folded { Normal },
      FoldColumn { fg = color.grey1, bg = color.bg1 },
      SignColumn { fg = color.fg0 },
      EndOfBuffer { fg = color.bg2 },

      IncSearch { fg = color.bg0, bg = color.red },
      CurSearch { IncSearch },
      Search { fg = color.bg0, bg = color.green, gui = "italic,bold" },
      Substitute { fg = color.bg0, bg = color.yellow, gui = "strikethrough,bold" },
      MatchParen { bg = color.bg_abyss.lighten(5), gui = "bold,underline" },

      ModeMsg { fg = color.fg0, gui = "bold" },
      MsgArea { bg = color.bg0 },
      MsgSeparator { bg = color.bg0 },
      MoreMsg { fg = color.yellow, gui = "bold" },
      FoldMoreMsg { Comment, gui = "italic,bold" },

      WildMenu { PmenuSel },
      NormalFloat { bg = color.bg2 },
      FloatBorder { NormalFloat, fg = NormalFloat.bg },
      NotifyBackground { bg = color.bg2.darken(10) },
      NotifyFloat { NotifyBackground, fg = color.bg2.darken(10) },
      FloatTitle { Visual },
      Question { fg = color.yellow },

      SpecialKey { fg = color.bg3 },

      -- ════════════════════════════════════════════════════════════════════
      -- SPELL
      -- ════════════════════════════════════════════════════════════════════
      SpellBad { fg = color.red, gui = "bold,underline", sp = color.red },
      SpellCap { fg = color.blue, gui = "underline", sp = color.blue },
      SpellLocal { fg = color.cyan, gui = "underline", sp = color.cyan },
      SpellRare { fg = color.purple, gui = "underline", sp = color.purple },

      -- ════════════════════════════════════════════════════════════════════
      -- SYNTAX (standard :h group-name)
      -- ════════════════════════════════════════════════════════════════════
      Boolean { fg = color.purple },
      Number { fg = color.purple },
      Float { fg = color.purple },
      PreProc { fg = color.purple, gui = "italic" },
      PreCondit { fg = color.purple },
      Include { fg = color.purple, gui = "italic" },
      Define { fg = color.purple, gui = "italic" },
      Conditional { fg = color.red, gui = "italic" },
      Repeat { fg = color.red },
      Keyword { fg = color.red, gui = "italic" },
      Typedef { fg = color.red, gui = "italic" },
      Exception { fg = color.red, gui = "italic" },
      Statement { fg = color.red, gui = "italic" },
      Error { fg = color.red },
      StorageClass { fg = color.orange },
      Tag { fg = color.orange },
      Label { fg = color.orange },
      Structure { fg = color.orange },
      Operator { fg = color.orange },
      Title { fg = color.orange, gui = "bold" },
      Special { fg = color.fg0.darken(20), gui = "bold" },
      SpecialChar { fg = color.yellow },
      Type { fg = color.yellow },
      Class { fg = color.orange },
      Module { fg = color.green },
      Method { fg = color.purple },
      Function { fg = color.green },
      String { fg = color.green },
      Character { fg = color.green },
      Constant { fg = color.aqua },
      Macro { fg = color.aqua },
      Identifier { fg = color.blue },
      SpecialComment { fg = color.grey1, gui = "italic" },
      Todo { fg = color.purple, gui = "italic" },
      Delimiter { fg = color.fg0 },
      Ignore { fg = color.grey1 },
      Debug { fg = color.orange },
      debugPC { fg = color.bg0, bg = color.green },
      debugBreakpoint { fg = color.bg0, bg = color.red },

      Bold { gui = "bold" },
      TransparentBold { gui = "bold" },
      Italic { gui = "italic" },
      TransparentItalic { gui = "italic" },
      Underlined { gui = "underline" },
      CurrentWord { bg = color.fg0, fg = color.bg0 },

      -- Color groups for convenience
      Fg { fg = color.fg0 },
      Grey { fg = color.grey1 },
      Red { fg = color.red },
      Orange { fg = color.orange },
      Yellow { fg = color.yellow },
      Green { fg = color.green },
      Aqua { fg = color.aqua },
      Blue { fg = color.blue },
      Purple { fg = color.purple },

      RedItalic { fg = color.red, gui = "italic" },
      OrangeItalic { fg = color.orange, gui = "italic" },
      YellowItalic { fg = color.yellow, gui = "italic" },
      GreenItalic { fg = color.green, gui = "italic" },
      AquaItalic { fg = color.cyan, gui = "italic" },
      BlueItalic { fg = color.blue, gui = "italic" },
      PurpleItalic { fg = color.purple, gui = "italic" },
      PurpleBold { fg = color.purple, gui = "bold" },

      RedSign { fg = color.red, bg = color.bg1 },
      OrangeSign { fg = color.orange, bg = color.bg1 },
      YellowSign { fg = color.yellow, bg = color.bg1 },
      GreenSign { fg = color.green, bg = color.bg1 },
      AquaSign { fg = color.cyan, bg = color.bg1 },
      BlueSign { fg = color.blue, bg = color.bg1 },
      PurpleSign { fg = color.purple, bg = color.bg1 },

      -- ════════════════════════════════════════════════════════════════════
      -- DIAGNOSTICS
      -- ════════════════════════════════════════════════════════════════════
      DiagnosticOk { fg = color.green },
      DiagnosticError { fg = color.red },
      DiagnosticWarn { fg = color.orange },
      DiagnosticInfo { fg = color.cyan },
      DiagnosticHint { fg = color.grey2 },
      DiagnosticTitle { Title, fg = color.blue.darken(10) },
      DiagnosticUnnecessary { fg = color.bg4 },

      DiagnosticFloatingError { DiagnosticError },
      DiagnosticFloatingWarn { DiagnosticWarn },
      DiagnosticFloatingInfo { DiagnosticInfo },
      DiagnosticFloatingHint { DiagnosticHint },

      DiagnosticDefaultError { DiagnosticError },
      DiagnosticDefaultWarn { DiagnosticWarn },
      DiagnosticDefaultInfo { DiagnosticInfo },
      DiagnosticDefaultHint { DiagnosticHint },

      DiagnosticVirtualTextError { DiagnosticError, fg = DiagnosticError.fg.darken(30) },
      DiagnosticVirtualTextWarn { DiagnosticWarn, fg = DiagnosticWarn.fg.darken(30) },
      DiagnosticVirtualTextInfo { DiagnosticInfo, fg = DiagnosticInfo.fg.darken(40) },
      DiagnosticVirtualTextHint { DiagnosticHint, fg = DiagnosticHint.fg.darken(40) },

      DiagnosticSignOk { DiagnosticOk },
      DiagnosticSignError { DiagnosticError },
      DiagnosticSignWarn { DiagnosticWarn },
      DiagnosticSignInfo { DiagnosticInfo },
      DiagnosticSignHint { DiagnosticHint },

      DiagnosticSignErrorText { DiagnosticError },
      DiagnosticSignWarnText { DiagnosticWarn },
      DiagnosticSignInfoText {},
      DiagnosticSignHintText {},

      DiagnosticSignErrorLine { DiagnosticSignErrorText },
      DiagnosticSignWarnLine { DiagnosticSignWarnText },
      DiagnosticSignInfoLine { DiagnosticSignInfoText },
      DiagnosticSignHintLine { DiagnosticSignHintText },

      DiagnosticSignErrorNum { DiagnosticError },
      DiagnosticSignWarnNum { DiagnosticWarn },
      DiagnosticSignInfoNum { DiagnosticInfo },
      DiagnosticSignHintNum { DiagnosticHint },

      DiagnosticSignErrorCursorLine { fg = DiagnosticError.fg, gui = "bold" },
      DiagnosticSignWarnCursorLine { fg = DiagnosticWarn.fg, gui = "bold" },
      DiagnosticSignInfoCursorLine { fg = DiagnosticInfo.fg, gui = "bold" },
      DiagnosticSignHintCursorLine { fg = DiagnosticHint.fg, gui = "bold" },

      DiagnosticErrorBorder { DiagnosticError },
      DiagnosticWarnBorder { DiagnosticWarn },
      DiagnosticInfoBorder { DiagnosticInfo },
      DiagnosticHintBorder { DiagnosticHint },

      DiagnosticUnderlineError { bg = color.bg_red, sp = DiagnosticError.fg, gui = "undercurl,bold,italic" },
      DiagnosticUnderlineWarn { bg = color.bg_hard, sp = DiagnosticWarn.fg, gui = "italic,bold,undercurl" },
      DiagnosticUnderlineInfo { bg = color.bg_hard, sp = DiagnosticInfo.fg, gui = "italic" },
      DiagnosticUnderlineHint { bg = color.bg_hard, sp = DiagnosticHint.fg, gui = "italic" },

      -- Custom floating labels (statusline)
      DiagnosticFloatingErrorLabel { fg = color.bg2, bg = DiagnosticError.fg },
      DiagnosticFloatingWarnLabel { fg = color.bg2, bg = DiagnosticWarn.fg },
      DiagnosticFloatingInfoLabel { fg = color.bg2, bg = DiagnosticInfo.fg },
      DiagnosticFloatingHintLabel { fg = color.bg2, bg = DiagnosticHint.fg },

      -- ════════════════════════════════════════════════════════════════════
      -- LSP
      -- ════════════════════════════════════════════════════════════════════
      LspReferenceText { gui = "underline" },
      LspReferenceRead { gui = "underline" },
      LspReferenceWrite { DiagnosticInfo, bg = color.bg_hard, gui = "underline,bold,italic" },

      LspCodeLens { DiagnosticInfo, fg = color.bg2.lighten(3) },
      LspCodeLensSeparator { DiagnosticHint },

      LspInlayHint { NonText },
      LspInfoBorder { FloatBorder },
      LspSignatureActiveParameter { Visual },
      SnippetTabstop { Visual },

      -- ════════════════════════════════════════════════════════════════════
      -- NOTIFY
      -- ════════════════════════════════════════════════════════════════════
      NotifyERRORBorder { NotifyFloat },
      NotifyWARNBorder { NotifyFloat },
      NotifyINFOBorder { NotifyFloat },
      NotifyDEBUGBorder { NotifyFloat },
      NotifyERRORBody { NotifyFloat, fg = color.grey2 },
      NotifyWARNBody { NotifyFloat, fg = color.grey2 },
      NotifyINFOBody { NotifyFloat, fg = color.grey2 },
      NotifyDEBUGBody { NotifyFloat, fg = color.grey2 },
      NotifyERRORIcon { fg = color.red },
      NotifyWARNIcon { fg = color.orange },
      NotifyINFOIcon { fg = color.green },
      NotifyDEBUGIcon { fg = color.grey2 },
      NotifyERRORTitle { fg = color.red },
      NotifyWARNTitle { fg = color.orange },
      NotifyINFOTitle { fg = color.green },
      NotifyDEBUGTitle { fg = color.grey2 },

      MiniNotifyNormal { NotifyFloat, fg = color.grey2 },

      -- ════════════════════════════════════════════════════════════════════
      -- HEALTH
      -- ════════════════════════════════════════════════════════════════════
      healthError { Red },
      healthSuccess { Green },
      healthWarning { Yellow },

      -- ════════════════════════════════════════════════════════════════════
      -- HEADLINES / RENDER-MARKDOWN
      -- ════════════════════════════════════════════════════════════════════
      Headline1 { fg = color.green, bg = color.bg_green, gui = "bold,italic" },
      Headline2 { fg = color.yellow, bg = color.bg_yellow, gui = "bold" },
      Headline3 { fg = color.red, bg = color.bg_red, gui = "italic" },
      Headline4 { fg = color.purple, bg = color.bg0, gui = "bold,italic" },
      Headline5 { fg = color.blue, bg = color.bg0, gui = "bold" },
      Headline6 { fg = color.orange, bg = color.bg0, gui = "italic" },
      Dash { fg = color.bg3, gui = "bold" },
      CodeBlock { bg = color.bg1.darken(5) },

      RenderMarkdownDash { Dash },
      RenderMarkdownCode { CodeBlock },
      RenderMarkdownChecked { fg = color.green },
      RenderMarkdownUnchecked { fg = color.bg_green },
      RenderMarkdownTodo { RenderMarkdownUnchecked },

      RenderMarkdownH1 { fg = color.green, bg = color.bg_green, gui = "bold,italic" },
      RenderMarkdownH2 { fg = color.yellow, sp = color.bg_yellow.lighten(5), gui = "bold,italic,underline" },
      RenderMarkdownH3 { fg = color.purple, sp = color.bg_blue, gui = "underline" },
      RenderMarkdownH4 { fg = color.orange, gui = "bold" },
      RenderMarkdownH5 { fg = color.red, gui = "italic" },
      RenderMarkdownH6 { fg = color.brown },

      RenderMarkdownH1Bg { RenderMarkdownH1 },
      RenderMarkdownH2Bg { RenderMarkdownH2 },
      RenderMarkdownH3Bg { RenderMarkdownH3 },
      RenderMarkdownH4Bg { RenderMarkdownH4 },
      RenderMarkdownH5Bg { RenderMarkdownH5 },

      RenderMarkdownListWip { fg = color.blue },
      RenderMarkdownListTodo { fg = color.orange },
      RenderMarkdownListSkipped { fg = color.yellow },
      RenderMarkdownListTrash { fg = color.red },

      RenderMarkdownListYes { fg = color.green },
      RenderMarkdownListNo { fg = color.red },
      RenderMarkdownListFire { fg = color.red },
      RenderMarkdownListIdea { fg = color.yellow },
      RenderMarkdownListStar { fg = color.yellow },
      RenderMarkdownListQuestion { fg = color.yellow },
      RenderMarkdownListInfo { fg = color.cyan },
      RenderMarkdownListImportant { fg = color.orange },

      -- ════════════════════════════════════════════════════════════════════
      -- TREESITTER
      -- ════════════════════════════════════════════════════════════════════
      sym"@headline1" { Headline1 },
      sym"@headline2" { Headline2 },
      sym"@headline3" { Headline3 },
      sym"@headline4" { Headline4 },
      sym"@headline5" { Headline5 },
      sym"@headline6" { Headline6 },
      sym"@dash" { Dash },
      sym"@codeblock" { CodeBlock },

      sym"@text.title.1.markdown" { Headline1 },
      sym"@text.title.2.markdown" { Headline2 },
      sym"@text.title.3.markdown" { Headline3 },
      sym"@text.title.4.markdown" { Headline4 },
      sym"@text.title.5.markdown" { Headline5 },
      sym"@text.title.6.markdown" { Headline6 },

      sym"@annotation" { Purple },
      sym"@attribute" { Purple },
      sym"@boolean" { fg = color.magenta.lighten(5) },
      sym"@character" { Yellow },
      sym"@class" { Blue },
      sym"@character.special" { Yellow },
      sym"@conditional" { Red },
      sym"@constant" { PurpleItalic },
      sym"@constant.builtin" { PurpleItalic },
      sym"@constant.macro" { Purple },
      sym"@constructor" { Fg },
      sym"@emphasis" { gui = "italic" },
      sym"@exception" { Red },
      sym"@field" { fg = color.green },
      sym"@float" { Purple },
      sym"@function" { Blue },
      sym"@function.builtin" { Green },
      sym"@function.macro" { Green },
      sym"@function.call" { fg = color.cyan },
      sym"@include" { PurpleItalic },
      sym"@interface" { Purple },

      sym"@keyword" { Red },
      sym"@keyword.function" { fg = color.pale_red, gui = "bold,italic" },
      sym"@keyword.return" { fg = color.pale_red, gui = "bold,italic" },
      sym"@keyword.operator" { fg = color.red },
      sym"@keyword.modifier" { fg = color.blue.darken(5) },
      sym"@label" { Orange },
      sym"@macro" { Green, gui = "italic" },

      sym"@markup.list" { Special },
      sym"@markup.link.label" { Tag },
      sym"@markup.strong" { fg = color.fg0, gui = "bold" },
      sym"@markup.italic" { fg = color.fg0, gui = "italic" },
      sym"@markup.underline" { fg = color.fg0, gui = "underline" },
      sym"@markup.strikethrough" { fg = color.fg0, gui = "strikethrough" },
      sym"@markup.heading" { fg = color.orange, gui = "bold" },
      sym"@markup.heading.1" { fg = color.red, gui = "bold" },
      sym"@markup.heading.1.marker" { sym"@markup.heading" },
      sym"@markup.heading.2" { fg = color.yellow, gui = "bold" },
      sym"@markup.heading.2.marker" { sym"@markup.heading" },
      sym"@markup.heading.3" { fg = color.green, gui = "bold" },
      sym"@markup.heading.3.marker" { sym"@markup.heading" },
      sym"@markup.heading.4" { fg = color.cyan, gui = "bold" },
      sym"@markup.heading.4.marker" { sym"@markup.heading" },
      sym"@markup.heading.5" { fg = color.blue, gui = "bold" },
      sym"@markup.heading.5.marker" { sym"@markup.heading" },
      sym"@markup.heading.6" { fg = color.purple, gui = "bold" },
      sym"@markup.heading.6.marker" { sym"@markup.heading" },
      sym"@markup.raw" { Green },
      sym"@markup.raw.delimiter" { fg = color.fg3 },
      sym"@markup.link.url" { fg = color.cyan, gui = "underline,italic" },
      sym"@markup.list.checked" { fg = color.yellow, gui = "bold" },
      sym"@markup.list.unchecked" { fg = color.fg3, gui = "bold" },
      sym"@markup.math" { fg = color.bright_blue },
      sym"@markup.link" { Tag },
      sym"@markup.environment" { fg = color.cyan, gui = "bold" },
      sym"@markup.environment.name" { Type },

      sym"@markup.strong.markdown_inline" { fg = color.grey2, gui = "bold" },
      sym"@markup.italic.markdown_inline" { fg = color.grey0, gui = "italic" },
      sym"@markup.strikethrough.markdown_inline" { fg = color.dark_brown, gui = "strikethrough" },

      sym"@method" { Green },
      sym"@namespace" { BlueItalic, fg = color.bright_blue },
      sym"@number" { Purple },
      sym"@operator" { Orange },
      sym"@parameter" { fg = color.orange.lighten(25) },
      sym"@parameter.reference" { Fg },
      sym"@property" { fg = color.cyan.lighten(5) },
      sym"@punctuation" { Fg },
      sym"@punctuation.bracket" { sym"@punctuation" },
      sym"@punctuation.delimiter" { sym"@punctuation" },
      sym"@punctuation.special" { sym"@punctuation" },
      sym"@punctuation.tilda" { Dash, fg = Dash.fg.lighten(10) },
      sym"@repeat" { Red },
      sym"@regex" { Yellow },
      sym"@string" { Yellow },
      sym"@string.regex" { Blue },
      sym"@string.escape" { Purple },
      sym"@string.special" { Purple },
      sym"@strong" { gui = "bold" },
      sym"@structure" { Orange },
      sym"@symbol" { Green },
      sym"@tag" { Orange },
      sym"@tag.delimiter" { Green },
      sym"@tag.attribute" { Green },
      sym"@text" { Green },
      sym"@text.strong" { gui = "bold" },
      sym"@text.emphasis" { gui = "italic" },
      sym"@text.underline" { gui = "underline" },
      sym"@text.strike" { gui = "strikethrough" },
      sym"@text.math" { Green },
      sym"@text.environment" { Green },
      sym"@text.environment.name" { Green },
      sym"@text.title" { sym"@text.underline" },
      sym"@text.uri" { fg = color.blue },
      sym"@text.quote" { fg = color.fg0.darken(30), gui = "italic" },
      sym"@text.reference" { fg = color.cyan },
      sym"@type" { Aqua },
      sym"@type.builtin" { BlueItalic },
      sym"@type" { fg = color.cyan },
      sym"@type.builtin" { fg = color.blue.darken(5) },
      sym"@type.definition" { fg = color.cyan },

      sym"@underline" { gui = "underline" },
      sym"@uri" { fg = color.blue, gui = "underline" },
      sym"@variable" { fg = color.fg0 },
      sym"@variable.builtin" { PurpleItalic },
      sym"@variable.lua" { fg = color.fg0 },
      sym"@variable.member" { fg = color.purple },
      sym"@variable.member.lua" { fg = color.cyan },
      sym"@comment" { fg = color.fg3, gui = "italic" },
      sym"@error" { gui = "undercurl", sp = color.red },
      sym"@error.heex" {},
      sym"@error.elixir" {},

      -- Comment highlighting
      sym"@comment.fix" { bg = color.red, fg = color.bg_hard, gui = "bold,underline" },
      sym"@comment.error" { bg = color.red, fg = color.bg_hard, gui = "bold" },
      sym"@comment.warn" { bg = color.orange, fg = color.bg1, gui = "bold" },
      sym"@comment.todo" { fg = color.orange, bg = color.bg1 },
      sym"@comment.note" { fg = color.grey0, bg = color.bg_hard, gui = "italic" },
      sym"@comment.ref" { fg = color.bright_blue, bg = color.bg_hard, gui = "italic" },

      sym"@text.danger" { sym"@comment.fix" },
      sym"@text.warn" { sym"@comment.warn" },
      sym"@text.todo" { sym"@comment.todo" },
      sym"@text.note" { sym"@comment.note" },
      sym"@text.ref" { sym"@comment.ref" },

      sym"@text.gitcommit" { fg = color.fg0 },
      sym"@text.title.gitcommit" { fg = color.green },
      sym"@keyword.gitcommit" { bg = color.red, fg = color.bg_hard },

      -- ════════════════════════════════════════════════════════════════════
      -- LSP SEMANTIC TOKENS
      -- ════════════════════════════════════════════════════════════════════
      sym"@lsp.mod.deprecated" { sym"@constant" },
      sym"@lsp.mod.readonly" { sym"@constant" },
      sym"@lsp.mod.typeHint" { sym"@type" },
      sym"@lsp.type.boolean" { sym"@boolean" },
      sym"@lsp.type.builtinConstant" { sym"@constant.builtin" },
      sym"@lsp.type.builtinType" { sym"@type.builtin" },
      sym"@lsp.type.class" { sym"@type" },
      sym"@lsp.type.comment" {},
      sym"@lsp.type.decorator" { sym"@function" },
      sym"@lsp.type.derive" { sym"@constructor" },
      sym"@lsp.type.deriveHelper" { sym"@attribute" },
      sym"@lsp.type.enum" { sym"@type" },
      sym"@lsp.type.enumMember" { sym"@property" },
      sym"@lsp.type.escapeSequence" { sym"@string.escape" },
      sym"@lsp.type.formatSpecifier" { sym"@punctuation.special" },
      sym"@lsp.type.function" { sym"@function" },
      sym"@lsp.type.generic" { sym"@text" },
      sym"@lsp.type.interface" { sym"@type" },
      sym"@lsp.type.keyword" { sym"@keyword" },
      sym"@lsp.type.macro" { sym"@constant.macro" },
      sym"@lsp.type.magicFunction" { sym"@function.builtin" },
      sym"@lsp.type.method" { sym"@method" },
      sym"@lsp.type.namespace" { sym"@namespace" },
      sym"@lsp.type.number" { sym"@number" },
      sym"@lsp.type.operator" { sym"@operator" },
      sym"@lsp.type.parameter" { sym"@parameter" },
      sym"@lsp.type.property" { sym"@property" },
      sym"@lsp.type.regexp" { sym"@string.regex" },
      sym"@lsp.type.selfKeyword" { sym"@variable.builtin" },
      sym"@lsp.type.selfParameter" { sym"@variable.builtin" },
      sym"@lsp.type.selfTypeKeyword" { sym"@type" },
      sym"@lsp.type.string" { sym"@string" },
      sym"@lsp.type.struct" { sym"@type" },
      sym"@lsp.type.type" { sym"@type" },
      sym"@lsp.type.variable" { sym"@variable" },
      sym"@lsp.typemod.class.defaultLibrary" { sym"@type.builtin" },
      sym"@lsp.typemod.enum.defaultLibrary" { sym"@type.builtin" },
      sym"@lsp.typemod.enumMember.defaultLibrary" { sym"@constant.builtin" },
      sym"@lsp.typemod.function.defaultLibrary" { sym"@function.builtin" },
      sym"@lsp.typemod.function.readonly" { sym"@method" },
      sym"@lsp.typemod.keyword.async" { sym"@keyword" },
      sym"@lsp.typemod.keyword.injected" { sym"@keyword" },
      sym"@lsp.typemod.macro.defaultLibrary" { sym"@function.builtin" },
      sym"@lsp.typemod.method.defaultLibrary" { sym"@function.builtin" },
      sym"@lsp.typemod.operator.injected" { sym"@operator" },
      sym"@lsp.typemod.string.injected" { sym"@string" },
      sym"@lsp.typemod.struct.defaultLibrary" { sym"@type.builtin" },
      sym"@lsp.typemod.type.defaultLibrary" { sym"@type.builtin" },
      sym"@lsp.typemod.typeAlias.defaultLibrary" { sym"@type.builtin" },
      sym"@lsp.typemod.variable.callable" { sym"@function" },
      sym"@lsp.typemod.variable.constant.rust" { sym"@constant" },
      sym"@lsp.typemod.variable.defaultLibrary" { sym"@variable.builtin" },
      sym"@lsp.typemod.variable.defaultLibrary.javascript" { sym"@constant.builtin" },
      sym"@lsp.typemod.variable.defaultLibrary.javascriptreact" { sym"@constant.builtin" },
      sym"@lsp.typemod.variable.defaultLibrary.typescript" { sym"@constant.builtin" },
      sym"@lsp.typemod.variable.defaultLibrary.typescriptreact" { sym"@constant.builtin" },
      sym"@lsp.typemod.variable.global" { sym"@constant" },
      sym"@lsp.typemod.variable.injected" { sym"@variable" },
      sym"@lsp.typemod.variable.readonly" { sym"@constant" },
      sym"@lsp.typemod.variable.static" { Red },
      sym"@lsp.type.typeParameter" { sym"@type.definition" },
      sym"@lsp.type.unresolvedReference" { gui = "undercurl", sp = color.red },
      sym"@lsp.type.lifetime" { sym"@keyword.modifier" },
      sym"@lsp.type.modifier" { sym"@keyword.modifier" },
      sym"@lsp.typemod.property.readonly" { fg = color.blue },
      sym"@lsp.typemod.keyword.injected" { sym"@keyword" },

      sym"@markup.raw.block.markdown" { sym"@comment" },

      -- ════════════════════════════════════════════════════════════════════
      -- TREESITTER-CONTEXT
      -- ════════════════════════════════════════════════════════════════════
      TreesitterContext { bg = color.bg1.lighten(5) },
      TreesitterContextLineNumber { fg = LineNr.fg.darken(10), bg = TreesitterContext.bg, gui = "bold,italic" },
      TreesitterContextBottom { bg = TreesitterContext.bg },
      TreesitterContextLineNumberBottom { fg = LineNr.fg.lighten(20), bg = TreesitterContext.bg },
      TreesitterContextSeparator { bg = color.bg1.darken(5), fg = color.bg0.darken(20) },

      sym"@markdown.title" { Statement, bg = color.bg1, fg = color.red },
      markdownCode { fg = color.grey1, bg = color.bg1 },

      -- ════════════════════════════════════════════════════════════════════
      -- YAML
      -- ════════════════════════════════════════════════════════════════════
      yamlTodo { Todo },
      yamlComment { Comment },
      yamlDocumentStart { PreProc },
      yamlDocumentEnd { PreProc },
      yamlDirectiveName { Keyword },
      yamlTAGDirective { yamlDirectiveName },
      yamlTagHandle { String },
      yamlTagPrefix { String },
      yamlYAMLDirective { yamlDirectiveName },
      yamlReservedDirective { Error },
      yamlYAMLVersion { Number },
      yamlString { String },
      yamlFlowString { yamlString },
      yamlFlowStringDelimiter { yamlString },
      yamlEscape { SpecialChar },
      yamlSingleEscape { SpecialChar },
      yamlBlockCollectionItemStart { Label },
      yamlBlockMappingKey { Identifier },
      yamlBlockMappingMerge { Special },
      yamlFlowMappingKey { Identifier },
      yamlFlowMappingMerge { Special },
      yamlMappingKeyStart { Special },
      yamlFlowIndicator { Special },
      yamlKeyValueDelimiter { Special },
      yamlConstant { Constant },
      yamlNull { yamlConstant },
      yamlBool { yamlConstant },
      yamlAnchor { Type },
      yamlAlias { Type },
      yamlNodeTag { Type },
      yamlInteger { Number },
      yamlFloat { Float },
      yamlTimestamp { Number },

      -- ════════════════════════════════════════════════════════════════════
      -- DIFF
      -- ════════════════════════════════════════════════════════════════════
      diffAdded { Green },
      diffChanged { Blue },
      diffRemoved { Red },
      diffOldFile { Yellow },
      diffNewFile { Orange },
      diffFile { Aqua },
      diffLine { Grey },
      diffIndexLine { Purple },

      DiffAdd { bg = color.bg_green },
      DiffChange { bg = color.bg_yellow },
      DiffDelete { bg = color.bg_red },
      DiffText { bg = color.bg_blue },
      DiffBase { bg = color.bg_hard.lighten(10) },

      GitConflictCurrent { DiffAdd },
      GitConflictIncoming { DiffText },
      GitConflictAncestor { DiffBase },
      GitConflictCurrentLabel { DiffAdd, bg = color.green.darken(20) },
      GitConflictIncomingLabel { DiffText, bg = color.blue.darken(20) },
      GitConflictAncestorLabel { DiffBase, bg = color.grey1.darken(20) },

      sym"@text.diff.add" { DiffAdd },
      sym"@text.diff.change" { DiffChange },
      sym"@text.diff.delete" { DiffDelete },
      sym"@text.diff.text" { DiffText },
      sym"@text.diff.base" { DiffBase },

      -- Diffview
      DiffviewDiffAdd { bg = color.diff_add },
      DiffviewDiffAddText { bg = color.diff_add.mix(color.green, 25).lighten(3) },
      DiffviewDiffDelete { bg = color.diff_delete },
      DiffviewDiffDeleteText { bg = color.diff_delete.mix(color.red, 35) },
      DiffviewDiffFill { fg = color.comment.mix(color.bg0, 50), bg = color.bg0 },

      -- Git highlight groups
      GitAdded { fg = color.git_add },
      GitChanged { fg = color.git_change },
      GitDeleted { fg = color.git_delete },
      GitUntracked { fg = color.git_untracked },
      GitStaged { fg = color.git_staged },

      -- ════════════════════════════════════════════════════════════════════
      -- NETRW
      -- ════════════════════════════════════════════════════════════════════
      netrwDir { Green },
      netrwClassify { Green },
      netrwLink { Grey },
      netrwSymLink { Fg },
      netrwExe { Yellow },
      netrwComment { Grey },
      netrwList { Aqua },
      netrwHelpCmd { Blue },
      netrwCmdSep { Grey },
      netrwVersion { Orange },

      -- ════════════════════════════════════════════════════════════════════
      -- ELIXIR
      -- ════════════════════════════════════════════════════════════════════
      elixirAlias { SpecialChar },
      elixirAtom { Number },
      elixirStringDelimiter { Green },
      elixirKeyword { Orange },
      elixirInterpolation { Yellow },
      elixirInterpolationDelimiter { Yellow },
      elixirSelf { Purple },
      elixirPseudoVariable { Purple },
      elixirModuleDefine { Red, gui = "italic,bold" },
      elixirBlock { fg = color.brown },
      elixirBlockDefinition { RedItalic },
      elixirDefine { RedItalic, gui = "bold,italic" },
      elixirPrivateDefine { PurpleItalic },
      elixirGuard { RedItalic },
      elixirPrivateGuard { RedItalic },
      elixirProtocolDefine { RedItalic },
      elixirImplDefine { RedItalic },
      elixirRecordDefine { RedItalic },
      elixirPrivateRecordDefine { RedItalic },
      elixirMacroDefine { RedItalic },
      elixirPrivateMacroDefine { RedItalic },
      elixirDelegateDefine { RedItalic },
      elixirOverridableDefine { RedItalic },
      elixirExceptionDefine { RedItalic },
      elixirCallbackDefine { RedItalic },
      elixirStructDefine { RedItalic },
      elixirExUnitMacro { RedItalic },

      -- ════════════════════════════════════════════════════════════════════
      -- GITCOMMIT
      -- ════════════════════════════════════════════════════════════════════
      gitcommitSummary { Red },
      gitcommitUntracked { Grey },
      gitcommitDiscarded { Grey },
      gitcommitSelected { Grey },
      gitcommitUnmerged { Grey },
      gitcommitOnBranch { Grey },
      gitcommitArrow { Grey },
      gitcommitFile { Green },

      -- ════════════════════════════════════════════════════════════════════
      -- HELP
      -- ════════════════════════════════════════════════════════════════════
      helpNote { fg = color.purple, gui = "bold" },
      helpHeadline { fg = color.red, gui = "bold" },
      helpHeader { fg = color.orange, gui = "bold" },
      helpURL { fg = color.green, gui = "underline" },
      helpHyperTextEntry { fg = color.yellow, gui = "bold" },
      helpHyperTextJump { Yellow },
      helpCommand { Aqua },
      helpExample { Green },
      helpSpecial { Blue },
      helpSectionDelim { Grey },

      -- ════════════════════════════════════════════════════════════════════
      -- NVIM-CMP / BLINK.CMP
      -- ════════════════════════════════════════════════════════════════════
      CmpItemKind { Special },
      CmpItemAttr { Comment },
      CmpItemAbbrDeprecated { fg = color.grey1, gui = "strikethrough" },
      CmpDocumentation { fg = color.fg0, bg = color.bg1 },
      CmpDocumentationBorder { fg = color.fg0, bg = color.bg1 },
      CmpItemAbbr { fg = color.fg0 },
      CmpItemAbbrMatch { fg = color.blue, gui = "bold,italic" },
      CmpItemAbbrMatchFuzzy { fg = color.cyan.darken(5), gui = "italic" },
      CmpItemMenu { NonText, gui = "italic" },
      CmpItemKindText { fg = color.yellow },
      CmpItemKindMethod { fg = color.blue },
      CmpItemKindFunction { CmpItemKindMethod },
      CmpItemKindConstructor { fg = color.cyan },
      CmpItemKindField { fg = color.fg0 },
      CmpItemKindVariable { fg = color.red },
      CmpItemKindClass { fg = color.yellow },
      CmpItemKindInterface { CmpItemKindClass },
      CmpItemKindProperty { fg = color.red },
      CmpItemKindValue { fg = color.orange },
      CmpItemKindKeyword { fg = color.purple },
      CmpItemKindSnippet { fg = color.green },
      CmpItemKindConstant { fg = color.green },
      CmpBorderedWindow_Normal { Normal, bg = color.bg1 },
      CmpBorderedWindow_FloatBorder { Normal, fg = color.bg1, bg = color.bg1 },
      CmpBorderedWindow_CursorLine { Visual, bg = color.bg1 },

      BlinkCmpLabel { fg = color.fg0 },
      BlinkCmpLabelMatch { CmpItemAbbrMatch },
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
      -- LUASNIP
      -- ════════════════════════════════════════════════════════════════════
      SimpleF { fg = color.magenta, bg = color.bg_hard, gui = "bold,underline" },

      -- ════════════════════════════════════════════════════════════════════
      -- INDENT-BLANKLINE
      -- ════════════════════════════════════════════════════════════════════
      IndentBlanklineChar { fg = color.bg1.lighten(3) },
      IndentBlanklineContextChar { fg = color.bg_blue },
      IndentBlanklineContextStart { sp = color.bg_blue.lighten(10), gui = "underline" },

      -- ════════════════════════════════════════════════════════════════════
      -- MINI
      -- ════════════════════════════════════════════════════════════════════
      MiniIndentscopeSymbol { fg = color.teal.darken(30) },

      MiniJump { fg = color.blue, bg = color.bg_blue, gui = "bold,underline" },
      MiniJump2dSpot { fg = color.purple, bg = color.bg_purple, gui = "bold,underline" },
      MiniJump2dSpotAhead { fg = color.green, bg = color.bg_green, gui = "bold,underline" },
      MiniJump2dSpotUnique { fg = color.red, bg = color.bg_red, gui = "bold,underline" },
      MiniJump2dDim { Comment },

      MiniHipatternsFixme { sym"@comment.fix" },
      MiniHipatternsError { sym"@comment.error" },
      MiniHipatternsWarn { sym"@comment.warn" },
      MiniHipatternsHack { sym"@comment.warn" },
      MiniHipatternsTodo { sym"@comment.todo" },
      MiniHipatternsNote { sym"@comment.note" },
      MiniHipatternsRef { sym"@comment.ref", gui = "bold" },

      MiniStarterSection { fg = color.fg0, bg = color.bg0, bold = true },
      MiniStarterFooter { Comment },

      MiniCursorword { bg = Normal.bg.lighten(10) },

      -- ════════════════════════════════════════════════════════════════════
      -- MINI.PICK
      -- ════════════════════════════════════════════════════════════════════
      MiniPickNormal { fg = color.fg0, bg = color.bg3.darken(25) },
      MiniPickBorder { fg = color.bg0, bg = color.bg3.darken(25) },
      MiniPickHeader { fg = color.red, bg = color.bg2.darken(20) },
      MiniPickMatchCurrent { bg = color.bg2.darken(20), gui = "italic,bold" },
      MiniPickMatchMarked { Title, gui = "italic" },
      MiniPickMatchRanges { Title, gui = "italic" },
      MiniPickPreviewLine { bg = PanelBackground.bg, fg = PanelBackground.bg },
      MiniPickPreviewRegion { bg = PanelBackground.bg, fg = PanelBackground.bg },
      MiniPickPrompt { fg = color.fg0.darken(30), bg = MiniPickNormal.bg },
      MiniPickPromptPrefix { fg = color.orange, bg = MiniPickNormal.bg },
      MiniPickPromptCaret { MiniPickNormal },
      MiniPickSelection { bg = color.bg3, gui = "bold,italic" },
      MiniPickSelectionCaret { fg = color.orange, bg = color.bg3 },

      -- ════════════════════════════════════════════════════════════════════
      -- LEAP
      -- ════════════════════════════════════════════════════════════════════
      LeapBackdrop { fg = "#707070" },
      LeapLabelPrimary { fg = "#ccff88", gui = "italic" },
      LeapLabelSecondary { fg = "#99ccff" },
      LeapLabelSelected { fg = "Magenta" },

      -- ════════════════════════════════════════════════════════════════════
      -- TABLINE
      -- ════════════════════════════════════════════════════════════════════
      TabLine { fg = "#abb2bf", bg = color.bg1 },
      TabLineTabActive { fg = color.green, bg = color.bg0, gui = "bold,italic" },
      TabLineWinActive { fg = color.green, bg = color.bg0, gui = "italic" },
      TabLineInactive { fg = color.grey2, bg = color.bg1 },
      TabFill { TabLine },
      TabLineFill { TabFill },
      TabLineSel { TabLineTabActive },
      TabLineHead { fg = color.bg_hard, bg = color.bg_hard },

      NavicSeparator { bg = color.bg_hard },

      -- ════════════════════════════════════════════════════════════════════
      -- PANELS & TERMINALS
      -- ════════════════════════════════════════════════════════════════════
      DarkenedPanel { bg = color.bg1 },
      DarkenedStatusline { bg = color.bg1 },
      DarkenedStatuslineNC { gui = "italic", bg = color.bg1 },

      PanelBackground { fg = color.fg0.darken(10), bg = color.bg0.darken(15) },
      PanelBorder { fg = PanelBackground.bg.darken(10), bg = PanelBackground.bg },
      PanelHeading { PanelBackground, gui = "bold" },
      PanelVertSplit { VertSplit, bg = color.bg0.darken(8) },
      PanelStNC { PanelVertSplit },
      PanelSt { bg = color.bg_blue.darken(20) },

      -- ════════════════════════════════════════════════════════════════════
      -- STATUSLINE
      -- ════════════════════════════════════════════════════════════════════
      StatusLineBg {},
      StatusLine { fg = color.grey1 },
      StatusLineNC { fg = color.grey1, bg = color.bg0 },
      StatusLineTerm { fg = color.grey1, bg = color.bg0 },
      StatusLineInactive { fg = color.bg_hard.lighten(20), bg = color.bg_hard, gui = "italic" },

      StModeNormal { fg = color.bg5.li(20) },
      StModeInsert { fg = color.green, gui = "bold" },
      StModeVisual { fg = color.magenta, gui = "bold" },
      StModeReplace { fg = color.dark_red, gui = "bold" },
      StModeCommand { fg = color.green, gui = "bold" },
      StModeOther { fg = color.fg2 },
      StModeTermNormal { StModeNormal },
      StModeTermInsert { StModeTermNormal, fg = color.green, gui = "bold,italic", sp = color.green },

      StBright { fg = color.fg0.lighten(10) },
      StBrightItalic { StBright, fg = StBright.fg.darken(5), gui = "italic" },
      StMetadata { Comment },
      StMetadataPrefix { fg = color.fg0 },
      StLspMessages { fg = color.fg0.darken(20), gui = "italic" },
      StIndicator { fg = color.dark_blue },
      StModified { fg = color.pale_red, gui = "bold,italic" },
      StModifiedIcon { fg = color.pale_red, gui = "bold" },
      StGitSymbol { fg = color.light_red },
      StGitBranch { fg = color.blue },
      StGitSigns { fg = color.dark_blue },
      StGitSignsAdd { GreenSign },
      StGitSignsDelete { RedSign },
      StGitSignsChange { OrangeSign },
      StNumber { fg = color.purple },
      StCount { fg = color.bg0, bg = color.blue, gui = "bold" },
      StPrefix { fg = color.fg0, bg = color.bg2 },
      StDirectory { fg = color.grey0, gui = "italic" },
      StParentDirectory { fg = color.blue, gui = "italic" },
      StFilename { fg = color.fg0, gui = "bold" },
      StFilenameInactive { fg = color.fg3, gui = "italic,bold" },
      StIdentifier { fg = color.blue },
      StTitle { fg = color.grey2, gui = "bold" },
      StComment { Comment },
      StLineNumber { fg = color.grey2, gui = "bold" },
      StLineSep { fg = color.grey0 },
      StLineTotal { fg = color.grey1 },
      StLineColumn { fg = color.grey2 },
      StClient { fg = color.fg0, gui = "bold" },
      StError { fg = DiagnosticError.fg },
      StWarn { fg = DiagnosticWarn.fg },
      StInfo { fg = DiagnosticInfo.fg },
      StHint { fg = DiagnosticHint.fg },
      StBufferCount { fg = DiagnosticInfo.fg },
      StSeparator { fg = color.bg0 },

      -- Jujutsu (jj) highlights
      StJjIcon { fg = color.magenta },
      StJjChangeId { fg = color.cyan },
      StJjBookmark { fg = color.blue, gui = "italic" },
      StJjConflict { fg = color.red, gui = "bold" },

      -- ════════════════════════════════════════════════════════════════════
      -- STATUSCOLUMN
      -- ════════════════════════════════════════════════════════════════════
      StatusColumnActiveBorder { bg = color.bg1, fg = "#7c8378" },
      StatusColumnActiveLineNr { fg = "#7c8378" },
      StatusColumnInactiveBorder { bg = NormalNC.bg, fg = color.bg_hard.lighten(15) },
      StatusColumnInactiveLineNr { fg = color.bg_hard.lighten(10) },

      -- ════════════════════════════════════════════════════════════════════
      -- WINBAR
      -- ════════════════════════════════════════════════════════════════════
      WinBar { StatusLine, fg = Title.fg, gui = "italic" },
      WinBarNC { StatusLineInactive },

      -- ════════════════════════════════════════════════════════════════════
      -- TS-RAINBOW / RAINBOW-DELIMITERS
      -- ════════════════════════════════════════════════════════════════════
      rainbowcol1 { fg = color.red },
      rainbowcol2 { fg = color.yellow },
      rainbowcol3 { fg = color.green },
      rainbowcol4 { fg = color.blue },
      rainbowcol5 { fg = color.cyan },
      rainbowcol6 { fg = color.magenta },
      rainbowcol7 { fg = color.purple },

      RainbowDelimiterRed { fg = color.red },
      RainbowDelimiterYellow { fg = color.yellow },
      RainbowDelimiterBlue { fg = color.blue },
      RainbowDelimiterOrange { fg = color.orange },
      RainbowDelimiterGreen { fg = color.green },
      RainbowDelimiterViolet { fg = color.purple },
      RainbowDelimiterCyan { fg = color.cyan },

      -- ════════════════════════════════════════════════════════════════════
      -- TELESCOPE
      -- ════════════════════════════════════════════════════════════════════
      TelescopeNormal { fg = color.fg0, bg = color.bg3.darken(25) },
      TelescopeBorder { fg = color.bg0, bg = color.bg3.darken(25) },
      TelescopeMatching { Title },
      TelescopeTitle { Normal, gui = "bold" },
      TelescopePreviewTitle { fg = color.fg0, bg = color.bg_blue, gui = "italic" },
      TelescopePreviewBorder { bg = PanelBackground.bg, fg = PanelBackground.bg },
      TelescopePreviewNormal { bg = PanelBackground.bg, fg = PanelBackground.bg },
      TelescopePrompt { bg = color.bg2.darken(10) },
      TelescopePromptPrefix { fg = color.orange, bg = color.bg2.darken(10) },
      TelescopePromptBorder { fg = color.bg2.darken(10), bg = color.bg2.darken(10) },
      TelescopePromptNormal { fg = color.fg0, bg = color.bg2.darken(10) },
      TelescopePromptTitle { fg = color.bg0, bg = color.bg_cyan },
      TelescopeSelection { bg = color.bg3, gui = "bold,italic" },
      TelescopeSelectionCaret { fg = color.fg0, bg = color.bg3 },
      TelescopeResults {},
      TelescopeResultsTitle { fg = color.bg0, bg = color.fg0, gui = "bold" },
      EgrepifySuffix { fg = color.bright_blue.darken(20), bg = color.bg_hard.lighten(5) },

      -- ════════════════════════════════════════════════════════════════════
      -- SNACKS.PICK
      -- ════════════════════════════════════════════════════════════════════
      SnacksPicker { TelescopeNormal },
      SnacksPickerDir { fg = color.grey2, gui = "italic" },
      SnacksPickerBorder { TelescopeBorder },
      SnacksPickerListCursorLine { TelescopeSelection },
      SnacksPickerPrompt { TelescopePromptPrefix },
      SnacksPickerSelected { TelescopeSelectionCaret },
      SnacksPickerTitle { TelescopeTitle },
      SnacksPickerPreview { TelescopePreviewNormal },
      SnacksPickerPreviewBorder { TelescopePreviewBorder },
      SnacksPickerPreviewTitle { TelescopePreviewTitle },
      SnacksPickerPreviewCursorLine { bg = color.bg2.lighten(6) },
      SnacksPickerMatch { fg = Normal.bg, bg = color.cyan },
      SnacksPickerPathHidden { fg = color.fg0 },
      SnacksPickerTotals { fg = color.comment },
      SnacksPickerBufNr { fg = color.comment },
      SnacksPickerRow { fg = color.comment },
      SnacksPickerCol { fg = color.comment },
      SnacksPickerTree { fg = color.bg5 },

      SnacksPickerGitStatusAdded { GitAdded },
      SnacksPickerGitStatusModified { GitChanged },
      SnacksPickerGitStatusStaged { GitStaged },
      SnacksPickerGitStatusUntracked { GitUntracked },

      -- ════════════════════════════════════════════════════════════════════
      -- SNACKS (other)
      -- ════════════════════════════════════════════════════════════════════
      SnacksIndent { fg = color.comment.mix(color.bg0, 80) },
      SnacksIndentScope { fg = color.comment },

      SnacksInputNormal { bg = color.bg2 },
      SnacksInputBorder { fg = color.bg2, bg = color.bg2 },
      SnacksInputTitle { fg = color.comment, bg = color.bg2 },

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
      TroubleText { PanelBackground },
      TroubleIndent { PanelVertSplit },
      TroubleFoldIcon { fg = color.yellow, gui = "bold" },
      TroubleLocation { fg = Comment.fg },
      TroublePreview { bg = color.bg_visual, gui = "bold,italic,underline" },
      TroubleDirectory { fg = color.fg1 },
      TroubleFilename { fg = color.fg1, bold = true },

      -- ════════════════════════════════════════════════════════════════════
      -- DAP
      -- ════════════════════════════════════════════════════════════════════
      DapBreakpoint { fg = color.light_red },
      DapStopped { fg = color.green },
      DapLogPoint { fg = color.blue },
      DapBreakpointCondition { fg = color.yellow },
      DapBreakpointRejected { fg = color.comment },

      -- ════════════════════════════════════════════════════════════════════
      -- FIDGET
      -- ════════════════════════════════════════════════════════════════════
      FidgetTitle { fg = color.orange },
      FidgetTask { fg = color.grey2, bg = color.bg1.darken(10) },

      -- ════════════════════════════════════════════════════════════════════
      -- NOTIFIER
      -- ════════════════════════════════════════════════════════════════════
      NotifierTitle { fg = color.orange },
      NotifierContent { NormalFloat },
      NotifierContentDim { fg = color.grey1, bg = color.bg1.darken(10), gui = "italic" },

      -- ════════════════════════════════════════════════════════════════════
      -- BQF
      -- ════════════════════════════════════════════════════════════════════
      BqfPreviewFloat { PanelBackground },
      BqfPreviewTitle { bg = color.bg_hard, fg = color.brown },
      BqfPreviewBorder { bg = color.bg_hard, fg = color.bg_blue },
      qfPosition { Todo },

      -- ════════════════════════════════════════════════════════════════════
      -- NEO-TREE
      -- ════════════════════════════════════════════════════════════════════
      NeoTreeIndentMarker { Comment },
      NeoTreeNormal { PanelBackground },
      NeoTreeNormalNC { PanelBackground },
      NeoTreeRootName { fg = color.cyan, gui = "bold,italic,underline" },
      NeoTreeFileNameOpened { bg = color.fg0, fg = color.fg0, gui = "underline,bold" },
      NeoTreeCursorLine { Visual },
      NeoTreeStatusLine { PanelSt },
      NeoTreeTitleBar { fg = color.red, bg = color.bg_hard },
      NeoTreeFloatBorder { PanelBackground, fg = color.bg0 },
      NeoTreeFloatTitle { fg = Comment.fg, bg = color.bg2 },
      NeoTreeTabActive { bg = PanelBackground.bg, gui = "bold" },
      NeoTreeTabInactive { bg = PanelBackground.bg.darken(15), fg = Comment.fg },
      NeoTreeTabSeparatorInactive { bg = PanelBackground.bg.darken(15), fg = PanelBackground.bg },
      NeoTreeTabSeparatorActive { PanelBackground, fg = Comment.fg },

      -- ════════════════════════════════════════════════════════════════════
      -- GITSIGNS
      -- ════════════════════════════════════════════════════════════════════
      GitSignsAdd { fg = color.bright_green },
      GitSignsAddCul { fg = color.bright_green, bg = color.bg_hard },
      GitSignsDelete { fg = color.red },
      GitSignsDeleteCul { fg = color.red, bg = color.bg_hard },
      GitSignsTopdelete { GitSignsDelete },
      GitSignsChange { fg = color.orange },
      GitSignsChangeCul { fg = color.orange, bg = color.bg_hard },
      GitSignsChangedelete { GitSignsChange },
      GitSignsUntracked { GitUntracked },

      GitSignsStagedAdd { fg = GitSignsAdd.fg.mix(Normal.bg, 70) },
      GitSignsStagedChange { fg = GitSignsChange.fg.mix(Normal.bg, 70) },
      GitSignsStagedDelete { fg = GitSignsDelete.fg.mix(Normal.bg, 70) },
      GitSignsStagedUntracked { fg = GitUntracked.fg.mix(Normal.bg, 70) },

      GitSignsAddNr { fg = color.bright_green },
      GitSignsDeleteNr { fg = color.red },
      GitSignsChangeNr { fg = color.orange },

      GitSignsAddPreview { fg = color.green, DiffviewDiffAdd },
      GitSignsDeletePreview { fg = color.red, DiffviewDiffDelete },
      GitSignsAddInline { DiffviewDiffAddText },
      GitSignsDeleteInline { DiffviewDiffDeleteText },

      -- ════════════════════════════════════════════════════════════════════
      -- MISC
      -- ════════════════════════════════════════════════════════════════════
      TmuxPopupNormal { bg = color.bg1 },
      VirtColumn { Whitespace, bg = color.bg0 },

      -- Flash
      FlashBackdrop { Comment },
      FlashMatch { Search },
      FlashCurrent { IncSearch },
      FlashLabel { fg = color.bright_blue_alt, bg = color.bg_blue, gui = "bold,underline" },
      FlashPrompt { bg = color.bg1 },
      FlashPromptIcon { bg = color.bg1 },

      -- Neorg
      sym"@neorg.headings.1.title" { gui = "italic" },
      sym"@neorg.headings.2.title" { gui = "italic" },
      sym"@neorg.headings.3.title" { gui = "italic" },
      sym"@neorg.headings.4.title" { gui = "italic" },
      sym"@neorg.headings.5.title" { gui = "italic" },
      sym"@neorg.headings.6.title" { gui = "italic" },

      -- Symbol-usage
      SymbolUsageRounding { CursorLine, gui = "italic" },
      SymbolUsageContent { fg = color.bg_hard.lighten(18), gui = "italic" },
      SymbolUsageRef { fg = Function.fg, gui = "italic" },
      SymbolUsageDef { fg = Type.fg, gui = "italic" },
      SymbolUsageImpl { fg = Keyword.fg, gui = "italic" },

      -- Oil
      OilDir { Directory },
      OilDirIcon { Directory },
      OilLink { Constant },
      OilLinkTarget { Comment },
      OilCopy { DiagnosticSignHint, gui = "bold" },
      OilMove { DiagnosticSignWarn, gui = "bold" },
      OilChange { DiagnosticSignWarn, gui = "bold" },
      OilCreate { DiagnosticSignInfo, gui = "bold" },
      OilDelete { DiagnosticSignError, gui = "bold" },
      OilPermissionNone { NonText },
      OilPermissionRead { DiagnosticSignWarn },
      OilPermissionWrite { DiagnosticSignError },
      OilPermissionExecute { DiagnosticSignOk },
      OilTypeDir { Directory },
      OilTypeFifo { Special },
      OilTypeFile { NonText },
      OilTypeLink { Constant },
      OilTypeSocket { Keyword },

      -- Misc
      ZenBg { fg = color.fg0, bg = color.bg0 },
      WinShiftMove { bg = Normal.bg.lighten(7) },
      TabsVsSpaces { fg = color.comment, underline = true },
      NvimSurroundHighlight { fg = Normal.bg, bg = color.cyan },

      -- Noice
      NoiceCmdline { bg = color.bg1 },
      NoiceLspProgressTitle { fg = color.fg2, bg = color.bg1 },
      NoiceLspProgressClient { fg = color.fg1, bg = color.bg1 },
      NoiceLspProgressSpinner { fg = color.yellow.mix(color.bg1, 50), bg = color.bg1 },

      -- Multi-cursor
      MultiCursorCursor { fg = color.fg_bright.mix(color.bg0, 50), reverse = true },
      MultiCursorVisual { bg = color.comment },
      MultiCursorSign { fg = color.fg_bright.mix(color.bg0, 50) },
      MultiCursorDisabledCursor { bg = color.red },
      MultiCursorDisabledVisual { bg = color.comment },
      MultiCursorDisabledSign { bg = color.red },

      -- Which-key
      WhichKey { fg = color.cyan },
      WhichKeyGroup { fg = color.blue },
      WhichKeyDesc { fg = color.fg0 },
      WhichKeySeparator { fg = color.comment },
      WhichKeyFloat { NormalFloat },
      WhichKeyBorder { FloatBorder },
      WhichKeyValue { Comment },
    }
  end)
  -- stylua: ignore end

  lush(theme)

  vim.api.nvim_exec_autocmds("User", { pattern = "ThemeApplied" })
end
