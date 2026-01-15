-- megaterm.lua - Terminal management for Neovim
-- Single-file module following mini.nvim patterns
-- Provides: Terminal class, Manager, Send API, keymaps/autocmds

if not Plugin_enabled("lsp") then return end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

---@class mega.term.Config
---@field default_position "bottom"|"right"|"tab"|"float"
---@field default_height number
---@field default_width number
---@field float_config table
---@field limits table<string, number>

local config = {
  default_position = "bottom",
  default_height = 15,
  default_width = 80,
  float_config = {
    relative = "editor",
    border = "rounded",
    style = "minimal",
  },
  limits = {
    bottom = 2,
    right = 2,
    float = 1,
    tab = 0, -- 0 = unlimited
  },
}

--------------------------------------------------------------------------------
-- Terminal Class
--------------------------------------------------------------------------------

---@class mega.term.Terminal
---@field buf number
---@field win number?
---@field job_id number?
---@field position "bottom"|"right"|"tab"|"float"
---@field opts table
local Terminal = {}
Terminal.__index = Terminal

---@class mega.term.TermOpts
---@field cmd? string|string[]
---@field position? "bottom"|"right"|"tab"|"float"
---@field height? number
---@field width? number
---@field win_config? { height?: number, width?: number }
---@field on_open? fun(term: mega.term.Terminal)
---@field on_exit? fun(job_id: number, exit_code: number, event: string, term: mega.term.Terminal)
---@field on_exit_notifier? fun(cmd: string, exit_code: number)
---@field focus? boolean
---@field start_insert? boolean
---@field temp? boolean

--- Create new terminal instance
---@param opts? mega.term.TermOpts
---@return mega.term.Terminal
function Terminal.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Terminal)

  self.position = opts.position or config.default_position
  self.opts = opts

  -- Create the terminal in appropriate window
  if self.position == "float" then
    self:_create_float()
  elseif self.position == "tab" then
    self:_create_tab()
  else
    self:_create_split()
  end

  -- Start terminal process
  local cmd = opts.cmd or vim.o.shell
  local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  self.job_id = vim.fn.termopen(cmd, {
    on_exit = function(job_id, exit_code, event)
      -- Call notifier if provided (for vim-test integration)
      if opts.on_exit_notifier then
        opts.on_exit_notifier(cmd_str, exit_code)
      end
      -- Call on_exit with signature matching vim-test expectations
      if opts.on_exit then
        opts.on_exit(job_id, exit_code, event, self)
      end
      -- Auto-cleanup invalid terminals
      vim.schedule(function()
        if not self:is_valid() then
          self:_remove_from_manager()
        end
      end)
    end,
  })

  -- Buffer settings
  vim.bo[self.buf].buflisted = false
  vim.bo[self.buf].bufhidden = "hide"

  -- Set buffer variables for statusline integration
  vim.api.nvim_buf_set_var(self.buf, "term_buf", self.buf)
  vim.api.nvim_buf_set_var(self.buf, "term_name", "megaterm")
  vim.api.nvim_buf_set_var(self.buf, "term_cmd", cmd_str)

  -- Apply UI niceties
  self:_apply_options()
  self:update_padding()
  self:update_cursorline_highlight()

  -- Callbacks
  if opts.on_open then opts.on_open(self) end
  if opts.start_insert ~= false then vim.cmd("startinsert") end

  return self
end

--- Get size from opts (supports both direct and win_config.* patterns)
---@param key "height"|"width"
---@return number
function Terminal:_get_size(key)
  -- Direct option takes precedence
  if self.opts[key] then return self.opts[key] end
  -- Then check win_config
  if self.opts.win_config and self.opts.win_config[key] then
    return self.opts.win_config[key]
  end
  -- Fall back to config defaults
  return key == "height" and config.default_height or config.default_width
end

--- Find visible terminals with the same position
---@return mega.term.Terminal[]
function Terminal:_find_siblings()
  local siblings = {}
  for _, term in ipairs(Megaterm.list()) do
    if term ~= self and term.position == self.position and term:is_visible() then
      table.insert(siblings, term)
    end
  end
  return siblings
end

