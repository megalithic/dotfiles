return {
  activate = function()
    local galaxyline = require "galaxyline"
    -- local diagnostic = require "galaxyline.provider_diagnostic"
    -- local buffer = require("galaxyline.provider_buffer")
    -- local fileinfo = require("galaxyline.provider_fileinfo")
    local gls = galaxyline.section
    local colors = require("mega.colors.nova").colors
    local icons = require("mega.colors.nova").icons
    -- DiagnosticError = diagnostic.get_diagnostic_error

    local mode_color = function()
      local mode_colors = {
        n = colors.normal_color,
        i = colors.insert_color,
        c = colors.magenta,
        V = colors.visual_color,
        [""] = colors.orange,
        v = colors.magenta,
        R = colors.replace_color,
        t = colors.terminal_color
      }

      return mode_colors[vim.fn.mode()]
    end

    local buffer_not_empty = function()
      if vim.fn.empty(vim.fn.expand("%:t")) ~= 1 then
        return true
      end
      return false
    end

    gls.left[1] = {
      ViMode = {
        provider = function()
          local alias = {
            n = "N",
            i = "I",
            c = "C",
            V = "VL",
            [""] = "VB",
            v = "V",
            R = "R",
            t = icons.mode_term
          }
          vim.api.nvim_command("hi GalaxyViMode gui=bold guifg=" .. colors.bg .. " guibg=" .. mode_color())
          return "  " .. alias[vim.fn.mode()] .. " "
        end,
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.bg, colors.bg}
      }
    }
    gls.left[2] = {
      GitBranch = {
        provider = "GitBranch",
        condition = buffer_not_empty,
        icon = "  " .. icons.vcs_symbol,
        -- icon = "   ",
        separator = " ",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.bg, colors.visual_gray}
      }
    }
    gls.left[3] = {
      FileName = {
        provider = function()
          local file = vim.fn.expand("%")
          if vim.bo.readonly and vim.bo.filetype ~= "help" then
            file = file .. " "
          end
          if vim.bo.modified then
            file = file .. " " .. icons.modified_symbol
            vim.api.nvim_command("hi GalaxyFileName gui=bold guifg=" .. colors.light_red .. " guibg=" .. colors.bg)
          else
            vim.api.nvim_command("hi GalaxyFileName guifg=" .. colors.blue .. " guibg=" .. colors.bg)
          end

          return file
        end,
        separator = " ",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.blue, colors.bg},
        highlight_modifier = function()
          if vim.bo.modified then
            return "Dirty"
          end
        end
      }
    }

    gls.right[1] = {
      DiagnosticError = {
        provider = "DiagnosticError",
        icon = icons.statusline_error .. " ",
        separator = " ",
        highlight = {colors.fg, colors.error_status}
      }
    }
    gls.right[2] = {
      DiagnosticWarn = {
        provider = "DiagnosticWarn",
        icon = icons.statusline_warning .. " ",
        separator = " ",
        highlight = {colors.fg, colors.warning_status}
      }
    }
    gls.right[3] = {
      DiagnosticInfo = {
        provider = "DiagnosticInfo",
        icon = icons.statusline_information .. " ",
        separator = " ",
        highlight = {colors.fg, colors.information_status}
      }
    }
    gls.right[4] = {
      DiagnosticHint = {
        provider = "DiagnosticHint",
        icon = icons.statusline_hint .. " ",
        separator = " ",
        highlight = {colors.fg, colors.hint_status}
      }
    }
    gls.right[5] = {
      Space = {
        provider = function()
          return ""
        end,
        icon = "",
        separator = "",
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }
    gls.right[6] = {
      FileIcon = {
        provider = "FileIcon",
        condition = buffer_not_empty,
        icon = " ",
        separator = "",
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }
    gls.right[7] = {
      FileTypeName = {
        provider = "FileTypeName",
        icon = "",
        separator = "",
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }
    gls.right[8] = {
      Space = {
        provider = function()
          return ""
        end,
        separator = " ",
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }
    gls.right[9] = {
      LineInfo = {
        provider = "LineColumn",
        separator = " " .. icons.col_sep .. " ",
        separator_highlight = {colors.bg, colors.blue},
        highlight = {colors.bg, colors.blue}
      }
    }
    gls.right[10] = {
      LinePercent = {
        provider = "LinePercent",
        separator = " " .. icons.perc_sep,
        separator_highlight = {colors.bg, colors.blue},
        highlight = {colors.bg, colors.blue}
      }
    }

    gls.short_line_left[1] = {
      FileName = {
        provider = function()
          local file = vim.fn.expand("%")
          if vim.bo.readonly and vim.bo.filetype ~= "help" then
            file = file .. " "
          end
          if vim.bo.modified then
            file = file .. " " .. icons.modified_symbol
            vim.api.nvim_command("hi GalaxyFileName gui=bold guifg=" .. colors.light_red .. " guibg=" .. colors.bg)
          else
            vim.api.nvim_command("hi GalaxyFileName guifg=" .. colors.blue .. " guibg=" .. colors.bg)
          end

          return file
        end,
        separator = " ",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.blue, colors.bg},
        highlight_modifier = function()
          if vim.bo.modified then
            return "Dirty"
          end
        end
      }
    }

    gls.short_line_right[1] = {
      BufferType = {
        provider = "FileTypeName",
        separator = " ",
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }

    galaxyline.load_galaxyline()
  end
}
