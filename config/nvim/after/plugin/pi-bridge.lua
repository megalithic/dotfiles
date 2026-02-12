-- Pi Coding Agent Bridge
-- Sends code context (selection, diagnostics, hover) to pi via Unix socket
--
-- Usage:
--   1. Run `pinvim` or `pisock` to start pi with bridge extension
--   2. In nvim, use <localleader>ps (visual) or <localleader>pp (toggle)
--
-- SOCKET CONFIGURATION (nix is single source of truth):
--   Pattern: /tmp/pi-{session}.sock (one socket per tmux session)
--   Env vars (set by pinvim/pisock wrapper):
--     - PI_SOCKET_DIR: /tmp
--     - PI_SOCKET_PREFIX: pi
--     - PI_SESSION: tmux session name
--     - PI_SOCKET: full path (e.g., /tmp/pi-mega.sock)
--
-- Used by:
--   - pinvim/pisock wrapper (sets PI_SOCKET env var)
--   - bridge.ts extension (listens on PI_SOCKET)
--   - This file (connects to socket)
--   - config/hammerspoon/lib/interop/pi.lua (forwards Telegram)
--   - bin/ftm (checks for socket existence)
--   - bin/tmux-toggle-pi (finds/manages agent window)
--
-- Socket discovery (in order):
--   1. PI_SOCKET env var (explicit, from pinvim/pisock)
--   2. /tmp/pi-{session}.sock (computed from tmux session)
--   3. /tmp/pi-default.sock (fallback for non-tmux)

---Get socket path using nix-defined pattern
---@return string|nil
local function get_socket_path()
  -- Explicit override (set by pinvim/pisock wrapper)
  if vim.env.PI_SOCKET then return vim.env.PI_SOCKET end

  -- Socket config from environment (with defaults matching nix)
  local socket_dir = vim.env.PI_SOCKET_DIR or "/tmp"
  local socket_prefix = vim.env.PI_SOCKET_PREFIX or "pi"

  -- Helper to check if socket exists
  local function socket_exists(path)
    return os.execute(string.format("test -S '%s'", path)) == 0
  end

  -- Compute from tmux session
  if vim.env.TMUX then
    local handle = io.popen("tmux display-message -p '#{session_name}' 2>/dev/null")
    if handle then
      local session = handle:read("*l")
      handle:close()
      if session and session ~= "" then
        -- Try {session}-agent.sock first (dedicated agent window)
        local agent_socket = string.format("%s/%s-%s-agent.sock", socket_dir, socket_prefix, session)
        if socket_exists(agent_socket) then return agent_socket end
        
        -- Fall back to any socket for this session
        local glob_handle = io.popen(string.format("ls %s/%s-%s-*.sock 2>/dev/null | head -1", socket_dir, socket_prefix, session))
        if glob_handle then
          local found = glob_handle:read("*l")
          glob_handle:close()
          if found and found ~= "" and socket_exists(found) then return found end
        end
      end
    end
  end

  -- Fallback to default
  local default = string.format("%s/%s-default.sock", socket_dir, socket_prefix)
  if socket_exists(default) then return default end
  
  return nil
end

