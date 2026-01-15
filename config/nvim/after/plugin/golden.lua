-- Golden Ratio Window Resizing
-- A clean implementation based on focus.nvim principles
--
-- Features:
--   - Golden ratio resizing on window focus (WinEnter)
--   - Preserves dimensions of ignored windows (sidebars, quickfix, etc.)
--   - Configurable via mega.golden_config
--   - Falls back to equal splits on narrow terminals
--
-- Usage:
--   - Disable globally: vim.g.resize_disable = true
--   - Disable per-window: vim.w.resize_disable = true
--   - Disable per-buffer: vim.b.resize_disable = true
--   - Runtime config: mega.golden_config.equalize_threshold = 100
--
if not Plugin_enabled() then return end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local config = {
  golden_ratio = 1.618,
  quickfix_height = 15, -- Fixed height for qf/loclist
  equalize_threshold = 120, -- Below this column count, use equal splits
  equalize_enabled = true, -- Set false to always use golden ratio
  min_unfocused_width = 40, -- Minimum width for unfocused windows
  min_unfocused_height = 10, -- Minimum height for unfocused windows
  debug = false, -- Set true to see resize logging
}

-- Expose for runtime modification
mega.golden_config = config

--------------------------------------------------------------------------------
-- Ignore Lists (sets for O(1) lookup)
--------------------------------------------------------------------------------

local IGNORE_FILETYPES = {
  help = true,
  terminal = true,
  megaterm = true,
  dirbuf = true,
  SidebarNvim = true,
  fidget = true,
  dbee = true,
  ["dbee-result"] = true,
  Trouble = true,
  trouble = true,
  qf = true,
  dbui = true,
  ["neo-tree"] = true,
  lazy = true,
  opencode = true,
  claude = true,
  claudecode = true,
  packer = true,
  startuptime = true,
  undotree = true,
  DiffviewFiles = true,
  DiffviewFilePanel = true,
  ["neotest-summary"] = true,
  edgy = true,
  msg = true,
  cmd = true,
  pager = true,
  dialog = true,
  oil = true,
  ["vscode-diff-explorer"] = true,
}

local IGNORE_BUFTYPES = {
  help = true,
  acwrite = true,
  quickfix = true,
  terminal = true,
  nofile = true,
  prompt = true,
}

--------------------------------------------------------------------------------
-- Core Logic
--------------------------------------------------------------------------------

--- Check if a window should be resized
---@param win number? Window handle (defaults to current)
---@return boolean
local function should_resize(win)
  win = win or vim.api.nvim_get_current_win()

  -- Check disable flags (consistent naming: resize_disable everywhere)
  if vim.g.resize_disable then
    return false
  end

  if vim.w[win].resize_disable then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if vim.b[buf].resize_disable then
    return false
  end

  -- Skip floating windows (have zindex)
  local win_config = vim.api.nvim_win_get_config(win)
  if win_config.zindex ~= nil then
    return false
  end

  -- Skip diff mode
  if vim.wo[win].diff then
    return false
  end

  -- Check ignore lists
  local ft = vim.bo[buf].filetype or ""
  local bt = vim.bo[buf].buftype or ""

  if IGNORE_FILETYPES[ft] or IGNORE_BUFTYPES[bt] then
    return false
  end

  return true
end

--- Calculate golden ratio width, respecting minimum widths for other windows
---@param num_other_wins number Number of other (unfocused) windows in the row
---@return number
local function golden_width(num_other_wins)
  num_other_wins = num_other_wins or 1
  local cols = vim.o.columns
  local separators = num_other_wins -- 1 separator per split

  -- Calculate ideal golden width
  local ideal = math.floor(cols / config.golden_ratio)

  -- Calculate minimum space needed for other windows
  local min_for_others = (num_other_wins * config.min_unfocused_width) + separators

  -- If golden ratio would leave too little for others, reduce our target
  local available_for_focused = cols - min_for_others
  if ideal > available_for_focused then
    ideal = math.max(available_for_focused, config.min_unfocused_width)
  end

  return ideal
end

--- Calculate golden ratio height, respecting minimum heights for other windows
---@param num_other_wins number Number of other (unfocused) windows in the column
---@return number
local function golden_height(num_other_wins)
  num_other_wins = num_other_wins or 1
  local usable = vim.o.lines - vim.o.cmdheight - 1 -- -1 for statusline
  local separators = num_other_wins

  -- Calculate ideal golden height
  local ideal = math.floor(usable / config.golden_ratio)

  -- Calculate minimum space needed for other windows
  local min_for_others = (num_other_wins * config.min_unfocused_height) + separators

  -- If golden ratio would leave too little for others, reduce our target
  local available_for_focused = usable - min_for_others
  if ideal > available_for_focused then
    ideal = math.max(available_for_focused, config.min_unfocused_height)
  end

  return ideal
