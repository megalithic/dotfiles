-- [ utils & helpers ] ---------------------------------------------------------

local M = {}
local loop = vim.loop
local fn = vim.fn
local api = vim.api
local cmd = vim.cmd

function table.merge(dest, src)
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

-- Key mapping
function M.map(mode, key, result, opts)
  opts =
    table.merge(
    {
      noremap = true,
      silent = true,
      expr = false
    },
    opts or {}
  )

  fn.nvim_set_keymap(mode, key, result, opts)
end

-- Stolen from https://github.com/kyazdani42/nvim-palenight.lua/blob/master/lua/palenight.lua#L10
-- Usage:
-- highlight(Cursor, { fg = bg_dark, bg = yellow })
function M.highlight(group, styles)
  local gui = styles.gui and "gui=" .. styles.gui or "gui=NONE"
  local sp = styles.sp and "guisp=" .. styles.sp or "guisp=NONE"
  local fg = styles.fg and "guifg=" .. styles.fg or "guifg=NONE"
  local bg = styles.bg and "guibg=" .. styles.bg or "guibg=NONE"
  cmd("highlight " .. group .. " " .. gui .. " " .. sp .. " " .. fg .. " " .. bg)
end

-- Usage:
-- highlight({
--      CursorLine   = { bg = bg },
--      Cursor       = { fg = bg_dark, bg = yellow }
-- })
function M.highlights(hi_table)
  for group, styles in pairs(hi_table) do
    M.highlight(group, styles)
  end
end

function M.hiLink(src, dest)
  cmd("highlight link " .. src .. " " .. dest)
end

function M.hiLinks(hi_table)
  for src, dest in pairs(hi_table) do
    M.hiLink(src, dest)
  end
end

function M.debounce(interval_ms, fn)
  local timer = loop.new_timer()
  local last_call = {}

  local make_call = function()
    if #last_call > 0 then
      fn(unpack(last_call))
      last_call = {}
    end
  end
  timer:start(interval_ms, interval_ms, make_call)
  return {
    call = function(...)
      last_call = {...}
    end,
    stop = function()
      make_call()
      timer:close()
    end
  }
end

function M.bmap(mode, key, result, opts)
  local map_opts = opts

  if opts == nil then
    map_opts = {noremap = true, silent = true}
  end

  api.nvim_buf_set_keymap(0, mode, key, result, map_opts)
end

function M.gmap(mode, key, result, opts)
  api.nvim_set_keymap(mode, key, result, opts)
end

function M.augroup(group, fn)
  api.nvim_command("augroup " .. group)
  api.nvim_command("autocmd!")
  fn()
  api.nvim_command("augroup END")
end

function M.get_icon(icon_name)
  local ICONS = {
    paste = "⍴",
    spell = "✎",
    -- branch = os.getenv('PURE_GIT_BRANCH') ~= '' and fn.trim(os.getenv('PURE_GIT_BRANCH')) or ' ',
    branch = " ",
    error = "×",
    info = "●",
    warn = "!",
    hint = "›",
    lock = "",
    success = " "
    -- success = ' '
  }

  return ICONS[icon_name] or ""
end

function M.get_color(synID, what, mode)
  return fn.synIDattr(fn.synIDtrans(fn.hlID(synID)), what, mode)
end

function M.locations_to_items(locations)
  local items = {}
  local grouped =
    setmetatable(
    {},
    {
      __index = function(t, k)
        local v = {}
        rawset(t, k, v)
        return v
      end
    }
  )
  local fname = api.nvim_buf_get_name(0)
  for _, d in ipairs(locations) do
    local range = d.range or d.targetSelectionRange
    table.insert(grouped[fname], {start = range.start})
  end

  local keys = vim.tbl_keys(grouped)
  table.sort(keys)
  local rows = grouped[fname]

  table.sort(rows, vim.position_sort)
  local bufnr = fn.bufnr()
  for _, temp in ipairs(rows) do
    local pos = temp.start
    local row = pos.line
    local line = api.nvim_buf_get_lines(0, row, row + 1, false)[1]
    if line then
      local col
      if pos.character > #line then
        col = #line
      else
        col = vim.str_byteindex(line, pos.character)
      end

      table.insert(
        items,
        {
          bufnr = bufnr,
          lnum = row + 1,
          col = col + 1,
          text = line
        }
      )
    end
  end
  return items
end

function M.inspect(k, v, l)
  local should_log = require("vim.lsp.log").should_log(1)
  if not should_log then
    return
  end

  local level = "[DEBUG]"
  if level ~= nil and l == 4 then
    level = "[ERROR]"
  end

  if v then
    print(level .. " " .. k .. " -> " .. vim.inspect(v))
  else
    print(level .. " " .. k .. "..")
  end

  return v
end

function M.pclients()
  M.inspect("active_clients", vim.inspect(vim.lsp.get_active_clients()))
end

function M.pbclients()
  M.inspect("buf_clients", vim.inspect(vim.lsp.buf_get_clients()))
end

function M.phandlers()
  M.inspect("handlers", vim.inspect(vim.lsp.handlers))
end

function M.plogpath()
  M.inspect("log_path", vim.inspect(vim.lsp.get_log_path()))
end

-- [ globals ] -----------------------------------------------------------------

P = function(v)
  print(vim.inspect(v))
  return v
end

PC = function()
  P(M.pclients())
end

PBC = function()
  P(M.pbclients())
end

return M
