if not mega then return end
if not vim.g.enabled_plugin["windows"] then return end

local GOLDEN_RATIO = 1.618
local ft_ignores = {
  "help",
  "terminal",
  "megaterm",
  "dirbuf",
  "SidebarNvim",
  "Trouble",
  "qf",
  "neo-tree",
  "lazy",
  "packer",
  "startuptime",
  "undotree",
  "DiffviewFiles",
  "neotest-summary",
}

local bt_ignores = {
  "help",
  -- "acwrite",
  "undotree",
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

  return should_ignore
end

function mega.resize_windows(bufnr)
  -- necessary to avoid split widths from going tooo small
  vim.o.winminwidth = 20

  bufnr = bufnr or 0
  if is_ignored(bufnr) then return end

  local columns = vim.api.nvim_get_option("columns")
  local rows = vim.api.nvim_get_option("lines")
  local current_height = vim.api.nvim_win_get_height(0)
  local current_width = vim.api.nvim_win_get_width(0)

  local golden_height = math.floor(rows / GOLDEN_RATIO)
  local golden_width = math.floor(columns / GOLDEN_RATIO)

  if current_width < golden_width then vim.api.nvim_win_set_width(0, golden_width) end
  if current_height < golden_height then vim.api.nvim_win_set_height(0, golden_height) end
end

mega.augroup("WindowsGoldenResizer", {
  {
    event = { "WinEnter", "VimResized" },
    command = function(args) mega.resize_windows(args.buf) end,
  },
  {
    event = { "WinEnter", "VimResized" },
    command = function(args) mega.resize_windows(args.buf) end,
  },
})
