-- utils/acp/integration.lua
-- Integration layer between pi.lua context and ACP client
--
-- Converts pi.lua context payloads to ACP content blocks
-- Provides unified send interface that tries ACP first, falls back to socket
--
-- Usage:
--   local integration = require("utils.acp.integration")
--   integration.send_selection(text, file, range, lang, opts)

local M = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

M.config = {
  -- Transport priority: "acp", "socket", "panel"
  -- ACP is tried first, then fallback to socket/panel
  prefer_acp = true,
  
  -- Auto-connect to ACP on first send
  auto_connect = true,
  
  -- Include diagnostics in context
  include_diagnostics = true,
  
  -- Include LSP hover in context  
  include_hover = false,
}

--------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------

local acp_client = nil
local acp_response = nil

local function lazy_require_acp()
  if not acp_client then
    local ok, client = pcall(require, "utils.acp.client")
    if ok then acp_client = client end
  end
  return acp_client
end

local function lazy_require_response()
  if not acp_response then
    local ok, response = pcall(require, "utils.acp.response")
    if ok then acp_response = response end
  end
  return acp_response
end

--------------------------------------------------------------------------------
-- Content Block Builders
--------------------------------------------------------------------------------

--- Build content blocks from selection context
---@param opts table { text: string, file: string, range?: number[], language?: string, task?: string, diagnostics?: string[], hover?: string }
---@return table[] content_blocks
function M.build_selection_blocks(opts)
  local blocks = {}
  
  -- Task/instructions first
  if opts.task and opts.task ~= "" then
    table.insert(blocks, {
      type = "text",
      text = opts.task,
    })
  end
  
  -- File reference with range
  if opts.file and opts.file ~= "" then
    local range_str = ""
    if opts.range then
      range_str = string.format(" (lines %d-%d)", opts.range[1], opts.range[2])
    end
    
    -- Add as resource link
    table.insert(blocks, {
      type = "resource_link",
      uri = "file://" .. vim.fn.fnamemodify(opts.file, ":p"),
      name = vim.fn.fnamemodify(opts.file, ":t") .. range_str,
    })
  end
  
  -- Diagnostics
  if opts.diagnostics and #opts.diagnostics > 0 then
    table.insert(blocks, {
      type = "text",
      text = "## Diagnostics\n" .. table.concat(opts.diagnostics, "\n"),
    })
  end
  
  -- Hover info
  if opts.hover and opts.hover ~= "" then
    table.insert(blocks, {
      type = "text",
      text = "## Hover Info\n```\n" .. opts.hover .. "\n```",
    })
  end
  
  -- Code content
  if opts.text and opts.text ~= "" then
    local lang = opts.language or ""
    table.insert(blocks, {
      type = "text",
      text = string.format("```%s\n%s\n```", lang, opts.text),
    })
  end
  
  return blocks
end

--- Build content blocks from file context
---@param opts table { file: string, content?: string, language?: string, lines?: number, diagnostics?: string[], as_reference?: boolean }
---@return table[] content_blocks
function M.build_file_blocks(opts)
  local blocks = {}
  
  local abs_path = vim.fn.fnamemodify(opts.file, ":p")
  local filename = vim.fn.fnamemodify(opts.file, ":t")
  
  -- Use reference or embed content based on option
  if opts.as_reference or not opts.content then
    -- Send as resource_link - pi reads the file itself
    table.insert(blocks, {
      type = "resource_link",
      uri = "file://" .. abs_path,
      name = filename,
    })
  else
    -- Embed file content
    table.insert(blocks, {
      type = "resource",
      resource = {
        uri = "file://" .. abs_path,
        text = opts.content,
      },
    })
  end
  
  -- Diagnostics
  if opts.diagnostics and #opts.diagnostics > 0 then
    table.insert(blocks, {
      type = "text",
      text = "## Diagnostics\n" .. table.concat(opts.diagnostics, "\n"),
    })
  end
  
  return blocks
end

--- Build content blocks from image
---@param data string Base64 encoded image data
---@param mime_type string MIME type
---@param task? string Optional task/question about the image
---@return table[] content_blocks
function M.build_image_blocks(data, mime_type, task)
  local blocks = {}
  
  if task and task ~= "" then
    table.insert(blocks, {
      type = "text",
      text = task,
    })
  end
  
  table.insert(blocks, {
    type = "image",
    data = data,
    mimeType = mime_type,
  })
  
  return blocks
end

--------------------------------------------------------------------------------
-- Send Functions
--------------------------------------------------------------------------------

--- Check if ACP is available and connected
---@return boolean
function M.is_acp_available()
  local acp = lazy_require_acp()
  return acp and acp.is_connected()
end

--- Send content blocks via ACP
---@param blocks table[] Content blocks
---@param callback? fun(success: boolean, err: string|nil)
---@return boolean sent Only returns true if connected and prompt sent
local function send_via_acp(blocks, callback)
  local acp = lazy_require_acp()
  if not acp then
    if callback then callback(false, "ACP client not available") end
    return false
  end
  
  -- Only send if already connected
  -- Don't auto-connect - it causes fallback issues
  -- User should explicitly connect via :PiAcpConnect if they want ACP
  if not acp.is_connected() then
    if callback then callback(false, "Not connected") end
    return false
  end
  
  -- Connected - send the prompt
  acp.prompt(blocks, function(stop_reason, err)
    if callback then
      callback(stop_reason ~= nil, err)
    end
  end)
  return true
