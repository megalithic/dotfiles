-- after/plugin/cursorline.lua
-- Cursorline management: auto-toggle on focus, blink effect for navigation feedback

if not mega then mega = {} end
if not mega.ui then mega.ui = {} end

local M = {}

-- Configuration
local config = {
  blink_delay = 150,
}

-- Filetypes/buftypes to ignore
local ignored_fts = {
  "alpha", "dashboard", "starter",
  "fzf", "TelescopePrompt", "snacks_picker",
  "oil", "netrw", "NvimTree", "neo-tree",
  "qf", "help", "man",
  "toggleterm", "terminal", "megaterm",
  "Trouble", "trouble",
  "lazy", "mason",
  "notify", "noice",
  "gitcommit", "fugitive",
  "dap-repl", "undotree",
}

local ignored_bts = {
  "quickfix", "terminal", "prompt", "nofile", "acwrite",
}

---@type uv_timer_t|nil
local timer = nil

---@return boolean
local function is_ignored()
  local ft = vim.bo.filetype
  local bt = vim.bo.buftype

  if ft == "" then return true end
  if vim.fn.win_gettype() == "popup" then return true end
  if vim.list_contains(ignored_fts, ft) then return true end
  if vim.list_contains(ignored_bts, bt) then return true end

  return false
end

-- Get colors from current colorscheme (cached per colorscheme change)
local cached_colors = nil
local cached_colorscheme = nil

local function get_colors()
  local current = vim.g.colors_name
  if cached_colors and cached_colorscheme == current then
    return cached_colors
  end

  local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  local visual = vim.api.nvim_get_hl(0, { name = "Visual" })

  cached_colors = {
    cursorline_bg = cursorline.bg and string.format("#%06x", cursorline.bg) or "NONE",
    blink_bg = visual.bg and string.format("#%06x", visual.bg) or "#3d59a1",
  }
  cached_colorscheme = current

  return cached_colors
end

local function set_cursorline_hl(is_blink)
  local colors = get_colors()
  local bg = is_blink and colors.blink_bg or colors.cursorline_bg
  vim.cmd("highlight! CursorLine guibg=" .. bg)
  vim.cmd("highlight! CursorLineNr guibg=" .. colors.cursorline_bg)
end

--- Blink the cursorline to provide visual feedback
---@param delay? number Milliseconds to show blink (default: 150)
---@param center? boolean Center screen before blinking
function M.blink(delay, center)
  if is_ignored() then return end

  -- Clean up any existing timer
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end

  if center then
    vim.cmd.normal({ "zz", bang = true })
  end

  vim.wo.cursorlineopt = "both"
  vim.wo.cursorline = true
  set_cursorline_hl(true)

  timer = vim.uv.new_timer()
  timer:start(delay or config.blink_delay, 0, vim.schedule_wrap(function()
    set_cursorline_hl(false)

    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
  end))
end

local function enable_cursorline(should_blink)
  if is_ignored() then return end

  vim.wo.cursorlineopt = "both"
  vim.wo.cursorline = true

  if should_blink then
    M.blink()
  else
    set_cursorline_hl(false)
  end
end

local function disable_cursorline()
  if is_ignored() then return end
  vim.wo.cursorline = false
end

-- Autocmds for auto-toggle behavior
local augroup = vim.api.nvim_create_augroup("mega.cursorline", { clear = true })

-- Enable cursorline (with blink) on window/buffer enter
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FocusGained" }, {
  group = augroup,
  callback = function() enable_cursorline(true) end,
})

-- Enable cursorline (without blink) after leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  group = augroup,
  callback = function() enable_cursorline(false) end,
})

-- Disable cursorline on window/buffer leave
vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
  group = augroup,
  callback = disable_cursorline,
})

-- In insert mode: show only line number, not full line highlight
vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI" }, {
  group = augroup,
  callback = function()
    if is_ignored() then return end
    vim.wo.cursorlineopt = "number"
    vim.wo.cursorline = true
  end,
})

-- Clear color cache on colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = function()
    cached_colors = nil
    cached_colorscheme = nil
  end,
})

-- Clean up timer on exit
vim.api.nvim_create_autocmd("VimLeave", {
  group = augroup,
  callback = function()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
  end,
})

-- Export
mega.ui.blink_cursorline = M.blink
