-- utils/acp/response.lua
-- Response display for ACP messages
--
-- Displays agent responses via:
--   - Notifications (vim.notify)
--   - Virtual text (inline with cursor)
--
-- Usage:
--   local response = require("utils.acp.response")
--   response.setup()
--   -- Automatically subscribes to ACP client events

local M = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

M.config = {
  -- Notification settings
  notify = {
    enabled = true,
    level = vim.log.levels.INFO,
    timeout = 5000, -- ms, 0 for persistent
    max_width = 80,
    max_lines = 20,
  },
  
  -- Virtual text settings
  virtual_text = {
    enabled = true,
    hl_group = "Comment",
    prefix = "󰌘 ",
    max_length = 100, -- chars per line
    position = "eol", -- "eol" or "right_align"
    clear_on_cursor_move = true,
  },
  
  -- What to display
  show = {
    messages = true,      -- Agent message chunks
    thoughts = false,     -- Agent thought chunks (usually verbose)
    tool_calls = true,    -- Tool execution status
    session_info = true,  -- Session title updates
  },
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local state = {
  current_message = "",
  message_lines = {},
  virtual_text_ns = nil,
  virtual_text_bufnr = nil,
  virtual_text_line = nil,
  unsubscribers = {},
}

--------------------------------------------------------------------------------
-- Virtual Text
--------------------------------------------------------------------------------

local function get_namespace()
  if not state.virtual_text_ns then
    state.virtual_text_ns = vim.api.nvim_create_namespace("pi_acp_response")
  end
  return state.virtual_text_ns
end

local function clear_virtual_text()
  if state.virtual_text_bufnr and vim.api.nvim_buf_is_valid(state.virtual_text_bufnr) then
    vim.api.nvim_buf_clear_namespace(state.virtual_text_bufnr, get_namespace(), 0, -1)
  end
  state.virtual_text_bufnr = nil
  state.virtual_text_line = nil
end

local function show_virtual_text(text)
  if not M.config.virtual_text.enabled then return end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  
  -- Clear previous
  clear_virtual_text()
  
  -- Truncate if needed
  local max_len = M.config.virtual_text.max_length
  local display_text = text
  if #display_text > max_len then
    display_text = display_text:sub(1, max_len - 3) .. "..."
  end
  
  -- Remove newlines for virtual text
  display_text = display_text:gsub("\n", " ")
  
  local ns = get_namespace()
  local prefix = M.config.virtual_text.prefix
  
  vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
    virt_text = { { prefix .. display_text, M.config.virtual_text.hl_group } },
    virt_text_pos = M.config.virtual_text.position,
  })
  
  state.virtual_text_bufnr = bufnr
  state.virtual_text_line = line
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------

local function notify(msg, level)
  if not M.config.notify.enabled then return end
  
  level = level or M.config.notify.level
  
  -- Truncate message if too long
  local lines = vim.split(msg, "\n")
  if #lines > M.config.notify.max_lines then
    lines = vim.list_slice(lines, 1, M.config.notify.max_lines)
    table.insert(lines, "... (truncated)")
  end
  
  local truncated_lines = {}
  for _, line in ipairs(lines) do
    if #line > M.config.notify.max_width then
      line = line:sub(1, M.config.notify.max_width - 3) .. "..."
    end
    table.insert(truncated_lines, line)
  end
  
  vim.notify(table.concat(truncated_lines, "\n"), level)
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local function on_message(data)
  if not M.config.show.messages then return end
  
  local text = data.text or ""
  
  -- Accumulate message
  state.current_message = state.current_message .. text
  
  -- Update virtual text with latest chunk
  show_virtual_text(text)
end

local function on_thought(data)
  if not M.config.show.thoughts then return end
  
  local text = data.text or ""
  show_virtual_text("💭 " .. text)
end

local function on_tool_call(data)
  if not M.config.show.tool_calls then return end
  
  local tool = data.tool_call or {}
  local name = tool.toolName or tool.name or "unknown"
  local status = tool.status or "pending"
  
  local msg = string.format("🔧 %s: %s", name, status)
  show_virtual_text(msg)
  
  if status == "pending" or status == "in_progress" then
    notify(msg, vim.log.levels.INFO)
  end
end

local function on_tool_call_update(data)
  if not M.config.show.tool_calls then return end
  
  local update = data.update or {}
  local status = update.status
  
  if status == "completed" then
    notify("✅ Tool completed", vim.log.levels.INFO)
    clear_virtual_text()
  elseif status == "failed" then
    notify("❌ Tool failed", vim.log.levels.WARN)
    clear_virtual_text()
  end
end

local function on_session_info(data)
  if not M.config.show.session_info then return end
  
  if data.title then
    notify(string.format("📝 Session: %s", data.title), vim.log.levels.INFO)
  end
end

local function on_connected(data)
  local info = data.agentInfo or {}
  notify(string.format("🔌 Connected to %s", info.name or "pi-acp"), vim.log.levels.INFO)
end

local function on_disconnected(data)
  notify(string.format("🔌 Disconnected (code: %d)", data.code or -1), vim.log.levels.WARN)
  clear_virtual_text()
end

local function on_session_created(data)
  local session_id = data.sessionId or "unknown"
  local short_id = session_id:sub(1, 8)
  notify(string.format("📁 New session: %s", short_id), vim.log.levels.INFO)
end

--------------------------------------------------------------------------------
-- Auto-clear on cursor move
--------------------------------------------------------------------------------

local function setup_autocmds()
  if M.config.virtual_text.clear_on_cursor_move then
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = vim.api.nvim_create_augroup("PiAcpResponse", { clear = true }),
      callback = function()
        -- Only clear if we moved to a different line
        if state.virtual_text_bufnr then
          local cursor = vim.api.nvim_win_get_cursor(0)
          local current_line = cursor[1] - 1
          if current_line ~= state.virtual_text_line then
            clear_virtual_text()
          end
        end
      end,
    })
  end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Get accumulated message text
---@return string
function M.get_current_message()
  return state.current_message
end

--- Clear accumulated message
function M.clear_message()
  state.current_message = ""
  state.message_lines = {}
end

--- Clear virtual text
function M.clear()
  clear_virtual_text()
end

--- Show a notification
---@param msg string
---@param level? number vim.log.levels.*
function M.notify(msg, level)
  notify(msg, level)
end

--- Show virtual text at cursor
---@param text string
function M.show_virtual_text(text)
  show_virtual_text(text)
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@param opts? table
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
  
  -- Setup autocmds
  setup_autocmds()
  
  -- Subscribe to ACP client events
  local ok, acp = pcall(require, "utils.acp.client")
  if ok then
    -- Clean up old subscriptions
    for _, unsub in ipairs(state.unsubscribers) do
      unsub()
    end
    state.unsubscribers = {}
    
    -- Subscribe to events
    table.insert(state.unsubscribers, acp.subscribe("message", on_message))
    table.insert(state.unsubscribers, acp.subscribe("thought", on_thought))
    table.insert(state.unsubscribers, acp.subscribe("tool_call", on_tool_call))
    table.insert(state.unsubscribers, acp.subscribe("tool_call_update", on_tool_call_update))
    table.insert(state.unsubscribers, acp.subscribe("session_info", on_session_info))
    table.insert(state.unsubscribers, acp.subscribe("connected", on_connected))
    table.insert(state.unsubscribers, acp.subscribe("disconnected", on_disconnected))
    table.insert(state.unsubscribers, acp.subscribe("session_created", on_session_created))
  end
end

return M
