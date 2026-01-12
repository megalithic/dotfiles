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

  -- Use netcat (nc) to send request and receive response
  -- -U for Unix socket, -w 2 for 2 second timeout
  local cmd = string.format(
    "echo -n %s | nc -U -w 2 %s 2>/dev/null",
    vim.fn.shellescape(request),
    vim.fn.shellescape(SOCKET_PATH)
  )

  local handle = io.popen(cmd, "r")
  if not handle then
    return nil, "Failed to connect to Shade"
  end

  local response_data = handle:read("*a")
  handle:close()

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

  -- Fire and forget via netcat
  local cmd = string.format(
    "echo -n %s | nc -U %s >/dev/null 2>&1 &",
    vim.fn.shellescape(notification),
    vim.fn.shellescape(SOCKET_PATH)
  )

  os.execute(cmd)
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
--- Makes :wq save and hide instead of quit
function M.setup()
  if not M.is_shade_context() then
    return
  end

  -- Create autocmd group
  local group = vim.api.nvim_create_augroup("ShadeIntegration", { clear = true })

  -- Helper to complete the hide sequence
  local function complete_hide()
    M.hide()
    vim.cmd("enew")
    vim.cmd("setlocal bufhidden=wipe")
  end

  -- Helper to check for empty capture and handle cleanup
  local function check_and_cleanup_capture(callback)
    -- Load capture cleanup module
    local ok, capture = pcall(require, "notes.capture")
    if not ok then
      -- Module not available, just proceed
      callback()
      return
    end

    local is_empty, filepath = capture.is_empty()

    if is_empty and filepath then
      -- Prompt for deletion before hiding
      capture.cleanup(filepath, function(deleted)
        callback()
      end)
    else
      callback()
    end
  end

  -- Intercept quit commands
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
      -- Check if this is a forced quit (:q!, :wq!)
      -- vim.v.event doesn't have this info in QuitPre, so we check differently
      local cmdline = vim.fn.getcmdline()
      if cmdline and cmdline:match("!$") then
        return -- Allow forced quit
      end

      -- Save if modified
      if vim.bo.modified then
        vim.cmd("silent! write")
      end

      -- Check for empty capture note and cleanup, then hide
      check_and_cleanup_capture(complete_hide)

      -- Cancel the quit
      return true
    end,
  })

  -- Also intercept ZZ
  vim.keymap.set("n", "ZZ", function()
    if vim.bo.modified then
      vim.cmd("silent! write")
    end
    check_and_cleanup_capture(complete_hide)
  end, { desc = "Save and hide Shade panel" })

  vim.notify("Shade integration enabled", vim.log.levels.DEBUG)
end

return M
