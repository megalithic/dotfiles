-- Inspiration
-- 1. nvim-cursorline

local M = {
  -- FIXME: presently, i believe LSP things are delaying the blink
  -- exceedingly longer than defined here:
  blink_delay = 150,
  minimal_jump = 20,
  cursorline_delay = 50,
  filetype_exclusions = {
    "alpha",
    "prompt",
    "fzf",
    "netrw",
    "undotree",
    "log",
    "man",
    "dap-repl",
    "markdown",
    "vimwiki",
    "vim-plug",
    "gitcommit",
    "toggleterm",
    "megaterm",
    "fugitive",
    "list",
    "NvimTree",
    "startify",
    "help",
    "orgagenda",
    "dirbuf",
    "org",
    "Trouble",
    "Telescope",
    "TelescopePrompt",
    "fzf",
    "NvimTree",
    "markdown",
    "dashboard",
    "qf",
  },
  buftype_exclusions = {
    "acwrite",
    "quickfix",
    "terminal",
    "nofile",
    "help",
    ".git/COMMIT_EDITMSG",
    "startify",
    "prompt",
  },
}

local DISABLED = 0
local CURSOR = 1
local WINDOW = 2

local status = CURSOR
local blink_active = false
local prev_col = 0
local prev_row = 0

local timer = vim.loop.new_timer()

local function is_floating_win()
  return vim.fn.win_gettype() == "popup"
end

---Determines whether or not a buffer/window should be ignored by this plugin
---@return boolean
local function is_ignored()
  return vim.tbl_contains(M.buftype_exclusions, vim.bo.buftype)
    or vim.tbl_contains(M.filetype_exclusions, vim.bo.filetype)
    or is_floating_win()
end

local normal_bg = require("mega.lush_theme.colors").bg0
local cursorline_bg = require("mega.lush_theme.colors").bg1
local blink_bg = require("mega.lush_theme.colors").bg_blue

local function highlight_cursorline()
  if blink_active then
    vim.cmd("highlight! CursorLine guibg=" .. blink_bg)
  else
    vim.cmd("highlight! CursorLine guibg=" .. cursorline_bg)
  end
  vim.cmd("highlight! CursorLineNr guibg=" .. cursorline_bg)
end

local function unhighlight_cursorline()
  vim.cmd("highlight! CursorLine guibg=" .. normal_bg)
  vim.cmd("highlight! CursorLineNr guibg=" .. normal_bg)
end

local function timer_start()
  timer:start(
    M.cursorline_delay,
    0,
    vim.schedule_wrap(function()
      highlight_cursorline()
      status = CURSOR
    end)
  )
end

local function set_cursorline(is_long_format)
  if not is_ignored() then
    if is_long_format then
      vim.opt.cursorlineopt = "screenline,number"
    else
      vim.opt.cursorlineopt = "number"
    end
    vim.opt.cursorline = true
    highlight_cursorline()
  end
end

-- REF:
-- https://neovim.discourse.group/t/how-to-use-repeat-on-timer-start-in-a-lua-function/1645
-- https://vi.stackexchange.com/questions/33056/how-to-use-vim-loop-interactively-in-neovim
local function blink_cursorline()
  local blink_timer = vim.loop.new_timer()
  blink_active = true
  set_cursorline(true)

  blink_timer:start(
    M.blink_delay,
    0,
    vim.schedule_wrap(function()
      unhighlight_cursorline()
      set_cursorline(true)
      blink_timer:stop()
      blink_timer:close()
      blink_active = false
      highlight_cursorline()
    end)
  )
end

local function disable_cursorline()
  vim.opt.cursorline = false
  blink_active = false
  status = WINDOW
end

local function enable_cursorline(should_blink)
  if should_blink then
    blink_cursorline()
  end

  set_cursorline(true)
  highlight_cursorline()
  status = WINDOW
end

local function should_change_cursorline()
  local should_blink = false
  local should_change = false

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]
  -- local cur_cursor = vim.fn.winline()
  -- local cur_abs = vim.fn.line(".")

  local col_diff = math.abs(col - prev_col)
  local row_diff = math.abs(row - prev_row)

  if row_diff >= M.minimal_jump then
    should_blink = true
  end

  if row ~= prev_row then
    should_change = true
  end

  prev_col = col
  prev_row = row

  return should_change, should_blink
end

local function cursor_moved()
  local should_change, should_blink = should_change_cursorline()

  if not should_change then
    return
  end

  if status == WINDOW then
    status = CURSOR
    return
  end

  set_cursorline(true)
  if not is_ignored() then
    timer_start()

    if should_blink then
      blink_cursorline()
    end
  end

  if status == CURSOR and M.cursorline_delay ~= 0 then
    unhighlight_cursorline()
    status = DISABLED
  end
end

mega.augroup("ToggleCursorLine", {
  {
    event = { "BufEnter", "WinEnter" },
    command = function()
      enable_cursorline(true)
    end,
  },
  {
    event = { "InsertLeave" },
    command = function()
      enable_cursorline(false)
    end,
  },
  {
    event = { "BufLeave", "WinLeave" },
    command = function()
      disable_cursorline()
    end,
  },
  {
    event = { "InsertEnter", "CursorMovedI" },
    command = function()
      set_cursorline(false)
    end,
  },
  {
    event = { "CursorMoved" },
    command = function()
      cursor_moved()
    end,
  },
})
