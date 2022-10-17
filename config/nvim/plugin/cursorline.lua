-- Inspiration
-- 1. nvim-cursorline

if not mega then return end
if not vim.g.enabled_plugin["cursorline"] then return end

local M = {
  -- FIXME: presently, i believe LSP things are delaying the blink
  -- exceedingly longer than defined here:
  blink_delay = 150,
  minimal_jump = 20,
  cursorline_delay = 100,
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
    "NeogitCommitMessage",
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
    "dashboard",
    "qf",
    "kittybuf",
  },
  buftype_exclusions = {
    "acwrite",
    "quickfix",
    "terminal",
    "help",
    ".git/COMMIT_EDITMSG",
    "startify",
    "prompt",
  },
  prev_col = 0,
  prev_row = 0,
}

local DISABLED = 0
local CURSOR = 1
local WINDOW = 2

local status = CURSOR
local blink_active = false

local timer = vim.loop.new_timer()

local function is_floating_win() return vim.fn.win_gettype() == "popup" end

---Determines whether or not a buffer/window should be ignored by this plugin
---@return boolean
local function is_ignored()
  local should_ignore = vim.bo.filetype == ""
    or vim.tbl_contains(M.buftype_exclusions, vim.bo.buftype)
    or vim.tbl_contains(M.filetype_exclusions, vim.bo.filetype)
    or is_floating_win()

  return should_ignore
end

local normal_bg = type(mega.colors) ~= "table" and "NONE" or mega.colors.bg0
local cursorline_bg = type(mega.colors) ~= "table" and "NONE" or mega.colors.bg1
local blink_bg = type(mega.colors) ~= "table" and "NONE" or mega.colors.bg_blue

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
  if not is_ignored() then
    timer:start(
      M.cursorline_delay,
      0,
      vim.schedule_wrap(function()
        highlight_cursorline()
        status = CURSOR
      end)
    )
  end
end

local function set_cursorline()
  if not is_ignored() then
    vim.opt_local.cursorline = true
    highlight_cursorline()
  end
end

-- REF:
-- https://neovim.discourse.group/t/how-to-use-repeat-on-timer-start-in-a-lua-function/1645
-- https://vi.stackexchange.com/questions/33056/how-to-use-vim-loop-interactively-in-neovim
function mega.blink_cursorline(delay)
  if is_ignored() then return end

  local blink_timer = vim.loop.new_timer()
  blink_active = true
  vim.opt_local.cursorlineopt = "screenline,number"
  highlight_cursorline()

  blink_timer:start(
    delay or M.blink_delay,
    0,
    vim.schedule_wrap(function()
      unhighlight_cursorline()
      set_cursorline()
      blink_timer:stop()
      blink_timer:close()
      blink_active = false
      highlight_cursorline()
    end)
  )
end

local function should_change_cursorline()
  local should_blink = false
  local should_change = false

  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_row = cursor[1]
  local current_col = cursor[2]

  -- local col_diff = math.abs(current_col - M.prev_col)
  local row_diff = math.abs(current_row - M.prev_row)

  should_blink = row_diff >= M.minimal_jump
  should_change = current_row ~= M.prev_row

  M.prev_col = current_col
  M.prev_row = current_row

  return should_change, should_blink
end

local function disable_cursorline()
  if is_ignored() then return end

  vim.opt_local.cursorlineopt = "number" -- optionally -> "screenline,number"
  vim.opt_local.cursorline = false
  status = WINDOW
  blink_active = false
end

local function enable_cursorline(should_blink)
  if is_ignored() then return end

  vim.opt_local.cursorlineopt = "screenline,number"

  if should_blink then mega.blink_cursorline() end

  set_cursorline()
  highlight_cursorline()
  status = WINDOW
end

local function cursor_moved()
  local should_change, should_blink = should_change_cursorline()

  if is_ignored() or not should_change then return end

  if status == WINDOW then
    status = CURSOR
    return
  end

  vim.opt_local.cursorlineopt = "screenline,number"
  timer_start()

  if should_blink then mega.blink_cursorline() end

  if status == CURSOR and M.cursorline_delay ~= 0 then
    unhighlight_cursorline()
    status = DISABLED
  end
end

-- local function toggle_tint(should_tint)
--   local ok, tint = mega.require("tint")
--   if ok then
--     -- FIXME: full stop! disable for now
--     tint.disable()

--     -- tint.enable()
--     if should_tint then
--       tint.tint(vim.api.nvim_get_current_win())
--     else
--       tint.untint(vim.api.nvim_get_current_win())
--     end
--   end
-- end

mega.augroup("ToggleCursorLine", {
  {
    event = { "VimEnter" },
    once = true,
    command = function() enable_cursorline(true) end,
  },
  {
    event = { "BufEnter", "WinEnter", "FocusGained" },
    command = function()
      -- require("tint").untint(vim.api.nvim_get_current_win())
      enable_cursorline(true)
    end,
  },
  -- {
  --   event = { "InsertLeave", "FocusLost" },
  --   command = function()
  --     -- require("tint").untint(vim.api.nvim_get_current_win())
  --     enable_cursorline(false)
  --     -- require("tint").refresh()
  --   end,
  -- },
  {
    event = { "BufLeave", "WinLeave" },
    command = function()
      -- require("tint").tint(vim.api.nvim_get_current_win())
      disable_cursorline()
    end,
  },
  {
    event = { "InsertEnter", "CursorMovedI" },
    command = function()
      vim.opt_local.cursorlineopt = "number"
      vim.opt_local.cursorline = true
    end,
  },
  {
    event = { "CursorMoved" },
    command = function()
      disable_cursorline()
      --cursor_moved()
    end,
  },
})
