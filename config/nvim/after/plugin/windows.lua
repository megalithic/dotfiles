-- after/plugin/windows.lua
-- Window management: golden ratio resize + window/buffer lifecycle guardian
--
-- Features:
-- 1. Golden ratio auto-resize for focused windows (resize_ignore_*)
-- 2. Smart quit: if only ephemeral windows remain, quit entirely (ephemeral_*)
-- 3. Safe window close: prevents E444, handles edge cases
--
-- Separation of concerns:
-- - resize_ignore: windows that shouldn't get golden ratio (help, oil, qf, etc.)
-- - quitter: windows that trigger quit if alone (sidebars, terminals, AI panels)

if not Plugin_enabled() then return end

--------------------------------------------------------------------------------
-- Skip entirely for embedded nvim contexts (Shade, Firenvim)
-- These have their own window/lifecycle management
--------------------------------------------------------------------------------
if vim.g.started_by_shade or vim.g.started_by_firenvim then return end

local GOLDEN_RATIO = 1.618
local MIN_WIDTH = 20

--------------------------------------------------------------------------------
-- Resize ignore: windows that shouldn't get golden ratio resize
-- (sidebars, terminals, special panels - they manage their own size)
--------------------------------------------------------------------------------

local resize_ignore_ft = {
  "",
  "DiffviewFilePanel",
  "DiffviewFiles",
  "Trouble",
  "claude",
  "claudecode",
  "dbee",
  "dbee-result",
  "dbui",
  "dirbuf",
  "edgy",
  "fidget",
  "help",
  "lazy",
  "megaterm",
  "neo-tree",
  "neotest-summary",
  "oil",
  "opencode",
  "packer",
  "qf",
  "startuptime",
  "terminal",
  "trouble",
  "undotree",
}

local resize_ignore_bt = {
  "acwrite",
  "help",
  "nofile",
  "quickfix",
  "terminal",
}