--- Create horizontal or vertical split
function Terminal:_create_split()
  local position = self.position
  local size = position == "bottom"
    and self:_get_size("height")
    or self:_get_size("width")

  -- Temporarily disable golden ratio during split creation
  local prev_resize_disable = vim.g.resize_disable
  vim.g.resize_disable = true

  -- Check for existing terminal in same position
  local siblings = self:_find_siblings()
  local sibling = siblings[1]

  if sibling and sibling:get_win() then
    -- Split within the sibling's region to sit side-by-side (bottom) or stacked (right)
    vim.api.nvim_set_current_win(sibling:get_win())
    if position == "bottom" then
      -- Vertical split within horizontal band = side-by-side
      vim.cmd("vsplit")
    elseif position == "right" then
      -- Horizontal split within vertical band = stacked
      vim.cmd(size .. "split")
    end
  else
    -- No sibling, create new region at edge
    if position == "bottom" then
      vim.cmd("botright " .. size .. "split")
    elseif position == "right" then
      vim.cmd("botright " .. size .. "vsplit")
    end
  end

  self.win = vim.api.nvim_get_current_win()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(self.win, self.buf)

  -- Mark terminal window/buffer to stay ignored
  vim.w[self.win].resize_disable = true
  vim.b[self.buf].resize_disable = true

  -- Restore global state
  vim.g.resize_disable = prev_resize_disable
end

--- Create floating window
function Terminal:_create_float()
  local width = self:_get_size("width")
  local height = self:_get_size("height")
  -- For float, if using defaults, use 80% of screen
  if width == config.default_width then
    width = math.floor(vim.o.columns * 0.8)
  end
  if height == config.default_height then
    height = math.floor(vim.o.lines * 0.8)
  end
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  self.buf = vim.api.nvim_create_buf(false, true)
  self.win = vim.api.nvim_open_win(self.buf, true, vim.tbl_extend("force", config.float_config, {
    width = width,
    height = height,
    row = row,
    col = col,
  }))
end

--- Create in new tab
function Terminal:_create_tab()
  vim.cmd("tabnew")
  self.win = vim.api.nvim_get_current_win()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(self.win, self.buf)
end

--- Apply winhighlight based on position
---@param hls? string[]
function Terminal:_set_winhighlight(hls)
  if not self.win or not vim.api.nvim_win_is_valid(self.win) then return end

  if not hls then
    if self.position == "float" then
      hls = {
        "Normal:PanelBackground",
        "FloatBorder:PanelBorder",
        "CursorLine:Visual",
        "Search:None",
      }
    else
      hls = {
        "Normal:PanelBackground",
        "CursorLine:PanelBackground",
        "CursorLineNr:PanelBackground",
        "CursorLineSign:PanelBackground",
        "SignColumn:PanelBackground",
        "FloatBorder:PanelBorder",
      }
    end
  end

  vim.wo[self.win].winhighlight = table.concat(hls, ",")
end

--- Apply window/buffer options
function Terminal:_apply_options()
  if not self.win or not vim.api.nvim_win_is_valid(self.win) then return end

  -- Buffer options
  vim.bo[self.buf].filetype = "megaterm"
  vim.bo[self.buf].buftype = "terminal"

  -- Window options
  vim.wo[self.win].number = false
  vim.wo[self.win].relativenumber = false
  vim.wo[self.win].foldcolumn = "0"
  vim.wo[self.win].spell = false
  vim.wo[self.win].statuscolumn = ""
  vim.wo[self.win].winblend = 0

  -- Signcolumn: yes:1 for splits, no for float/tab
  if vim.tbl_contains({ "float", "tab" }, self.position) then
    vim.wo[self.win].signcolumn = "no"
    vim.bo[self.buf].bufhidden = "wipe"
  else
    vim.wo[self.win].signcolumn = "yes:1"
  end

  -- Apply winhighlight
  self:_set_winhighlight()

  -- Set buffer-local keymaps
  self:_set_keymaps()
end

--- Set buffer-local keymaps for terminal
function Terminal:_set_keymaps()
  local opts = { buffer = self.buf, silent = true }

  -- Normal mode: q closes terminal (only for non-tab positions)
  if self.position ~= "tab" then
    vim.keymap.set("n", "q", function()
      self:close()
    end, vim.tbl_extend("force", opts, { desc = "Close terminal" }))
  end

  -- Terminal mode keymaps
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], vim.tbl_extend("force", opts, { desc = "Exit terminal mode" }))
  vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate left" }))
  vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate down" }))
  vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate up" }))
  vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate right" }))
  vim.keymap.set("t", "<C-;>", function()
    Megaterm.toggle()
  end, vim.tbl_extend("force", opts, { desc = "Toggle terminal" }))
  vim.keymap.set("t", "<C-'>", function()
    Megaterm.cycle()
  end, vim.tbl_extend("force", opts, { desc = "Cycle terminals" }))
  vim.keymap.set("t", "<C-x>", function()
    self:close()
  end, vim.tbl_extend("force", opts, { desc = "Close terminal" }))
