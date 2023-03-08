-- Inspiration
-- 1. nvim-cursorline

if not mega then return end
if not vim.g.enabled_plugin["colorcolumn"] then return end

local vc_ok, vc = mega.require("virt-column")

local contains = vim.tbl_contains
local api = vim.api

local M = {
  -- ft's that i have explicit settings for; so let's just ignore all of this..
  column_ignore = { "gitcommit", "NeogitCommitMessage" },
  -- ft's that need to have their colorcolumn cleared
  column_clear = {
    "startify",
    "vimwiki",
    "packer",
    "help",
    "fugitive",
    "org",
    "orgagenda",
    "markdown",
    "Telescope",
    "dirbuf",
    "terminal",
    "megaterm",
    "toggleterm",
    "neo-tree",
    "NeogitCommitSelectView",
    "DiffviewFileHistory",
    "NeogitStatus",
  },
}

local function set_colorcolumn(leaving)
  if contains(M.column_ignore, vim.bo.filetype) then return end

  local not_eligible = not vim.bo.modifiable or vim.wo.previewwindow or vim.bo.buftype ~= "" or not vim.bo.buflisted
  local small_window = api.nvim_win_get_width(0) <= vim.bo.textwidth + 1
  local is_last_win = #api.nvim_list_wins() == 1

  if contains(M.column_clear, vim.bo.filetype) or not_eligible or (leaving and not is_last_win) or small_window then
    vim.wo.colorcolumn = ""
    if vc_ok then vc.setup_buffer({ char = "", virtcolumn = vim.wo.colorcolumn }) end

    return
  end

  if vim.wo.colorcolumn == "" then
    vim.wo.colorcolumn = tostring(vim.g.default_colorcolumn)
    if vc_ok then vc.setup_buffer({ char = "│", virtcolumn = vim.wo.colorcolumn }) end
  end
end

local function disable_colorcolumn(leaving)
  if not vim.g.started_by_firenvim and vim.g.loaded_indent_blankline then vim.cmd("IndentBlanklineDisable") end
  set_colorcolumn(leaving)
end

local function enable_colorcolumn()
  if not vim.g.started_by_firenvim and vim.g.loaded_indent_blankline then vim.cmd("IndentBlanklineEnable") end
  set_colorcolumn()
end
--
-- REF: https://github.com/m4xshen/smartcolumn.nvim/blob/main/lua/smartcolumn.lua
mega.augroup("ToggleColorColumn", {
  {
    -- Update the cursor column to match current window size
    event = { "FocusGained", "WinEnter", "BufEnter", "VimResized", "FileType" }, -- BufWinEnter instead of WinEnter?
    command = function() enable_colorcolumn() end,
  },
  {
    event = { "FocusLost", "WinLeave", "BufLeave" },
    command = function() disable_colorcolumn(true) end,
  },
})
