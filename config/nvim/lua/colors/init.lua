if vim.g.colorscheme == "megaforest" then
  return { spec = {} }
end

local M = require("colors.everforest")

require("colors.hl").override({
  iCursor = { bg = M.palette.blue },
  vCursor = { bg = M.palette.purple },
  rCursor = { bg = M.palette.red },

  StatusLine = { bg = M.palette.bg1, fg = M.palette.fg3 },
  StatusLineTerm = { bg = M.palette.bg1, fg = M.palette.fg3 },
  TabLine = { bg = M.palette.bg0, fg = M.palette.fg3, nocombine = true },
  TabLineFill = { bg = M.palette.bg0, fg = M.palette.fg3, nocombine = true },

  WinBar = { bg = "NONE", fg = M.palette.fg3 },
  WinBarNC = { bg = "NONE", fg = M.palette.fg3 },
})

return M
