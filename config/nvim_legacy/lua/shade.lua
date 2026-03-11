--- Shade RPC client for nvim
--- Connects to Shade's RPC server at ~/.local/state/shade/shade.sock
--- Allows nvim to send commands back to Shade (hide, show, toggle, etc.)
---
--- Usage:
---   local shade = require('shade')
---   shade.hide()      -- Hide the Shade panel
---   shade.show()      -- Show the Shade panel
---   shade.toggle()    -- Toggle panel visibility
---   shade.ping()      -- Test connectivity (returns "pong")
---   shade.get_context() -- Get capture context
---
--- @module shade

local M = {}

-- Socket path (XDG compliant)
local SOCKET_PATH = vim.fn.expand("~/.local/state/shade/shade.sock")

-- msgpack-rpc message types
local MSG_REQUEST = 0
local MSG_RESPONSE = 1
local MSG_NOTIFICATION = 2

-- Request ID counter
local next_msgid = 1

--- Check if running inside Shade
--- @return boolean
function M.is_shade_context()
  return vim.g.shade_context == true or vim.env.SHADE == "1"
end

--- Check if the shade socket exists
--- @return boolean
function M.socket_exists()
  return vim.fn.filereadable(SOCKET_PATH) == 1 or vim.fn.getftype(SOCKET_PATH) == "socket"
end

--- Send a request to Shade and wait for response (synchronous)
--- @param method string The RPC method name
--- @param params? any Optional parameters
--- @return any|nil result The result on success
--- @return string|nil error Error message on failure
function M.request(method, params)
  if not M.socket_exists() then
    return nil, "Shade socket not found: " .. SOCKET_PATH
  end

  -- Build msgpack-rpc request: [type, msgid, method, params]
  local msgid = next_msgid
  next_msgid = next_msgid + 1

  local request = vim.mpack.encode({ MSG_REQUEST, msgid, method, params or {} })

  -- Use vim.system to send binary data to Unix socket
  -- This properly handles Blobs (vim.mpack.encode returns Blob in newer nvim)
  local result = vim.system(
    { "nc", "-U", "-w", "2", SOCKET_PATH },
    { stdin = request, text = false }
  ):wait()

  if result.code ~= 0 then
    return nil, "Failed to connect to Shade"
  end

  local response_data = result.stdout
  if not response_data or response_data == "" then
    return nil, "No response from Shade"
  end

  -- Decode msgpack response: [type, msgid, error, result]
  local ok, response = pcall(vim.mpack.decode, response_data)
  if not ok then
    return nil, "Failed to decode response: " .. tostring(response)
  end

  if type(response) ~= "table" or #response < 4 then
    return nil, "Invalid response format"
  end

  local resp_type, resp_msgid, resp_error, resp_result = response[1], response[2], response[3], response[4]

  if resp_type ~= MSG_RESPONSE then
    return nil, "Unexpected message type: " .. tostring(resp_type)
  end

  if resp_error and resp_error ~= vim.NIL then
    return nil, tostring(resp_error)
  end

  return resp_result, nil
end

--- Send a notification to Shade (fire-and-forget, no response expected)
--- @param method string The RPC method name
--- @param params? any Optional parameters
--- @return boolean success
function M.notify(method, params)
  if not M.socket_exists() then
    vim.notify("Shade socket not found", vim.log.levels.WARN)
    return false
  end

  -- Build msgpack-rpc notification: [type, method, params]
  local notification = vim.mpack.encode({ MSG_NOTIFICATION, method, params or {} })

  -- Fire and forget using vim.system (handles binary Blobs properly)
  vim.system(
    { "nc", "-U", SOCKET_PATH },
    { stdin = notification, text = false }
  )
  -- Note: not calling :wait() since this is fire-and-forget

  return true
end

--- Hide the Shade panel
--- @return boolean success
function M.hide()
  local result, err = M.request("hide")
  if err then
    vim.notify("shade.hide() failed: " .. err, vim.log.levels.ERROR)
    return false
  end
  return result == true
end

--- Show the Shade panel
--- @return boolean success
function M.show()
  local result, err = M.request("show")
  if err then
    vim.notify("shade.show() failed: " .. err, vim.log.levels.ERROR)
    return false
  end
  return result == true
end

--- Toggle the Shade panel visibility
--- @return boolean success
function M.toggle()
  local result, err = M.request("toggle")
  if err then
    vim.notify("shade.toggle() failed: " .. err, vim.log.levels.ERROR)
    return false
  end
  return result == true
end

--- Ping Shade to test connectivity
--- @return string|nil "pong" on success, nil on failure
function M.ping()
  local result, err = M.request("ping")
  if err then
    return nil
  end
  return result
end

--- Get the current capture context from Shade
--- @return table|nil context The context table or nil on failure
function M.get_context()
  local result, err = M.request("get_context")
  if err then
    vim.notify("shade.get_context() failed: " .. err, vim.log.levels.ERROR)
    return nil
  end
  return result
end

--- Setup Shade integration (call from nvim config when SHADE=1)
--- Currently a no-op - Shade handles hide-on-exit from the Swift side
--- by detecting when the terminal process exits
function M.setup()
  -- No-op: Shade detects process exit and hides automatically
  -- Keeping this function for API compatibility
end

return M