end

--- Send selection to pi via best available transport
---@param text string Selection text
---@param file string File path
---@param range? number[] { start_row, end_row }
---@param language? string Language for code fence
---@param opts? table { task?: string, diagnostics?: string[], hover?: string, force_socket?: boolean, callback?: function }
---@return boolean sent Whether send was initiated
function M.send_selection(text, file, range, language, opts)
  opts = opts or {}
  
  -- Build context
  local context = {
    text = text,
    file = file,
    range = range,
    language = language,
    task = opts.task,
    diagnostics = opts.diagnostics,
    hover = opts.hover,
  }
  
  -- Try ACP first (unless forced to socket)
  if M.config.prefer_acp and not opts.force_socket then
    local blocks = M.build_selection_blocks(context)
    if send_via_acp(blocks, opts.callback) then
      vim.notify("Sent to pi (ACP)", vim.log.levels.INFO)
      return true
    end
  end
  
  -- Fall back to existing pi.lua send_payload
  -- This will be called by the existing pi.lua code
  return false
end

--- Send file to pi via best available transport
---@param file string File path
---@param content? string File content (nil for reference-only)
---@param opts? table { lines?: number, language?: string, diagnostics?: string[], force_socket?: boolean, callback?: function, as_reference?: boolean }
---@return boolean sent Whether send was initiated
function M.send_file(file, content, opts)
  opts = opts or {}
  
  local context = {
    file = file,
    content = content,
    lines = opts.lines,
    language = opts.language,
    diagnostics = opts.diagnostics,
    as_reference = opts.as_reference or (content == nil),
  }
  
  if M.config.prefer_acp and not opts.force_socket then
    local blocks = M.build_file_blocks(context)
    if send_via_acp(blocks, opts.callback) then
      vim.notify("Sent to pi (ACP)", vim.log.levels.INFO)
      return true
    end
  end
  
  return false
end

--- Send image to pi via ACP (ACP only, no socket fallback)
---@param data string Base64 encoded image data
---@param mime_type string MIME type (e.g., "image/png")
---@param task? string Optional question/task about the image
---@param callback? fun(success: boolean, err: string|nil)
---@return boolean sent Whether send was initiated
function M.send_image(data, mime_type, task, callback)
  local blocks = M.build_image_blocks(data, mime_type, task)
  return send_via_acp(blocks, callback)
end

--- Send raw text prompt via ACP
---@param text string Prompt text
---@param callback? fun(success: boolean, err: string|nil)
---@return boolean sent
function M.send_prompt(text, callback)
  local blocks = { { type = "text", text = text } }
  return send_via_acp(blocks, callback)
end

--------------------------------------------------------------------------------
-- Session Helpers
--------------------------------------------------------------------------------

--- Create new ACP session
---@param callback? fun(session_id: string|nil, err: string|nil)
function M.new_session(callback)
  local acp = lazy_require_acp()
  if not acp then
    if callback then callback(nil, "ACP not available") end
    return
  end
  
  if not acp.is_connected() then
    acp.connect(function(success, err)
      if success then
        acp.new_session({}, callback)
      else
        if callback then callback(nil, err) end
      end
    end)
  else
    acp.new_session({}, callback)
  end
end

--- List available sessions
---@param callback fun(sessions: table[]|nil, err: string|nil)
function M.list_sessions(callback)
  local acp = lazy_require_acp()
  if not acp or not acp.is_connected() then
    callback(nil, "ACP not connected")
    return
  end
  
  acp.list_sessions(callback)
end

--- Get current session info
---@return table|nil { id: string, models: table, modes: table }
function M.get_session_info()
  local acp = lazy_require_acp()
  if not acp or not acp.is_connected() then
    return nil
  end
  
  return {
    id = acp.get_session_id(),
    models = acp.get_models(),
    modes = acp.get_modes(),
  }
end

--------------------------------------------------------------------------------
-- Image Capture Helpers
--------------------------------------------------------------------------------

--- Capture screenshot from clipboard and send to pi
---@param task? string Optional question about the screenshot
---@param callback? fun(success: boolean, err: string|nil)
function M.send_clipboard_image(task, callback)
  -- Try to get image from clipboard using pngpaste (macOS)
  local tmpfile = os.tmpname() .. ".png"
  local result = vim.fn.system({ "pngpaste", tmpfile })
  
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(tmpfile)
    if callback then callback(false, "No image in clipboard") end
    return
  end
  
  -- Read and encode
  local file = io.open(tmpfile, "rb")
  if not file then
    vim.fn.delete(tmpfile)
    if callback then callback(false, "Failed to read image") end
    return
  end
  
  local data = file:read("*all")
  file:close()
  vim.fn.delete(tmpfile)
  
  local base64_data = vim.base64.encode(data)
  M.send_image(base64_data, "image/png", task, callback)
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@param opts? table
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
  
  -- Initialize response display
  local response = lazy_require_response()
  if response then
    response.setup()
  end
end

return M
