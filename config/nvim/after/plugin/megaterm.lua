-- megaterm.lua - Terminal management for Neovim
-- Single-file module following mini.nvim patterns
-- Provides: Terminal class, Manager, Send API, keymaps/autocmds
-- Architecture: One window per position, multiple terminals as buffers (buffer-switching model)

if not Plugin_enabled() then return end  -- auto-detects "megaterm" from filename

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

---@class mega.term.Config
---@field default_position "bottom"|"right"|"tab"|"float"
---@field default_height number
---@field default_width number
---@field float_config table

local config = {
  default_position = "bottom",
  default_height = 15,
  default_width = 80,
  float_config = {
    relative = "editor",
    border = "rounded",
    style = "minimal",
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
---@field cmd_str string
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

  -- Resolve command string early for tracking
  local cmd = opts.cmd or vim.o.shell
  self.cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or cmd

  -- Create buffer first (window creation is deferred to show())
  self.buf = vim.api.nvim_create_buf(false, true)

  -- Start terminal process in the correct buffer
  -- termopen() operates on current buffer, so we use nvim_buf_call to run it in self.buf
  vim.api.nvim_buf_call(self.buf, function()
    self.job_id = vim.fn.termopen(cmd, {
      on_exit = function(job_id, exit_code, event)
        if opts.on_exit_notifier then opts.on_exit_notifier(self.cmd_str, exit_code) end
        if opts.on_exit then opts.on_exit(job_id, exit_code, event, self) end
        -- Auto-cleanup invalid terminals
        vim.schedule(function()
          if not self:is_valid() then self:_remove_from_manager() end
        end)
      end,
    })
  end)

  -- Buffer settings
  vim.bo[self.buf].buflisted = false
  vim.bo[self.buf].bufhidden = "hide"
  vim.bo[self.buf].filetype = "megaterm"
  vim.bo[self.buf].buftype = "terminal"

  -- Set buffer variables for statusline integration
  vim.api.nvim_buf_set_var(self.buf, "term_buf", self.buf)
  vim.api.nvim_buf_set_var(self.buf, "term_name", "megaterm")
  vim.api.nvim_buf_set_var(self.buf, "term_cmd", self.cmd_str)

  -- Mark buffer to stay ignored by golden ratio
  vim.b[self.buf].resize_disable = true

  -- Set buffer-local keymaps
  self:_set_keymaps()

  -- Show the terminal in a window
  self:show({ start_insert = opts.start_insert })

  -- Callbacks
  if opts.on_open then opts.on_open(self) end

  return self
end

--- Get size from opts (supports both direct and win_config.* patterns)
---@param key "height"|"width"
---@return number
function Terminal:_get_size(key)
  if self.opts[key] then return self.opts[key] end
  if self.opts.win_config and self.opts.win_config[key] then return self.opts.win_config[key] end
  return key == "height" and config.default_height or config.default_width
end

--- Get or create window for this position
---@return number? win Window handle
function Terminal:_get_or_create_window()
  -- Check if a window already exists for this position
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      -- Check if this window contains a terminal of the same position
      local ok, pos = pcall(vim.api.nvim_buf_get_var, buf, "term_position")
      if ok and pos == self.position then return win end
    end
  end

  -- No existing window, create one
  return self:_create_window()
end

--- Create window based on position
---@return number win Window handle
function Terminal:_create_window()
  local win
  local size = self:_get_size(self.position == "bottom" and "height" or "width")

  -- Temporarily disable golden ratio during window creation
  local prev_resize_disable = vim.g.resize_disable
  vim.g.resize_disable = true

  if self.position == "float" then
    local width = self:_get_size("width")
    local height = self:_get_size("height")
    -- For float, if using defaults, use 80% of screen
    if width == config.default_width then width = math.floor(vim.o.columns * 0.8) end
    if height == config.default_height then height = math.floor(vim.o.lines * 0.8) end
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    win = vim.api.nvim_open_win(
      self.buf,
      true,
      vim.tbl_extend("force", config.float_config, {
        width = width,
        height = height,
        row = row,
        col = col,
      })
    )
  elseif self.position == "tab" then
    vim.cmd("tabnew")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, self.buf)
  else
    -- Split at edge
    if self.position == "bottom" then
      vim.cmd("botright " .. size .. "split")
    elseif self.position == "right" then
      vim.cmd("botright " .. size .. "vsplit")
    end
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, self.buf)
  end

  -- Mark terminal window to stay ignored by golden ratio
  vim.w[win].resize_disable = true

  -- Store position in buffer for window tracking
  vim.api.nvim_buf_set_var(self.buf, "term_position", self.position)

  -- Restore global state
  vim.g.resize_disable = prev_resize_disable

  return win
end

