-- REF: might want to make our own without galaxyline?
-- https://github.com/wbthomason/dotfiles/blob/linux/neovim/.config/nvim/lua/statusline.lua
return {
  activate = function()
    local gl = require("galaxyline")
    local diag = require("galaxyline.provider_diagnostic")
    local gls = gl.section
    local colors = require("mega.colors.nova").colors
    local icons = require("mega.colors.nova").icons

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

    -- local checkwidth = function()
    --   local squeeze_width = vim.fn.winwidth(0) / 2
    --   if squeeze_width > 40 then
    --     return true
    --   end
    --   return false
    -- end

    local check_diagnostics = function(diag_type)
      local fn_string = "get_diagnostic_" .. diag_type
      local result = diag["" .. fn_string .. ""]()
      if result then
        return true
      end

      return false
    end

    gl.short_line_list = {
      "LuaTree",
      "vista",
      "dbui",
      "startify",
      "term",
      "nerdtree",
      "fugitive",
      "fugitiveblame",
      "plug",
      "packer",
      "paq"
    }

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
        icon = "  " .. icons.vcs_symbol .. " ",
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
        provider = function()
          return diag.get_diagnostic_error()
        end,
        icon = " " .. icons.statusline_error .. " ",
        condition = function()
          return check_diagnostics("error")
        end,
        separator = "",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.error_status, colors.bg}
      }
    }
    gls.right[2] = {
      DiagnosticWarn = {
        provider = function()
          return diag.get_diagnostic_warn()
        end,
        icon = " " .. icons.statusline_warning .. " ",
        condition = function()
          return check_diagnostics("warn")
        end,
        separator = "",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.warning_status, colors.bg}
      }
    }
    gls.right[3] = {
      DiagnosticInfo = {
        provider = function()
          return diag.get_diagnostic_info()
        end,
        icon = " " .. icons.statusline_information .. " ",
        condition = function()
          return check_diagnostics("info")
        end,
        separator = "",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.information_status, colors.bg}
      }
    }
    gls.right[4] = {
      DiagnosticHint = {
        provider = function()
          return diag.get_diagnostic_hint()
        end,
        icon = icons.statusline_hint .. " ",
        condition = function()
          return check_diagnostics("hint")
        end,
        separator = "",
        separator_highlight = {colors.bg, colors.bg},
        highlight = {colors.hint_status, colors.bg}
      }
    }
    gls.right[5] = {
      Space = {
        provider = function()
          return " "
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
        -- highlight = {colors.gutter_gray, colors.bg}
        highlight = {colors.bg, colors.visual_gray}
      }
    }
    gls.right[7] = {
      FileTypeName = {
        provider = "FileTypeName",
        icon = "",
        separator = "",
        separator_highlight = {colors.bg, colors.visual_gray},
        -- highlight = {colors.gutter_gray, colors.bg}
        highlight = {colors.bg, colors.visual_gray}
      }
    }
    -- FIXME: unused?
    gls.right[8] = {
      Space = {
        provider = function()
          return ""
        end,
        icon = "",
        separator = "",
        separator_highlight = {colors.bg, colors.visual_gray},
        highlight = {colors.bg, colors.visual_gray}
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
      BufferName = {
        provider = "FileName",
        separator = " ",
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }

    gls.short_line_right[1] = {
      BufferType = {
        provider = "FileTypeName",
        separator = " ",
        condition = buffer_not_empty,
        separator_highlight = {colors.gutter_gray, colors.bg},
        highlight = {colors.gutter_gray, colors.bg}
      }
    }

    gl.load_galaxyline()
  end
}
