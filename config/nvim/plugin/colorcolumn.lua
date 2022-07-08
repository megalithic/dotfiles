-- Inspiration
-- 1. nvim-cursorline

local contains = vim.tbl_contains
local api = vim.api

local M = {
  -- ft's that i have explicit settings for; so let's just ignore all of this..
  column_ignore = { "gitcommit" },
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
    "DirBuf",
    "terminal",
    "megaterm",
    "toggleterm",
    "neo-tree",
  },
}

---Set or unset the color column depending on the filetype of the buffer and its eligibility
-- local function check_color_column()
--   for _, win in ipairs(api.nvim_list_wins()) do
--     local buffer = vim.bo[api.nvim_win_get_buf(win)]
--     local window = vim.wo[win]
--     if vim.fn.win_gettype() == "" and not vim.tbl_contains(M.column_ignore, buffer.filetype) then
--       local too_small = api.nvim_win_get_width(win) <= buffer.textwidth + 1
--       local is_excluded = vim.tbl_contains(M.column_clear, buffer.filetype)
--       if is_excluded or too_small then
--         window.colorcolumn = ""
--         local vc_ok, vc = mega.safe_require("virt-column")
--         if vc_ok then
--           vc.setup_buffer({ virtcolumn = window.colorcolumn })
--         end
--       elseif window.colorcolumn == "" then
--         window.colorcolumn = tostring(vim.g.default_colorcolumn)
--         window.colorcolumn = "+1"

--         local vc_ok, vc = mega.safe_require("virt-column")
--         if vc_ok then
--           vc.setup_buffer({ virtcolumn = window.colorcolumn })
--         end
--       end
--     end
--   end
-- end

local function set_colorcolumn(leaving)
  if contains(M.column_ignore, vim.bo.filetype) then return end

  local not_eligible = not vim.bo.modifiable or vim.wo.previewwindow or vim.bo.buftype ~= "" or not vim.bo.buflisted
  local small_window = api.nvim_win_get_width(0) <= vim.bo.textwidth + 1
  local is_last_win = #api.nvim_list_wins() == 1

  if contains(M.column_clear, vim.bo.filetype) or not_eligible or (leaving and not is_last_win) or small_window then
    vim.wo.colorcolumn = ""
    local vc_ok, vc = mega.safe_require("virt-column")
    if vc_ok then vc.setup_buffer({ virtcolumn = vim.wo.colorcolumn }) end

    return
  end

  if vim.wo.colorcolumn == "" then
    vim.wo.colorcolumn = tostring(vim.g.default_colorcolumn)

    local vc_ok, vc = mega.safe_require("virt-column")
    if vc_ok then vc.setup_buffer({ virtcolumn = vim.wo.colorcolumn }) end
  end
end

local function disable_colorcolumn(leaving) set_colorcolumn(leaving) end

local function enable_colorcolumn() set_colorcolumn() end

-- initial setup of virt-column; required for this plugin
mega.conf("virt-column", { config = { char = "│" } })

mega.augroup("ToggleColorColumn", {
  {
    -- Update the cursor column to match current window size
    event = { "WinEnter", "BufEnter", "VimResized", "FileType" }, -- BufWinEnter instead of WinEnter?
    command = function() enable_colorcolumn() end,
  },
  {
    event = { "WinLeave", "BufLeave" },
    command = function() disable_colorcolumn(true) end,
  },
})

-- mega.augroup("ToggleColorColumn", {
--   {
--     -- Update the cursor column to match current window size
--     event = { "BufEnter", "WinNew", "WinClosed", "FileType", "VimResized", "WinLeave", "BufLeave" },
--     command = check_color_column,
--   },
-- })
