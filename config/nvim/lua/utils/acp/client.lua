-- utils/acp/client.lua
-- ACP (Agent Client Protocol) client for pi-acp
--
-- Provides communication with pi via ACP protocol, enabling:
--   - Session management (create, list, resume, fork)
--   - Structured prompts (text, images, resources)
--   - Model/mode switching
--   - MCP server passthrough
--
-- Usage:
--   local acp = require("utils.acp.client")
--   acp.connect()
--   acp.prompt({ { type = "text", text = "Hello" } })

local M = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

M.config = {
  command = "pi-acp",
  args = {},
  auto_create_session = true,
  debug = false,
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local state = {
  job_id = nil,
  connected = false,
  initialized = false,
  session_id = nil,
  agent_capabilities = nil,
  agent_info = nil,
  models = nil,
  modes = nil,
  config_options = nil,
  request_id = 0,
  pending_requests = {}, -- id -> { callback, method }
  message_buffer = "",
  subscribers = {}, -- event_type -> callback[]
}

--------------------------------------------------------------------------------
-- Logging
--------------------------------------------------------------------------------

local function log(level, msg, ...)
  if M.config.debug or level == vim.log.levels.ERROR then
    vim.notify(string.format("[pi-acp] " .. msg, ...), level)
  end
end

local function log_debug(msg, ...) log(vim.log.levels.DEBUG, msg, ...) end
local function log_info(msg, ...) log(vim.log.levels.INFO, msg, ...) end
local function log_warn(msg, ...) log(vim.log.levels.WARN, msg, ...) end
local function log_error(msg, ...) log(vim.log.levels.ERROR, msg, ...) end

--------------------------------------------------------------------------------
-- JSON-RPC Helpers
--------------------------------------------------------------------------------

local function next_id()
  state.request_id = state.request_id + 1
  return state.request_id
end

local function send_raw(data)
  if not state.job_id then
    log_error("Not connected")
    return false
  end
  
  local json = vim.fn.json_encode(data) .. "\n"
  log_debug(">>> %s", vim.fn.json_encode(data))
  vim.fn.chansend(state.job_id, json)
  return true
end

local function send_request(method, params, callback)
  local id = next_id()
  local request = {
    jsonrpc = "2.0",
    id = id,
    method = method,
    params = params or {},
  }
  
  state.pending_requests[id] = {
    callback = callback,
    method = method,
    timestamp = vim.uv.now(),
  }
  
  return send_raw(request)
end

local function send_notification(method, params)
  local notification = {
    jsonrpc = "2.0",
    method = method,
    params = params or {},
  }
  return send_raw(notification)
end

--------------------------------------------------------------------------------
-- Message Handling
--------------------------------------------------------------------------------

local function handle_response(msg)
  local id = msg.id
  local pending = state.pending_requests[id]
  
  if not pending then
    log_warn("Received response for unknown request id: %d", id)
    return
  end
  
  state.pending_requests[id] = nil
  
  if msg.error then
    log_error("RPC error [%s]: %s", pending.method, msg.error.message)
    if pending.callback then
      pending.callback(nil, msg.error)
    end
  else
    if pending.callback then
      pending.callback(msg.result, nil)
    end
  end
end

local function emit(event_type, data)
  local subs = state.subscribers[event_type]
  if subs then
    for _, callback in ipairs(subs) do
      vim.schedule(function()
        callback(data)
      end)
    end
  end
end

local function handle_session_update(params)
  local session_id = params.sessionId
  local update = params.update
  local update_type = update.sessionUpdate
  
  log_debug("Session update [%s]: %s", session_id, update_type)
  
  -- Emit to subscribers
  emit("session_update", { session_id = session_id, update = update })
  emit(update_type, { session_id = session_id, update = update })
  
  -- Handle specific update types
  if update_type == "agent_message_chunk" then
    local content = update.content
    if content and content.type == "text" then
      emit("message", { session_id = session_id, text = content.text })
    end
  elseif update_type == "agent_thought_chunk" then
    local content = update.content
    if content and content.type == "text" then
      emit("thought", { session_id = session_id, text = content.text })
    end
  elseif update_type == "tool_call" then
    emit("tool_call", { session_id = session_id, tool_call = update })
  elseif update_type == "tool_call_update" then
    emit("tool_call_update", { session_id = session_id, update = update })
  elseif update_type == "session_info_update" then
    emit("session_info", { 
      session_id = session_id, 
      title = update.title,
      updated_at = update.updatedAt,
    })
  elseif update_type == "available_commands_update" then
    emit("commands_update", { 
      session_id = session_id, 
      commands = update.commands,
    })
  end
end

local function handle_notification(msg)
  local method = msg.method
  local params = msg.params
  
  log_debug("Notification: %s", method)
  
  if method == "session/update" then
    handle_session_update(params)
  else
    log_debug("Unhandled notification: %s", method)
  end
end

local function handle_message(msg)
  if msg.id then
    -- Response to a request
    handle_response(msg)
  elseif msg.method then
    -- Notification from agent
    handle_notification(msg)
  else
    log_warn("Unknown message format: %s", vim.inspect(msg))
  end
end

local function process_buffer()
  -- Process NDJSON (newline-delimited JSON)
  while true do
    local newline_pos = state.message_buffer:find("\n")
    if not newline_pos then break end
    
    local line = state.message_buffer:sub(1, newline_pos - 1)
    state.message_buffer = state.message_buffer:sub(newline_pos + 1)
    
    if line ~= "" then
      local ok, msg = pcall(vim.fn.json_decode, line)
      if ok and msg then
        log_debug("<<< %s", line)
        handle_message(msg)
      else
        log_warn("Failed to parse JSON: %s", line)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Connection Management
--------------------------------------------------------------------------------

local function on_stdout(_, data)
  if not data then return end
  
  for _, chunk in ipairs(data) do
    if chunk ~= "" then
      state.message_buffer = state.message_buffer .. chunk
    end
  end
  
  process_buffer()
end

local function on_stderr(_, data)
  if not data then return end
  
  for _, line in ipairs(data) do
    if line ~= "" then
      log_debug("stderr: %s", line)
    end
  end
end

local function on_exit(_, code)
  log_info("pi-acp exited with code %d", code)
  state.job_id = nil
  state.connected = false
  state.initialized = false
  state.session_id = nil
  emit("disconnected", { code = code })
end

--- Connect to pi-acp process
---@param callback? fun(success: boolean, err: string|nil)
function M.connect(callback)
  if state.job_id then
    if callback then callback(true, nil) end
    return
  end
  
  local cmd = vim.list_extend({ M.config.command }, M.config.args)
  
  log_info("Starting pi-acp: %s", table.concat(cmd, " "))
  
  state.job_id = vim.fn.jobstart(cmd, {
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    on_exit = on_exit,
    stdout_buffered = false,
    stderr_buffered = false,
  })
  
  if state.job_id <= 0 then
    local err = "Failed to start pi-acp"
    log_error(err)
    if callback then callback(false, err) end
    return
  end
  
  state.connected = true
  
  -- Initialize
  send_request("initialize", {
    protocolVersion = 1,
    clientInfo = {
      name = "pi.lua",
      version = "1.0.0",
    },
    clientCapabilities = {
      fs = {
        readTextFile = true,
        writeTextFile = true,
      },
      terminal = false,
    },
  }, function(result, err)
    if err then
      log_error("Initialize failed: %s", err.message)
      if callback then callback(false, err.message) end
      return
    end
    
    state.initialized = true
    state.agent_capabilities = result.agentCapabilities
    state.agent_info = result.agentInfo
    
    log_info("Connected to %s v%s", 
      result.agentInfo.name, 
      result.agentInfo.version)
    
    emit("connected", result)
    
    if callback then callback(true, nil) end
  end)
end

--- Disconnect from pi-acp
function M.disconnect()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end
  state.connected = false
  state.initialized = false
  state.session_id = nil
end

--- Check if connected
---@return boolean
function M.is_connected()
  return state.connected and state.initialized
end

--------------------------------------------------------------------------------
-- Session Management
--------------------------------------------------------------------------------

--- Create a new session
---@param opts? { cwd?: string, mcp_servers?: table[] }
---@param callback? fun(session_id: string|nil, err: string|nil)
function M.new_session(opts, callback)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  
  send_request("session/new", {
    cwd = cwd,
    mcpServers = opts.mcp_servers or {},
  }, function(result, err)
    if err then
      log_error("Failed to create session: %s", err.message)
      if callback then callback(nil, err.message) end
      return
    end
    
    state.session_id = result.sessionId
    state.models = result.models
    state.modes = result.modes
    state.config_options = result.configOptions
    
    log_info("Created session: %s", result.sessionId)
    emit("session_created", result)
    
    if callback then callback(result.sessionId, nil) end
  end)
end

--- Load an existing session
---@param session_id string
---@param opts? { cwd?: string }
---@param callback? fun(success: boolean, err: string|nil)
function M.load_session(session_id, opts, callback)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  
  send_request("session/load", {
    sessionId = session_id,
    cwd = cwd,
    mcpServers = {},
  }, function(result, err)
    if err then
      log_error("Failed to load session: %s", err.message)
      if callback then callback(false, err.message) end
      return
    end
    
    state.session_id = session_id
    state.models = result.models
    state.modes = result.modes
    state.config_options = result.configOptions
    
    log_info("Loaded session: %s", session_id)
    emit("session_loaded", { session_id = session_id, result = result })
    
    if callback then callback(true, nil) end
  end)
end

--- List available sessions
---@param callback fun(sessions: table[]|nil, err: string|nil)
function M.list_sessions(callback)
  send_request("unstable/session/list", {}, function(result, err)
    if err then
      log_error("Failed to list sessions: %s", err.message)
      callback(nil, err.message)
      return
    end
    
    callback(result.sessions, nil)
  end)
end

--- Get current session ID
---@return string|nil
function M.get_session_id()
  return state.session_id
end

--- Get available models
---@return table|nil
function M.get_models()
  return state.models
end

--- Get available modes
---@return table|nil
function M.get_modes()
  return state.modes
end

--------------------------------------------------------------------------------
-- Prompting
--------------------------------------------------------------------------------

--- Send a prompt to the current session
---@param content_blocks table[] Array of ACP content blocks
---@param callback? fun(stop_reason: string|nil, err: string|nil)
function M.prompt(content_blocks, callback)
  -- Auto-create session if needed
  if not state.session_id then
    if M.config.auto_create_session then
      M.new_session({}, function(session_id, err)
        if err then
          if callback then callback(nil, err) end
          return
        end
        M.prompt(content_blocks, callback)
      end)
      return
    else
      local err = "No active session"
      log_error(err)
      if callback then callback(nil, err) end
      return
    end
  end
  
  send_request("session/prompt", {
    sessionId = state.session_id,
    prompt = content_blocks,
  }, function(result, err)
    if err then
      log_error("Prompt failed: %s", err.message)
      if callback then callback(nil, err.message) end
      return
    end
    
    if callback then callback(result.stopReason, nil) end
  end)
end

--- Cancel current generation
function M.cancel()
  if state.session_id then
    send_notification("session/cancel", {
      sessionId = state.session_id,
    })
  end
end

--------------------------------------------------------------------------------
-- Model/Mode Switching
--------------------------------------------------------------------------------

--- Set the current model
---@param model_id string
---@param callback? fun(success: boolean, err: string|nil)
function M.set_model(model_id, callback)
  if not state.session_id then
    if callback then callback(false, "No active session") end
    return
  end
  
  send_request("unstable/session/set_model", {
    sessionId = state.session_id,
    modelId = model_id,
  }, function(_, err)
    if err then
      log_error("Failed to set model: %s", err.message)
      if callback then callback(false, err.message) end
      return
    end
    
    log_info("Model set to: %s", model_id)
    if callback then callback(true, nil) end
  end)
end

--- Set the current mode
---@param mode_id string
---@param callback? fun(success: boolean, err: string|nil)
function M.set_mode(mode_id, callback)
  if not state.session_id then
    if callback then callback(false, "No active session") end
    return
  end
  
  send_request("unstable/session/set_mode", {
    sessionId = state.session_id,
    modeId = mode_id,
  }, function(_, err)
    if err then
      log_error("Failed to set mode: %s", err.message)
      if callback then callback(false, err.message) end
      return
    end
    
    log_info("Mode set to: %s", mode_id)
    if callback then callback(true, nil) end
  end)
end

--------------------------------------------------------------------------------
-- Event Subscription
--------------------------------------------------------------------------------

--- Subscribe to events
---@param event_type string Event type to subscribe to
---@param callback fun(data: table) Callback function
---@return fun() Unsubscribe function
function M.subscribe(event_type, callback)
  if not state.subscribers[event_type] then
    state.subscribers[event_type] = {}
  end
  
  table.insert(state.subscribers[event_type], callback)
  
  -- Return unsubscribe function
  return function()
    local subs = state.subscribers[event_type]
    if subs then
      for i, cb in ipairs(subs) do
        if cb == callback then
          table.remove(subs, i)
          break
        end
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Content Block Helpers
--------------------------------------------------------------------------------

--- Create a text content block
---@param text string
---@return table
function M.text_block(text)
  return { type = "text", text = text }
end

--- Create a resource link content block (file reference)
---@param filepath string
---@param name? string
---@return table
function M.resource_link_block(filepath, name)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  return {
    type = "resource_link",
    uri = "file://" .. abs_path,
    name = name or vim.fn.fnamemodify(filepath, ":t"),
  }
end

--- Create a resource content block (embedded file content)
---@param filepath string
---@param content string
---@return table
function M.resource_block(filepath, content)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  return {
    type = "resource",
    resource = {
      uri = "file://" .. abs_path,
      text = content,
    },
  }
end

--- Create an image content block
---@param data string Base64 encoded image data
---@param mime_type string MIME type (e.g., "image/png")
---@return table
function M.image_block(data, mime_type)
  return {
    type = "image",
    data = data,
    mimeType = mime_type,
  }
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@param opts? table
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
end

return M
