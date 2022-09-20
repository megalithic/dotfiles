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
}

-- local function ignore_float_windows()
--   local current_config = vim.api.nvim_win_get_config(0)
--   if current_config["relative"] ~= "" then return 1 end
-- end

-- local function ignore_by_window_flag()
--   local ignore_golden_size = 0

--   local status, result = pcall(vim.api.nvim_win_get_var, 0, "ignore_golden_size")
--   if status then ignore_golden_size = result end

--   if ignore_golden_size == 1 then
--     return 1
--   else
--     return 0
--   end
-- end

local function is_floating_win() return vim.fn.win_gettype() == "popup" end

local function is_ignored()
  return vim.tbl_contains(bt_ignores, vim.bo.buftype)
    or vim.tbl_contains(ft_ignores, vim.bo.filetype)
    or is_floating_win()
end

function mega.resize_windows()
  if is_ignored() then return end

  local columns = vim.api.nvim_get_option("columns")
  local rows = vim.api.nvim_get_option("lines")
  local current_height = vim.api.nvim_win_get_height(0)
  local current_width = vim.api.nvim_win_get_width(0)
  local golden_width = math.floor(columns / GOLDEN_RATIO)

  if current_width < golden_width then vim.api.nvim_win_set_width(0, golden_width) end

  local golden_height = math.floor(rows / GOLDEN_RATIO)
  if current_height < golden_height then vim.api.nvim_win_set_height(0, golden_height) end
end

mega.augroup("WindowsGoldenResizer", {
  {
    event = { "WinEnter", "VimResized" },
    command = function() mega.resize_windows() end,
  },
})
