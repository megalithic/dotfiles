return {
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- if pcall(require, "lush") then
      --   local lush = require("lush")
      --   local base = require("forestbones")
      --   local C = require("lush_theme.colors")

      --   -- Create some specs
      --   local specs = lush.parse(function()
      --     return {
      --       Normal({ fg = C.fg, bg = C.transparent }), -- normal text
      --       NormalNC({ bg = C.bg0.da(7) }), -- inactive window split
      --       NonText({ fg = C.bg4, bg = C.transparent }), -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.

      --       CursorColumn({ fg = C.transparent, bg = C.bg2 }), -- Screen-column at the cursor, when 'cursorcolumn' is set.
      --       CursorWord({ fg = C.transparent, bg = C.transparent, gui = "bold,underline" }),
      --       CursorLine({ bg = C.bg2 }), -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR fg) is not set.
      --       LineNr({ fg = C.grey0, bg = C.transparent }), -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
      --       CursorLineNr({ CursorLine, fg = C.brown, bg = C.bg0.li(5), gui = "bold,italic" }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
      --       -- CursorLineNrNC({ CursorLine, fg = C.transparent, bg = C.bg2 }), -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
      --       -- CursorLineSign({ bg = C.red }),
      --       VertSplit({ fg = C.bg4, bg = C.transparent }), -- the column separating vertically split windows
      --       WinSeparator({ fg = C.bg_dark.li(15), bg = C.bg_dark.li(1), gui = "bold" }),

      --       Title({ fg = C.orange, bg = C.transparent, gui = "bold" }),

      --       RedSign({ fg = C.red, bg = C.bg1 }),
      --       OrangeSign({ fg = C.orange, bg = C.bg1 }),
      --       YellowSign({ fg = C.yellow, bg = C.bg1 }),
      --       GreenSign({ fg = C.green, bg = C.bg1 }),
      --       AquaSign({ fg = C.cyan, bg = C.bg1 }),
      --       BlueSign({ fg = C.blue, bg = C.bg1 }),
      --       PurpleSign({ fg = C.purple, bg = C.bg1 }),

      --       ---- :help diagnostic-highlight ----------------------------

      --       DiagnosticOk({ fg = C.green, bg = C.transparent }),
      --       DiagnosticError({ fg = C.red, bg = C.transparent }),
      --       DiagnosticWarn({ fg = C.orange, bg = C.transparent }),
      --       DiagnosticInfo({ fg = C.cyan, bg = C.transparent }),
      --       DiagnosticHint({ fg = C.grey2, bg = C.transparent }),
      --       DiagnosticTitle({ Title, fg = C.blue.darken(10) }),

      --       -- REF: https://github.com/neovim/neovim/pull/15585
      --       DiagnosticFloatingError({ DiagnosticError }),
      --       DiagnosticFloatingWarn({ DiagnosticWarn }),
      --       DiagnosticFloatingInfo({ DiagnosticInfo }),
      --       DiagnosticFloatingHint({ DiagnosticHint }),

      --       DiagnosticDefaultError({ DiagnosticError }),
      --       DiagnosticDefaultWarn({ DiagnosticWarn }),
      --       DiagnosticDefaultInfo({ DiagnosticInfo }),
      --       DiagnosticDefaultHint({ DiagnosticHint }),

      --       DiagnosticVirtualTextError({ DiagnosticError, fg = DiagnosticError.fg.darken(30) }),
      --       DiagnosticVirtualTextWarn({ DiagnosticWarn, fg = DiagnosticWarn.fg.darken(30) }),
      --       DiagnosticVirtualTextInfo({ DiagnosticInfo, fg = DiagnosticInfo.fg.darken(40) }),
      --       DiagnosticVirtualTextHint({ DiagnosticHint, fg = DiagnosticHint.fg.darken(40) }),

      --       DiagnosticSignOk({ DiagnosticOk }),
      --       DiagnosticSignError({ DiagnosticError }),
      --       DiagnosticSignWarn({ DiagnosticWarn }),
      --       DiagnosticSignInfo({ DiagnosticInfo }),
      --       DiagnosticSignHint({ DiagnosticHint }),

      --       -- DiagnosticSignErrorText({ DiagnosticError, bg = C.bg_dark, sp = C.red, gui = "italic,undercurl,bold" }),
      --       -- DiagnosticSignWarnText({ DiagnosticWarn, bg = C.bg_dark, sp = C.orange, gui = "italic,bold" }),
      --       -- DiagnosticSignInfoText({ gui = "italic,bold" }),
      --       -- DiagnosticSignHintText({ gui = "italic,bold" }),

      --       DiagnosticSignErrorText({ DiagnosticError }),
      --       DiagnosticSignWarnText({ DiagnosticWarn }),
      --       DiagnosticSignInfoText({}),
      --       DiagnosticSignHintText({}),
      --       -- DiagnosticSignHintText({ fg = C.red, bg = C.red, sp = C.red, gui = "underline" }),

      --       DiagnosticSignErrorLine({ DiagnosticSignErrorText }),
      --       DiagnosticSignWarnLine({ DiagnosticSignWarnText }),
      --       DiagnosticSignInfoLine({ DiagnosticSignInfoText }),
      --       DiagnosticSignHintLine({ DiagnosticSignHintText }),
      --       -- DiagnosticSignHintLine({ fg = C.red, bg = C.bg_dark, sp = C.red, gui = "" }),

      --       DiagnosticSignErrorNum({ DiagnosticError }),
      --       DiagnosticSignWarnNum({ DiagnosticWarn }),
      --       DiagnosticSignInfoNum({ DiagnosticInfo }),
      --       DiagnosticSignHintNum({ DiagnosticHint }),
      --       -- DiagnosticSignHintNum({ fg = C.red, bg = C.bg_dark, sp = C.red, gui = "" }),

      --       DiagnosticSignErrorCursorLine({ fg = DiagnosticError.fg, gui = "bold" }),
      --       DiagnosticSignWarnCursorLine({ fg = DiagnosticWarn.fg, gui = "bold" }),
      --       DiagnosticSignInfoCursorLine({ fg = DiagnosticInfo.fg, gui = "bold" }),
      --       DiagnosticSignHintCursorLine({ fg = DiagnosticHint.fg, gui = "bold" }),
      --       -- DiagnosticSignHintCursorLine({ fg = C.red, bg = C.bg_dark, sp = C.red, gui = "underline" }),

      --       DiagnosticErrorBorder({ DiagnosticError }),
      --       DiagnosticWarnBorder({ DiagnosticWarn }),
      --       DiagnosticInfoBorder({ DiagnosticInfo }),
      --       DiagnosticHintBorder({ DiagnosticHint }),

      --       -- affects individual bits of code that are errored:
      --       DiagnosticUnderlineError({
      --         fg = C.transparent,
      --         bg = C.bg_red,
      --         sp = DiagnosticError.fg,
      --         gui = "undercurl,bold,italic",
      --       }),
      --       DiagnosticUnderlineWarn({ fg = C.transparent, bg = C.bg_dark, sp = DiagnosticWarn.fg, gui = "italic,bold,undercurl" }),
      --       DiagnosticUnderlineInfo({ fg = C.transparent, bg = C.bg_dark, sp = DiagnosticInfo.fg, gui = "italic" }),
      --       DiagnosticUnderlineHint({ fg = C.transparent, bg = C.bg_dark, sp = DiagnosticHint.fg, gui = "italic" }),

      --       ---- :help tabline ---------------------------------------------------------

      --       TabLine({ fg = "#abb2bf", bg = C.bg1 }),

      --       -- TabLineHead({ fg = C.bg1, bg = C.bg2 }),
      --       TabLineTabActive({ fg = C.green, bg = C.bg0, gui = "bold,italic" }),
      --       TabLineWinActive({ fg = C.green, bg = C.bg0, gui = "italic" }),
      --       TabLineInactive({ fg = C.grey2, bg = C.bg1 }),
      --       TabFill({ TabLine }),

      --       TabLineFill({ TabFill }),
      --       TabLineSel({ TabLineTabActive }),
      --       TabLineHead({ fg = C.bg_dark, bg = C.bg_dark }),

      --       NavicSeparator({ bg = C.bg_dark }),

      --       ---- :help megaterm  -----------------------------------------------------

      --       DarkenedPanel({ bg = C.bg1 }),
      --       DarkenedStatusline({ bg = C.bg1 }),
      --       DarkenedStatuslineNC({ gui = "italic", bg = C.bg1 }),

      --       ---- sidebar  -----------------------------------------------------

      --       PanelBackground({ fg = C.fg.darken(10), bg = C.bg0.darken(15) }),
      --       PanelBorder({ fg = PanelBackground.bg.darken(10), bg = PanelBackground.bg }),
      --       PanelHeading({ PanelBackground, gui = "bold" }),
      --       PanelVertSplit({ VertSplit, bg = C.bg0.darken(8) }),
      --       PanelStNC({ PanelVertSplit }),
      --       PanelSt({ bg = C.bg_blue.darken(20) }),

      --       ---- megaline -- :help statusline ------------------------------------------

      --       StatusLineBg({ bg = C.transparent }),
      --       -- StatusLineNCBg({bg=C.transparent}),
      --       -- StatusLineInactiveBg({bg=C.transparent}),
      --       StatusLine({ fg = C.grey1, bg = StatusLineBg.bg }), -- status line of current window
      --       StatusLineNC({ fg = C.grey1, bg = C.bg0 }), -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
      --       StatusLineInactive({ fg = C.bg_dark.lighten(20), bg = C.bg_dark, gui = "italic" }),
      --       StModeNormal({ bg = StatusLineBg.bg, fg = C.bg5, gui = C.transparent }), -- alts: bg = C.bg2
      --       StModeInsert({ bg = StatusLineBg.bg, fg = C.green, gui = "bold" }),
      --       StModeVisual({ bg = StatusLineBg.bg, fg = C.magenta, gui = "bold" }),
      --       StModeReplace({ bg = StatusLineBg.bg, fg = C.dark_red, gui = "bold" }),
      --       StModeCommand({ bg = StatusLineBg.bg, fg = C.green, gui = "bold" }),
      --       StModeTermNormal({ StModeNormal, bg = StatusLineBg.bg }),
      --       StModeTermInsert({ StModeTermNormal, fg = C.green, gui = "bold,italic", sp = C.green }),
      --       StBright({ fg = C.fg.li(10), bg = StatusLineBg.bg }),
      --       StBrightItalic({ StBright, fg = StBright.fg.da(5), gui = "italic" }),
      --       StMetadata({ Comment, bg = StatusLineBg.bg }),
      --       StMetadataPrefix({ fg = C.fg, bg = StatusLineBg.bg, gui = "" }),
      --       StLspMessages({ fg = C.fg.da(20), bg = StatusLineBg.bg, gui = "italic" }),
      --       StIndicator({ fg = C.dark_blue, bg = StatusLineBg.bg }),
      --       StModified({ fg = C.pale_red, bg = StatusLineBg.bg, gui = "bold,italic" }),
      --       StModifiedIcon({ fg = C.pale_red, bg = StatusLineBg.bg, gui = "bold" }),
      --       StGitSymbol({ fg = C.light_red, bg = StatusLineBg.bg }),
      --       StGitBranch({ fg = C.blue, bg = StatusLineBg.bg }),
      --       StGitSigns({ fg = C.dark_blue, bg = StatusLineBg.bg }),
      --       StGitSignsAdd({ GreenSign, bg = StatusLineBg.bg }),
      --       StGitSignsDelete({ RedSign, bg = StatusLineBg.bg }),
      --       StGitSignsChange({ OrangeSign, bg = StatusLineBg.bg }),
      --       StNumber({ fg = C.purple, bg = StatusLineBg.bg }),
      --       StCount({ fg = C.bg0, bg = C.blue, gui = "bold" }),
      --       StPrefix({ fg = C.fg, bg = C.bg2 }),
      --       StDirectory({ bg = StatusLineBg.bg, fg = C.grey0, gui = "italic" }),
      --       StParentDirectory({ bg = StatusLineBg.bg, fg = C.blue, gui = "" }),
      --       StFilename({ bg = StatusLineBg.bg, fg = C.fg, gui = "bold" }),
      --       StFilenameInactive({ fg = C.light_grey, bg = StatusLineBg.bg, gui = "italic,bold" }),
      --       StIdentifier({ fg = C.blue, bg = StatusLineBg.bg }),
      --       StTitle({ bg = StatusLineBg.bg, fg = C.grey2, gui = "bold" }),
      --       StComment({ Comment, bg = StatusLineBg.bg }),
      --       StLineNumber({ fg = C.grey2, bg = StatusLineBg.bg, gui = "bold" }),
      --       StLineSep({ fg = C.grey0, bg = StatusLineBg.bg, gui = "" }),
      --       StLineTotal({ fg = C.grey1, bg = StatusLineBg.bg }),
      --       StLineColumn({ fg = C.grey2, bg = StatusLineBg.bg }),
      --       StClient({ bg = StatusLineBg.bg, fg = C.fg, gui = "bold" }),
      --       StError({ fg = DiagnosticError.fg }),
      --       StWarn({ fg = DiagnosticWarn.fg }),
      --       StInfo({ fg = DiagnosticInfo.fg }),
      --       StHint({ fg = DiagnosticHint.fg }),
      --       StBufferCount({ fg = DiagnosticInfo.fg }),
      --       StSeparator({ fg = C.bg0, bg = StatusLineBg.bg }),

      --       ---- :help statuscolumn  ---------------------------------------------------------

      --       StatusColumnActiveBorder({ bg = C.bg1, fg = "#7c8378" }),
      --       StatusColumnActiveLineNr({ fg = "#7c8378" }),
      --       StatusColumnInactiveBorder({ bg = NormalNC.bg, fg = C.bg_dark.li(15) }),
      --       StatusColumnInactiveLineNr({ fg = C.bg_dark.li(10) }),
      --       -- StatusColumnBuffer({}),
      --       --
      --       -- [[%#StatusColumnBorder#]], -- HL

      --       ---- :help winbar  ---------------------------------------------------------

      --       WinBar({ StatusLine, gui = "italic" }),
      --       WinBarNC({ StatusLineInactive }),
      --     }
      --   end)
      --   -- Apply specs using lush tool-chain
      --   lush.apply(lush.compile(specs))
      -- end

      vim.g.forestbones = { solid_line_nr = true, darken_comments = 45, transparent_background = true }
      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
    end,
  },
}