end

--- Save dimensions of windows that should NOT be resized
--- This allows us to restore sidebars, help windows, etc. after resizing
---@return table<number, {width: number, height: number}>
local function save_fixed_window_dims()
  local dims = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    -- Skip floating windows entirely
    local win_config = vim.api.nvim_win_get_config(win)
    if win_config.zindex == nil then
      -- Save dimensions of windows that should NOT resize
      if not should_resize(win) then
        dims[win] = {
          width = vim.api.nvim_win_get_width(win),
          height = vim.api.nvim_win_get_height(win),
        }
      end
    end
  end

  return dims
end

--- Restore saved window dimensions
---@param dims table<number, {width: number, height: number}>
local function restore_window_dims(dims)
  for win, d in pairs(dims) do
    if vim.api.nvim_win_is_valid(win) then
      -- Use pcall to handle edge cases (e.g., window closed between save/restore)
      pcall(vim.api.nvim_win_set_width, win, d.width)
      pcall(vim.api.nvim_win_set_height, win, d.height)
    end
  end
end

--- Main resize function
--- Called on WinEnter to apply golden ratio to focused window
function mega.golden_resize()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)

  -- Special handling for quickfix: always set to fixed height
  local bt = vim.bo[buf].buftype or ""
  if bt == "quickfix" then
    pcall(vim.api.nvim_win_set_height, win, config.quickfix_height)
    return
  end

  -- Check if this window should be resized
  if not should_resize(win) then
    if config.debug then
      vim.notify("Golden: should_resize returned false", vim.log.levels.DEBUG)
    end
    return
  end

  -- Only resize if we have multiple windows
  local wins = vim.api.nvim_tabpage_list_wins(0)
  -- Filter out floating windows from count
  local real_wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).zindex == nil
  end, wins)

  if #real_wins < 2 then
    if config.debug then
      vim.notify("Golden: only 1 real window, skipping", vim.log.levels.DEBUG)
    end
    return
  end

  -- Check if terminal is too narrow for golden ratio
  if config.equalize_enabled and vim.o.columns < config.equalize_threshold then
    vim.cmd("wincmd =")
    return
  end

  -- Save cmdheight (window height changes can affect it)
  local cmdheight = vim.o.cmdheight

  -- Enforce minimum widths globally so Neovim won't crush unfocused windows
  -- Must set winwidth/winheight first (they must be >= minwidth/minheight)
  if vim.o.winwidth < config.min_unfocused_width then
    vim.o.winwidth = config.min_unfocused_width
  end
  vim.o.winminwidth = config.min_unfocused_width

  if vim.o.winheight < config.min_unfocused_height then
    vim.o.winheight = config.min_unfocused_height
  end
  vim.o.winminheight = config.min_unfocused_height

  -- Save dimensions of windows that shouldn't resize (sidebars, help, etc.)
  local saved = save_fixed_window_dims()

  -- Count other resizable windows for minimum width calculations
  local other_wins = 0
  for _, w in ipairs(real_wins) do
    if w ~= win and should_resize(w) then
      other_wins = other_wins + 1
    end
  end

  -- Apply golden ratio to current window (respecting minimums for others)
  local target_width = golden_width(other_wins)
  local target_height = golden_height(other_wins)

  local before_w = vim.api.nvim_win_get_width(win)
  local ok_w, err_w = pcall(vim.api.nvim_win_set_width, win, target_width)
  local after_w = vim.api.nvim_win_get_width(win)

  if config.debug then
    vim.notify(
      string.format("Golden: width %d -> %d (target %d, ok=%s)", before_w, after_w, target_width, tostring(ok_w)),
      vim.log.levels.DEBUG
    )
  end

  pcall(vim.api.nvim_win_set_height, win, target_height)

  -- Restore dimensions of fixed windows
  restore_window_dims(saved)

  -- Restore cmdheight
  vim.o.cmdheight = cmdheight
end

--------------------------------------------------------------------------------
-- Autocmds
--------------------------------------------------------------------------------

