local colors = require("colors")
local icons = colors.icons
local lualine = require("lualine")
local lsp_status = require "lsp-status"

lsp_status.register_progress()
lsp_status.config {
  status_symbol = "",
  indicator_errors = icons.statusline_error,
  indicator_warnings = icons.statusline_warning,
  indicator_info = icons.statusline_info,
  indicator_hint = icons.statusline_hint,
  indicator_ok = icons.statusline_ok,
  -- spinner_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
  spinner_frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
}

local function LspStatus()
  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status()
  end
  return ""
end

local config = {}

-- local masterModeMaps = {
--   ['n']    = 'NORMAL',
--   ['no']   = 'O-PENDING',
--   ['nov']  = 'O-PENDING',
--   ['noV']  = 'O-PENDING',
--   ['no'] = 'O-PENDING',
--   ['niI']  = 'NORMAL',
--   ['niR']  = 'NORMAL',
--   ['niV']  = 'NORMAL',
--   ['v']    = 'VISUAL',
--   ['V']    = 'V-LINE',
--   ['']   = 'V-BLOCK',
--   ['s']    = 'SELECT',
--   ['S']    = 'S-LINE',
--   ['']   = 'S-BLOCK',
--   ['i']    = 'INSERT',
--   ['ic']   = 'INSERT',
--   ['ix']   = 'INSERT',
--   ['R']    = 'REPLACE',
--   ['Rc']   = 'REPLACE',
--   ['Rv']   = 'V-REPLACE',
--   ['Rx']   = 'REPLACE',
--   ['c']    = 'COMMAND',
--   ['cv']   = 'EX',
--   ['ce']   = 'EX',
--   ['r']    = 'REPLACE',
--   ['rm']   = 'MORE',
--   ['r?']   = 'CONFIRM',
--   ['!']    = 'SHELL',
--   ['t']    = 'TERMINAL',
-- }

local function mode()
  local modeMap = {
    ["n"] = "N",
    ["niI"] = "N",
    ["niR"] = "N",
    ["niV"] = "N",
    ["v"] = "V",
    ["V"] = "VL",
    [""] = "VB",
    ["s"] = "S",
    ["S"] = "SL",
    [""] = "SB",
    ["i"] = "I",
    ["ic"] = "I",
    ["ix"] = "I",
    ["R"] = "R",
    ["Rc"] = "R",
    ["Rx"] = "R",
    ["Rv"] = "VR",
    ["c"] = "C",
    ["cv"] = "EX",
    ["ce"] = "EX",
    ["r"] = "R",
    ["rm"] = "MORE",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    ["t"] = "T"
  }
  local mapped = modeMap[vim.api.nvim_get_mode().mode] or "?"
  return string.format("%s", mapped)
end

config.options = {
  theme = "everforest",
  section_separators = {"", ""},
  component_separators = {"|", "|"},
  --
  -- section_separators = {'', ''}, -- default
  -- component_separators = {'', ''}
  --
  -- section_separators = { "", "" }, -- @folke
  -- component_separators = { "", "" },
  --
  -- section_separators = {"", ""}, -- @kristijanhusak
  -- component_separators = {"|", "|"},
  icons_enabled = true
}

config.sections = {
  lualine_a = {mode},
  lualine_b = {{"branch", icon = mega.utf8(0xe725)}},
  lualine_c = {
    {
      "filename",
      file_status = true,
      path = 1,
      symbols = {modified = string.format(" %s", icons.modified_symbol)}
    }
  },
  lualine_x = {LspStatus},
  lualine_y = {{"filetype", colored = false, icons_enabled = true}, {"fileformat", icons_enabled = false}},
  lualine_z = {"location", "progress"},
  lualine_diagnostics = {}
}

config.inactive_sections = {
  lualine_a = {},
  lualine_b = {},
  lualine_c = {"filename"},
  lualine_x = {},
  lualine_y = {},
  lualine_z = {}
}

lualine.setup(config)
