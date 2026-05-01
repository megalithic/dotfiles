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
local shade_ctx_timer = nil -- vim.uv.new_timer handle from vim.defer_fn

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
  -- vim.defer_fn returns a vim.uv.new_timer handle
  if shade_ctx_timer then
    shade_ctx_timer:stop()
    shade_ctx_timer:close()
  end
  shade_ctx_timer = vim.defer_fn(function()
    shade_ctx_cache = nil
    shade_ctx_timer = nil
  end, 1000)

  return ctx
end

--- Clear the context cache (for testing or forced refresh)
function M.shade.clear_cache()
  shade_ctx_cache = nil
  if shade_ctx_timer then
    shade_ctx_timer:stop()
    shade_ctx_timer:close()
    shade_ctx_timer = nil
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

--- Open today's daily note via Shade RPC
--- Calls Shade's `open_daily_note` method which executes `Obsidian today` in nvim
---@return any|nil result Path to daily note or nil on failure
---@return string|nil error
function M.shade.open_daily_note()
  return M.shade.request("open_daily_note")
end

--- Open a new capture note via Shade RPC
--- Calls Shade's `open_new_capture` method
---@return any|nil result Path to capture note or nil on failure
---@return string|nil error
function M.shade.open_new_capture()
  return M.shade.request("open_new_capture")
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
-- Hammerspoon (nvim socket registration for hammerspoon://nvim-open + RPC)
--
-- Hammerspoon's lib/interop/nvim.lua scans /tmp/nvim-sockets/ to find running
-- nvim instances. Each entry is a file named by socket-id whose contents are
-- the nvim --listen socket path.
--
-- Socket id formats (must match parser in config/hammerspoon/lib/interop/nvim.lua):
--   tmux:     {session}_{window}_{pane}_{pid}
--   non-tmux: global_{pid}
--------------------------------------------------------------------------------

M.hs = {}

local HS_SOCKET_DIR = "/tmp/nvim-sockets"

--- Build socket id from current context (tmux-aware).
---@return string
function M.hs.build_socket_id()
  if os.getenv("TMUX_PANE") then
    local handle = io.popen("tmux display-message -p '#{session_name}_#{window_index}_#{pane_index}' 2>/dev/null")
    if handle then
      local info = handle:read("*l")
      handle:close()
      if info and info ~= "" then return info .. "_" .. vim.fn.getpid() end
    end
  end
  return "global_" .. vim.fn.getpid()
end

--- Register this nvim's --listen socket so Hammerspoon can discover it.
function M.hs.register_socket()
  if vim.v.servername == nil or vim.v.servername == "" then return end
  local id = M.hs.build_socket_id()
  vim.fn.mkdir(HS_SOCKET_DIR, "p")
  local f = io.open(HS_SOCKET_DIR .. "/" .. id, "w")
  if f then
    f:write(vim.v.servername)
    f:close()
    vim.g._hs_socket_id = id
  end
end

--- Cleanup the socket file on nvim exit.
function M.hs.cleanup_socket()
  local id = vim.g._hs_socket_id
  if id then os.remove(HS_SOCKET_DIR .. "/" .. id) end
end

--------------------------------------------------------------------------------
-- Future: M.tmux, M.ghostty
--------------------------------------------------------------------------------

return M