end

--- Remove self from manager tracking
function Terminal:_remove_from_manager()
  for i, term in ipairs(Megaterm.terminals) do
    if term == self then
      table.remove(Megaterm.terminals, i)
      break
    end
  end
end

--------------------------------------------------------------------------------
-- Terminal State Methods
--------------------------------------------------------------------------------

--- Check if terminal buffer is valid
---@return boolean
function Terminal:is_valid()
  return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

--- Check if terminal is visible in any window
---@return boolean
function Terminal:is_visible()
  if not self:is_valid() then return false end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == self.buf then
      return true
    end
  end
  return false
end

--- Get window displaying this terminal (if visible)
---@return number?
function Terminal:get_win()
  if not self:is_valid() then return nil end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == self.buf then
      return win
    end
  end
  return nil
end

--- Check if this terminal is focused in given window
---@param win? number
---@return boolean
function Terminal:is_focused(win)
  win = win or vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_buf(win) == self.buf
end

--------------------------------------------------------------------------------
-- Terminal Show/Hide/Toggle
--------------------------------------------------------------------------------

--- Show terminal (create window if needed)
---@param opts? { start_insert?: boolean }
function Terminal:show(opts)
  opts = opts or {}
  if not self:is_valid() then return end

  -- Already visible - just focus
  local existing_win = self:get_win()
  if existing_win then
    vim.api.nvim_set_current_win(existing_win)
    if opts.start_insert ~= false then vim.cmd("startinsert") end
    return
  end

  -- Temporarily disable golden ratio during window creation
  local prev_resize_disable = vim.g.resize_disable
  vim.g.resize_disable = true

  -- Create window based on position
  if self.position == "float" then
    local width = self:_get_size("width")
    local height = self:_get_size("height")
    -- For float, if using defaults, use 80% of screen
    if width == config.default_width then
      width = math.floor(vim.o.columns * 0.8)
    end
    if height == config.default_height then
      height = math.floor(vim.o.lines * 0.8)
    end
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    self.win = vim.api.nvim_open_win(self.buf, true, vim.tbl_extend("force", config.float_config, {
      width = width,
      height = height,
      row = row,
      col = col,
    }))
  elseif self.position == "tab" then
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, self.buf)
    self.win = vim.api.nvim_get_current_win()
  else
    local size = self.position == "bottom"
      and self:_get_size("height")
      or self:_get_size("width")

    -- Check for existing terminal in same position
    local siblings = self:_find_siblings()
    local sibling = siblings[1]

    if sibling and sibling:get_win() then
      -- Split within the sibling's region
      vim.api.nvim_set_current_win(sibling:get_win())
      if self.position == "bottom" then
        vim.cmd("vsplit")
      elseif self.position == "right" then
        vim.cmd(size .. "split")
      end
    else
      -- No sibling, create new region at edge
      if self.position == "bottom" then
        vim.cmd("botright " .. size .. "split")
      else
        vim.cmd("botright " .. size .. "vsplit")
      end
    end
    vim.api.nvim_win_set_buf(0, self.buf)
    self.win = vim.api.nvim_get_current_win()
  end

  -- Mark terminal window to stay ignored by golden ratio
  vim.w[self.win].resize_disable = true

  -- Restore global state
  vim.g.resize_disable = prev_resize_disable

  self:_apply_options()
  self:update_padding()
  if opts.start_insert ~= false then vim.cmd("startinsert") end
end

--- Hide terminal (close window, keep buffer)
function Terminal:hide()
  local win = self:get_win()
  if win and vim.api.nvim_win_is_valid(win) then
    -- Switch to normal mode first to avoid issues
    local mode = vim.api.nvim_get_mode().mode
    if mode == "t" then
      vim.cmd("stopinsert")
    end
    vim.api.nvim_win_close(win, false)
    self.win = nil
  end
end

--- Toggle terminal visibility
---@param opts? { start_insert?: boolean }
function Terminal:toggle(opts)
  if self:is_visible() then
    self:hide()
  else
    self:show(opts)
  end
end

--- Focus terminal and optionally enter insert mode
---@param opts? { start_insert?: boolean }
function Terminal:focus(opts)
  opts = opts or {}
  if not self:is_visible() then
    self:show(opts)
  else
    local win = self:get_win()
    if win then
      vim.api.nvim_set_current_win(win)
      if opts.start_insert ~= false then vim.cmd("startinsert") end
    end
  end
end

