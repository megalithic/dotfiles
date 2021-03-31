return {
  load = function(colorscheme_str)
    local colorscheme = require(string.format("mega.colors.%s", colorscheme_str or "nova"))
    -- local colors = colorscheme.colors
    local icons = colorscheme.icons

    local lsp_status = require "lsp-status"
    lsp_status.register_progress()
    lsp_status.config {
      status_symbol = "",
      indicator_errors = icons.statusline_error,
      indicator_warnings = icons.statusline_warning,
      indicator_info = icons.statusline_info,
      indicator_hint = icons.statusline_hint,
      indicator_ok = icons.statusline_ok
    }

    local function LspStatus()
      if #vim.lsp.buf_get_clients() > 0 then
        return lsp_status.status()
      end
      return ""
    end

    local lualine = require("lualine")
    local config = {}
    config.theme = colorscheme_str
    -- lualine.separator = "|"
    -- lualine.section_separators = {"", ""}
    -- lualine.section_separators = {" ", " "}
    -- lualine.component_separators = {"", ""}
    -- lualine.component_separators = {"|", "|"}
    config.options = {
      theme = "gruvbox",
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
          shorten = true,
          full_path = true
        }
      },
      lualine_x = {LspStatus},
      lualine_y = {"filetype", {"fileformat", icons_enabled = false}},
      -- lualine_y = {"encoding", {"fileformat", icons_enabled = false}, "filetype"},
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
    config.extensions = {"fzf"}
    lualine.setup(config)
  end
}
