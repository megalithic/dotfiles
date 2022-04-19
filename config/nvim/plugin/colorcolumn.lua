-- Inspiration
-- 1. nvim-cursorline

local contains = vim.tbl_contains
local api = vim.api

local M = {
  column_ignore = { "gitcommit" },
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
    "DirBuf",
  },
}

local function set_colorcolumn(leaving)
  if contains(M.column_ignore, vim.bo.filetype) then
    return
  end

  local not_eligible = not vim.bo.modifiable or vim.wo.previewwindow or vim.bo.buftype ~= "" or not vim.bo.buflisted
  local small_window = api.nvim_win_get_width(0) <= vim.bo.textwidth + 1
  local is_last_win = #api.nvim_list_wins() == 1

  if contains(M.column_clear, vim.bo.filetype) or not_eligible or (leaving and not is_last_win) or small_window then
    vim.wo.colorcolumn = ""
    local vc_ok, vc = mega.safe_require("virt-column")
    if vc_ok then
      vc.setup_buffer({ virtcolumn = vim.wo.colorcolumn })
    end

    return
  end

  if vim.wo.colorcolumn == "" then
    vim.wo.colorcolumn = tostring(vim.g.default_colorcolumn)

    local vc_ok, vc = mega.safe_require("virt-column")
    if vc_ok then
      vc.setup_buffer({ virtcolumn = vim.wo.colorcolumn })
    end
  end
end

local function disable_colorcolumn(leaving)
  set_colorcolumn(leaving)
end

local function enable_colorcolumn()
  set_colorcolumn()
end

mega.augroup("ToggleColorColumn", {
  {
    -- Update the cursor column to match current window size
    event = { "WinEnter", "BufEnter", "VimResized", "FileType" },
    command = function()
      enable_colorcolumn()
    end,
  },
  {
    event = { "WinLeave", "BufLeave" },
    command = function()
      disable_colorcolumn(true)
    end,
  },
})