Augroup("mega.plugin.golden", {
  {
    event = "WinEnter",
    command = function()
      -- Try immediate execution first, defer if needed for FileType race
      -- vim.schedule(mega.golden_resize)
      mega.golden_resize()
    end,
    desc = "Golden ratio resize on window focus",
  },
  {
    event = "VimResized",
    command = function()
      -- On terminal resize, equalize first then apply golden ratio
      vim.cmd("wincmd =")
      vim.schedule(mega.golden_resize)
    end,
    desc = "Re-apply golden ratio after terminal resize",
  },
})

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command("GoldenToggle", function()
  vim.g.resize_disable = not vim.g.resize_disable
  local status = vim.g.resize_disable and "disabled" or "enabled"
  vim.notify("Golden ratio resizing " .. status, vim.log.levels.INFO)
end, { desc = "Toggle golden ratio window resizing" })

vim.api.nvim_create_user_command("GoldenRatio", function()
  mega.golden_resize()
end, { desc = "Apply golden ratio to current window" })

vim.api.nvim_create_user_command("GoldenEqual", function()
  vim.cmd("wincmd =")
end, { desc = "Equalize all window sizes" })

vim.api.nvim_create_user_command("GoldenDebug", function()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cols = vim.o.columns
  local current_w = vim.api.nvim_win_get_width(win)
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local real_wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).zindex == nil
  end, wins)

  -- Count other resizable windows
  local other_wins = 0
  for _, w in ipairs(real_wins) do
    local b = vim.api.nvim_win_get_buf(w)
    local w_ft = vim.bo[b].filetype or ""
    local w_bt = vim.bo[b].buftype or ""
    if w ~= win and not IGNORE_FILETYPES[w_ft] and not IGNORE_BUFTYPES[w_bt] then
      other_wins = other_wins + 1
    end
  end

  local ideal_w = math.floor(cols / config.golden_ratio)
  local target_w = golden_width(other_wins)

  -- Inline should_resize check for debugging
  local ft = vim.bo[buf].filetype or ""
  local bt = vim.bo[buf].buftype or ""
  local is_floating = vim.api.nvim_win_get_config(win).zindex ~= nil
  local is_diff = vim.wo[win].diff
  local ft_ignored = IGNORE_FILETYPES[ft] or false
  local bt_ignored = IGNORE_BUFTYPES[bt] or false

  local info = {
    "Golden Debug:",
    string.format("  Terminal: %d cols x %d lines", cols, vim.o.lines),
    string.format("  Other resizable windows: %d", other_wins),
    string.format("  Ideal golden width: %d (%.1f%%)", ideal_w, (ideal_w / cols) * 100),
    string.format("  Adjusted target width: %d (%.1f%%) [respects min_unfocused_width=%d]", target_w, (target_w / cols) * 100, config.min_unfocused_width),
    string.format("  Current window width: %d (%.1f%%)", current_w, (current_w / cols) * 100),
    string.format("  Equalize threshold: %d (enabled: %s, below: %s)", config.equalize_threshold, tostring(config.equalize_enabled), tostring(cols < config.equalize_threshold)),
    "",
    "  All windows (" .. #real_wins .. " real, " .. #wins .. " total):",
  }

  -- Show all real windows with their dimensions
  for i, w in ipairs(real_wins) do
    local b = vim.api.nvim_win_get_buf(w)
    local w_width = vim.api.nvim_win_get_width(w)
    local w_height = vim.api.nvim_win_get_height(w)
    local w_ft = vim.bo[b].filetype or ""
    local w_bt = vim.bo[b].buftype or ""
    local is_current = w == win and " <- CURRENT" or ""
    local is_ignored = (IGNORE_FILETYPES[w_ft] or IGNORE_BUFTYPES[w_bt]) and " [ignored]" or ""
    table.insert(
      info,
      string.format(
        "    [%d] %dx%d (%.1f%%) ft='%s' bt='%s'%s%s",
        i,
        w_width,
        w_height,
        (w_width / cols) * 100,
        w_ft,
        w_bt,
        is_ignored,
        is_current
      )
    )
  end

  table.insert(info, "")
  table.insert(info, "  Should resize checks (current window):")
  table.insert(info, string.format("    vim.g.resize_disable: %s", tostring(vim.g.resize_disable)))
  table.insert(info, string.format("    vim.w.resize_disable: %s", tostring(vim.w[win].resize_disable)))
  table.insert(info, string.format("    vim.b.resize_disable: %s", tostring(vim.b[buf].resize_disable)))
  table.insert(info, string.format("    is_floating: %s", tostring(is_floating)))
  table.insert(info, string.format("    is_diff: %s", tostring(is_diff)))
  table.insert(info, string.format("    ft='%s' ignored: %s", ft, tostring(ft_ignored)))
  table.insert(info, string.format("    bt='%s' ignored: %s", bt, tostring(bt_ignored)))

  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
end, { desc = "Debug golden ratio calculations" })
