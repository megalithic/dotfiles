if not Plugin_enabled() then return end
--
-- local config = {
--   enable = true, -- Enable module
--   commands = true, -- Create Focus commands
--   autoresize = {
--     enable = true, -- Enable or disable auto-resizing of splits
--     width = 0, -- Force width for the focused window
--     height = 0, -- Force height for the focused window
--     minwidth = 0, -- Force minimum width for the unfocused window
--     minheight = 0, -- Force minimum height for the unfocused window
--     focusedwindow_minwidth = 100, -- Force minimum width for the focused window
--     focusedwindow_minheight = 0, -- Force minimum height for the focused window
--     height_quickfix = 10, -- Set the height of quickfix panel
--   },
--   split = {
--     bufnew = false, -- Create blank buffer for new split windows
--     tmux = false, -- Create tmux splits instead of neovim splits
--   },
--   ui = {
--     number = false, -- Display line numbers in the focussed window only
--     relativenumber = false, -- Display relative line numbers in the focussed window only
--     hybridnumber = false, -- Display hybrid line numbers in the focussed window only
--     absolutenumber_unfocussed = false, -- Preserve absolute numbers in the unfocussed windows
--
--     cursorline = true, -- Display a cursorline in the focussed window only
--     cursorcolumn = false, -- Display cursorcolumn in the focussed window only
--     colorcolumn = {
--       enable = false, -- Display colorcolumn in the foccused window only
--       list = "+1", -- Set the comma-saperated list for the colorcolumn
--     },
--     signcolumn = true, -- Display signcolumn in the focussed window only
--     winhighlight = false, -- Auto highlighting for focussed/unfocussed windows
--   },
-- }
--
-- local utils = {}
--
-- --RETURNS TABLE OF LOWER CASE STRINGS
-- --
-- utils.to_lower = function(list)
--   for k, v in ipairs(list) do
--     list[k] = v:lower()
--   end
--   return list
-- end
--
-- --RETURNS SET FROM A TABLE FOR FAST LOOKUPS
-- utils.to_set = function(list)
--   local set = {}
--   for _, l in ipairs(list) do
--     set[l] = true
--   end
--   return set
-- end
--
-- utils.add_to_set = function(set, item)
--   set[item] = true
--   return set
-- end
--
-- utils.remove_from_set = function(set, item)
--   set[item] = nil
--   return set
-- end
--
-- utils.is_disabled = function()
--   return vim.g.resize_disable == true or vim.w.resize_disable == true or vim.b.resize_disable == true
-- end
--
-- local M = {}
--
-- local golden_ratio = 1.618
--
-- local golden_ratio_width = function()
--   local maxwidth = vim.o.columns
--   return math.floor(maxwidth / golden_ratio)
-- end
--
-- local golden_ratio_minwidth = function()
--   return math.floor(golden_ratio_width() / (3 * golden_ratio))
-- end
--
-- local golden_ratio_height = function()
--   local maxheight = vim.o.lines
--   return math.floor(maxheight / golden_ratio)
-- end
--
-- local golden_ratio_minheight = function()
--   return math.floor(golden_ratio_height() / (3 * golden_ratio))
-- end
--
-- local function save_fixed_win_dims()
--   local fixed_dims = {}
--
--   for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
--     if vim.api.nvim_win_get_config(win).zindex == nil then
--       local buf = vim.api.nvim_win_get_buf(win)
--       if vim.w[win].focus_disable or vim.b[buf].focus_disable then
--         fixed_dims[win] = {
--           width = vim.api.nvim_win_get_width(win),
--           height = vim.api.nvim_win_get_height(win),
--         }
--       end
--     end
--   end
--
--   return fixed_dims
-- end
--
-- local function restore_fixed_win_dims(fixed_dims)
--   for win, dims in pairs(fixed_dims) do
--     if vim.api.nvim_win_is_valid(win) then
--       vim.api.nvim_win_set_width(win, dims.width)
--       vim.api.nvim_win_set_height(win, dims.height)
--     end
--   end
-- end
--
-- function M.autoresize(config)
--   local width
--   if config.autoresize.width > 0 then
--     width = config.autoresize.width
--   else
--     width = golden_ratio_width()
--     if config.autoresize.focusedwindow_minwidth > 0 then
--       if width < config.autoresize.focusedwindow_minwidth then
--         width = config.autoresize.focusedwindow_minwidth
--       end
--     elseif config.autoresize.minwidth > 0 then
--       width = math.max(width, config.autoresize.minwidth)
--     elseif width < golden_ratio_minwidth() then
--       width = golden_ratio_minwidth()
--     end
--   end
--
--   local height
--   if config.autoresize.height > 0 then
--     height = config.autoresize.height
--   else
--     height = golden_ratio_height()
--     if config.autoresize.focusedwindow_minheight > 0 then
--       if height < config.autoresize.focusedwindow_minheight then
--         height = config.autoresize.focusedwindow_minheight
--       end
--     elseif config.autoresize.minheight > 0 then
--       height = math.max(height, config.autoresize.minheight)
--     elseif height < golden_ratio_minheight() then
--       height = golden_ratio_minheight()
--     end
--   end
--
--   -- save cmdheight to ensure it is not changed by nvim_win_set_height
--   local cmdheight = vim.o.cmdheight
--
--   local fixed = save_fixed_win_dims()
--
--   vim.api.nvim_win_set_width(0, width)
--   vim.api.nvim_win_set_height(0, height)
--
--   restore_fixed_win_dims(fixed)
--
--   vim.o.cmdheight = cmdheight
-- end
--
-- function M.equalise()
--   vim.api.nvim_exec2("wincmd =", { output = false })
-- end
--
-- function M.maximise()
--   local width, height = vim.o.columns, vim.o.lines
--
--   local fixed = save_fixed_win_dims()
--
--   vim.api.nvim_win_set_width(0, width)
--   vim.api.nvim_win_set_height(0, height)
--
--   restore_fixed_win_dims(fixed)
-- end
--
-- M.goal = "autoresize"
--
-- function M.split_resizer(config, goal) --> Only resize normal buffers, set qf to 10 always
--   if goal then
--     M.goal = goal
--   end
--   if
--     utils.is_disabled()
--     or vim.api.nvim_win_get_option(0, "diff")
--     or vim.api.nvim_win_get_config(0).zindex ~= nil
--     or not config.autoresize.enable
--   then
--     -- Setting minwidth/minheight must be done before setting width/height
--     -- to avoid errors when winminwidth and winminheight are larger than 1.
--     vim.o.winminwidth = 1
--     vim.o.winminheight = 1
--     vim.o.winwidth = 1
--     vim.o.winheight = 1
--     return
--   else
--     if config.autoresize.minwidth > 0 and config.autoresize.focusedwindow_minwidth <= 0 then
--       if vim.o.winwidth < config.autoresize.minwidth then
--         vim.o.winwidth = config.autoresize.minwidth
--       end
--       vim.o.winminwidth = config.autoresize.minwidth
--     end
--     if config.autoresize.minheight > 0 and config.autoresize.focusedwindow_minheight <= 0 then
--       if vim.o.winheight < config.autoresize.minheight then
--         vim.o.winheight = config.autoresize.minheight
--       end
--       vim.o.winminheight = config.autoresize.minheight
--     end
--   end
--
--   if vim.bo.filetype == "qf" and config.autoresize.height_quickfix > 0 then
--     vim.api.nvim_win_set_height(0, config.autoresize.height_quickfix)
--     return
--   end
-- end
--
-- Augroup("mega.plugin.windows", {
--   {
--     event = { "WinEnter", "VimEnter" },
--     command = function(args)
--       M[M.goal](config)
--     end,
--   },
-- })

