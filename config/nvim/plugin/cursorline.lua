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
local blink_timer = vim.loop.new_timer()

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
-- local cursorline_bg = mega.colors().Megaforest.lush.orange.hex

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
      -- enable cursorline
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
    -- disable cursorline
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

-- REF: https://neovim.discourse.group/t/how-to-use-repeat-on-timer-start-in-a-lua-function/1645
local function blink_cursorline()
  local i = 0
  vim.opt.cursorlineopt = "screenline,number" -- optionally -> "screenline,number"
  highlight_cursorline()
  blink_timer:start(
    cursorline_timeout * 2,
    500,
    vim.schedule_wrap(function()
      unhighlight_cursorline()
      print("timer invoked! i=" .. tostring(i))
      vim.opt.cursorlineopt = "number" -- optionally -> "screenline,number"
      if i >= 1 then
        blink_timer:close() -- Always close handles to avoid leaks.
      end

      -- -- Create a timer handle (implementation detail: uv_timer_t).
      -- local timer = vim.loop.new_timer()
      -- local i = 0
      -- -- Waits 1000ms, then repeats every 750ms until timer:close().
      -- timer:start(1000, 750, function()
      --   print('timer invoked! i='..tostring(i))
      --   if i > 4 then
      --     timer:close()  -- Always close handles to avoid leaks.
      --   end
      --   i = i + 1
      -- end)
      -- print('sleeping');
      i = i + 1
      -- highlight_cursorline()
    end)
  )
end

local function disable_cursorline()
  vim.opt_local.cursorline = false
  status = WINDOW
end

local function enable_cursorline()
  -- disable_cursorline()
  -- blink_cursorline()
  set_cursorline()
  status = WINDOW
end

mega.augroup("ToggleCursorLine", {
  {
    events = { "BufEnter", "WinEnter" },
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
      -- blink_timer:close() -- Always close handles to avoid leaks.
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

-- blink_cursorline()