--------------------------------------------------------------------------------
-- Quitter windows: quit nvim if only these remain
-- (sidebars, panels, AI tools - shouldn't be left alone)
--------------------------------------------------------------------------------

local quitter_ft = {
  "",
  "DiffviewFilePanel",
  "DiffviewFiles",
  "claude",
  "claudecode",
  "dbee",
  "dbee-result",
  "dbui",
  "edgy",
  "fidget",
  "lazy",
  "megaterm",
  "neo-tree",
  "neotest-summary",
  "opencode",
  "packer",
  "startuptime",
  "terminal",
  "undotree",
}

local quitter_bt = {
  "nofile",
  "terminal",
}

-- Convert to sets for O(1) lookup
local resize_ft_set = {}
for _, v in ipairs(resize_ignore_ft) do resize_ft_set[v] = true end
local resize_bt_set = {}
for _, v in ipairs(resize_ignore_bt) do resize_bt_set[v] = true end

local quitter_ft_set = {}
for _, v in ipairs(quitter_ft) do quitter_ft_set[v] = true end
local quitter_bt_set = {}
for _, v in ipairs(quitter_bt) do quitter_bt_set[v] = true end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function is_floating(win)
  win = win or 0
  return vim.fn.win_gettype(win) == "popup"
end

--- Check if buffer should be ignored for resize
---@param buf number
---@return boolean
local function is_resize_ignored_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return true end
  if resize_ft_set[vim.bo[buf].filetype] then return true end
  if resize_bt_set[vim.bo[buf].buftype] then return true end
  if vim.b[buf].pi_panel then return true end
  return false
end

--- Check if buffer is a quitter (quit if only these remain)
---@param buf number
---@return boolean
local function is_quitter_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return true end
  if quitter_ft_set[vim.bo[buf].filetype] then return true end
  if quitter_bt_set[vim.bo[buf].buftype] then return true end
  if vim.b[buf].pi_panel then return true end
  return false
end

--- Check if window should be ignored for resize
---@param bufnr number
---@return boolean
local function is_ignored_for_resize(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return true end
  if vim.g.disable_autoresize then return true end
  if vim.g.resize_disable or vim.w.resize_disable or vim.b.resize_disable then return true end
  if is_floating() then return true end
  return is_resize_ignored_buf(bufnr)
end

--- Count non-quitter windows (real editing windows)
---@return number
local function count_real_windows()
  local count = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and not is_floating(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if not is_quitter_buf(buf) then
        count = count + 1
      end
    end
  end
  return count
end

--- Find a suitable alternate buffer to switch to
---@return number bufnr
local function find_alternate_buffer()
  -- Try alternate buffer first
  local alt = vim.fn.bufnr("#")
  if alt > 0 and vim.api.nvim_buf_is_valid(alt)
     and vim.bo[alt].buflisted and not is_quitter_buf(alt) then
    return alt
  end

  -- Try any listed, non-quitter buffer
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
       and vim.bo[buf].buflisted and not is_quitter_buf(buf) then
      return buf
    end
  end

  -- Create a new empty buffer
  return vim.api.nvim_create_buf(true, false)
end

--------------------------------------------------------------------------------
-- Golden Ratio Resize
--------------------------------------------------------------------------------

local saved_cmdheight = vim.o.cmdheight

local function golden_width()
  return math.floor(vim.o.columns / GOLDEN_RATIO)
end

local function golden_height()
  return math.floor(vim.o.lines / GOLDEN_RATIO)
end

local function golden_minwidth()
  return math.max(MIN_WIDTH, math.floor(golden_width() / (3 * GOLDEN_RATIO)))
end

local function save_fixed_win_dims()
  local dims = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if is_ignored_for_resize(buf) then
        dims[win] = {
          width = vim.api.nvim_win_get_width(win),
          height = vim.api.nvim_win_get_height(win),
        }
      end
    end
  end
  return dims
end

local function restore_fixed_win_dims(dims)
  for win, size in pairs(dims) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_width, win, size.width)
      pcall(vim.api.nvim_win_set_height, win, size.height)
    end
  end
end

local function resize_to_golden(bufnr)
  if is_ignored_for_resize(bufnr) then return end

  local fixed_dims = save_fixed_win_dims()

  local cur_w = vim.api.nvim_win_get_width(0)
  local cur_h = vim.api.nvim_win_get_height(0)
  local target_w = golden_width()
  local target_h = golden_height()
  local min_w = golden_minwidth()

  if cur_w < target_w then
    vim.api.nvim_win_set_width(0, target_w)
  end
  if cur_h < target_h then
    vim.api.nvim_win_set_height(0, target_h)
  end

  if vim.o.winwidth < min_w then
    vim.o.winwidth = min_w
  end
  vim.o.winminwidth = min_w

  restore_fixed_win_dims(fixed_dims)
  vim.o.cmdheight = saved_cmdheight
end

--------------------------------------------------------------------------------
-- Window Guardian: Safe close + auto-quit when only special windows remain
--------------------------------------------------------------------------------

local M = {}

--- Safely close a window, handling last-window edge case
---@param win? number Window to close (default: current)
---@return boolean success
function M.safe_close(win)
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then return false end

  local ok, err = pcall(vim.api.nvim_win_close, win, false)
  if ok then return true end

  -- E444: Cannot close last window
  if err and err:match("E444") then
    -- Switch to alternate buffer instead
    local alt = find_alternate_buffer()
    vim.api.nvim_win_set_buf(win, alt)
    return true
  end

  return false
end

--- Check if we should quit (only special windows remain)
---@return boolean
function M.should_quit()
  return count_real_windows() == 0 and #vim.api.nvim_list_wins() > 0
end

--- Quit if only special windows remain
function M.quit_if_only_special()
  if M.should_quit() then
    vim.cmd("qa!")
  end
end

-- Export for use by other modules (megaterm, etc.)
mega.windows = M

--------------------------------------------------------------------------------
-- Autocmds
--------------------------------------------------------------------------------

local group = vim.api.nvim_create_augroup("mega.windows", { clear = true })

-- Golden ratio resize on window/buffer focus
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = group,
  callback = function(args)
    resize_to_golden(args.buf)
  end,
  desc = "Golden ratio auto-resize",
})

-- Mark resize-ignored buftypes/filetypes
vim.api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    vim.w.resize_disable = resize_bt_set[vim.bo.buftype] or false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function()
    vim.b.resize_disable = resize_ft_set[vim.bo.filetype] or false
  end,
})

-- Guardian: quit entirely when only special windows remain after a quit attempt
vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  nested = true,
  desc = "Quit if only special windows remain",
  callback = function()
    -- Schedule to run after the quit completes
    vim.schedule(function()
      M.quit_if_only_special()
    end)
  end,
})

-- Guardian: check after any window closes
vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  desc = "Quit if only special windows remain after window close",
  callback = function()
    vim.schedule(function()
      M.quit_if_only_special()
    end)
  end,
})
