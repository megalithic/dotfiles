-- utils/acp/init.lua
-- ACP (Agent Client Protocol) utilities
--
-- Provides:
--   client      - Low-level ACP JSON-RPC client
--   integration - High-level send functions
--   response    - Response display (notifications, virtual text)
--
-- Usage:
--   local acp = require("utils.acp")
--   acp.connect()  -- Shortcut to client.connect()
--   acp.send_selection(text, file, range, lang)

local M = {}

-- Lazy-loaded submodules
local _client = nil
local _integration = nil
local _response = nil

local function get_client()
  if not _client then
    _client = require("utils.acp.client")
  end
  return _client
end

local function get_integration()
  if not _integration then
    _integration = require("utils.acp.integration")
  end
  return _integration
end

local function get_response()
  if not _response then
    _response = require("utils.acp.response")
  end
  return _response
end

-- Expose submodules via getters for lazy loading
M.client = setmetatable({}, {
  __index = function(_, k)
    return get_client()[k]
  end,
})

M.integration = setmetatable({}, {
  __index = function(_, k)
    return get_integration()[k]
  end,
})

M.response = setmetatable({}, {
  __index = function(_, k)
    return get_response()[k]
  end,
})

--------------------------------------------------------------------------------
-- Convenience shortcuts (delegate to client)
--------------------------------------------------------------------------------

function M.connect(callback)
  return get_client().connect(callback)
end

function M.disconnect()
  return get_client().disconnect()
end

function M.is_connected()
  return get_client().is_connected()
end

function M.prompt(content_blocks, callback)
  return get_client().prompt(content_blocks, callback)
end

function M.cancel()
  return get_client().cancel()
end

function M.subscribe(event_type, callback)
  return get_client().subscribe(event_type, callback)
end

--------------------------------------------------------------------------------
-- Convenience shortcuts (delegate to integration)
--------------------------------------------------------------------------------

function M.send_selection(text, file, range, language, opts)
  return get_integration().send_selection(text, file, range, language, opts)
end

function M.send_file(file, content, opts)
  return get_integration().send_file(file, content, opts)
end

function M.send_image(data, mime_type, task, callback)
  return get_integration().send_image(data, mime_type, task, callback)
end

function M.send_clipboard_image(task, callback)
  return get_integration().send_clipboard_image(task, callback)
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@param opts? { client?: table, integration?: table, response?: table }
function M.setup(opts)
  opts = opts or {}
  
  if opts.client then
    get_client().setup(opts.client)
  end
  
  if opts.integration then
    get_integration().setup(opts.integration)
  end
  
  if opts.response then
    get_response().setup(opts.response)
  end
end

return M
