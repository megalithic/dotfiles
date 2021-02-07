local M = {}

function M.hi(group, _fg, _bg, _style, _bang)
  local fg, bg, style, bang = "", "", "", ""

  if _fg ~= nil then
    fg = "guifg=" .. _fg
  end

  if _bg ~= nil then
    bg = "guibg=" .. _bg
  end

  if _style ~= nil then
    style = "gui=" .. _style
  end

  if _bang ~= nil and _bang then
    bang = "!"
  end

  vim.api.nvim_exec("highlight" .. bang .. " " .. group .. " " .. fg .. " " .. bg .. " " .. style, true)
end

function M.is_buffer_empty()
  -- Check whether the current buffer is empty
  return vim.fn.empty(vim.fn.expand("%:t")) == 1
end

function M.has_width_gt(cols)
  -- Check if the windows width is greater than a given number of columns
  return vim.fn.winwidth(0) / 2 > cols
end

return M
