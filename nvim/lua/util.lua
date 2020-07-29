-- from https://github.com/neovim/nvim-lsp/blob/master/lua/nvim_lsp/util.lua
local path_sep = is_windows and "\\" or "/"
local strip_dir_pat = path_sep.."([^"..path_sep.."]+)$"
local strip_sep_pat = path_sep.."$"
local is_windows = vim.loop.os_uname().version:match("Windows")

local is_fs_root
if is_windows then
    is_fs_root = function(path)
        return path:match("^%a:$")
    end
else
    is_fs_root = function(path)
        return path == "/"
    end
end

function root_pattern(bufnr, ...)
  local patterns = vim.tbl_flatten {...}
  local function matcher(path)
    for _, pattern in ipairs(patterns) do
      if exists(path_join(path, pattern)) then
        return path
      end
    end
  end

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local path = dirname(filepath)
  return search_ancestors(path, matcher)
end

function search_ancestors(startpath, fn)
  validate { fn = {fn, 'f'} }
  if fn(startpath) then return startpath end
  for path in iterate_parents(startpath) do
    if fn(path) then return path end
  end
end

function exists(filename)
    local stat = vim.loop.fs_stat(filename)
    return stat and stat.type or false
end

function dirname(path)
    if not path then return end
    local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
    if #result == 0 then
        return "/"
    end
    return result
end

function path_join(...)
    local result = table.concat(vim.tbl_flatten {...}, path_sep):gsub(path_sep.."+", path_sep)
    return result
end

function iterate_parents(path)
    path = vim.loop.fs_realpath(path)
    local function it(s, v)
        if not v then return end
        if is_fs_root(v) then return end
        return dirname(v), path
    end
    return it, path, path
end


-- dump table to string
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- start with helper function
function starts_with(str, start)
   return str:sub(1, #start) == start
end

--  get decoration column with (signs + folding + number)
function window_decoration_columns()
    local decoration_width = 0

    -- number width
    -- Note: 'numberwidth' is only the minimal width, can be more if...
    local max_number = 0
    if vim.api.nvim_win_get_option(0,"number") then
        -- ...the buffer has many lines.
        max_number = vim.api.nvim_buf_line_count(bufnr)
    elseif vim.api.nvim_win_get_option(0,"relativenumber") then
        -- ...the window width has more digits.
        max_number = vim.fn.winheight(0)
    end
    if max_number > 0 then
        local actual_number_width = string.len(max_number) + 1
        local number_width = vim.api.nvim_win_get_option(0,"numberwidth")
        decoration_width = decoration_width + math.max(number_width, actual_number_width)
    end

    -- signs
    if vim.fn.has('signs') then
        local signcolumn = vim.api.nvim_win_get_option(0,"signcolumn")
        local signcolumn_width = 2
        if starts_with(signcolumn, 'yes') or starts_with(signcolumn, 'auto') then
            decoration_width = decoration_width + signcolumn_width
        end
    end

    -- folding
    if vim.fn.has('folding') then
        local folding_width = vim.api.nvim_win_get_option(0,"foldcolumn")
        decoration_width = decoration_width + folding_width
    end

    return decoration_width
end

function get_buf_var(bufnr, var)
    return vim.api.nvim_buf_get_var(bufnr, var)
end

function trim_empty_lines(lines)
  local start = 1
  for i = 1, #lines do
    if #lines[i] > 0 then
      start = i
      break
    end
  end
  local finish = 1
  for i = #lines, 1, -1 do
    if #lines[i] > 0 then
      finish = i
      break
    end
  end
  return vim.list_extend({}, lines, start, finish)
end
