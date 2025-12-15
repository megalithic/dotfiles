--- @class mega.Terminal
--- @field buf number
local Terminal = {}

function Terminal.new()
  vim.cmd("terminal")
  vim.cmd("startinsert")

  local self = setmetatable({}, { __index = Terminal })
  self.buf = vim.api.nvim_get_current_buf()
  if vim.bo[self.buf].buftype ~= "terminal" then
    error("Created a terminal buffer but didn't find it as the current buffer after creating it")
  end
  self:update_cursorline_highlight()
  self:update_padding()

  return self
end

function Terminal:is_valid() return vim.api.nvim_buf_is_valid(self.buf) end

--- @param win number?
--- @return boolean
function Terminal:is_focused(win) return vim.api.nvim_win_get_buf(win or 0) == self.buf end

--- @return boolean
function Terminal:is_visible()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_get_buf(win) == self.buf then return true end
  end
  return false
end

function Terminal:focus() vim.api.nvim_set_current_buf(self.buf) end

function Terminal:focus_and_enter_insert()
  self:focus()
  vim.cmd("startinsert")
end

function Terminal:focus_existing_and_enter_insert()
  -- Find the first window with this terminal and focus it
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_get_buf(win) == self.buf then
      vim.api.nvim_set_current_win(win)
      vim.cmd("startinsert")
      return
    end
  end

  -- Not visible, so focus in the cuurrent window
  self:focus_and_enter_insert()
end

--- Use the signcolumn as padding on the left side for when there's more than one window
--- open in the current tab
function Terminal:update_padding()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local win_count = 0
  local visible_in_wins = {}

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "incline" then win_count = win_count + 1 end
    if buf == self.buf then table.insert(visible_in_wins, win) end
  end

  local enabled = win_count > 1
  for _, win in ipairs(visible_in_wins) do
    vim.api.nvim_set_option_value("signcolumn", enabled and "yes" or "no", { scope = "local", win = win })
  end
end

--- The sign column will be highlighted by the cursorline while in terminal mode
--- while the rest of the line will not, so we update the winhighlight to override
--- the CursorLineSign highlight
function Terminal:update_cursorline_highlight()
  local mode = vim.api.nvim_get_mode().mode

  local curr_win = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == self.buf then
      local winhighlight = (curr_win == win and mode ~= "nt") and "CursorLineSign:Normal,CursorLineNr:Normal" or ""
      vim.api.nvim_set_option_value("winhighlight", winhighlight, { scope = "local", win = win })
    end
  end
end

return Terminal
