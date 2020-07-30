require 'util'

local validate = vim.validate
local api = vim.api

local M = {}

function M.floating_window(border, width_per, height_per)
  validate {
    width_per = { width_per, 'n', true };
    height_per = { height_per, 'n', true };
    border = { border, 'b', true };
  }
  border = border or false
  width_per = width_per or 0.5
  height_per = height_per or 0.6

  local vim_width = api.nvim_get_option("columns")
  local vim_height = api.nvim_get_option("lines")
  local win_height = math.max(math.ceil(vim_height * height_per), 25)
  local win_width = math.ceil(vim_width * width_per)
  if (vim_width < 150) then win_width = math.ceil(vim_width - 8) end

  -- border window
  if border then
    local border_opts = {
      relative = "editor",
      width = win_width,
      height = win_height,
      row = math.ceil((vim_height - win_height) / 2),
      col = math.ceil((vim_width - win_width) / 2),
      style = 'minimal'
    }
    -- local top = "╭"..string.rep("─", win_width - 2).."╮"
    -- local mid = "│"..string.rep(" ", win_width - 2).."│"
    -- local bot = "╰"..string.rep("─", win_width - 2).."╯"
    local top = "▛"..string.rep("▀", win_width - 2).."▜"
    local mid = "▌"..string.rep(" ", win_width - 2).."▐"
    local bot = "▙"..string.rep("▄", win_width - 2).."▟"
    local lines = { top }
    for i=1,win_height-2 do
      table.insert(lines, mid)
    end
    table.insert(lines, bot)
    local border_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(border_buf, 0, -1, true, lines)
    for i=0,win_height-1 do
      api.nvim_buf_add_highlight(border_buf, 0, 'PopupWindowBorder', i, 0, -1)
    end

    border_win = api.nvim_open_win(border_buf, false, border_opts)
    api.nvim_win_set_option(border_win, "winhighlight", "Normal:Normal")
    api.nvim_win_set_option(border_win, 'wrap', false)
    api.nvim_win_set_option(border_win, 'number', false)
    api.nvim_win_set_option(border_win, 'relativenumber', false)
    api.nvim_win_set_option(border_win, 'cursorline', false)
    api.nvim_win_set_option(border_win, 'signcolumn', 'no')
    api.nvim_command("autocmd BufWipeout <buffer> exe 'bw '"..border_buf)
  end

  -- content window
  local content_opts = {
    relative = "editor",
    width = win_width - 4,
    height = win_height - 2,
    row = 1 + math.ceil((vim_height - win_height) / 2),
    col = 2 + math.ceil((vim_width - win_width) / 2),
    style = 'minimal'
  }
  local content_buf = api.nvim_create_buf(false, true)
  local content_win = api.nvim_open_win(content_buf, true, content_opts)
  api.nvim_win_set_option(content_win, 'wrap', false)
  api.nvim_win_set_option(content_win, 'number', false)
  api.nvim_win_set_option(content_win, 'relativenumber', false)
  api.nvim_win_set_option(content_win, 'cursorline', false)
  api.nvim_win_set_option(content_win, 'signcolumn', 'no')

  -- map 'q' to close window
  --api.nvim_buf_set_keymap(content_buf, 'n', 'q', ':lua pcall(vim.api.nvim_win_close, '..content_win..', true)<CR>', {["silent"]=true})
  if border then
    -- close border window when leaving the main buffer
    --api.nvim_command("autocmd BufLeave <buffer> ++once lua pcall(vim.api.nvim_win_close, "..border_win..", true)")
    vim.lsp.util.close_preview_autocmd({"BufLeave", "BufHidden"}, border_win)
  end
end