--
local cmdheight = vim.o.cmdheight

-- local golden_ratio_width = function()
--   local maxwidth = vim.o.columns
--   return math.floor(maxwidth / GOLDEN_RATIO)
-- end
--
-- local golden_ratio_minwidth = function()
--   return math.floor(golden_ratio_width() / (3 * GOLDEN_RATIO))
-- end
--
-- local golden_ratio_height = function()
--   local maxheight = vim.o.lines
--   return math.floor(maxheight / GOLDEN_RATIO)
-- end
--
-- local golden_ratio_minheight = function()
--   return math.floor(golden_ratio_height() / (3 * GOLDEN_RATIO))
-- end

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
  "opencode",
  "claude",
  "claudecode",
  "packer",
  "startuptime",
  "undotree",
  "DiffviewFiles",
  "DiffviewFilePanel",
  "neotest-summary",
  "edgy",
  "msg",
  "cmd",
  "pager",
  "dialog",
  "oil",
  "vscode-diff-explorer",
}

local bt_ignores = {
  "help",
  "acwrite", -- maybe not?
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
  "edgy",
  "edgy://",
  "oil",
  "oil://",
}

local function is_floating_win() return vim.fn.win_gettype() == "popup" end

local function is_disabled()
  return vim.g.resize_disable == true or vim.w.resize_disable == true or vim.b.resize_disable == true
