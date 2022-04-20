-- Inspiration
-- 1. nvim-cursorline

local M = {
  cursorline_delay = 250,
  blink_delay = 50,
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
local blink_active = true

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
  --   or vim.wo.previewwindow
  --   or vim.wo.winhighlight == ""
  --   or vim.bo.filetype == ""
  --   or require("cmp").visible()
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

local function cursor_moved()
  if status == WINDOW then
    status = CURSOR
    return
  end

  vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
  if not is_ignored() then
    timer_start()
  end

  if status == CURSOR and M.cursorline_delay ~= 0 then
    unhighlight_cursorline()
    status = DISABLED
  end
end

local function set_cursorline()
  if not is_ignored() then
    vim.opt.cursorline = true
    -- vim.opt.cursorlineopt = table.concat(cursorlineopts, ",")
    highlight_cursorline()
  end
end

-- REF:
-- https://neovim.discourse.group/t/how-to-use-repeat-on-timer-start-in-a-lua-function/1645
-- https://vi.stackexchange.com/questions/33056/how-to-use-vim-loop-interactively-in-neovim
local function blink_cursorline()
  local blink_timer = vim.loop.new_timer()
  blink_active = true
  vim.opt.cursorlineopt = "screenline,number" -- optionally -> "screenline,number"
  highlight_cursorline()

  blink_timer:start(
    M.blink_delay,
    0,
    vim.schedule_wrap(function()
      unhighlight_cursorline()
      set_cursorline()
      vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
      blink_timer:stop()
      blink_timer:close()
      blink_active = false
    end)
  )
end

local function disable_cursorline()
  vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
  vim.opt.cursorline = false
  status = WINDOW
  blink_active = false
end

local function enable_cursorline()
  vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
  blink_cursorline()
  set_cursorline()
  highlight_cursorline()
  status = WINDOW
end

mega.augroup("ToggleCursorLine", {
  {
    event = { "BufEnter" },
    command = function()
      enable_cursorline()
    end,
  },
  {
    event = { "BufLeave", "WinLeave" },
    command = function()
      disable_cursorline()
    end,
  },
  {
    event = { "CursorMoved", "CursorMovedI" },
    command = function()
      -- cursor_moved()
    end,
  },
})
