-- if true then return end
if not mega then return end

local U = require("mega.utils")
local C = require("mega.lush_theme.colors")
local M = {
  blink_delay = 150,
  minimal_jump = 20,
  cursorline_delay = 100,
  filetype_exclusions = {
    "alpha",
    "prompt",
    "fzf",
    "fzflua",
    "fzf-lua",
    "netrw",
    "undotree",
    "log",
    "man",
    "fidget",
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
    "oil",
    "org",
    "Trouble",
    "Telescope",
    "TelescopePrompt",
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
    "neorg://Quick Actions",
  },
  prev_col = 0,
  prev_row = 0,
}

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
    or U.is_chonky()

  return should_ignore
end

local normal_bg = type(C) ~= "table" and "NONE" or C.bg0
local cursorline_bg = type(C) ~= "table" and "NONE" or C.bg1
local blink_bg = type(C) ~= "table" and "NONE" or C.bg_blue

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

local function set_cursorline()
  if not is_ignored() then
    vim.wo.cursorline = true
    highlight_cursorline()
  end
end

-- REF:
-- https://neovim.discourse.group/t/how-to-use-repeat-on-timer-start-in-a-lua-function/1645
-- https://vi.stackexchange.com/questions/33056/how-to-use-vim-loop-interactively-in-neovim
function mega.blink_cursorline(delay)
  if is_ignored() then return end

  timer = vim.loop.new_timer()
  blink_active = true

  vim.wo.cursorlineopt = "both"
  highlight_cursorline()

  timer:start(
    delay or M.blink_delay,
    0,
    vim.schedule_wrap(function()
      unhighlight_cursorline()
      set_cursorline()
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
      blink_active = false
      highlight_cursorline()

      -- if tint_ok then tint.enable() end
    end)
  )
end

local function disable_cursorline()
  if is_ignored() then return end

  vim.wo.cursorlineopt = "number" -- optionally -> "screenline,number"
  vim.wo.cursorline = false
  blink_active = false
end

local function enable_cursorline(should_blink)
  if is_ignored() then return end

  vim.wo.cursorlineopt = "both"

  if should_blink then mega.blink_cursorline() end

  set_cursorline()
  highlight_cursorline()
end

-- local function should_change_cursorline()
--   local should_blink = false
--   local should_change = false
--
--   local cursor = vim.api.nvim_win_get_cursor(0)
--   local current_row = cursor[1]
--   local current_col = cursor[2]
--
--   local col_diff = math.abs(current_col - M.prev_col)
--   local row_diff = math.abs(current_row - M.prev_row)
--
--   should_blink = row_diff >= M.minimal_jump
--   should_change = current_row ~= M.prev_row
--
--   M.prev_col = current_col
--   M.prev_row = current_row
--
--   return should_change, should_blink
-- end
--
-- local function cursor_moved()
--   local should_change, should_blink = should_change_cursorline()
--
--   if is_ignored() or not should_change then return end
--
--   vim.opt_local.cursorlineopt = "screenline,number"
--
--   timer = vim.loop.new_timer()
--   timer:start(
--     M.cursorline_delay,
--     0,
--     vim.schedule_wrap(function()
--       if timer then
--         timer:stop()
--         timer:close()
--         timer = nil
--       end
--
--       blink_active = false
--       highlight_cursorline()
--     end)
--   )
--
--   if should_blink then mega.blink_cursorline() end
--
--   if M.cursorline_delay ~= 0 then unhighlight_cursorline() end
-- end

require("mega.autocmds").augroup("ToggleCursorLine", {
  {
    event = { "BufEnter", "WinEnter", "FocusGained" },
    command = function() enable_cursorline(true) end,
  },
  {
    event = { "InsertLeave", "FocusLost" },
    command = function() enable_cursorline(false) end,
  },
  {
    event = { "BufLeave", "WinLeave" },
    command = function() disable_cursorline() end,
  },
  {
    event = { "InsertEnter", "CursorMovedI" },
    command = function()
      vim.wo.cursorlineopt = "number"
      vim.wo.cursorline = true
    end,
  },
  -- {
  --   event = { "CursorMoved" },
  --   command = function() cursor_moved() end,
  -- },
})