end

local function is_ignored(bufnr)
  -- local win_count = #vim.api.nvim_tabpage_list_wins(0)
  -- dd(win_count)

  -- P(vim.bo[bufnr].buftype, vim.bo[bufnr].filetype)

  local should_ignore = vim.g.focus_disable == true
    or vim.w.resize_disable == true
    or vim.b.resize_disable == true
    or not vim.api.nvim_buf_is_valid(bufnr)
    or vim.tbl_contains(bt_ignores, vim.bo[bufnr].buftype)
    or vim.tbl_contains(ft_ignores, vim.bo[bufnr].filetype)
    or vim.bo[bufnr].filetype == ""
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
      if vim.w[win].resize_disable or vim.b[buf].resize_disable then
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
  -- cmdheight = vim.o.cmdheight

  -- local fixed = save_fixed_win_dims()
  --
  -- vim.api.nvim_win_set_width(0, width)
  -- vim.api.nvim_win_set_height(0, height)
  --
  -- restore_fixed_win_dims(fixed)
  --
  -- vim.o.cmdheight = cmdheight
end

function mega.resize_windows(bufnr)
  -- necessary to avoid split widths from going tooo small
  vim.o.cmdheight = cmdheight
  -- vim.o.cmdwinheight = 4
  vim.o.winfixheight = true
  vim.o.winfixwidth = true

  bufnr = bufnr or 0
  local winnr = vim.api.nvim_get_current_win()

  if is_ignored(bufnr) or is_disabled() then
    -- vim.o.winminwidth = vim.api.nvim_win_get_width(0)
    -- vim.o.winminheight = vim.api.nvim_win_get_height(0)

    --
    -- vim.o.winwidth = vim.api.nvim_win_get_width(0)
    -- vim.o.winheight = vim.api.nvim_win_get_height(0)

    return
  end

  --this does a weird flickering thing
  -- resize(bufnr)

  local current_height = vim.api.nvim_win_get_height(0)
  local current_width = vim.api.nvim_win_get_width(0)

  local golden_height = golden_ratio_height() -- math.floor(rows / GOLDEN_RATIO)
  local golden_width = golden_ratio_width() -- math.floor(columns / GOLDEN_RATIO)

  if current_width < golden_width then
    vim.api.nvim_win_set_width(0, golden_width)
    -- vim.print(golden_width, vim.o.winwidth, vim.o.winminwidth, math.min(golden_width, vim.api.nvim_win_get_width(0)))
    vim.o.winminwidth = vim.o.winwidth
    -- vim.o.winwidth = math.min(golden_width, 50)
  end
  if current_height < golden_height then
    vim.api.nvim_win_set_height(0, golden_height)
    vim.o.winminheight = vim.o.winheight
    -- vim.o.winminheight = 10
  end
end

Augroup("mega.plugin.windows", {
  {
    event = { "VimEnter", "BufEnter", "BufLeave" },
    -- event = { "VimEnter", "WinEnter", "WinLeave", "BufEnter", "BufLeave" },
    command = function(args) mega.resize_windows(args.buf) end,
    desc = "Auto-resize window with golden ratio",
  },
  {
    event = "WinEnter",
    command = function(args)
      if vim.tbl_contains(bt_ignores, vim.bo.buftype) then
        vim.w.resize_disable = true
      else
        vim.w.resize_disable = false
      end
    end,
  },
  {
    event = "FileType",
    command = function(args)
      if vim.tbl_contains(ft_ignores, vim.bo.filetype) then
        vim.b.resize_disable = true
      else
        vim.b.resize_disable = false
      end
    end,
  },
})