--- Close terminal (destroy buffer and window)
function Terminal:close()
  self:hide()
  if self:is_valid() then
    -- Kill the job if still running
    if self.job_id then
      pcall(vim.fn.jobstop, self.job_id)
    end
    vim.api.nvim_buf_delete(self.buf, { force = true })
  end
  self:_remove_from_manager()
end

--------------------------------------------------------------------------------
-- Send API (for REPLs, Claude Code, etc.)
--------------------------------------------------------------------------------

--- Send text to terminal
---@param text string
---@param opts? { newline?: boolean }
function Terminal:send(text, opts)
  opts = opts or {}
  if not self:is_valid() or not self.job_id then return end

  local to_send = text
  if opts.newline then
    to_send = to_send .. "\r"
  end

  vim.api.nvim_chan_send(self.job_id, to_send)
end

--- Send text followed by Enter
---@param text string
function Terminal:send_line(text)
  self:send(text, { newline = true })
end

--- Send raw keycodes (for special keys)
---@param keys string
function Terminal:send_keys(keys)
  if not self:is_focused() then
    self:focus({ start_insert = false })
  end
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "t", true)
end

--------------------------------------------------------------------------------
-- UI Niceties
--------------------------------------------------------------------------------

--- Update padding (signcolumn) based on window count
function Terminal:update_padding()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local win_count = 0
  local visible_in_wins = {}

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    -- Exclude incline windows from count
    if vim.bo[buf].filetype ~= "incline" then
      win_count = win_count + 1
    end
    if buf == self.buf then
      table.insert(visible_in_wins, win)
    end
  end

  local enabled = win_count > 1
  for _, win in ipairs(visible_in_wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_option_value("signcolumn", enabled and "yes" or "no", { scope = "local", win = win })
    end
  end
end

--- Update cursorline highlight for terminal mode
function Terminal:update_cursorline_highlight()
  local mode = vim.api.nvim_get_mode().mode
  local curr_win = vim.api.nvim_get_current_win()

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == self.buf then
      local winhighlight = (curr_win == win and mode ~= "nt")
        and "CursorLineSign:Normal,CursorLineNr:Normal"
        or ""
      vim.api.nvim_set_option_value("winhighlight", winhighlight, { scope = "local", win = win })
    end
  end
end

--------------------------------------------------------------------------------
-- Manager (Module API)
--------------------------------------------------------------------------------

---@class mega.term.Manager
---@field terminals mega.term.Terminal[]
---@field history mega.term.Terminal[]
---@field config mega.term.Config
---@field last_toggled_position string?
local M = {
  terminals = {},
  history = {},
  config = config,
  last_toggled_position = nil,
}

--- Setup configuration
---@param opts? mega.term.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  config = M.config
end

--- Count terminals by position
---@param position string
---@return number
function M.count_by_position(position)
  local count = 0
  for _, term in ipairs(M.list()) do
    if term.position == position then
      count = count + 1
    end
  end
  return count
end

--- Get terminals by position
---@param position string
---@return mega.term.Terminal[]
function M.get_by_position(position)
  local result = {}
  for _, term in ipairs(M.list()) do
    if term.position == position then
      table.insert(result, term)
    end
  end
  return result
end

--- Create new terminal (respects limits)
---@param opts? mega.term.TermOpts
---@return mega.term.Terminal
function M.create(opts)
  opts = opts or {}
  local position = opts.position or config.default_position
  local limit = config.limits[position] or 0

  -- Check limit (0 = unlimited)
  if limit > 0 and M.count_by_position(position) >= limit then
    -- Limit reached, focus an existing terminal of this position instead
    local existing = M.get_by_position(position)
    if #existing > 0 then
      existing[1]:focus()
      return existing[1]
    end
  end

  local term = Terminal.new(opts)
  table.insert(M.terminals, term)
  table.insert(M.history, 1, term)
  return term
end

--- Get list of valid terminals
---@return mega.term.Terminal[]
function M.list()
  M.terminals = vim.tbl_filter(function(t) return t:is_valid() end, M.terminals)
  return M.terminals
end

--- Get currently focused terminal
---@return mega.term.Terminal?
function M.get_current()
  for _, term in ipairs(M.list()) do
    if term:is_focused() then
      return term
    end
  end
  return nil
end

--- Get terminal by index
---@param idx number
---@return mega.term.Terminal?
function M.get(idx)
  return M.list()[idx]
end

--- Toggle terminals by position (hides/shows all terminals of same position)
---@param opts? mega.term.TermOpts
function M.toggle(opts)
  local terms = M.list()

  -- If a terminal is focused, hide ALL terminals of that position
  local current = M.get_current()
  if current then
    local position = current.position
    M.last_toggled_position = position
    for _, term in ipairs(M.get_by_position(position)) do
      if term:is_visible() then
        term:hide()
      end
    end
    return
  end

  -- Not focused - try to show terminals
  if #terms > 0 then
    -- Determine which position to show
    local position_to_show = M.last_toggled_position

    -- If no last toggled position, find from history
    if not position_to_show then
      for _, term in ipairs(M.history) do
        if term:is_valid() then
          position_to_show = term.position
          break
        end
      end
    end

    -- Show all hidden terminals of that position
    if position_to_show then
      local shown_any = false
      for _, term in ipairs(M.get_by_position(position_to_show)) do
        if term:is_valid() and not term:is_visible() then
          term:show({ start_insert = not shown_any }) -- Only start_insert on first
          shown_any = true
        end
      end
      if shown_any then
        M.last_toggled_position = nil
        return
      end
    end

    -- Fallback: show first hidden terminal from history
    for _, term in ipairs(M.history) do
      if term:is_valid() and not term:is_visible() then
        term:show()
        return
      end
    end
  end

  -- No terminals exist, create one
  M.create(opts)
end

--- Cycle through terminals
function M.cycle()
  local terms = M.list()
  if #terms == 0 then
    M.create()
    return
  end

  if #terms == 1 then
    terms[1]:focus()
    return
  end

  -- Find current index and cycle
  local current_idx
  for idx, term in ipairs(terms) do
    if term:is_focused() then
      current_idx = idx
      break
    end
  end

  if current_idx then
    local next_idx = (current_idx % #terms) + 1
    terms[next_idx]:focus()
  else
    -- No terminal focused, focus first
    terms[1]:focus()
  end
end

--- Focus last used terminal
function M.focus_last()
  for _, term in ipairs(M.history) do
    if term:is_valid() and not term:is_visible() then
      term:focus()
      return
    end
  end
  -- Fallback to first terminal
  local terms = M.list()
  if #terms > 0 then
    terms[1]:focus()
  end
end

--- Close all terminals
function M.close_all()
  for _, term in ipairs(M.list()) do
    term:close()
  end
end

--------------------------------------------------------------------------------
-- Global Exposure
--------------------------------------------------------------------------------

-- Expose as callable global: Megaterm(opts) creates terminal
-- Also indexable: Megaterm.list(), Megaterm.toggle(), etc.
_G.Megaterm = setmetatable(M, {
  __call = function(_, opts)
    return M.create(opts)
  end,
})

--------------------------------------------------------------------------------
-- Autocmds
--------------------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup("megaterm", { clear = true })

-- Track terminal focus history and auto-enter insert mode
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  callback = vim.schedule_wrap(function(ev)
    for _, term in ipairs(M.list()) do
      if term.buf == ev.buf then
        -- Remove from history and add to front
        for i, t in ipairs(M.history) do
          if t == term then
            table.remove(M.history, i)
            break
          end
        end
        table.insert(M.history, 1, term)

        -- Auto-enter insert mode when focusing terminal
        if vim.api.nvim_get_mode().mode ~= "t" then
          vim.cmd("startinsert")
        end
        return
      end
    end
  end),
})

