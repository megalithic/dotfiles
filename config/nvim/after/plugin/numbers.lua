if not mega then return end

local api = vim.api
local M = {}

vim.g.number_filetype_exclusions = {
  "NeogitCommitMessage",
  "NeogitCommitMessage",
  "NeogitRebaseTodo",
  "NeogitStatus",
  "NvimTree",
  "Trouble",
  "alpha",
  "dap-repl",
  "fidget",
  "fugitive",
  "fzf",
  "fzf-lua",
  "fzflua",
  "gitcommit",
  "help",
  "lazy",
  "list",
  "log",
  "man",
  "megaterm",
  "netrw",
  "oil",
  "org",
  "orgagenda",
  "outputpanel",
  "prompt",
  "startify",
  "toggleterm",
  "undotree",
  "vim-plug",
  "vimwiki",
}

vim.g.number_buftype_exclusions = {
  "prompt",
  "terminal",
  "help",
  "nofile",
  "acwrite",
  "quickfix",
}

vim.g.number_buftype_ignored = { "quickfix" }

local function is_floating_win() return vim.fn.win_gettype() == "popup" end

local is_enabled = true

---Determines whether or not a window should be ignored by this plugin
---@return boolean
local function is_ignored() return vim.tbl_contains(vim.g.number_buftype_ignored, vim.bo.buftype) or is_floating_win() or vim.env.TMUX_POPUP end

-- block list certain plugins and buffer types
local function is_blocked()
  local win_type = vim.fn.win_gettype()

  if not api.nvim_buf_is_valid(0) and not api.nvim_buf_is_loaded(0) then return true end

  if vim.wo.diff then return true end

  if win_type == "command" then return true end

  if vim.wo.previewwindow then return true end

  for _, ft in ipairs(vim.g.number_filetype_exclusions) do
    if vim.bo.ft == ft or string.match(vim.bo.ft, ft) then return true end
  end

  if vim.tbl_contains(vim.g.number_buftype_exclusions, vim.bo.buftype) then return true end
  return false
end

local function enable_relative_number()
  if not is_enabled then return end
  if is_ignored() then return end
  if is_blocked() then
    -- setlocal nonumber norelativenumber
    vim.wo.number = false
    vim.wo.relativenumber = false
  else
    -- setlocal number relativenumber
    vim.wo.number = true
    vim.wo.relativenumber = true
  end
end

local function disable_relative_number()
  if is_ignored() then return end
  if is_blocked() then
    -- setlocal nonumber norelativenumber
    vim.wo.number = false
    vim.wo.relativenumber = false
  else
    -- setlocal number norelativenumber
    vim.wo.number = true
    vim.wo.relativenumber = false
  end
end

-- mega.command("ToggleRelativeNumber", function()
--   is_enabled = not is_enabled
--   if is_enabled then
--     enable_relative_number()
--   else
--     disable_relative_number()
--   end
-- end)

require("mega.autocmds").augroup("ToggleRelativeLineNumbers", {
  {
    event = { "BufEnter", "FileType", "FocusGained", "InsertLeave", "TermLeave", "CmdlineLeave" },
    command = function() enable_relative_number() end,
  },
  {
    event = { "FocusLost", "BufLeave", "InsertEnter", "TermOpen", "CmdlineEnter" },
    command = function() disable_relative_number() end,
  },
})

return M
