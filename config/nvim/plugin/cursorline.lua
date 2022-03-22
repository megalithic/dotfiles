-- Inspiration
-- 1. nvim-cursorline

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
  "dirbuf",
  "org",
  "Trouble",
  "Telescope",
  "TelescopePrompt",
  "fzf",
  "NvimTree",
  "markdown",
  "dashboard",
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

local normal_bg = mega.colors().Background.bg.hex
local cursorline_bg = mega.colors().CursorLine.bg.hex

local function highlight_blinking_cursorline()
  vim.cmd("highlight! CursorLine guibg=" .. mega.colors().Megaforest.lush.orange)
  vim.cmd("highlight! CursorLineNr guibg=" .. mega.colors().Megaforest.lush.orange)
  -- vim.cmd("highlight! CursorLineNr guibg=" .. cursorline_bg)
end

local function highlight_cursorline()
  vim.cmd("highlight! CursorLine guibg=" .. cursorline_bg)
  vim.cmd("highlight! CursorLineNr guibg=" .. cursorline_bg)
end

local function unhighlight_cursorline()
  vim.cmd("highlight! CursorLine guibg=" .. normal_bg)
  vim.cmd("highlight! CursorLineNr guibg=" .. normal_bg)
end

local function timer_start()
  timer:start(
    cursorline_timeout,
    0,
    vim.schedule_wrap(function()
      highlight_cursorline()
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
    unhighlight_cursorline()
    status = DISABLED
  end
end

local function set_cursorline()
  if not is_ignored() then
    vim.opt_local.cursorline = true
    highlight_cursorline()
  end
end

-- REF:
-- https://neovim.discourse.group/t/how-to-use-repeat-on-timer-start-in-a-lua-function/1645
-- https://vi.stackexchange.com/questions/33056/how-to-use-vim-loop-interactively-in-neovim
local function blink_cursorline()
  local blink_timer = vim.loop.new_timer()
  vim.opt.cursorlineopt = "screenline,number" -- optionally -> "screenline,number"
  highlight_blinking_cursorline()
  blink_timer:start(
    cursorline_timeout * 2,
    0,
    vim.schedule_wrap(function()
      unhighlight_cursorline()
      vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
      blink_timer:stop()
      blink_timer:close()
    end)
  )
end

local function disable_cursorline()
  vim.opt_local.cursorline = false
  status = WINDOW
end

local function enable_cursorline()
  blink_cursorline()
  set_cursorline()
  highlight_cursorline()
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
    events = { "BufLeave" },
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