-- Update padding when buffer enters window
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  callback = function()
    for _, term in ipairs(M.list()) do
      term:update_padding()
    end
  end,
})

-- Update cursorline highlight on mode change
vim.api.nvim_create_autocmd("ModeChanged", {
  group = augroup,
  callback = function()
    for _, term in ipairs(M.list()) do
      term:update_cursorline_highlight()
    end
  end,
})

-- Clean up history
vim.api.nvim_create_autocmd("BufDelete", {
  group = augroup,
  callback = function(ev)
    M.history = vim.tbl_filter(function(t)
      return t:is_valid() and t.buf ~= ev.buf
    end, M.history)
  end,
})

--------------------------------------------------------------------------------
-- Keymaps & Commands
--------------------------------------------------------------------------------

-- Global toggle (normal mode only - terminal mode handled by buffer-local keymap)
vim.keymap.set("n", "<C-;>", function()
  Megaterm.toggle()
end, { desc = "Toggle terminal" })

-- Global cycle through terminals
vim.keymap.set({ "n", "t" }, "<C-'>", function()
  Megaterm.cycle()
end, { desc = "Cycle terminals" })

-- :T command to create/toggle terminal with optional args
vim.api.nvim_create_user_command("T", function(opts)
  local args = opts.args
  if args and #args > 0 then
    Megaterm({ cmd = args })
  else
    Megaterm.toggle()
  end
end, { nargs = "*", desc = "Toggle or create megaterm" })
