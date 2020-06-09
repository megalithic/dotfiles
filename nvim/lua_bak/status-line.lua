local api = vim.api
local icons = require 'devicon'
local session = require 'abduco'
local M = {}

session.abduco_session()

-- Different colors for mode
local purple = '#B48EAD'
local blue = '#81A1C1'
local yellow = '#EBCB8B'
local green = '#A3BE8C'
local red = '#BF616A'

-- fg and bg
local white_fg = '#e6e6e6'
local black_fg = '#282c34'
local bg = '#4d4d4d'

-- Separators
local left_separator = ''
local right_separator = ''

-- Blank Between Components
local blank = ' '

------------------------------------------------------------------------
--                             StatusLine                             --
------------------------------------------------------------------------

-- Mode Prompt Table
local current_mode = setmetatable({
      ['n'] = 'NORMAL',
      ['no'] = 'N·Operator Pending',
      ['v'] = 'VISUAL',
      ['V'] = 'V·Line',
      ['^V'] = 'V·Block',
      ['s'] = 'Select',
      ['S'] = 'S·Line',
      ['^S'] = 'S·Block',
      ['i'] = 'INSERT',
      ['ic'] = 'INSERT',
      ['ix'] = 'INSERT',
      ['R'] = 'Replace',
      ['Rv'] = 'V·Replace',
      ['c'] = 'COMMAND',
      ['cv'] = 'Vim Ex',
      ['ce'] = 'Ex',
      ['r'] = 'Prompt',
      ['rm'] = 'More',
      ['r?'] = 'Confirm',
      ['!'] = 'Shell',
      ['t'] = 'TERMINAL'
    }, {
      -- fix weird issues
      __index = function(_, _)
        return 'V·Block'
      end
    }
)

-- Obsession Color
local obsession_fg = purple
local obsession_gui = 'bold'
api.nvim_command('hi Obsession guifg='..obsession_fg..' gui='..obsession_gui)

-- Filename Color
local file_bg = purple
local file_fg = black_fg
local file_gui = 'bold'
api.nvim_command('hi File guibg='..file_bg..' guifg='..file_fg..' gui='..file_gui)
api.nvim_command('hi FileSeparator guifg='..file_bg)

-- Working directory Color
local dir_bg = bg
local dir_fg = white_fg
local dir_gui = 'bold'
api.nvim_command('hi Directory guibg='..dir_bg..' guifg='..dir_fg..' gui='..dir_gui)
api.nvim_command('hi DirSeparator guifg='..dir_bg)

-- FileType Color
local filetype_bg = 'None'
local filetype_fg = purple
local filetype_gui = 'bold'
api.nvim_command('hi Filetype guibg='..filetype_bg..' guifg='..filetype_fg..' gui='..filetype_gui)

-- row and column Color
local line_bg = 'None'
local line_fg = white_fg
local line_gui = 'bold'
api.nvim_command('hi Line guibg='..line_bg..' guifg='..line_fg..' gui='..line_gui)



-- Redraw different colors for different mode
local RedrawColors = function(mode)
  if mode == 'n' then
    api.nvim_command('hi Mode guibg='..green..' guifg='..black_fg..' gui=bold')
    api.nvim_command('hi ModeSeparator guifg='..green)
  end
  if mode == 'i' then
    api.nvim_command('hi Mode guibg='..blue..' guifg='..black_fg..' gui=bold')
    api.nvim_command('hi ModeSeparator guifg='..blue)
  end
  if mode == 'v' or mode == 'V' or mode == '^V' then
    api.nvim_command('hi Mode guibg='..purple..' guifg='..black_fg..' gui=bold')
    api.nvim_command('hi ModeSeparator guifg='..purple)
  end
  if mode == 'c' then
    api.nvim_command('hi Mode guibg='..yellow..' guifg='..black_fg..' gui=bold')
    api.nvim_command('hi ModeSeparator guifg='..yellow)
  end
  if mode == 't' then
    api.nvim_command('hi Mode guibg='..red..' guifg='..black_fg..' gui=bold')
    api.nvim_command('hi ModeSeparator guifg='..red)
  end
end

