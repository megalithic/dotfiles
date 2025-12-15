local M = {}

M.palette = {
  bg_dark = "#273433",
  bg0 = "#2e353c",
  bg1 = "#323c41",
  bg2 = "#3a454a",
  bg3 = "#445055",
  bg4 = "#53605c",
  bg5 = "#53605c",
  fg0 = "#d3c6aa",
  fg1 = "#d3c6aa",
  fg2 = "#d3c6aa",
  fg3 = "#859289",
  red = "#e67e80",
  orange = "#e69875",
  yellow = "#ddbc7f",
  green = "#a7c080",
  aqua = "#83c092",
  blue = "#7fbbb3",
  purple = "#d699b6",
  bg_red = "#4e3e43",
  bg_yellow = "#4a4940",
  bg_green = "#404d44",
  bg_aqua = "#455956",
  bg_blue = "#394f5a",
  bg_purple = "#503946",
  bg_shade = "#2d373d",
}
M.palette.accent = M.palette.green
M.palette.bg_accent = M.palette.bg_green

M.spec = {
  "sainnhe/everforest",
  lazy = false,
  priority = 1000,
  -- dependencies = ,
  init = function()
    vim.g.everforest_enable_italic = true
    vim.g.everforest_background = "medium"
    vim.g.everforest_better_performance = true
    vim.g.everforest_colors_override = {
      bg_dim = { M.palette.bg_dark, "233" },
      bg0 = { M.palette.bg0, "235" },
      bg1 = { M.palette.bg1, "236" },
      bg2 = { M.palette.bg2, "237" },
      bg3 = { M.palette.bg3, "238" },
      bg4 = { M.palette.bg4, "239" },
      bg5 = { M.palette.bg5, "240" },
      bg_visual = { M.palette.bg_purple, "52" },
      bg_red = { M.palette.bg_red, "52" },
      bg_green = { M.palette.bg_green, "22" },
      bg_blue = { M.palette.bg_blue, "17" },
      bg_yellow = { M.palette.bg_yellow, "136" },
    }
  end,
  config = function(_)
    vim.cmd.colorscheme("everforest")
  end,
}

M.dark = true

vim.schedule(function()
  require("colors.hl").override({
    Search = { bg = M.palette.bg_aqua, fg = M.palette.aqua },
    IncSearch = { bg = M.palette.aqua, fg = M.palette.bg0 },
    NormalFloat = { bg = M.palette.bg1, fg = M.palette.fg0 },
    FloatBorder = { bg = M.palette.bg1, fg = M.palette.bg1 },
    ErrorFloat = { bg = M.palette.bg1, fg = M.palette.red },
    WarningFloat = { bg = M.palette.bg1, fg = M.palette.yellow },
    InfoFloat = { bg = M.palette.bg1, fg = M.palette.blue },
    HintFloat = { bg = M.palette.bg1, fg = M.palette.green },
    VertSplit = { bg = M.palette.bg0, fg = M.palette.bg0 },
    PmenuThumb = { bg = M.palette.bg5 },

    CursorLine = { bg = M.palette.bg_shade },
    CursorLineSign = { bg = M.palette.bg_shade },
    CursorLineNr = { bg = M.palette.bg_shade, fg = M.palette.fg3 },

    --
    -- relies soley on lush.nvim and colors/megaforest.lua:
    --
    -- PanelBackground = { fg = mega.ui.theme.PanelBackground.fg.hex, bg = mega.ui.theme.PanelBackground.bg.hex },
    -- PanelBorder = { fg = mega.ui.theme.PanelBorder.fg.hex, bg = mega.ui.theme.PanelBorder.bg.hex },
    -- PanelHeading = { fg = mega.ui.theme.PanelBorder.fg.hex, bg = mega.ui.theme.PanelBorder.bg.hex },
    -- PanelVertSplit = { fg = mega.ui.theme.PanelBorder.fg.hex, bg = mega.ui.theme.PanelBorder.bg.hex },
    -- PanelStNC = { fg = mega.ui.theme.PanelBorder.fg.hex, bg = mega.ui.theme.PanelBorder.bg.hex },
    -- PanelSt = { fg = mega.ui.theme.PanelBorder.fg.hex, bg = mega.ui.theme.PanelBorder.bg.hex },

    -- PanelHeading={ PanelBackground, gui = "bold" },
    -- PanelVertSplit={ VertSplit, bg = C.bg0.darken(8) },
    -- PanelStNC={ PanelVertSplit },
    -- PanelSt={ bg = C.bg_blue.darken(20) },

    -- GitConflictCurrent = { fg = mega.ui.theme.GitConflictCurrent.fg.hex, bg = mega.ui.theme.GitConflictCurrent.bg.hex },
    -- GitConflictIncoming = { fg = mega.ui.theme.GitConflictCurrent.fg.hex, bg = mega.ui.theme.GitConflictCurrent.bg.hex },
    -- GitConflictAncestor = { fg = mega.ui.theme.GitConflictCurrent.fg.hex, bg = mega.ui.theme.GitConflictCurrent.bg.hex },
    -- GitConflictCurrentLabel = { fg = mega.ui.theme.GitConflictCurrent.fg.hex, bg = mega.ui.theme.GitConflictCurrent.bg.hex },
    -- GitConflictIncomingLabel = { fg = mega.ui.theme.GitConflictCurrent.fg.hex, bg = mega.ui.theme.GitConflictCurrent.bg.hex },
    -- GitConflictAncestorLabel = { fg = mega.ui.theme.GitConflictCurrent.fg.hex, bg = mega.ui.theme.GitConflictCurrent.bg.hex },
  })
end)

return M
