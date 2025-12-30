--- Interop module for external tool communication (Hammerspoon, etc.)
--- Handles socket registration for RPC-based state queries

local M = {}

--- Socket directory for nvim server registration
M.socket_dir = "/tmp/nvim-sockets"

--- Build socket ID from current context
--- Prefers tmux context (session_window_pane_pid), falls back to global_{pid}
---
--- Socket ID formats:
---   - tmux: {session}_{window}_{pane}_{pid}
---   - non-tmux: global_{pid}
---
---@return string Socket ID (always returns a value)
function M.build_socket_id()
  local pane = os.getenv("TMUX_PANE")

  -- Tmux context: session_window_pane_pid
  if pane then
    local handle = io.popen("tmux display-message -p '#{session_name}_#{window_index}_#{pane_index}' 2>/dev/null")
    if handle then
      local tmux_info = handle:read("*l")
      handle:close()

      if tmux_info and tmux_info ~= "" then
        return tmux_info .. "_" .. vim.fn.getpid()
      end
    end
  end

  -- Non-tmux fallback: global_{pid}
  return "global_" .. vim.fn.getpid()
end

--- Register nvim server socket for external discovery
--- Creates a file in socket_dir containing the server socket path
--- External tools can read this to connect via RPC
function M.register_socket()
  if vim.v.servername == "" then return end

  local socket_id = M.build_socket_id()
  vim.fn.mkdir(M.socket_dir, "p")

  local socket_file = M.socket_dir .. "/" .. socket_id
  local f = io.open(socket_file, "w")
  if f then
    f:write(vim.v.servername)
    f:close()

    -- Store socket_id for cleanup on exit
    vim.g._hs_socket_id = socket_id
  end
end

--- Cleanup registered socket file on nvim exit
function M.cleanup_socket()
  local socket_id = vim.g._hs_socket_id
  if socket_id then
    os.remove(M.socket_dir .. "/" .. socket_id)
  end
end

return M