local TrimmedDirectory = function(dir)
  local home = os.getenv("HOME")
  local _, index = string.find(dir, home, 1)
  if index ~= nil and index ~= string.len(dir) then
    -- TODO Trimmed Home Directory
    return string.gsub(dir, home, '~')
  end
  return dir
end

function M.activeLine()
  local statusline = ""
  -- Component: Mode
  local mode = api.nvim_get_mode()['mode']
  RedrawColors(mode)
  statusline = statusline.."%#ModeSeparator#"..left_separator.."%#Mode# "..current_mode[mode].." %#ModeSeparator#"..right_separator
  statusline = statusline..blank

  -- Component: Working Directory
  local dir = api.nvim_call_function('getcwd', {})
  statusline = statusline.."%#DirSeparator#"..left_separator.."%#Directory# "..TrimmedDirectory(dir).." %#DirSeparator#"..right_separator
  statusline = statusline..blank

  -- Alignment to left
  statusline = statusline.."%="

  local lsp_function = vim.b.lsp_current_function
  if lsp_function ~= nil then
    statusline = statusline.."%#Function# "..lsp_function
  end

  local filetype = api.nvim_buf_get_option(0, 'filetype')
  statusline = statusline.."%#Filetype#  Filetype: "..filetype
  statusline = statusline..blank

  -- Component: FileType
  -- Component: row and col
  local line = api.nvim_call_function('line', {"."})
  local col = vim.fn.col('.')
  while string.len(line) < 3 do
    line = line..' '
  end
  while string.len(col) < 3 do
    col = col..' '
  end
  statusline = statusline.."%#Line# ℓ "..line.." 𝚌 "..col

  return statusline
end

local InactiveLine_bg = '#1c1c1c'
local InactiveLine_fg = white_fg
api.nvim_command('hi InActive guibg='..InactiveLine_bg..' guifg='..InactiveLine_fg)

function M.inActiveLine()
  local file_name = api.nvim_call_function('expand', {'%F'})
  return "%#InActive# "..file_name
end

------------------------------------------------------------------------
--                              TabLine                               --
------------------------------------------------------------------------

local getTabLabel = function(n)
  local current_win = api.nvim_tabpage_get_win(n)
  local current_buf = api.nvim_win_get_buf(current_win)
  local file_name = api.nvim_buf_get_name(current_buf)
  if string.find(file_name, 'term://') ~= nil then
    return ' '..api.nvim_call_function('fnamemodify', {file_name, ":p:t"})
  end
  file_name = api.nvim_call_function('fnamemodify', {file_name, ":p:t"})
  if file_name == '' then
    return "No Name"
  end
  local icon = icons.deviconTable[file_name]
  if icon ~= nil then
    return icon..' '..file_name
  end
  return file_name
end

api.nvim_command('hi TabLineSel gui=Bold guibg=#81A1C1 guifg=#292929')
api.nvim_command('hi TabLineSelSeparator gui=bold guifg=#81A1C1')
api.nvim_command('hi TabLine guibg=#4d4d4d guifg=#c7c7c7 gui=None')
api.nvim_command('hi TabLineSeparator guifg=#4d4d4d')
api.nvim_command('hi TabLineFill guibg=None gui=None')


function M.TabLine()
  local tabline = ''
  local tab_list = api.nvim_list_tabpages()
  local current_tab = api.nvim_get_current_tabpage()
  for _, val in ipairs(tab_list) do
    local file_name = getTabLabel(val)
    if val == current_tab then
      tabline = tabline.."%#TabLineSelSeparator# "..left_separator
      tabline = tabline.."%#TabLineSel# "..file_name
      tabline = tabline.." %#TabLineSelSeparator#"..right_separator
    else
      tabline = tabline.."%#TabLineSeparator# "..left_separator
      tabline = tabline.."%#TabLine# "..file_name
      tabline = tabline.." %#TabLineSeparator#"..right_separator
    end
  end
  tabline = tabline.."%="
  local obsession_status = api.nvim_call_function('ObsessionStatus', {})
  tabline = tabline.."%#Obsession#"..obsession_status..' '
  if session.data ~= nil then
    tabline = tabline.."%#TabLineSeparator# "..left_separator
    tabline = tabline.."%#TabLine# session: "..session.data
    tabline = tabline.." %#TabLineSeparator#"..right_separator
  end
  return tabline
end
return M


