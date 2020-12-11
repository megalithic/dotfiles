local gl = require("galaxyline")
local utils = require("mega.colors.utils")

local gls = gl.section
gl.short_line_list = {"defx", "packager", "vista"}

-- Colors
local colors = require('mega.colors.nova').colors
-- local colors = {
--   bg = "#282a36",
--   fg = "#f8f8f2",
--   section_bg = "#38393f",
--   yellow = "#f1fa8c",
--   cyan = "#8be9fd",
--   green = "#50fa7b",
--   orange = "#ffb86c",
--   magenta = "#ff79c6",
--   blue = "#8be9fd",
--   red = "#ff5555"
-- }

-- Local helper functions
local buffer_not_empty = function()
  return not utils.is_buffer_empty()
end

local checkwidth = function()
  return utils.has_width_gt(40) and buffer_not_empty()
end

local mode_color = function()
  local mode_colors = {
    n = colors.cyan,
    i = colors.green,
    c = colors.orange,
    V = colors.magenta,
    [""] = colors.magenta,
    v = colors.magenta,
    R = colors.red
  }

  return mode_colors[vim.fn.mode()]
end

-- Left side
gls.left[1] = {
  FirstElement = {
    provider = function()
      return "▋"
    end,
    highlight = {colors.cyan, colors.section_bg}
  }
}
gls.left[2] = {
  ViMode = {
    provider = function()
      local alias = {
        n = "NORMAL",
        i = "INSERT",
        c = "COMMAND",
        V = "VISUAL",
        [""] = "VISUAL",
        v = "VISUAL",
        R = "REPLACE"
      }
      vim.api.nvim_command("hi GalaxyViMode guifg=" .. mode_color())
      return alias[vim.fn.mode()] .. " "
    end,
    highlight = {colors.bg, colors.bg},
    separator = "  ",
    separator_highlight = {colors.bg, colors.section_bg}
  }
}
gls.left[3] = {
  FileIcon = {
    provider = "FileIcon",
    condition = buffer_not_empty,
    highlight = {require("galaxyline.provider_fileinfo").get_file_icon_color, colors.section_bg}
  }
}
gls.left[4] = {
  FileName = {
    provider = {"FileName", "FileSize"},
    condition = buffer_not_empty,
    highlight = {colors.fg, colors.section_bg},
    separator = " ",
    separator_highlight = {colors.section_bg, colors.bg}
  }
}
gls.left[5] = {
  GitIcon = {
    provider = function()
      return "  "
    end,
    condition = buffer_not_empty,
    highlight = {colors.red, colors.bg}
  }
}
gls.left[6] = {
  GitBranch = {
    provider = "GitBranch",
    condition = buffer_not_empty,
    highlight = {colors.fg, colors.bg}
  }
}
gls.left[7] = {
  DiffAdd = {
    provider = "DiffAdd",
    condition = checkwidth,
    icon = " ",
    highlight = {colors.green, colors.bg}
  }
}
gls.left[8] = {
  DiffModified = {
    provider = "DiffModified",
    condition = checkwidth,
    icon = " ",
    highlight = {colors.orange, colors.bg}
  }
}
gls.left[9] = {
  DiffRemove = {
    provider = "DiffRemove",
    condition = checkwidth,
    icon = " ",
    highlight = {colors.red, colors.bg}
  }
}
gls.left[10] = {
  LeftEnd = {
    provider = function()
      return " "
    end,
    condition = buffer_not_empty,
    highlight = {colors.section_bg, colors.bg}
  }
}
gls.left[11] = {
  DiagnosticError = {
    provider = "DiagnosticError",
    icon = "  ",
    highlight = {colors.red, colors.section_bg}
  }
}
gls.left[12] = {
  DiagnosticWarn = {
    provider = "DiagnosticWarn",
    icon = "  ",
    highlight = {colors.orange, colors.section_bg}
  }
}
gls.left[13] = {
  DiagnosticInfo = {
    provider = "DiagnosticInfo",
    icon = "  ",
    highlight = {colors.blue, colors.section_bg},
    separator = " ",
    separator_highlight = {colors.section_bg, colors.bg}
  }
}

-- Right side
gls.right[1] = {
  FileFormat = {
    provider = function()
      return vim.bo.filetype
    end,
    highlight = {colors.fg, colors.section_bg},
    separator = " ",
    separator_highlight = {colors.section_bg, colors.bg}
  }
}
gls.right[2] = {
  LineInfo = {
    provider = "LineColumn",
    highlight = {colors.fg, colors.section_bg},
    separator = " | ",
    separator_highlight = {colors.bg, colors.section_bg}
  }
}
gls.right[3] = {
  Heart = {
    provider = function()
      return " "
    end,
    highlight = {colors.red, colors.section_bg},
    separator = " | ",
    separator_highlight = {colors.bg, colors.section_bg}
  }
}

-- Short status line
gls.short_line_left[1] = {
  BufferType = {
    provider = "FileTypeName",
    highlight = {colors.fg, colors.section_bg},
    separator = " ",
    separator_highlight = {colors.section_bg, colors.bg}
  }
}

gls.short_line_right[1] = {
  BufferIcon = {
    provider = "BufferIcon",
    highlight = {colors.yellow, colors.section_bg},
    separator = " ",
    separator_highlight = {colors.section_bg, colors.bg}
  }
}

-- Force manual load so that nvim boots with a status line
gl.load_galaxyline()
-- local M = {}

-- M.section = {}
-- M.section.left = {}
-- M.section.right = {}
-- M.section.short_line_left = {}
-- M.section.short_line_right = {}
-- M.short_line_list = {}

-- function M.inactive_statusline()
--     local combine = function ()
--         local short_left_section = load_section(M.section.short_line_left,'left')
--         local short_right_section = load_section(M.section.short_line_right,'right')
--         local line = short_left_section .. '%=' .. short_right_section
--         return line
--     end
--     vim.wo.statusline = combine()
-- end

-- function M.active_statusline()
--     local sections = function()
--         local left_section = load_section(M.section.left,'left')
--         local right_section = load_section(M.section.right,'right')
--         local short_left_section = load_section(M.section.short_line_left,'left')
--         local short_right_section = load_section(M.section.short_line_right,'right')
--         if common.has_value(M.short_line_list,vim.bo.filetype) then
--             return short_left_section .. '%=' .. short_right_section
--         else
--             return  left_section .. '%=' .. right_section
--         end
--     end
--     vim.wo.statusline = sections()
--     colors.init_theme('nova', get_section)
--     -- register_user_events()
-- end

-- function M.init_colorscheme()
--     colors.init_theme('nova', get_section)
-- end

-- function M.disable_statusline()
--     vim.wo.statusline = ''
--     vim.api.nvim_command('augroup statusline')
--     vim.api.nvim_command('autocmd!')
--     vim.api.nvim_command('augroup END!')
-- end

-- function M.statusline_augroup()
--     local events = { 'FileType','BufWinEnter','BufReadPost','BufWritePost','BufEnter','WinEnter','FileChangedShellPost','VimResized' }
--     vim.api.nvim_command('augroup statusline')
--     vim.api.nvim_command('autocmd!')
--     for _, def in ipairs(events) do
--         local command = string.format('autocmd %s * lua require("statusline").active_statusline()',def)
--         vim.api.nvim_command(command)
--     end
--     vim.api.nvim_command('autocmd WinLeave * lua require("statusline").inactive_statusline()')
--     vim.api.nvim_command('augroup END')
-- end

-- return {}
