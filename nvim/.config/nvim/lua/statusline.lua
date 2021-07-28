local colorscheme = require("colors")
local icons = colorscheme.icons

local lsp_status = require "lsp-status"
lsp_status.register_progress()
lsp_status.config {
  status_symbol = "",
  indicator_errors = icons.statusline_error,
  indicator_warnings = icons.statusline_warning,
  indicator_info = icons.statusline_info,
  indicator_hint = icons.statusline_hint,
  indicator_ok = icons.statusline_ok,
  spinner_frames = {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"}
}

local function LspStatus()
  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status()
  end
  return ""
end

local lualine = require("lualine")
local config = {}
config.options = {
  theme = "everforest",
  section_separators = {"", ""},
  component_separators = {"|", "|"},
  icons_enabled = true
}
config.sections = {
  lualine_a = {"mode"},
  lualine_b = {"branch"},
  lualine_c = {
    {
      "filename",
      file_status = true,
      path = 1
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
  lualine_x = {"location"},
  lualine_y = {},
  lualine_z = {}
}
lualine.setup(config)
