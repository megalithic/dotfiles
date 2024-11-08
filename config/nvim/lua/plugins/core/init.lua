local fmt = string.format

return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1010,
    init = function()
      local colorscheme = "megaforest"

      local theme = fmt("mega.lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil

        require("lush")(lush_theme)
      end

      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  -- {
  --   "EdenEast/nightfox.nvim",
  --   version = false,
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     options = {
  --       transparent = true,
  --       terminal_colors = true,
  --       dim_inactive = true,
  --     },
  --   },
  --   config = function(_, opts) require("nightfox").setup(opts) end,
  -- },
  -- {
  --   "neanias/everforest-nvim",
  --   version = false,
  --   lazy = false,
  --   priority = 1000,
  --   init = function(_args) pcall(vim.cmd.colorscheme, vim.g.colorscheme) end,
  --   opts = {
  --     background = "soft",
  --     transparent_background_level = 2,
  --     on_highlights = function(hl, p)
  --       local C = require("mega.lush_theme.colors")

  --       -- hl.VisualYank({ bg = p.bg_dim, fg = p.orange })
  --       hl.DarkenedPanel({ bg = C.bg1 })
  --       hl.DarkenedStatusline({ bg = C.bg1 })
  --       hl.DarkenedStatuslineNC({ gui = "italic", bg = C.bg1 })
  --       hl.PanelBackground({ fg = C.fg.darken(10), bg = C.bg0.darken(15) })
  --       hl.PanelBorder({ fg = hl.PanelBackground.bg.darken(10), bg = hl.PanelBackground.bg })
  --       hl.PanelHeading({ link = hl.PanelBackground, gui = "bold" })
  --       hl.PanelVertSplit({ link = hl.VertSplit, bg = C.bg0.darken(8) })
  --       hl.PanelStNC({ link = hl.PanelVertSplit })
  --       hl.PanelSt({ bg = C.bg_blue.darken(20) })
  --       hl.StatusLine({ fg = C.grey1, bg = C.bg1 })
  --       hl.StatusLineNC({ fg = C.grey1, bg = C.bg0 })
  --       hl.StatusLineInactive({ fg = C.bg_dark.lighten(20), bg = C.bg_dark, gui = "italic" })
  --       hl.StBright({ fg = C.fg.li(10), bg = C.bg1 })
  --       hl.StModeNormal({ bg = C.bg2, fg = C.bg5, gui = C.transparent })
  --       hl.StModeInsert({ bg = C.bg2, fg = C.green, bold = true })
  --       hl.StModeVisual({ bg = C.bg2, fg = C.magenta, bold = true })
  --       hl.StModeReplace({ bg = C.bg2, fg = C.dark_red, bold = true })
  --       hl.StModeCommand({ bg = C.bg2, fg = C.green, bold = true })
  --       hl.StModeTermNormal({ link = hl.StModeNormal, bg = C.bg1 })
  --       hl.StModeTermInsert({ link = hl.StModeTermNormal, fg = C.green, gui = "bold,italic", sp = C.green })
  --       hl.StMetadata({ link = hl.Comment, bg = C.bg1 })
  --       hl.StMetadataPrefix({ link = hl.Comment, bg = C.bg1 })
  --       hl.StIndicator({ fg = C.dark_blue, bg = C.bg1 })
  --       hl.StModified({ fg = C.pale_red, bg = C.bg1, gui = "bold,italic" })
  --       hl.StModifiedIcon({ fg = C.pale_red, bg = C.bg1, bold = true })
  --       hl.StGitSymbol({ fg = C.light_red, bg = C.bg1 })
  --       hl.StGitBranch({ fg = C.blue, bg = C.bg1 })
  --       hl.StGitSigns({ fg = C.dark_blue, bg = C.bg1 })
  --       hl.StGitSignsAdd({ link = hl.GreenSign, bg = C.bg1 })
  --       hl.StGitSignsDelete({ link = hl.RedSign, bg = C.bg1 })
  --       hl.StGitSignsChange({ link = hl.OrangeSign, bg = C.bg1 })
  --       hl.StNumber({ fg = C.purple, bg = C.bg1 })
  --       hl.StCount({ fg = C.bg0, bg = C.blue, bold = true })
  --       hl.StPrefix({ fg = C.fg, bg = C.bg2 })
  --       hl.StDirectory({ bg = C.bg1, fg = C.grey0, gui = "italic" })
  --       hl.StParentDirectory({ bg = C.bg1, fg = C.blue, gui = "" })
  --       hl.StFilename({ bg = C.bg1, fg = C.fg, bold = true })
  --       hl.StFilenameInactive({ fg = C.light_grey, bg = C.bg1, gui = "italic,bold" })
  --       hl.StIdentifier({ fg = C.blue, bg = C.bg1 })
  --       hl.StTitle({ bg = C.bg1, fg = C.grey2, bold = true })
  --       hl.StComment({ link = hl.Comment, bg = C.bg1 })
  --       hl.StLineNumber({ fg = C.grey2, bg = C.bg1, bold = true })
  --       hl.StLineSep({ fg = C.grey0, bg = C.bg1, gui = "" })
  --       hl.StLineTotal({ fg = C.grey1, bg = C.bg1 })
  --       hl.StLineColumn({ fg = C.grey2, bg = C.bg1 })
  --       hl.StClient({ bg = C.bg1, fg = C.fg, bold = true })
  --       hl.StError({ link = hl.DiagnosticError, bg = C.bg1 })
  --       hl.StWarn({ link = hl.DiagnosticWarn, bg = C.bg1 })
  --       hl.StInfo({ link = hl.DiagnosticInfo, bg = C.bg1 })
  --       hl.StHint({ link = hl.DiagnosticHint, bg = C.bg1 })
  --       hl.StSeparator({ fg = C.bg0, bg = C.bg1 })
  --       hl.StatusColumnActiveBorder({ bg = C.bg1, fg = "#7c8378" })
  --       hl.StatusColumnActiveLineNr({ fg = "#7c8378" })
  --       hl.StatusColumnInactiveBorder({ bg = hl.NormalNC.bg, fg = C.bg_dark.li(15) })
  --       hl.StatusColumnInactiveLineNr({ fg = C.bg_dark.li(10) })
  --     end,
  --     colours_override = function(palette)
  --       local mega_colors = require("mega.lush_theme.colors")
  --       vim.iter(palette):each(function(entry)
  --         if mega_colors[entry] ~= nil and mega_colors[entry].hex ~= nil then
  --           palette[entry] = mega_colors[entry].hex
  --         else
  --           palette.bg_dim = mega_colors.bg_dark.hex
  --         end
  --       end)
  --     end,
  --   },
  --   config = function(_, opts) require("everforest").setup(opts) end,
  -- },
}
