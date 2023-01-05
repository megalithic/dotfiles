if not mega then return end
if not vim.g.enabled_plugin["windows"] then return end

local GOLDEN_RATIO = 1.618
local ft_ignores = {
  "help",
  "terminal",
  "megaterm",
  "dirbuf",
  "Trouble",
  "qf",
  "neo-tree",
  "packer",
  "startuptime",
}

local bt_ignores = {
  "help",
  "acwrite",
  "Undotree",
  "quickfix",
  "nerdtree",
  "current",
  "Vista",
  "Trouble",
  "LuaTree",
  "NvimTree",
  "terminal",
  "dirbuf",
  "tsplayground",
  "neo-tree",
  "packer",
  "startuptime",
}

local ignored_height = nil
local ignored_width = nil

local function ignored_by_window_resize_flag()
  local ignore_golden_resize = false

  local ok, result = pcall(vim.api.nvim_win_get_var, 0, "ignore_golden_resize")
  if ok then ignore_golden_resize = result end

  return ignore_golden_resize
end

local function is_floating_win() return vim.fn.win_gettype() == "popup" end

local function is_ignored(bufnr)
  local should_ignore = vim.tbl_contains(bt_ignores, vim.bo[bufnr].buftype)
    or vim.tbl_contains(ft_ignores, vim.bo[bufnr].filetype)
    or vim.bo[bufnr].filetype == ""
    or ignored_by_window_resize_flag()
    or is_floating_win()

  -- P(fmt("resize_windows should ignore (%s): %s", should_ignore, vim.bo[bufnr].filetype, vim.bo[bufnr].buftype))
  return should_ignore
end

function mega.resize_windows(bufnr)
  -- P(fmt("resize_windows filetype: %s", vim.bo[bufnr].filetype))
  if is_ignored(bufnr) then return end

  local columns = vim.api.nvim_get_option("columns")
  local rows = vim.api.nvim_get_option("lines")
  local current_height = vim.api.nvim_win_get_height(0)
  local current_width = vim.api.nvim_win_get_width(0)

  -- ignored_height = current_height
  -- ignored_width = current_width
  -- vim.api.nvim_win_set_height(0, ignored_height)
  -- vim.api.nvim_win_set_width(0, ignored_width)
  -- vim.cmd(fmt("let &winwidth=%d", ignored_width))
  -- vim.cmd(fmt("let &winheight=%d", ignored_height))

  local golden_height = math.floor(rows / GOLDEN_RATIO)
  local golden_width = math.floor(columns / GOLDEN_RATIO)

  if current_width < golden_width then vim.api.nvim_win_set_width(0, golden_width) end
  if current_height < golden_height then vim.api.nvim_win_set_height(0, golden_height) end
end

-----------------------------------------------------------------------------//
-- Autoresize
-----------------------------------------------------------------------------//
-- Auto resize Vim splits to active split to 70% -
-- https://stackoverflow.com/questions/11634804/vim-auto-resize-focused-window
function mega.auto_resize()
  -- local auto_resize_on = false
  -- return function(args)
  --   if not auto_resize_on then
  --     local factor = args and tonumber(args) or 70
  --     local fraction = factor / 10
  --     -- NOTE: mutating &winheight/&winwidth are key to how
  --     -- this functionality works, the API fn equivalents do
  --     -- not work the same way
  --     vim.cmd(fmt("let &winheight=&lines * %d / 10 ", fraction))
  --     vim.cmd(fmt("let &winwidth=&columns * %d / 10 ", fraction))
  --     auto_resize_on = true
  --     vim.notify("Auto resize ON")
  --   else
  --     vim.cmd("let &winheight=30")
  --     vim.cmd("let &winwidth=30")
  --     vim.cmd("wincmd =")
  --     auto_resize_on = false
  --     vim.notify("Auto resize OFF")
  --   end
  -- end
end

-- mega.command("AutoResize", mega.auto_resize(), { nargs = "?" })

mega.augroup("WindowsGoldenResizer", {
  {
    event = { "WinEnter", "VimResized" },
    command = function(args) mega.resize_windows(args.buf) end,
  },
  {
    event = { "WinLeave" },
    command = function(args)
      -- if is_ignored(args.buf) then
      --   P(fmt("resize_windows winleave: %s(%d)", vim.api.nvim_buf_get_name(args.buf), args.buf))
      --   -- if ignored_height ~= nil then vim.api.nvim_command(vim.api.nvim_win_set_height(0, ignored_height)) end
      --   -- if ignored_width ~= nil then vim.api.nvim_command(vim.api.nvim_win_set_width(0, ignored_width)) end
      --   -- vim.cmd(fmt("let &winwidth=%d", ignored_width))
      --   -- vim.cmd(fmt("let &winheight=%d", ignored_height))
      -- end

      -- if ignored_height ~= nil then vim.api.nvim_command(vim.api.nvim_win_set_height(0, ignored_height)) end
      -- if ignored_width ~= nil then vim.api.nvim_command(vim.api.nvim_win_set_width(0, ignored_width)) end
      -- vim.cmd(fmt("let &winwidth=%d", ignored_width))
      -- vim.cmd(fmt("let &winheight=%d", ignored_height))
    end,
  },
})
