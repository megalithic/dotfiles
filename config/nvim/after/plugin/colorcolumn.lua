if not mega then return end

local SETTINGS = require("mega.settings")
local ok_vc, vc = pcall(require, "virt-column")

local M = {
  -- ft's that i have explicit settings for; so let's just ignore all of this..
  column_ignore = { "gitcommit", "NeogitCommitMessage" },
  -- ft's that need to have their colorcolumn cleared
  column_clear = {
    "startify",
    "vimwiki",
    "markdown",
    "packer",
    "help",
    "fugitive",
    "org",
    "orgagenda",
    "Telescope",
    "dirbuf",
    "oil",
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
  if vim.tbl_contains(M.column_ignore, vim.bo.filetype) then return end

  local not_eligible = not vim.bo.modifiable or vim.wo.previewwindow or vim.bo.buftype ~= "" or not vim.bo.buflisted
  local small_window = vim.api.nvim_win_get_width(0) <= vim.bo.textwidth + 1
  local is_last_win = #vim.api.nvim_list_wins() == 1

  if vim.tbl_contains(M.column_clear, vim.bo.filetype) or not_eligible or (leaving and not is_last_win) or small_window then
    vim.wo.colorcolumn = ""
    if ok_vc then vc.setup_buffer({ char = "", virtcolumn = vim.wo.colorcolumn }) end
    return
  end

  if vim.wo.colorcolumn == "" then
    -- TODO:
    -- https://github.com/Wansmer/nvim-config/blob/main/lua/autocmd.lua#L81-L87
    vim.wo.colorcolumn = tostring(vim.g.default_colorcolumn)
    if ok_vc then vc.setup_buffer({ char = SETTINGS.virt_column_char, virtcolumn = vim.wo.colorcolumn }) end
  end
end

-- REF: https://github.com/m4xshen/smartcolumn.nvim/blob/main/lua/smartcolumn.lua
Augroup("ToggleColorColumn", {
  {
    -- Update the cursor column to match current window size
    event = { "FocusGained", "WinEnter", "BufEnter", "VimResized", "FileType" }, -- BufWinEnter instead of WinEnter?
    command = function()
      local leaving = false
      set_colorcolumn(leaving)
    end,
  },
  {
    event = { "FocusLost", "WinLeave", "BufLeave" },
    command = function()
      local leaving = true
      set_colorcolumn(leaving)
    end,
  },
})
