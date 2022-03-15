-- Inspiration
-- 1. nvim-cursorline

local api = vim.api
local fn = vim.fn

vim.g.cursorline_filetype_exclusions = {
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
  "toggleterm",
  "fugitive",
  "list",
  "NvimTree",
  "startify",
  "help",
  "orgagenda",
  "DirBuf",
  "org",
  "Trouble",
  "Telescope",
  "TelescopePrompt",
  "fzf",
  "NvimTree",
  "markdown",
  "dashboard",
  "Toggleterm",
  "qf",
}

vim.g.cursorline_buftype_exclusions = {
  "acwrite",
  "quickfix",
  "terminal",
  "nofile",
  "help",
  ".git/COMMIT_EDITMSG",
  "startify",
  "prompt",
}
local cursorline_timeout = 250
local DISABLED = 0
local CURSOR = 1
local WINDOW = 2
local status = CURSOR

local timer = vim.loop.new_timer()

local function is_floating_win()
  return vim.fn.win_gettype() == "popup"
end

---Determines whether or not a buffer/window should be ignored by this plugin
---@return boolean
local function is_ignored()
  return vim.tbl_contains(vim.g.cursorline_buftype_exclusions, vim.bo.buftype)
    or vim.tbl_contains(vim.g.cursorline_filetype_exclusions, vim.bo.filetype)
    or is_floating_win()
  --   or vim.wo.previewwindow
  --   or vim.wo.winhighlight == ""
  --   or vim.bo.filetype == ""
  --   or require("cmp").visible()
end

local function set_cursorline()
  if not is_ignored() then
    vim.wo.cursorline = true
  end
end

local function return_highlight_term(group, term)
  local output = api.nvim_exec("highlight " .. group, true)
  local hi = fn.matchstr(output, term .. [[=\zs\S*]])
  if hi == nil or hi == "" then
    return "None"
  else
    return hi
  end
end

local normal_bg = return_highlight_term("Normal", "guibg")
local cursorline_bg = return_highlight_term("CursorLine", "guibg")

local function timer_start()
  timer:start(
    cursorline_timeout,
    0,
    vim.schedule_wrap(function()
      -- enable cursorline
      vim.cmd("highlight! CursorLine guibg=" .. cursorline_bg)
      vim.cmd("highlight! CursorLineNr guibg=" .. cursorline_bg)
      status = CURSOR
    end)
  )
end

local function cursor_moved()
  if status == WINDOW then
    status = CURSOR
    return
  end
  if not is_ignored() then
    timer_start()
  end
  if status == CURSOR and cursorline_timeout ~= 0 then
    -- disable cursorline
    vim.cmd("highlight! CursorLine guibg=" .. normal_bg)
    vim.cmd("highlight! CursorLineNr guibg=" .. normal_bg)
    status = DISABLED
  end
end

local function enable_cursorline()
  set_cursorline()
  status = WINDOW
end

local function disable_cursorline()
  vim.o.cursorline = false
  status = WINDOW
end

mega.augroup("ToggleCursorLine", {
  {
    events = { "BufEnter" },
    targets = { "*" },
    command = function()
      enable_cursorline()
    end,
  },
  {
    events = { "BufLeave", "WinLeave" },
    targets = { "*" },
    command = function()
      disable_cursorline()
    end,
  },
  {
    events = { "CursorMoved", "CursorMovedI" },
    targets = { "*" },
    command = function()
      cursor_moved()
    end,
  },
})
