if not Plugin_enabled() then return end

local api = vim.api
local M = {}

local excluded_fts = {
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
  -- "markdown",
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

local excluded_bts = {
  "prompt",
  "terminal",
  "help",
  "nofile",
  "acwrite",
  "quickfix",
}

local function is_floating_win() return vim.fn.win_gettype() == "popup" end

local is_enabled = true

-- block list certain plugins and buffer types
local function is_excluded()
  local win_type = vim.fn.win_gettype()

  if not api.nvim_buf_is_valid(0) and not api.nvim_buf_is_loaded(0) then return true end

  if vim.wo.diff then return true end

  if win_type == "command" then return true end

  if vim.wo.previewwindow then return true end

  if is_floating_win() or vim.env.TMUX_POPUP then return true end

  for _, ft in ipairs(excluded_fts) do
    if vim.bo.ft == ft or string.match(vim.bo.ft, ft) then return true end
  end

  if vim.tbl_contains(excluded_bts, vim.bo.buftype) then return true end

  return false
end

local function enable_relative_number()
  if not is_enabled then return end

  if is_excluded() then
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
  if is_excluded() then
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

require("config.autocmds").augroup("ToggleRelativeLineNumbers", {
  {
    event = { "BufEnter", "FileType", "FocusGained", "InsertLeave", "TermLeave", "CmdlineLeave" },
    command = function() enable_relative_number() end,
  },
  {
    event = { "FocusLost", "WinLeave", "BufLeave", "InsertEnter", "TermOpen", "CmdlineEnter" },
    command = function() disable_relative_number() end,
  },
})

return M
