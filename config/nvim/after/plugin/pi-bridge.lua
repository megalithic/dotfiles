-- Pi Coding Agent Bridge
-- Sends code context (selection, diagnostics, hover) to pi via Unix socket
--
-- Usage:
--   1. Run `pinvim` (not `pi`) to start pi with nvim-bridge extension
--   2. In nvim, use <localleader>ps (visual) or <localleader>pp (toggle)
--
-- SOCKET CONTRACT (single source of truth):
--   Session symlink pattern: /tmp/pi-{tmux_session_name}.sock
--   This pattern is used by:
--     - home/programs/ai/pi-coding-agent/extensions/nvim-bridge.ts (creates it)
--     - This file (connects to it)
--   If you change this pattern, update both files.
--
-- Socket discovery (in order):
--   1. PI_SOCKET env var (explicit override)
--   2. /tmp/pi-{tmux_session}.sock (session symlink from pinvim)
--   3. /tmp/pi.sock (fallback for non-tmux usage)

---Get the socket path to use
---@return string
local function get_socket_path()
  -- Explicit override
  if vim.env.PI_SOCKET then
    return vim.env.PI_SOCKET
  end

  -- Try tmux session symlink
  if vim.env.TMUX then
    local handle = io.popen("tmux display-message -p '#{session_name}' 2>/dev/null")
    if handle then
      local session = handle:read("*l")
      handle:close()
      if session and session ~= "" then
        local session_socket = "/tmp/pi-" .. session .. ".sock"
        if vim.fn.filereadable(session_socket) == 1 then
          return session_socket
        end
      end
    end
  end

  -- Fallback
  return "/tmp/pi.sock"
end

---Send a JSON payload to the pi socket
---@param payload table
local function send_payload(payload)
  if vim.fn.executable("nc") ~= 1 then
    vim.notify("nc not found in PATH", vim.log.levels.ERROR)
    return
  end

  local socket_path = get_socket_path()
  local json = vim.fn.json_encode(payload) .. "\n"
  local chan = vim.fn.jobstart({ "nc", "-U", socket_path }, { stdin = "pipe" })
  if chan <= 0 then
    vim.notify("pi socket not available (is pinvim running?)", vim.log.levels.ERROR)
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
local function get_visual_selection()
  local bufnr = 0
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

  if start_row == 0 or end_row == 0 then
    return nil
  end

  start_row, start_col, end_row, end_col = normalize_range(start_row, start_col, end_row, end_col)

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
  if #lines == 0 then
    return nil
  end

  lines[1] = string.sub(lines[1], start_col + 1)
  lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)

  return table.concat(lines, "\n"), start_row, end_row
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
local function send_selection(opts)
  opts = opts or {}
  local selection, start_row, end_row = get_visual_selection()

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

---Toggle pinvim pane into/out of current tmux window
local function toggle()
  if not vim.env.TMUX then
    vim.notify("Not in tmux", vim.log.levels.WARN)
    return
  end
  vim.fn.system("tmux-pinvim-toggle")
end

-- Commands
vim.api.nvim_create_user_command("PiSelection", function(opts)
  send_selection(opts)
end, { desc = "Send selection to pi", range = true })

vim.api.nvim_create_user_command("PiCursor", function()
  send_cursor()
end, { desc = "Send cursor line to pi" })

vim.api.nvim_create_user_command("PiToggle", function()
  toggle()
end, { desc = "Toggle pinvim pane in current window" })

-- Keymaps
vim.keymap.set("v", "<localleader>ps", "<cmd>PiSelection<cr>", { silent = true, desc = "Pi: send selection" })
vim.keymap.set("n", "<localleader>pp", "<cmd>PiToggle<cr>", { silent = true, desc = "Pi: toggle pinvim pane" })
