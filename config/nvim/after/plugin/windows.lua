if not Plugin_enabled() then return end

local GOLDEN_RATIO = 1.618
local cmdheight = vim.o.cmdheight

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
  "dbee",
  "dbee-result",
  "Trouble",
  "trouble",
  "qf",
  "dbui",
  "neo-tree",
  "lazy",
  "packer",
  "startuptime",
  "undotree",
  "DiffviewFiles",
  "DiffviewFilePanel",
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
  "dbee",
  "LuaTree",
  "NvimTree",
  "terminal",
  "dbee",
  "dbee-result",
  "dirbuf",
  "tsplayground",
  "neo-tree",
  "packer",
  "startuptime",
  "DiffviewFiles",
  "DiffviewFilePanel",
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

  local should_ignore = vim.g.focus_disable == true
    or vim.w.focus_disable == true
    or vim.b.focus_disable == true
    or vim.tbl_contains(bt_ignores, vim.bo[bufnr].buftype)
    or vim.tbl_contains(ft_ignores, vim.bo[bufnr].filetype)
    or vim.bo[bufnr].filetype == ""
    or ignored_by_window_resize_flag()
    or vim.g.disable_autoresize
    or is_floating_win()

  -- D("window resize; should_ignore buffer? ", bufnr, should_ignore)

  -- dd({ vim.bo[bufnr].filetype, vim.bo[bufnr].buftype, bufnr, should_ignore })
  return should_ignore
end

local golden_ratio = 1.618

local golden_ratio_width = function()
  local maxwidth = vim.o.columns
  return math.floor(maxwidth / golden_ratio)
end

local golden_ratio_minwidth = function() return math.floor(golden_ratio_width() / (3 * golden_ratio)) end

local golden_ratio_height = function()
  local maxheight = vim.o.lines
  return math.floor(maxheight / golden_ratio)
end

local golden_ratio_minheight = function() return math.floor(golden_ratio_height() / (3 * golden_ratio)) end

local function save_fixed_win_dims()
  local fixed_dims = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).zindex == nil then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.w[win].focus_disable or vim.b[buf].focus_disable then
        fixed_dims[win] = {
          width = vim.api.nvim_win_get_width(win),
          height = vim.api.nvim_win_get_height(win),
        }
      end
    end
  end

  return fixed_dims
end

local function restore_fixed_win_dims(fixed_dims)
  for win, dims in pairs(fixed_dims) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_width(win, dims.width)
      vim.api.nvim_win_set_height(win, dims.height)
    end
  end
end

local function resize(bufnr)
  local width = golden_ratio_width()
  -- if config.autoresize.minwidth > 0 then
  --   width = math.max(width, config.autoresize.minwidth)
  -- elseif width < golden_ratio_minwidth() then
  --   width = golden_ratio_minwidth()
  -- end
  if width < golden_ratio_minwidth() then width = golden_ratio_minwidth() end

  local height = golden_ratio_height()
  -- if config.autoresize.minheight > 0 then
  --   height = math.max(height, config.autoresize.minheight)
  -- elseif height < golden_ratio_minheight() then
  --   height = golden_ratio_minheight()
  -- end
  if height < golden_ratio_minheight() then height = golden_ratio_minheight() end

  -- save cmdheight to ensure it is not changed by nvim_win_set_height
  cmdheight = vim.o.cmdheight

  local fixed = save_fixed_win_dims()

  vim.api.nvim_win_set_width(0, width)
  vim.api.nvim_win_set_height(0, height)

  restore_fixed_win_dims(fixed)

  vim.o.cmdheight = cmdheight
end

function mega.resize_windows(bufnr)
  -- necessary to avoid split widths from going tooo small
  vim.o.cmdheight = cmdheight
  vim.o.cmdwinheight = 7

  vim.o.winminwidth = 20
  vim.opt.winfixheight = true
  vim.opt.winfixwidth = true

  bufnr = bufnr or 0

  if is_ignored(bufnr) then
    -- vim.o.winminwidth = 20
    -- vim.o.winminheight = 10
    -- vim.o.winwidth = 20
    -- vim.o.winheight = 10
    return
  else
    resize(bufnr)

    -- -- local columns = vim.api.nvim_get_option("columns")
    -- -- local rows = vim.api.nvim_get_option("lines")
    -- local current_height = vim.api.nvim_win_get_height(0)
    -- local current_width = vim.api.nvim_win_get_width(0)
    --
    -- local golden_height = golden_ratio_height() -- math.floor(rows / GOLDEN_RATIO)
    -- local golden_width = golden_ratio_width() -- math.floor(columns / GOLDEN_RATIO)
    --
    -- if current_width < golden_width then vim.api.nvim_win_set_width(0, golden_width) end
    -- if current_height < golden_height then vim.api.nvim_win_set_height(0, golden_height) end
  end
end

vim.api.nvim_create_user_command("ToggleAutoResize", function()
  vim.g.disable_autoresize = not vim.g.disable_autoresize
  if vim.g.disable_autoresize then
    vim.notify("Disabled auto-window-resizing.", L.WARN)
  else
    vim.notify("Enabled auto-window-resizing.", L.INFO)
  end
end, {})

require("config.autocmds").augroup("WindowsGoldenResizer", {
  {
    event = { "BufEnter", "WinEnter", "VimResized" },
    command = function(args) mega.resize_windows(args.buf) end,
    desc = "Auto-resize window with golden ratio",
  },
  {
    event = { "WinEnter" },
    command = function(_)
      if vim.tbl_contains(bt_ignores, vim.bo.buftype) or vim.g.disable_autoresize then
        vim.w.focus_disable = true
      else
        vim.w.focus_disable = false
      end
    end,
    desc = "Disable auto-resize for buftype",
  },
  {
    event = { "FileType" },
    command = function(_)
      if vim.tbl_contains(ft_ignores, vim.bo.filetype) or vim.g.disable_autoresize then
        vim.b.focus_disable = true
      else
        vim.b.focus_disable = false
      end
    end,
    desc = "Disable auto-resize for filetype",
  },
})