function M.popup_window(contents, filetype, opts, border)
  validate {
    contents = { contents, 't' };
    filetype = { filetype, 's', true };
    opts = { opts, 't', true };
    border = { border, 'b', true };
  }
  opts = opts or {}
  border = border or false

  -- Trim empty lines from the end.
  contents = trim_empty_lines(contents)

  local width = opts.width
  local height = opts.height or #contents
  if not width then
    width = 0
    for i, line in ipairs(contents) do
      -- Clean up the input and add left pad.
      line = " "..line:gsub("\r", "")
      -- TODO(ashkan) use nvim_strdisplaywidth if/when that is introduced.
      local line_width = vim.fn.strdisplaywidth(line)
      width = math.max(line_width, width)
      contents[i] = line
    end
    -- Add right padding of 1 each.
    width = width + 1
  end

  -- content window
  local content_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(content_buf, 0, -1, true , contents)
  if filetype then
    api.nvim_buf_set_option(content_buf, 'filetype', filetype)
  end
  api.nvim_buf_set_option(content_buf, 'modifiable', false)
  local content_opts = M.make_popup_options(width, height, opts)
  if border and content_opts.anchor == 'SE' then
    content_opts.row = content_opts.row - 1
    content_opts.col = content_opts.col - 1
  elseif border and content_opts.anchor == 'NE' then
    content_opts.row = content_opts.row + 1
    content_opts.col = content_opts.col - 1
  elseif border and content_opts.anchor == 'NW' then
    content_opts.row = content_opts.row + 1
    content_opts.col = content_opts.col + 1
  elseif border and content_opts.anchor == 'SW' then
    content_opts.row = content_opts.row - 1
    content_opts.col = content_opts.col + 1
  end
  local content_win = api.nvim_open_win(content_buf, false, content_opts)
  if filetype == 'markdown' then
    api.nvim_win_set_option(content_win, 'conceallevel', 2)
  end
  api.nvim_win_set_option(content_win, "winhighlight", "Normal:NormalFloat")
  api.nvim_win_set_option(content_win, 'cursorline', false)

  -- border window
  if border then
    local border_width = width + 2
    local border_height = height + 2
    local top = "▛"..string.rep("▀", border_width-2).."▜"
    local mid = "▌"..string.rep(" ", border_width-2).."▐"
    local bot = "▙"..string.rep("▄", border_width-2).."▟"
    local lines = { top }
    for i=1, height do
      table.insert(lines, mid)
    end
    table.insert(lines, bot)
    local border_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(border_buf, 0, -1, true, lines)
    api.nvim_buf_add_highlight(border_buf, 0, 'InvertedPopupWindowBorder', 0, 0, -1)
    for i=1,border_height do
      api.nvim_buf_add_highlight(border_buf, 0, 'InvertedPopupWindowBorder', i, 0, -1)
    end
    api.nvim_buf_add_highlight(border_buf, 0, 'InvertedPopupWindowBorder', border_height-1, 0, -1)
    api.nvim_command("autocmd BufWipeout <buffer> exe 'bw '"..border_buf)
    border_opts = M.make_popup_options(border_width, border_height, opts)
    border_win = api.nvim_open_win(border_buf, false, border_opts)
    api.nvim_win_set_option(border_win, "winhighlight", "Normal:NormalFloat")
    api.nvim_win_set_option(border_win, 'cursorline', false)

    vim.lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre", "WinLeave", "FocusLost"}, border_win)
  end
  vim.lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre", "WinLeave", "FocusLost"}, content_win)
end

function M.make_popup_options(width, height, opts)
  validate {
    opts = { opts, 't', true };
  }
  opts = opts or {}
  validate {
    ["opts.offset_x"] = { opts.offset_x, 'n', true };
    ["opts.offset_y"] = { opts.offset_y, 'n', true };
  }

  local anchor = ''
  local row, col

  local lines_above = vim.fn.winline() - 1
  local lines_below = vim.fn.winheight(0) - lines_above

  if lines_above < lines_below then
    anchor = anchor..'N'
    height = math.min(lines_below, height)
    row = 1
  else
    anchor = anchor..'S'
    height = math.min(lines_above, height)
    row = 0
  end

  if vim.fn.wincol() + width <= api.nvim_get_option('columns') then
    anchor = anchor..'W'
    col = 0
  else
    anchor = anchor..'E'
    col = 1
  end

  return {
    anchor = anchor,
    col = col + (opts.offset_x or 0),
    height = height,
    relative = 'cursor',
    row = row + (opts.offset_y or 0),
    style = 'minimal',
    width = width,
  }
end

return M
