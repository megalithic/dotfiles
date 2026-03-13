-- lua/utils/interop.lua
-- External app interop (Shade, tmux, ghostty, hammerspoon)
-- NOT auto-loaded - require explicitly when needed

local M = {}

--------------------------------------------------------------------------------
-- Shade (macOS floating terminal panel)
-- https://github.com/megalithic/shade
--------------------------------------------------------------------------------

M.shade = {}

local SHADE_STATE_DIR = vim.fn.expand("~/.local/state/shade")
local SHADE_SOCKET_PATH = SHADE_STATE_DIR .. "/shade.sock"
local SHADE_CONTEXT_PATH = SHADE_STATE_DIR .. "/context.json"

-- Context caching (avoid repeated file reads during template expansion)
local shade_ctx_cache = nil
local shade_ctx_timer_id = nil

--- Check if running inside Shade panel
---@return boolean
function M.shade.is_active()
  return vim.g.started_by_shade == true
end

--- Get capture context from Shade
--- Cached for 1 second to handle batch template expansions
---@return table|nil context { appName, windowTitle, url, selection, detectedLanguage, ... }
function M.shade.get_context()
  if shade_ctx_cache then return shade_ctx_cache end

  local f = io.open(SHADE_CONTEXT_PATH, "r")
  if not f then return nil end

  local content = f:read("*a")
  f:close()

  local ok, ctx = pcall(vim.json.decode, content)
  if not ok then return nil end

  shade_ctx_cache = ctx

  -- Clear cache after 1 second (for template expansion batches)
  if shade_ctx_timer_id then
    vim.fn.timer_stop(shade_ctx_timer_id)
  end
  shade_ctx_timer_id = vim.defer_fn(function()
    shade_ctx_cache = nil
    shade_ctx_timer_id = nil
  end, 1000)

  return ctx
end

--- Clear the context cache (for testing or forced refresh)
function M.shade.clear_cache()
  shade_ctx_cache = nil
  if shade_ctx_timer_id then
    vim.fn.timer_stop(shade_ctx_timer_id)
    shade_ctx_timer_id = nil
  end
end

--- Check if Shade socket exists
---@return boolean
function M.shade.socket_exists()
  return vim.fn.getftype(SHADE_SOCKET_PATH) == "socket"
end

-- msgpack-rpc message types
local MSG_REQUEST = 0
local MSG_RESPONSE = 1

-- Request ID counter
local shade_next_msgid = 1

--- Send msgpack-rpc request to Shade
---@param method string RPC method name
---@param params? any Parameters (optional)
---@return any|nil result
---@return string|nil error
function M.shade.request(method, params)
  if not M.shade.socket_exists() then
    return nil, "Shade socket not found"
  end

  local msgid = shade_next_msgid
  shade_next_msgid = shade_next_msgid + 1

  local request = vim.mpack.encode({ MSG_REQUEST, msgid, method, params or {} })

  local result = vim.system(
    { "nc", "-U", "-w", "2", SHADE_SOCKET_PATH },
    { stdin = request, text = false }
  ):wait()

  if result.code ~= 0 then
    return nil, "Connection failed"
  end

  if not result.stdout or result.stdout == "" then
    return nil, "No response"
  end

  local ok, response = pcall(vim.mpack.decode, result.stdout)
  if not ok then
    return nil, "Decode failed: " .. tostring(response)
  end

  if type(response) ~= "table" or #response < 4 then
    return nil, "Invalid response format"
  end

  local resp_type, _, resp_error, resp_result = response[1], response[2], response[3], response[4]

  if resp_type ~= MSG_RESPONSE then
    return nil, "Unexpected message type"
  end

  if resp_error and resp_error ~= vim.NIL then
    return nil, tostring(resp_error)
  end

  return resp_result, nil
end

--- Hide Shade panel
---@return any|nil result
---@return string|nil error
function M.shade.hide()
  return M.shade.request("hide")
end

--- Show Shade panel
---@return any|nil result
---@return string|nil error
function M.shade.show()
  return M.shade.request("show")
end

--- Toggle Shade panel visibility
---@return any|nil result
---@return string|nil error
function M.shade.toggle()
  return M.shade.request("toggle")
end

--- Smart toggle: if inside Shade, hide it; otherwise show/focus it
--- This is the typical "activate or dismiss" pattern
---@return any|nil result
---@return string|nil error
function M.shade.smart_toggle()
  if M.shade.is_active() then
    -- We're inside Shade panel, hide it
    return M.shade.hide()
  else
    -- We're outside Shade, show/focus it
    return M.shade.show()
  end
end

--------------------------------------------------------------------------------
-- Future: M.tmux, M.ghostty, M.hs (hammerspoon)
--------------------------------------------------------------------------------

-- M.tmux = {}
-- M.ghostty = {}
-- M.hs = {}

return M