--- Apply winhighlight based on position
---@param win number
function Terminal:_set_winhighlight(win)
  if not vim.api.nvim_win_is_valid(win) then return end

  local hls
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

  -- vim.wo[win].winhighlight = table.concat(hls, ",")
  vim.api.nvim_set_option_value("winhighlight", table.concat(hls, ","), { win = win, scope = "local" })
end

--- Apply window/buffer options
---@param win number
function Terminal:_apply_window_options(win)
  if not vim.api.nvim_win_is_valid(win) then return end

  -- Window options
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].spell = false
  vim.wo[win].statuscolumn = ""
  vim.wo[win].winblend = 0

  -- Signcolumn: yes:1 for splits, no for float/tab
  if vim.tbl_contains({ "float", "tab" }, self.position) then
    vim.wo[win].signcolumn = "no"
    vim.bo[self.buf].bufhidden = "wipe"
  else
    vim.wo[win].signcolumn = "yes:1"
  end

  -- Apply winhighlight
  self:_set_winhighlight(win)
  self:update_padding(win)
end

--- Set buffer-local keymaps for terminal
function Terminal:_set_keymaps()
  local opts = { buffer = self.buf, silent = true }

  -- Normal mode: q closes terminal (only for non-tab positions)
  if self.position ~= "tab" then
    vim.keymap.set("n", "q", function() self:close() end, vim.tbl_extend("force", opts, { desc = "Close terminal" }))
  end

  -- Terminal mode keymaps
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], vim.tbl_extend("force", opts, { desc = "Exit terminal mode" }))
  vim.keymap.set("t", "<C-h>", [[<cmd>wincmd h<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate left" }))
  vim.keymap.set("t", "<C-j>", [[<cmd>wincmd j<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate down" }))
  vim.keymap.set("t", "<C-k>", [[<cmd>wincmd k<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate up" }))
  vim.keymap.set("t", "<C-l>", [[<cmd>wincmd l<cr>]], vim.tbl_extend("force", opts, { desc = "Navigate right" }))
  vim.keymap.set(
    "t",
    "<C-;>",
    function() Megaterm.toggle() end,
    vim.tbl_extend("force", opts, { desc = "Toggle terminal" })
  )
  vim.keymap.set(
    "t",
    "<C-'>",
    function() Megaterm.cycle() end,
    vim.tbl_extend("force", opts, { desc = "Cycle terminals" })
  )
  vim.keymap.set("t", "<C-x>", function() self:close() end, vim.tbl_extend("force", opts, { desc = "Close terminal" }))
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
function Terminal:is_valid() return self.buf and vim.api.nvim_buf_is_valid(self.buf) end

--- Check if terminal is visible in any window
---@return boolean
function Terminal:is_visible()
  if not self:is_valid() then return false end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == self.buf then return true end
  end
  return false
end

--- Get window displaying this terminal (if visible)
---@return number?
function Terminal:get_win()
  if not self:is_valid() then return nil end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == self.buf then return win end
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

--- Show terminal (create/reuse window, switch buffer)
---@param opts? { start_insert?: boolean }
function Terminal:show(opts)
  opts = opts or {}
  if not self:is_valid() then return end

  -- Get or create window for this position
  local win = self:_get_or_create_window()
  if not win then return end

  -- Switch buffer in window
  vim.api.nvim_win_set_buf(win, self.buf)
  vim.api.nvim_set_current_win(win)

  -- Apply window options
  self:_apply_window_options(win)

  if opts.start_insert ~= false then vim.cmd("startinsert") end
end

--- Hide terminal window (only if this terminal is the only one in the position)
function Terminal:hide()
  local win = self:get_win()
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  -- Switch to normal mode first
  local mode = vim.api.nvim_get_mode().mode
  if mode == "t" then vim.cmd("stopinsert") end

  -- Check if there are other terminals for this position
  local other_terms = Megaterm.get_by_position(self.position)
  if #other_terms > 1 then
    -- Switch to another terminal in this position
    for _, term in ipairs(other_terms) do
      if term ~= self and term:is_valid() then
        vim.api.nvim_win_set_buf(win, term.buf)
        return
      end
    end
  end

  -- No other terminals, close the window
  vim.api.nvim_win_close(win, false)
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

--- Close terminal (destroy buffer and remove from manager)
function Terminal:close()
  self:hide()
  if self:is_valid() then
    -- Kill the job if still running
    if self.job_id then pcall(vim.fn.jobstop, self.job_id) end
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
  if opts.newline then to_send = to_send .. "\r" end

  vim.api.nvim_chan_send(self.job_id, to_send)
end

--- Send text followed by Enter
---@param text string
function Terminal:send_line(text) self:send(text, { newline = true }) end

--- Send raw keycodes (for special keys)
---@param keys string
function Terminal:send_keys(keys)
  if not self:is_focused() then self:focus({ start_insert = false }) end
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "t", true)
end

--------------------------------------------------------------------------------
-- UI Niceties
--------------------------------------------------------------------------------

--- Update padding (signcolumn) based on window count
---@param win? number
function Terminal:update_padding(win)
  win = win or self:get_win()
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  local wins = vim.api.nvim_tabpage_list_wins(0)
  local win_count = 0

  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    -- Exclude incline windows from count
    if vim.bo[buf].filetype ~= "incline" then win_count = win_count + 1 end
  end

  local enabled = win_count > 1
  vim.api.nvim_set_option_value("signcolumn", enabled and "yes" or "no", { scope = "local", win = win })
end

--- Update cursorline highlight for terminal mode
function Terminal:update_cursorline_highlight()
  local mode = vim.api.nvim_get_mode().mode
  local curr_win = vim.api.nvim_get_current_win()
  local win = self:get_win()

  if win and vim.api.nvim_win_is_valid(win) then
    local winhighlight = (curr_win == win and mode ~= "nt") and "CursorLineSign:Normal,CursorLineNr:Normal" or ""
    vim.api.nvim_set_option_value("winhighlight", winhighlight, { scope = "local", win = win })
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
    if term.position == position then count = count + 1 end
  end
  return count
end

--- Get terminals by position
---@param position string
---@return mega.term.Terminal[]
function M.get_by_position(position)
  local result = {}
  for _, term in ipairs(M.list()) do
    if term.position == position then table.insert(result, term) end
  end
  return result
end

--- Create new terminal (unlimited with buffer-switching model)
---@param opts? mega.term.TermOpts
---@return mega.term.Terminal
function M.create(opts)
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
    if term:is_focused() then return term end
  end
  return nil
end

--- Get terminal by index
---@param idx number
---@return mega.term.Terminal?
function M.get(idx) return M.list()[idx] end

--- Toggle terminals by position
---@param opts? mega.term.TermOpts
function M.toggle(opts)
  local terms = M.list()

  -- If a terminal is focused, hide it (and the window if it's the last one)
  local current = M.get_current()
  if current then
    M.last_toggled_position = current.position
    current:hide()
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

    -- Show most recent terminal of that position
    if position_to_show then
      for _, term in ipairs(M.history) do
        if term:is_valid() and term.position == position_to_show then
          term:show()
          M.last_toggled_position = nil
          return
        end
      end
    end

    -- Fallback: show first terminal from history
    for _, term in ipairs(M.history) do
      if term:is_valid() then
        term:show()
        return
      end
    end
  end

  -- No terminals exist, create one
  M.create(opts)
end

--- Cycle through terminals in current window (buffer-switching model)
function M.cycle()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)

  -- Get position of current window (if it's a terminal window)
  local ok, position = pcall(vim.api.nvim_buf_get_var, current_buf, "term_position")
  if not ok then
    -- Not in a terminal window, do nothing
    return
  end

  -- Get all terminals for this position
  local terms = M.get_by_position(position)
  if #terms == 0 then return end
  if #terms == 1 then return end -- Only one terminal, nothing to cycle

  -- Find current terminal index
  local current_idx
  for idx, term in ipairs(terms) do
    if term.buf == current_buf then
      current_idx = idx
      break
    end
  end

  if current_idx then
    -- Cycle to next terminal
    local next_idx = (current_idx % #terms) + 1
    local next_term = terms[next_idx]
    vim.api.nvim_win_set_buf(current_win, next_term.buf)
    vim.cmd("startinsert")
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
  __call = function(_, opts) return M.create(opts) end,
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
        if vim.api.nvim_get_mode().mode ~= "t" then vim.cmd("startinsert") end
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
    M.history = vim.tbl_filter(function(t) return t:is_valid() and t.buf ~= ev.buf end, M.history)
  end,
})

--------------------------------------------------------------------------------
-- Keymaps & Commands
--------------------------------------------------------------------------------

-- Global toggle (normal mode only - terminal mode handled by buffer-local keymap)
vim.keymap.set("n", "<C-;>", function() Megaterm.toggle() end, { desc = "Toggle terminal" })

-- Global cycle through terminals
vim.keymap.set({ "n", "t" }, "<C-'>", function() Megaterm.cycle() end, { desc = "Cycle terminals" })

-- :T command to create/toggle terminal with optional args
vim.api.nvim_create_user_command("T", function(opts)
  local args = opts.args
  if args and #args > 0 then
    Megaterm({ cmd = args })
  else
    Megaterm.toggle()
  end
end, { nargs = "*", desc = "Toggle or create megaterm" })