---Send a JSON payload to the pi socket
---@param payload table
local function send_payload(payload)
  if vim.fn.executable("nc") ~= 1 then
    vim.notify("nc not found in PATH", vim.log.levels.ERROR)
    return
  end

  local socket_path = get_socket_path()
  if not socket_path then
    vim.notify("No pi socket found (is pinvim/pisock running?)", vim.log.levels.ERROR)
    return
  end
  
  local json = vim.fn.json_encode(payload) .. "\n"
  local chan = vim.fn.jobstart({ "nc", "-U", socket_path }, { stdin = "pipe" })
  if chan <= 0 then
    vim.notify("pi socket not available: " .. socket_path, vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(chan, json)
  vim.fn.chanclose(chan, "stdin")
  vim.notify("Sent to pi (" .. socket_path .. ")", vim.log.levels.INFO)
end

---Normalize visual selection range
local function normalize_range(start_row, start_col, end_row, end_col)
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    return end_row, end_col, start_row, start_col
  end
  return start_row, start_col, end_row, end_col
end

---Get the visual selection text and range
---@param force_update boolean? If true, exit visual mode first to update marks
local function get_visual_selection(force_update)
  local bufnr = 0
  local mode = vim.fn.mode()
  
  -- If in visual mode, exit to set the marks, then get them
  if force_update and (mode == "v" or mode == "V" or mode == "\22") then
    -- Execute ESC to exit visual mode and set marks
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  end
  
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

  if start_row == 0 or end_row == 0 then return nil end

  start_row, start_col, end_row, end_col = normalize_range(start_row, start_col, end_row, end_col)

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
  if #lines == 0 then return nil end

  -- Handle selection based on visual mode type
  local vmode = vim.fn.visualmode()
  if vmode == "V" then
    -- Line-wise: return full lines
    return table.concat(lines, "\n"), start_row, end_row
  elseif vmode == "\22" then
    -- Block-wise: extract columns from each line
    local result = {}
    for i, line in ipairs(lines) do
      local s = math.min(start_col + 1, #line + 1)
      local e = math.min(end_col + 1, #line)
      table.insert(result, string.sub(line, s, e))
    end
    return table.concat(result, "\n"), start_row, end_row
  else
    -- Character-wise
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col + 1, end_col + 1)
    else
      lines[1] = string.sub(lines[1], start_col + 1)
      lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
    end
    return table.concat(lines, "\n"), start_row, end_row
  end
end

---Get LSP diagnostics for a line range
local function get_diagnostics(start_row, end_row)
  local bufnr = 0
  local result = {}

  for _, d in ipairs(vim.diagnostic.get(bufnr)) do
    local line = d.lnum + 1
    if (not start_row or line >= start_row) and (not end_row or line <= end_row) then
      local source = d.source or "lsp"
      local entry = string.format("%d:%d %s (%s)", line, d.col + 1, d.message, source)
      table.insert(result, entry)
    end
  end

  return result
end

---Send visual selection to pi
---@param opts table? Options from user command
---@param from_visual boolean? Whether called directly from visual mode
local function send_selection(opts, from_visual)
  opts = opts or {}
  local selection, start_row, end_row = get_visual_selection(from_visual)

  -- When invoked from visual mode via `:` (which prefixes `'<,'>`), Neovim
  -- passes a line range. Accept it and fall back to sending full lines.
  if not selection and opts.range and opts.range > 0 then
    start_row, end_row = opts.line1, opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    selection = table.concat(lines, "\n")
  end

  if not selection then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local task = vim.fn.input("Task: ")
  local file = vim.api.nvim_buf_get_name(0)

  send_payload({
    file = file,
    range = { start_row, end_row },
    selection = selection,
    lsp = { diagnostics = get_diagnostics(start_row, end_row) },
    task = task,
  })
end

---Send cursor line to pi
local function send_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local file = vim.api.nvim_buf_get_name(0)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local task = vim.fn.input("Task: ")

  send_payload({
    file = file,
    range = { row, row },
    selection = line,
    lsp = { diagnostics = get_diagnostics(row, row) },
    task = task,
  })
end

---Toggle pisock/pinvim pane into/out of current tmux window
local function toggle()
  if not vim.env.TMUX then
    vim.notify("Not in tmux", vim.log.levels.WARN)
    return
  end
  vim.fn.system("tmux-toggle-pi")
end

-- Commands
vim.api.nvim_create_user_command(
  "PiSelection",
  function(opts) send_selection(opts) end,
  { desc = "Send selection to pi", range = true }
)

vim.api.nvim_create_user_command("PiCursor", function() send_cursor() end, { desc = "Send cursor line to pi" })

vim.api.nvim_create_user_command(
  "PiToggle",
  function() toggle() end,
  { desc = "Toggle pisock/pinvim pane in current window" }
)

-- Keymaps
vim.keymap.set("n", "<localleader>pp", "<cmd>PiToggle<cr>", { silent = true, desc = "Pi: toggle pisock pane" })
vim.keymap.set("v", "<localleader>ps", function() send_selection(nil, true) end, { silent = true, desc = "Pi: send selection" })
