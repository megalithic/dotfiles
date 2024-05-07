if not mega then return end

local GOLDEN_RATIO = 1.618

local golden_ratio_width = function()
  local maxwidth = vim.o.columns
  return math.floor(maxwidth / GOLDEN_RATIO)
end

local golden_ratio_minwidth = function() return math.floor(golden_ratio_width() / (3 * GOLDEN_RATIO)) end

local golden_ratio_height = function()
  local maxheight = vim.o.lines
  return math.floor(maxheight / GOLDEN_RATIO)
end

local golden_ratio_minheight = function() return math.floor(golden_ratio_height() / (3 * GOLDEN_RATIO)) end

local ft_ignores = {
  "help",
  "terminal",
  "megaterm",
  "dirbuf",
  "SidebarNvim",
  "fidget",
  "Trouble",
  "trouble",
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
  "trouble",
  "qf",
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
  -- local win_count = #vim.api.nvim_tabpage_list_wins(0)
  -- dd(win_count)

  local should_ignore = vim.tbl_contains(bt_ignores, vim.bo[bufnr].buftype)
    or vim.tbl_contains(ft_ignores, vim.bo[bufnr].filetype)
    or vim.bo[bufnr].filetype == ""
    or ignored_by_window_resize_flag()
    or is_floating_win()

  -- dd({ vim.bo[bufnr].filetype, vim.bo[bufnr].buftype, bufnr, should_ignore })
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

  local golden_height = golden_ratio_height() -- math.floor(rows / GOLDEN_RATIO)
  local golden_width = golden_ratio_width() -- math.floor(columns / GOLDEN_RATIO)

  if current_width < golden_width then vim.api.nvim_win_set_width(0, golden_width) end
  if current_height < golden_height then vim.api.nvim_win_set_height(0, golden_height) end
end

require("mega.autocmds").augroup("WindowsGoldenResizer", {
  {
    event = { "WinEnter", "VimResized" },
    command = function(args) mega.resize_windows(args.buf) end,
  },
  {
    event = { "WinEnter", "VimResized" },
    command = function(args) mega.resize_windows(args.buf) end,
  },
})
