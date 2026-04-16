-- after/plugin/pi.lua
-- Pi Coding Agent integrations
--
-- Pi runs as a tmux pane managed by tmux-toggle-pi (not inside nvim).
-- Nvim communicates with pi via persistent unix socket (vim.uv.new_pipe).
--
-- Features:
--   1. Persistent bidirectional connection with auto-reconnect
--   2. Socket discovery: cwd-match > tmux-session > default
--   3. Context sending (selection, diagnostics, file info) via socket
--   4. Tmux integration (toggle pi split via tmux-toggle-pi)
--   5. Buffer tracking (remember what's been shared)
--   6. File context (add entire files to context)
--   7. LSP hover info inclusion
--   8. In-process LSP server for code actions
--   9. Live context sync (debounced editor_state on autocmd events)
--  10. Compose mode (PiAdd/PiFlush/PiClear - queue context + prompt)
--  11. Raw prompt (PiPrompt - send text directly)
--  12. Auto-reload (checktime polling when connected)
--  13. Ping/pong health check

if not Plugin_enabled() then return end

mega.p.pi = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local config = {
  socket = {
    dir = vim.env.PI_SOCKET_DIR or "/tmp",
    prefix = vim.env.PI_SOCKET_PREFIX or "pi",
  },
  context = {
    max_file_size = 100000, -- Max bytes to send for a file (100KB)
    send_as_reference = true, -- Send file path reference instead of content (pi reads the file)
  },
  connection = {
    reconnect_max_retries = 5,
    reconnect_max_delay_s = 30,
    ping_interval_s = 30,
    queue_max = 50,
  },
  live_context = {
    enabled = true,
    -- NOTE: CursorMoved is high-traffic. Use CursorHold for lower frequency.
    events = { "BufEnter", "BufWritePost", "InsertLeave", "ModeChanged" },
    debounce_ms = 150,
    include_buffer_text = false,
    max_buffer_bytes = 200000,
    max_selection_bytes = 50000,
  },
  auto_reload = {
    enabled = true,
    interval_s = 5, -- checktime polling interval (only when connected)
  },
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- Track files that have been added to context
-- Key: absolute file path, Value: { added_at: timestamp, lines: count }
local context_files = {}

local detect_language -- forward declaration (defined in Selection & Context Helpers)

-- Compose mode queue (PiAdd/PiFlush/PiClear)
local compose_queue = {} ---@type {type: string, content: string, file: string?, range: number[]?}[]

-- Live context sync state
local live_context_timer = nil ---@type uv_timer_t?
local live_context_pending = false

-- Auto-reload state
local reload_timer = nil ---@type uv_timer_t?

-- Connection state
local conn = {
  pipe = nil, ---@type uv_pipe_t?
  socket_path = nil, ---@type string?
  connected = false,
  connecting = false,
  read_buffer = "",
  -- Reconnect state
  reconnect_timer = nil, ---@type uv_timer_t?
  reconnect_attempts = 0,
  reconnect_delay_s = 1,
  -- Ping/pong
  ping_timer = nil, ---@type uv_timer_t?
  last_pong = 0, -- os.time() of last pong
  -- Message queue (for messages during reconnect)
  queue = {}, ---@type {payload: table, cb: function?}[]
}

--------------------------------------------------------------------------------
-- Socket Discovery
--------------------------------------------------------------------------------

--- Check if a path is a socket
---@param path string
---@return boolean
local function socket_exists(path)
  return vim.fn.getftype(path) == "socket"
end

--- Discover socket via /tmp/pi-nvim-sockets/*.info (cwd match, then newest)
---@return string?
local function discover_socket_by_cwd()
  local info_dir = "/tmp/pi-nvim-sockets"
  local ok, files = pcall(vim.fn.glob, info_dir .. "/*.info", false, true)
  if not ok or not files or #files == 0 then return nil end

  local cwd = vim.uv.cwd()
  local best_sock = nil
  local best_mtime = 0

  -- First pass: exact cwd match, prefer newest
  for _, info_path in ipairs(files) do
    local content_ok, content = pcall(vim.fn.readfile, info_path)
    if content_ok and content and content[1] then
      local parsed_ok, info = pcall(vim.json.decode, content[1])
      if parsed_ok and info and info.socket then
        if info.cwd == cwd and socket_exists(info.socket) then
          local stat = vim.uv.fs_stat(info.socket)
          if stat and stat.mtime.sec > best_mtime then
            best_mtime = stat.mtime.sec
            best_sock = info.socket
          end
        end
      end
    end
  end
  if best_sock then return best_sock end

  -- Second pass: any live socket (newest)
  for _, info_path in ipairs(files) do
    local content_ok, content = pcall(vim.fn.readfile, info_path)
    if content_ok and content and content[1] then
      local parsed_ok, info = pcall(vim.json.decode, content[1])
      if parsed_ok and info and info.socket and socket_exists(info.socket) then
        local stat = vim.uv.fs_stat(info.socket)
        if stat and stat.mtime.sec > best_mtime then
          best_mtime = stat.mtime.sec
          best_sock = info.socket
        end
      end
    end
  end

  return best_sock
end

--- Discover socket via tmux session pattern (legacy fallback)
---@return string?
local function discover_socket_by_tmux()
  local socket_dir = config.socket.dir
  local socket_prefix = config.socket.prefix

  if not vim.env.TMUX then return nil end

  local handle = io.popen("tmux display-message -p '#{session_name}' 2>/dev/null")
  if not handle then return nil end
  local session = handle:read("*l")
  handle:close()
  if not session or session == "" then return nil end

  -- Try {session}-agent.sock first (dedicated agent window)
  local agent_socket = string.format("%s/%s-%s-agent.sock", socket_dir, socket_prefix, session)
  if socket_exists(agent_socket) then return agent_socket end

  -- Fall back to any socket for this session
  local glob_handle =
    io.popen(string.format("ls %s/%s-%s-*.sock 2>/dev/null | head -1", socket_dir, socket_prefix, session))
  if not glob_handle then return nil end
  local found = glob_handle:read("*l")
  glob_handle:close()
  if found and found ~= "" and socket_exists(found) then return found end

  return nil
end

--- Get socket path with priority: explicit > buffer-local > cwd-match > tmux-session > default
---@return string?
local function get_socket_path()
  -- Explicit override (set by pinvim/pisock wrapper)
  if vim.env.PI_SOCKET then return vim.env.PI_SOCKET end

  -- Buffer-local target
  local buf_target = vim.b.pi_target_socket
  if buf_target and socket_exists(buf_target) then return buf_target end

  -- cwd-based discovery (from .info manifests)
  local cwd_sock = discover_socket_by_cwd()
  if cwd_sock then return cwd_sock end

  -- tmux-session pattern (legacy)
  local tmux_sock = discover_socket_by_tmux()
  if tmux_sock then return tmux_sock end

  -- Fallback to default
  local default = string.format("%s/%s-default.sock", config.socket.dir, config.socket.prefix)
  if socket_exists(default) then return default end

  return nil
end

--------------------------------------------------------------------------------
-- Persistent Connection (vim.uv.new_pipe)
--------------------------------------------------------------------------------

local connection_connect -- forward declaration

--- Process a JSON response line from bridge.ts
---@param line string
local function handle_response(line)
  local ok, resp = pcall(vim.json.decode, line)
  if not ok then return end

  if resp.type == "pong" then
    conn.last_pong = os.time()
    return -- silent pong
  end

  if resp.ok == false and resp.error then
    vim.schedule(function()
      vim.notify("pi error: " .. resp.error, vim.log.levels.ERROR)
    end)
  end
end

--- Flush queued messages after reconnect
local function flush_queue()
  if #conn.queue == 0 then return end

  local count = #conn.queue
  for _, item in ipairs(conn.queue) do
    local json = vim.json.encode(item.payload) .. "\n"
    if conn.pipe and conn.connected then
      conn.pipe:write(json)
    end
  end
  conn.queue = {}

  vim.schedule(function()
    vim.notify(string.format("Flushed %d queued message(s) to pi", count), vim.log.levels.INFO)
  end)
end

--- Stop ping timer
local function stop_ping_timer()
  if conn.ping_timer then
    conn.ping_timer:stop()
    conn.ping_timer:close()
    conn.ping_timer = nil
  end
end

--- Start ping timer for health checks
local function start_ping_timer()
  stop_ping_timer()
  local interval_ms = config.connection.ping_interval_s * 1000
  conn.ping_timer = vim.uv.new_timer()
  conn.ping_timer:start(interval_ms, interval_ms, vim.schedule_wrap(function()
    if conn.pipe and conn.connected then
      local ok, _ = pcall(function()
        conn.pipe:write(vim.json.encode({ type = "ping" }) .. "\n")
      end)
      if not ok then
        -- Write failed, connection is dead
        stop_ping_timer()
      end
    end
  end))
end

--- Stop reconnect timer
local function stop_reconnect_timer()
  if conn.reconnect_timer then
    conn.reconnect_timer:stop()
    conn.reconnect_timer:close()
    conn.reconnect_timer = nil
  end
end

--- Schedule a reconnect attempt with exponential backoff
local function schedule_reconnect()
  if conn.reconnect_timer then return end -- already scheduled

  conn.reconnect_attempts = conn.reconnect_attempts + 1
  if conn.reconnect_attempts > config.connection.reconnect_max_retries then
    vim.schedule(function()
      vim.notify(
        string.format("Pi: gave up reconnecting after %d attempts", config.connection.reconnect_max_retries),
        vim.log.levels.WARN
      )
    end)
    -- Drop queued messages
    if #conn.queue > 0 then
      local dropped = #conn.queue
      conn.queue = {}
      vim.schedule(function()
        vim.notify(string.format("Pi: dropped %d queued message(s)", dropped), vim.log.levels.WARN)
      end)
    end
    return
  end

  local delay_s = math.min(conn.reconnect_delay_s, config.connection.reconnect_max_delay_s)
  conn.reconnect_delay_s = conn.reconnect_delay_s * 2 -- exponential backoff

  vim.schedule(function()
    vim.notify(string.format("Pi: reconnecting in %ds (attempt %d/%d)",
      delay_s, conn.reconnect_attempts, config.connection.reconnect_max_retries), vim.log.levels.INFO)
  end)

  conn.reconnect_timer = vim.uv.new_timer()
  conn.reconnect_timer:start(delay_s * 1000, 0, vim.schedule_wrap(function()
    stop_reconnect_timer()
    connection_connect()
  end))
end

--- Disconnect and clean up pipe
local function connection_disconnect()
  stop_ping_timer()
  stop_reconnect_timer()

  if conn.pipe then
    if not conn.pipe:is_closing() then
      conn.pipe:read_stop()
      conn.pipe:close()
    end
    conn.pipe = nil
  end

  conn.connected = false
  conn.connecting = false
  conn.read_buffer = ""
end

--- Connect to the pi socket
function connection_connect()
  if conn.connected or conn.connecting then return end

  local socket_path = get_socket_path()
  if not socket_path then return end

  conn.connecting = true
  conn.socket_path = socket_path

  local pipe = vim.uv.new_pipe(false)
  if not pipe then
    conn.connecting = false
    return
  end

  pipe:connect(socket_path, function(err)
    if err then
      pipe:close()
      conn.connecting = false
      vim.schedule(function()
        schedule_reconnect()
      end)
      return
    end

    conn.pipe = pipe
    conn.connected = true
    conn.connecting = false
    conn.reconnect_attempts = 0
    conn.reconnect_delay_s = 1
    conn.read_buffer = ""

    -- Start reading responses
    pipe:read_start(function(read_err, data)
      if read_err or not data then
        -- Connection lost
        vim.schedule(function()
          connection_disconnect()
          schedule_reconnect()
        end)
        return
      end

      conn.read_buffer = conn.read_buffer .. data
      -- Process complete lines
      local idx = conn.read_buffer:find("\n")
      while idx do
        local line = conn.read_buffer:sub(1, idx - 1)
        conn.read_buffer = conn.read_buffer:sub(idx + 1)
        if line ~= "" then
          vim.schedule(function()
            handle_response(line)
          end)
        end
        idx = conn.read_buffer:find("\n")
      end
    end)

    -- Start health check pings
    vim.schedule(function()
      start_ping_timer()
      flush_queue()
    end)
  end)
end

--- Send a JSON payload to the pi socket via persistent connection
--- Falls back to one-shot pipe if persistent connection unavailable
---@param payload table
---@param opts? { auto_toggle?: boolean, silent?: boolean }
---@return boolean success
local function send_payload(payload, opts)
  opts = opts or {}
  if opts.auto_toggle == nil then opts.auto_toggle = true end

  -- Try persistent connection first
  if conn.pipe and conn.connected then
    local json = vim.json.encode(payload) .. "\n"
    local ok, write_err = pcall(function() conn.pipe:write(json) end)
    if ok then
      if not opts.silent then
        vim.notify("Sent to pi", vim.log.levels.INFO)
      end
      -- Ring tmux bell + ensure pane
      if conn.socket_path then
        local fname = vim.fn.fnamemodify(conn.socket_path, ":t:r")
        local session, win = fname:match("^pi%-(.+)%-(%w+)$")
        if session and win then
          local tty = vim.fn.system(string.format("tmux display -p -t '%s:%s' '#{pane_tty}' 2>/dev/null", session, win))
          tty = vim.trim(tty)
          if tty ~= "" then vim.fn.system(string.format("printf '\\a' > %s 2>/dev/null", vim.fn.shellescape(tty))) end
        end
      end
      if opts.auto_toggle and vim.env.TMUX then
        vim.fn.jobstart({ "tmux-toggle-pi", "--ensure" }, { detach = true })
      end
      return true
    else
      -- Write failed, connection is dead
      connection_disconnect()
    end
  end

  -- Queue message if reconnecting
  if conn.reconnect_attempts > 0 or conn.connecting then
    if #conn.queue >= config.connection.queue_max then
      vim.notify("Pi: message queue full, dropping oldest", vim.log.levels.WARN)
      table.remove(conn.queue, 1)
    end
    table.insert(conn.queue, { payload = payload })
    vim.notify(string.format("Pi: queued message (%d in queue)", #conn.queue), vim.log.levels.INFO)
    return true
  end

  -- Try one-shot send for buffer-local targets or when not using persistent conn
  local socket_path = get_socket_path()
  if not socket_path then
    vim.notify("No pi socket found. Use tmux prefix+p to start pi.", vim.log.levels.WARN)
    return false
  end

  local pipe = vim.uv.new_pipe(false)
  if not pipe then
    vim.notify("Failed to create pipe", vim.log.levels.ERROR)
    return false
  end

  pipe:connect(socket_path, function(err)
    if err then
      pipe:close()
      vim.schedule(function()
        vim.notify("pi socket not available: " .. socket_path, vim.log.levels.ERROR)
      end)
      return
    end

    local json = vim.json.encode(payload) .. "\n"
    pipe:write(json)

    -- Read response
    local buf = ""
    pipe:read_start(function(read_err, data)
      if read_err or not data then
        pipe:close()
        return
      end
      buf = buf .. data
      local nl = buf:find("\n")
      if nl then
        local line = buf:sub(1, nl - 1)
        pipe:read_stop()
        pipe:close()
        vim.schedule(function()
          handle_response(line)
        end)
      end
    end)

    vim.schedule(function()
      if not opts.silent then
        vim.notify("Sent to pi", vim.log.levels.INFO)
      end
      -- Ring tmux bell
      local fname = vim.fn.fnamemodify(socket_path, ":t:r")
      local session, win = fname:match("^pi%-(.+)%-(%w+)$")
      if session and win then
        local tty = vim.fn.system(string.format("tmux display -p -t '%s:%s' '#{pane_tty}' 2>/dev/null", session, win))
        tty = vim.trim(tty)
        if tty ~= "" then vim.fn.system(string.format("printf '\\a' > %s 2>/dev/null", vim.fn.shellescape(tty))) end
      end
      if opts.auto_toggle and vim.env.TMUX then
        vim.fn.jobstart({ "tmux-toggle-pi", "--ensure" }, { detach = true })
      end
    end)
  end)

  return true
end

--------------------------------------------------------------------------------
-- Selection & Context Helpers
--------------------------------------------------------------------------------

--- Normalize visual selection range
local function normalize_range(start_row, start_col, end_row, end_col)
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    return end_row, end_col, start_row, start_col
  end
  return start_row, start_col, end_row, end_col
end

--- Get the visual selection text and range
---@param force_update boolean? If true, exit visual mode first to update marks
local function get_visual_selection(force_update)
  local bufnr = 0
  local mode = vim.fn.mode()

  -- If in visual mode, exit to set the marks, then get them
  if force_update and (mode == "v" or mode == "V" or mode == "\22") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  end

  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

  if start_row == 0 or end_row == 0 then return nil end

  start_row, start_col, end_row, end_col = normalize_range(start_row, start_col, end_row, end_col)

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
  if #lines == 0 then return nil end

  local vmode = vim.fn.visualmode()
  if vmode == "V" then
    -- Line-wise: return full lines
    return table.concat(lines, "\n"), start_row, end_row
  elseif vmode == "\22" then
    -- Block-wise: extract columns from each line
    local result = {}
    for _, line in ipairs(lines) do
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

--- Get LSP diagnostics for a line range
---@param start_row number?
---@param end_row number?
---@param bufnr number?
---@return string[]
local function get_diagnostics(start_row, end_row, bufnr)
  bufnr = bufnr or 0
  local result = {}

  for _, d in ipairs(vim.diagnostic.get(bufnr)) do
    local line = d.lnum + 1
    if (not start_row or line >= start_row) and (not end_row or line <= end_row) then
      local source = d.source or "lsp"
      local severity = vim.diagnostic.severity[d.severity] or "?"
      local entry = string.format("[%s] %d:%d %s (%s)", severity, line, d.col + 1, d.message, source)
      table.insert(result, entry)
    end
  end

  return result
end

--- Get LSP hover information at cursor
---@param bufnr number?
---@param row number?
---@param col number?
---@return string?
local function get_hover_info(bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local pos = row and col and { row - 1, col } or vim.api.nvim_win_get_cursor(0)

  local hover_result = nil
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  for _, client in ipairs(clients) do
    if client.server_capabilities.hoverProvider then
      local params = vim.lsp.util.make_position_params()
      params.position = { line = pos[1], character = pos[2] }

      local result = client.request_sync("textDocument/hover", params, 1000, bufnr)
      if result and result.result and result.result.contents then
        local contents = result.result.contents
        if type(contents) == "string" then
          hover_result = contents
        elseif type(contents) == "table" then
          if contents.value then
            hover_result = contents.value
          elseif contents[1] then
            hover_result = type(contents[1]) == "string" and contents[1] or contents[1].value
          end
        end
        if hover_result then break end
      end
    end
  end

  return hover_result
end

--- Get file content with size limit
---@param filepath string
---@return string?, number?
local function get_file_content(filepath)
  local stat = vim.uv.fs_stat(filepath)
  if not stat then return nil, nil end

  if stat.size > config.context.max_file_size then return nil, stat.size end

  local lines = vim.fn.readfile(filepath)
  return table.concat(lines, "\n"), #lines
end

--- Get buffer content
---@param bufnr number
---@return string, number
local function get_buffer_content(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n"), #lines
end

--- Detect filetype/language for code fence
---@param filepath string
---@return string
detect_language = function(filepath)
  local ext = vim.fn.fnamemodify(filepath, ":e")
  local ft_map = {
    lua = "lua",
    ex = "elixir",
    exs = "elixir",
    py = "python",
    js = "javascript",
    ts = "typescript",
    tsx = "typescriptreact",
    jsx = "javascriptreact",
    rb = "ruby",
    rs = "rust",
    go = "go",
    sh = "bash",
    bash = "bash",
    zsh = "zsh",
    fish = "fish",
    nix = "nix",
    md = "markdown",
    json = "json",
    yaml = "yaml",
    yml = "yaml",
    toml = "toml",
  }
  return ft_map[ext] or ext or ""
end

--------------------------------------------------------------------------------
-- Tmux Pi Management
--------------------------------------------------------------------------------

--- Toggle pi pane via tmux-toggle-pi (the single source of truth for pi lifecycle)
function mega.p.pi.toggle_panel()
  if not vim.env.TMUX then
    vim.notify("Not in tmux — pi runs as a tmux pane", vim.log.levels.WARN)
    return
  end
  vim.fn.system("tmux-toggle-pi")
end

--------------------------------------------------------------------------------
-- Context Tracking
--------------------------------------------------------------------------------

--- Add a file to the tracked context
---@param filepath string
---@param line_count number?
local function track_file(filepath, line_count)
  context_files[filepath] = {
    added_at = os.time(),
    lines = line_count or 0,
  }
end

--- Get list of tracked context files
---@return string[]
function mega.p.pi.get_context_files()
  local files = {}
  for filepath, _ in pairs(context_files) do
    table.insert(files, filepath)
  end
  table.sort(files)
  return files
end

--- Clear tracked context
function mega.p.pi.clear_context()
  context_files = {}
  vim.notify("Pi context cleared", vim.log.levels.INFO)
end

--- Check if file is in context
---@param filepath string
---@return boolean
function mega.p.pi.is_in_context(filepath) return context_files[filepath] ~= nil end

--- Get context file count (for statusline)
---@return number
function mega.p.pi.context_count()
  local count = 0
  for _ in pairs(context_files) do
    count = count + 1
  end
  return count
end

--------------------------------------------------------------------------------
-- Context Sending Commands
--------------------------------------------------------------------------------

--- Send visual selection to pi
---@param opts table? Options from user command
---@param from_visual boolean? Whether called directly from visual mode
---@param skip_prompt boolean? Skip task prompt (quick send)
---@param send_opts table? Options for send_payload ({ auto_toggle?: boolean })
function mega.p.pi.send_selection(opts, from_visual, skip_prompt, send_opts)
  opts = opts or {}
  send_opts = send_opts or {}
  local selection, start_row, end_row = get_visual_selection(from_visual)

  -- Handle range from command mode
  if not selection and opts.range and opts.range > 0 then
    start_row, end_row = opts.line1, opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    selection = table.concat(lines, "\n")
  end

  if not selection then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local task = ""
  if not skip_prompt then
    task = vim.fn.input("Task: ")
    if task == "" then return end
  end

  local file = vim.api.nvim_buf_get_name(0)
  local lang = detect_language(file)

  local payload = {
    type = "selection",
    file = file,
    range = { start_row, end_row },
    selection = selection,
    language = lang,
    lsp = { diagnostics = get_diagnostics(start_row, end_row) },
    task = task,
  }

  send_payload(payload, send_opts)
end

--- Quick send selection without prompt
---@param opts table?
---@param from_visual boolean?
---@param send_opts table? Options for send_payload
function mega.p.pi.quick_send_selection(opts, from_visual, send_opts)
  mega.p.pi.send_selection(opts, from_visual, true, send_opts)
end

--- Send cursor line to pi
---@param include_hover boolean? Include LSP hover info
---@param send_opts table? Options for send_payload ({ auto_toggle?: boolean })
function mega.p.pi.send_cursor(include_hover, send_opts)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local file = vim.api.nvim_buf_get_name(0)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local lang = detect_language(file)

  local task = vim.fn.input("Task: ")
  if task == "" then return end

  local lsp_info = { diagnostics = get_diagnostics(row, row) }
  if include_hover then
    local hover = get_hover_info(nil, row, col)
    if hover then lsp_info.hover = hover end
  end

  local payload = {
    type = "cursor",
    file = file,
    range = { row, row },
    selection = line,
    language = lang,
    lsp = lsp_info,
    task = task,
  }

  send_payload(payload, send_opts)
end

--- Send cursor with hover info
function mega.p.pi.send_cursor_with_hover() mega.p.pi.send_cursor(true) end

--- Add current file to pi context
---@param filepath string? File path (defaults to current buffer)
function mega.p.pi.add_file(filepath, opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  filepath = filepath or vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    vim.notify("No file to add", vim.log.levels.WARN)
    return
  end

  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  local rel_path = vim.fn.fnamemodify(filepath, ":~:.")
  local lang = detect_language(filepath)
  local is_buffer = vim.fn.bufloaded(filepath) == 1

  -- Check if we should send as reference or content
  local send_as_reference = opts.as_reference
  if send_as_reference == nil then
    send_as_reference = config.context.send_as_reference
  end

  if send_as_reference then
    -- Send file reference (pi reads the file itself)
    local payload = {
      type = "file_reference",
      file = abs_path,
      relative_path = rel_path,
      language = lang,
    }

    if send_payload(payload) then
      -- Count lines for tracking (without loading full content)
      local line_count = 0
      if is_buffer then
        line_count = vim.api.nvim_buf_line_count(vim.fn.bufnr(filepath))
      else
        local stat = vim.uv.fs_stat(abs_path)
        if stat then
          -- Estimate line count (rough, just for display)
          line_count = math.floor(stat.size / 40) -- ~40 bytes per line average
        end
      end
      track_file(filepath, line_count)
      vim.notify(string.format("Added to context: %s (reference)", rel_path), vim.log.levels.INFO)
    end
  else
    -- Send file content (original behavior)
    local content, line_count

    if is_buffer then
      local buf = vim.fn.bufnr(filepath)
      content, line_count = get_buffer_content(buf)
    else
      content, line_count = get_file_content(filepath)
      if not content then
        if line_count then
          vim.notify(
            string.format("File too large: %d bytes (max %d)", line_count, config.context.max_file_size),
            vim.log.levels.WARN
          )
        else
          vim.notify("Cannot read file: " .. filepath, vim.log.levels.ERROR)
        end
        return
      end
    end

    local payload = {
      type = "file",
      file = filepath,
      relative_path = rel_path,
      content = content,
      language = lang,
      lines = line_count,
      lsp = { diagnostics = get_diagnostics(nil, nil, is_buffer and vim.fn.bufnr(filepath) or nil) },
    }

    if send_payload(payload) then
      track_file(filepath, line_count)
      vim.notify(string.format("Added to context: %s (%d lines)", rel_path, line_count), vim.log.levels.INFO)
    end
  end
end

--- Add multiple files (from visual selection in oil or file picker)
---@param filepaths string[]
function mega.p.pi.add_files(filepaths)
  for _, filepath in ipairs(filepaths) do
    mega.p.pi.add_file(filepath)
  end
end

--- Show context files in a floating window
function mega.p.pi.show_context()
  local files = mega.p.pi.get_context_files()
  if #files == 0 then
    vim.notify("No files in context", vim.log.levels.INFO)
    return
  end

  local lines = { "# Pi Context Files", "" }
  for _, filepath in ipairs(files) do
    local info = context_files[filepath]
    local rel_path = vim.fn.fnamemodify(filepath, ":~:.")
    local age = os.time() - info.added_at
    local age_str = age < 60 and string.format("%ds ago", age)
      or age < 3600 and string.format("%dm ago", math.floor(age / 60))
      or string.format("%dh ago", math.floor(age / 3600))
    table.insert(lines, string.format("- %s (%d lines, %s)", rel_path, info.lines, age_str))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

--------------------------------------------------------------------------------
-- Tmux Integration
--------------------------------------------------------------------------------

--- Get session name from socket path
---@param socket_path string?
---@return string?
local function get_session_name(socket_path)
  if not socket_path then return nil end
  local fname = vim.fn.fnamemodify(socket_path, ":t:r")
  -- Pattern: pi-{session}-{window} or pi-{session}
  local session = fname:match("^pi%-(.+)%-[^-]+$") or fname:match("^pi%-(.+)$")
  return session
end

--- Check if connected to a pi agent (persistent connection or socket available)
---@return boolean
function mega.p.pi.is_connected() return conn.connected or mega.p.pi.get_target() ~= nil end

--- Get connection status info
---@return string
function mega.p.pi.status()
  local lines = {}

  -- Socket status (respects buffer-local target)
  local socket = mega.p.pi.get_target()
  local is_explicit = vim.b.pi_target_socket ~= nil
  if socket then
    local session = get_session_name(socket) or "unknown"
    local marker = is_explicit and " (explicit)" or ""
    table.insert(lines, string.format("󰌘 Socket: %s%s (%s)", session, marker, socket))
  else
    table.insert(lines, "󰌘 Socket: not connected")
  end

  -- Context
  local ctx_count = mega.p.pi.context_count()
  if ctx_count > 0 then table.insert(lines, string.format("󰈙 Context: %d files", ctx_count)) end

  return table.concat(lines, "\n")
end

--- List all available pi sockets (from both .info manifests and tmux pattern)
---@return string[]
function mega.p.pi.list_sockets()
  local seen = {}
  local sockets = {}

  -- From .info manifests
  local info_dir = "/tmp/pi-nvim-sockets"
  local ok, files = pcall(vim.fn.glob, info_dir .. "/*.info", false, true)
  if ok and files then
    for _, info_path in ipairs(files) do
      local content_ok, content = pcall(vim.fn.readfile, info_path)
      if content_ok and content and content[1] then
        local parsed_ok, info = pcall(vim.json.decode, content[1])
        if parsed_ok and info and info.socket and socket_exists(info.socket) then
          if not seen[info.socket] then
            seen[info.socket] = true
            table.insert(sockets, info.socket)
          end
        end
      end
    end
  end

  -- From tmux socket pattern
  local pattern = string.format("%s/%s-*.sock", config.socket.dir, config.socket.prefix)
  local glob_socks = vim.fn.glob(pattern, false, true)
  for _, path in ipairs(glob_socks) do
    if socket_exists(path) and not seen[path] then
      seen[path] = true
      table.insert(sockets, path)
    end
  end

  return sockets
end

--- Get current target socket (explicit or auto-discovered)
---@return string?
function mega.p.pi.get_target()
  -- Use persistent connection if active
  if conn.connected and conn.socket_path then return conn.socket_path end
  -- Fall back to discovery
  return get_socket_path()
end

--- Set explicit target socket for current buffer
---@param socket_path string?
function mega.p.pi.set_target(socket_path)
  vim.b.pi_target_socket = socket_path
  if socket_path then
    local session = get_session_name(socket_path) or "unknown"
    vim.notify(string.format("Pi target set: %s", session), vim.log.levels.INFO)
  else
    vim.notify("Pi target cleared (using auto-discovery)", vim.log.levels.INFO)
  end
end

--- Select pi session from available sockets (via snacks picker)
function mega.p.pi.select_session()
  local items = {}

  -- Add socket-based sessions
  local sockets = mega.p.pi.list_sockets()
  for _, socket_path in ipairs(sockets) do
    local session = get_session_name(socket_path) or "unknown"
    table.insert(items, {
      text = string.format("󰌘 %s", session),
      type = "socket",
      path = socket_path,
      session = session,
    })
  end

  -- Add auto option at top
  table.insert(items, 1, {
    text = "󰁔 (auto-discover)",
    type = "auto",
  })

  if #items == 1 then
    vim.notify("No pi sockets found. Use tmux prefix+p to start pi.", vim.log.levels.WARN)
    return
  end

  -- Use snacks picker if available, fall back to vim.ui.select
  local ok, Snacks = pcall(require, "snacks")
  if ok and Snacks.picker then
    Snacks.picker.pick({
      source = items,
      prompt = "Select pi instance",
      format = function(item)
        return {
          { item.text, hl = "Normal" },
        }
      end,
      confirm = function(picker, item)
        picker:close()
        if item.type == "auto" then
          mega.p.pi.set_target(nil)
        elseif item.type == "socket" then
          mega.p.pi.set_target(item.path)
        end
      end,
    })
  else
    vim.ui.select(items, {
      prompt = "Select pi instance:",
      format_item = function(item) return item.text end,
    }, function(choice)
      if not choice then return end
      if choice.type == "auto" then
        mega.p.pi.set_target(nil)
      elseif choice.type == "socket" then
        mega.p.pi.set_target(choice.path)
      end
    end)
  end
end

--------------------------------------------------------------------------------
-- Statusline Integration
--------------------------------------------------------------------------------

--- Get statusline component data
---@return { connected: boolean, reconnecting: boolean, session: string?, context_count: number, queue_count: number, compose_count: number }
function mega.p.pi.statusline_data()
  local socket = mega.p.pi.get_target()
  local session = socket and get_session_name(socket)

  return {
    connected = conn.connected or (socket ~= nil),
    reconnecting = conn.reconnect_attempts > 0 and not conn.connected,
    session = session,
    context_count = mega.p.pi.context_count(),
    queue_count = #conn.queue,
    compose_count = #compose_queue,
  }
end

--- Get statusline string (for direct use)
---@return string
function mega.p.pi.statusline()
  local data = mega.p.pi.statusline_data()
  local icon = mega.ui.icons.pi.symbol

  if data.reconnecting then
    return string.format("%%#StWarning#%s…%%*", icon)
  end

  if not data.connected then return string.format("%%#StComment#%s%%*", icon) end

  local session = data.session or "pi"
  local ctx = data.context_count > 0 and string.format(" %d", data.context_count) or ""
  local compose = data.compose_count > 0 and string.format(" ✎%d", data.compose_count) or ""
  local queue = data.queue_count > 0 and string.format(" Q%d", data.queue_count) or ""

  return string.format("%%#StIdentifier#%s%%* %%#StComment#%s%s%s%s%%*", icon, session, ctx, compose, queue)
end

--- Get statusline component for lualine/custom statusline
--- Returns table with text and highlight info
---@return table[]
function mega.p.pi.statusline_component()
  local data = mega.p.pi.statusline_data()
  local icon = mega.ui.icons.pi.symbol

  if data.reconnecting then return {
    { icon .. "…", hl = "DiagnosticWarn" },
  } end

  if not data.connected then return {
    { icon, hl = "Comment" },
  } end

  local session = data.session or "pi"
  local components = {
    { icon .. " ", hl = "StIdentifier" },
    { session, hl = "StComment" },
  }

  if data.context_count > 0 then table.insert(components, { " " .. data.context_count, hl = "StBufferCount" }) end
  if data.compose_count > 0 then table.insert(components, { " ✎" .. data.compose_count, hl = "StTitle" }) end
  if data.queue_count > 0 then table.insert(components, { " Q" .. data.queue_count, hl = "DiagnosticWarn" }) end

  return components
end

--------------------------------------------------------------------------------
-- In-Process LSP (Phase 2c)
--------------------------------------------------------------------------------

local pi_lsp_client_id = nil

--- Get LSP capabilities for pi-lsp
local function get_pi_lsp_capabilities()
  return {
    hoverProvider = true,
    codeActionProvider = true,
    textDocumentSync = {
      openClose = false,
      change = 0, -- None - we read buffers directly
    },
  }
end

--- Handle textDocument/hover
---@param params table LSP hover params
---@param callback function
local function handle_hover(params, callback)
  local uri = params.textDocument.uri
  local filepath = vim.uri_to_fname(uri)

  local is_tracked = mega.p.pi.is_in_context(filepath)
  local target = mega.p.pi.get_target()
  local session = target and get_session_name(target) or "disconnected"

  local lines = {}
  table.insert(lines, string.format("**Pi Status**: %s", session))

  if is_tracked then
    local info = context_files[filepath]
    local added = info and os.date("%Y-%m-%d %H:%M", info.added_at) or "unknown"
    table.insert(lines, string.format("**Context**: ✓ Added %s", added))
    if info and info.lines then table.insert(lines, string.format("**Lines**: %d", info.lines)) end
  else
    table.insert(lines, "**Context**: Not in context")
  end

  local diag_count = #vim.diagnostic.get(vim.uri_to_bufnr(uri))
  if diag_count > 0 then table.insert(lines, string.format("**Diagnostics**: %d issues", diag_count)) end

  callback(nil, {
    contents = {
      kind = "markdown",
      value = table.concat(lines, "\n"),
    },
  })
end

--- Handle textDocument/codeAction
---@param params table LSP code action params
---@param callback function
local function handle_code_action(params, callback)
  local uri = params.textDocument.uri
  local filepath = vim.uri_to_fname(uri)
  local bufnr = vim.uri_to_bufnr(uri)
  local range = params.range

  local actions = {}

  -- Action: Add file to context
  if not mega.p.pi.is_in_context(filepath) then
    table.insert(actions, {
      title = "󰌘 Add file to pi context",
      kind = "refactor",
      command = {
        title = "Add to context",
        command = "pi.add_file",
        arguments = { filepath },
      },
    })
  end

  -- Action: Send selection to pi
  if range then
    local start_row = range.start.line + 1
    local end_row = range["end"].line + 1
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
    if #lines > 0 then
      table.insert(actions, {
        title = "󰌘 Send selection to pi",
        kind = "refactor",
        command = {
          title = "Send to pi",
          command = "pi.send_selection",
          arguments = { table.concat(lines, "\n"), filepath, start_row, end_row },
        },
      })
    end
  end

  -- Action: Send file with diagnostics
  local diags = vim.diagnostic.get(bufnr)
  if #diags > 0 then
    table.insert(actions, {
      title = string.format("󰌘 Send file with %d diagnostic(s)", #diags),
      kind = "quickfix",
      command = {
        title = "Send with diagnostics",
        command = "pi.send_with_diagnostics",
        arguments = { filepath },
      },
    })
  end

  -- Action: Ask pi about selection
  if range then
    table.insert(actions, {
      title = "󰌘 Ask pi about this code",
      kind = "refactor",
      command = {
        title = "Ask pi",
        command = "pi.ask_about_selection",
        arguments = { filepath, range },
      },
    })
  end

  callback(nil, actions)
end

--- Execute LSP command
---@param command table
---@param callback function
local function handle_execute_command(command, callback)
  local cmd = command.command
  local args = command.arguments or {}

  if cmd == "pi.add_file" then
    local filepath = args[1]
    if filepath then mega.p.pi.add_file(filepath) end
  elseif cmd == "pi.send_selection" then
    local text, filepath, start_row, end_row = unpack(args)
    if text then
      local lang = detect_language(filepath)
      send_payload({
        type = "selection",
        file = filepath,
        range = { start_row, end_row },
        selection = text,
        language = lang,
      })
    end
  elseif cmd == "pi.send_with_diagnostics" then
    local filepath = args[1]
    if filepath then mega.p.pi.add_file(filepath) end
  elseif cmd == "pi.ask_about_selection" then
    local filepath, range = unpack(args)
    if filepath and range then
      local bufnr = vim.fn.bufnr(filepath)
      if bufnr == -1 then
        vim.notify("Buffer not loaded: " .. filepath, vim.log.levels.WARN)
        callback(nil, nil)
        return
      end
      local start_row = range.start.line + 1
      local end_row = range["end"].line + 1
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
      local text = table.concat(lines, "\n")

      vim.ui.input({ prompt = "Ask pi: " }, function(input)
        if input then
          local lang = detect_language(filepath)
          send_payload({
            type = "selection",
            file = filepath,
            range = { start_row, end_row },
            selection = text,
            language = lang,
            task = input,
          })
        end
      end)
    end
  end

  callback(nil, nil)
end

--- Start the in-process pi LSP server
function mega.p.pi.start_lsp()
  if pi_lsp_client_id then return pi_lsp_client_id end

  local handlers = {
    ["textDocument/hover"] = handle_hover,
    ["textDocument/codeAction"] = handle_code_action,
    ["workspace/executeCommand"] = handle_execute_command,
  }

  -- Create the in-process LSP using the "black magic" pattern
  pi_lsp_client_id = vim.lsp.start({
    name = "pi-lsp",
    cmd = function()
      return {
        request = function(method, params, callback)
          -- Handle initialize request
          if method == "initialize" then
            callback(nil, {
              capabilities = get_pi_lsp_capabilities(),
              serverInfo = {
                name = "pi-lsp",
                version = "1.0.0",
              },
            })
            return
          end

          -- Handle initialized notification
          if method == "initialized" then
            callback(nil, nil)
            return
          end

          -- Handle shutdown
          if method == "shutdown" then
            callback(nil, nil)
            return
          end

          -- Handle custom methods
          local handler = handlers[method]
          if handler then
            handler(params, callback)
          else
            callback({ code = -32601, message = "Method not found: " .. method }, nil)
          end
        end,
        notify = function() end,
        is_closing = function() return false end,
        terminate = function() end,
      }
    end,
    root_dir = vim.fn.getcwd(),
  })

  return pi_lsp_client_id
end

--- Stop the in-process pi LSP server
function mega.p.pi.stop_lsp()
  if pi_lsp_client_id then
    vim.lsp.stop_client(pi_lsp_client_id)
    pi_lsp_client_id = nil
  end
end

--- Attach pi-lsp to current buffer
function mega.p.pi.attach_lsp()
  if not pi_lsp_client_id then mega.p.pi.start_lsp() end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.buf_attach_client(bufnr, pi_lsp_client_id)
  vim.notify("Pi LSP attached to buffer", vim.log.levels.INFO)
end

--------------------------------------------------------------------------------
-- Live Context Sync
--------------------------------------------------------------------------------

--- Build editor_state payload from current buffer
---@return table
local function build_editor_state()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local filetype = vim.bo[bufnr].filetype
  local modified = vim.bo[bufnr].modified
  local buftype = vim.bo[bufnr].buftype

  local state = {
    file = vim.fn.fnamemodify(file, ":~:."),
    absFile = file,
    filetype = filetype,
    modified = modified,
    buftype = buftype,
    cursor = { line = cursor[1], col = cursor[2] },
  }

  -- Include visual selection if in visual mode
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local sel = get_visual_selection(false)
    if sel then
      if #sel > config.live_context.max_selection_bytes then
        sel = sel:sub(1, config.live_context.max_selection_bytes)
      end
      state.selection = sel
    end
  end

  -- Optionally include buffer text
  if config.live_context.include_buffer_text then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local text = table.concat(lines, "\n")
    if #text > config.live_context.max_buffer_bytes then
      text = text:sub(1, config.live_context.max_buffer_bytes)
    end
    state.buffer_text = text
  end

  return state
end

--- Send editor state (debounced)
local function push_editor_state()
  if not config.live_context.enabled then return end
  if not conn.connected then return end

  -- Mark pending and debounce
  live_context_pending = true

  if not live_context_timer then
    live_context_timer = vim.uv.new_timer()
  end

  live_context_timer:stop()
  live_context_timer:start(config.live_context.debounce_ms, 0, vim.schedule_wrap(function()
    if not live_context_pending then return end
    live_context_pending = false

    if not conn.connected then return end

    local state = build_editor_state()
    -- Skip non-file buffers
    if state.buftype ~= "" then return end
    if state.absFile == "" then return end

    send_payload({ type = "editor_state", state = state }, { auto_toggle = false, silent = true })
  end))
end

--- Set up autocmds for live context sync
local function setup_live_context()
  if not config.live_context.enabled then return end

  local group = vim.api.nvim_create_augroup("PiLiveContext", { clear = true })
  for _, event in ipairs(config.live_context.events) do
    vim.api.nvim_create_autocmd(event, {
      group = group,
      callback = function()
        push_editor_state()
      end,
    })
  end
end

--------------------------------------------------------------------------------
-- Compose Mode (PiAdd / PiFlush / PiClear)
--------------------------------------------------------------------------------

--- Get compose queue count (for statusline)
---@return number
function mega.p.pi.compose_count() return #compose_queue end

--- Add current selection or file reference to compose queue
---@param opts table? Command opts (for range)
function mega.p.pi.compose_add(opts)
  opts = opts or {}
  local file = vim.api.nvim_buf_get_name(0)
  local rel_path = vim.fn.fnamemodify(file, ":~:.")

  -- Try visual selection first
  local selection, start_row, end_row = get_visual_selection(true)

  -- Handle range from command mode
  if not selection and opts.range and opts.range > 0 then
    start_row, end_row = opts.line1, opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    selection = table.concat(lines, "\n")
  end

  if selection then
    local lang = detect_language(file)
    table.insert(compose_queue, {
      type = "selection",
      content = selection,
      file = rel_path,
      range = { start_row, end_row },
      language = lang,
    })
  else
    -- Add file reference
    table.insert(compose_queue, {
      type = "file",
      content = rel_path,
      file = rel_path,
    })
  end

  vim.notify(string.format("Pi: queued %d item(s)", #compose_queue), vim.log.levels.INFO)
end

--- Flush compose queue with a prompt
function mega.p.pi.compose_flush()
  vim.ui.input({ prompt = "Pi prompt: " }, function(input)
    if not input then return end

    -- Build message from queue + prompt
    local parts = {}

    for i, item in ipairs(compose_queue) do
      if item.type == "selection" then
        local header = item.file or "unknown"
        if item.range then
          header = string.format("%s lines %d-%d", header, item.range[1], item.range[2])
        end
        table.insert(parts, string.format("Context %d - %s:", i, header))
        table.insert(parts, string.format("```%s", item.language or ""))
        table.insert(parts, item.content)
        table.insert(parts, "```")
      elseif item.type == "file" then
        table.insert(parts, string.format("Context %d - File: %s", i, item.content))
      end
      table.insert(parts, "")
    end

    if input ~= "" then
      table.insert(parts, input)
    end

    local message = table.concat(parts, "\n")
    if message:match("^%s*$") then
      vim.notify("Pi: nothing to send", vim.log.levels.WARN)
      return
    end

    send_payload({ type = "prompt", message = message })
    compose_queue = {}
  end)
end

--- Clear compose queue
function mega.p.pi.compose_clear()
  local count = #compose_queue
  compose_queue = {}
  vim.notify(string.format("Pi: cleared %d queued item(s)", count), vim.log.levels.INFO)
end

--------------------------------------------------------------------------------
-- Raw Prompt
--------------------------------------------------------------------------------

--- Send raw prompt string to pi
---@param message string?
function mega.p.pi.prompt(message)
  if message and message ~= "" then
    send_payload({ type = "prompt", message = message })
  else
    vim.ui.input({ prompt = "Pi prompt: " }, function(input)
      if input and input ~= "" then
        send_payload({ type = "prompt", message = input })
      end
    end)
  end
end

--------------------------------------------------------------------------------
-- Auto-reload (checktime)
--------------------------------------------------------------------------------

--- Start checktime polling (only when connected)
local function start_auto_reload()
  if not config.auto_reload.enabled then return end
  if reload_timer then return end

  if not vim.o.autoread then
    vim.o.autoread = true
  end

  local interval_ms = config.auto_reload.interval_s * 1000
  reload_timer = vim.uv.new_timer()
  reload_timer:start(interval_ms, interval_ms, vim.schedule_wrap(function()
    if conn.connected then
      pcall(vim.cmd, "silent! checktime")
    end
  end))
end

--- Stop checktime polling
local function stop_auto_reload()
  if reload_timer then
    reload_timer:stop()
    reload_timer:close()
    reload_timer = nil
  end
end

--------------------------------------------------------------------------------
-- Health Check
--------------------------------------------------------------------------------

--- Run pi health checks (connection, discovery, extensions, LSP)
--- Uses vim.health when available, falls back to vim.notify
function mega.p.pi.health()
  local h = vim.health or {}
  -- Detect if called from :checkhealth (vim.health context) or :PiHealth (manual)
  local use_health = h.start and h.ok and h.warn and h.error and h.info
  local results = {}

  local function ok(msg)
    if use_health then h.ok(msg) else table.insert(results, "✓ " .. msg) end
  end
  local function warn(msg, advice)
    if use_health then h.warn(msg, advice) else table.insert(results, "⚠ " .. msg) end
  end
  local function err(msg, advice)
    if use_health then h.error(msg, advice) else table.insert(results, "✗ " .. msg) end
  end
  local function info(msg)
    if use_health then h.info(msg) else table.insert(results, "  " .. msg) end
  end
  local function section(name)
    if use_health then h.start(name) else table.insert(results, "\n── " .. name .. " ──") end
  end

  ---------------------------------------------------------------------------
  -- Connection
  ---------------------------------------------------------------------------
  section("Pi Connection")

  if conn.connected then
    ok("Persistent connection active")
    info("Socket: " .. (conn.socket_path or "unknown"))
    if conn.last_pong > 0 then
      local ago = os.time() - conn.last_pong
      if ago < 60 then
        ok(string.format("Last pong: %ds ago", ago))
      else
        warn(string.format("Last pong: %ds ago (stale)", ago), { "Run :PiPing to test" })
      end
    else
      info("No pong received yet")
    end
  elseif conn.connecting then
    warn("Connection in progress")
  elseif conn.reconnect_attempts > 0 then
    warn(string.format("Reconnecting (attempt %d/%d)",
      conn.reconnect_attempts, config.connection.reconnect_max_retries))
  else
    info("No persistent connection (will use one-shot sends)")
  end

  -- Message queue
  if #conn.queue > 0 then
    warn(string.format("%d message(s) queued during reconnect", #conn.queue))
  end

  ---------------------------------------------------------------------------
  -- Socket Discovery
  ---------------------------------------------------------------------------
  section("Pi Socket Discovery")

  -- Environment
  if vim.env.PI_SOCKET then
    ok("PI_SOCKET override: " .. vim.env.PI_SOCKET)
    if socket_exists(vim.env.PI_SOCKET) then
      ok("PI_SOCKET is a valid socket")
    else
      err("PI_SOCKET path is not a socket", { "Check if pi is running" })
    end
  else
    info("PI_SOCKET not set (using auto-discovery)")
  end

  -- Buffer-local target
  local buf_target = vim.b.pi_target_socket
  if buf_target then
    if socket_exists(buf_target) then
      ok("Buffer-local target: " .. buf_target)
    else
      warn("Buffer-local target set but invalid: " .. buf_target,
        { "Run :PiTarget to clear or update" })
    end
  end

  -- cwd-based discovery
  local info_dir = "/tmp/pi-nvim-sockets"
  local cwd = vim.uv.cwd()
  local info_ok, info_files = pcall(vim.fn.glob, info_dir .. "/*.info", false, true)
  if info_ok and info_files and #info_files > 0 then
    ok(string.format("%d .info manifest(s) in %s", #info_files, info_dir))
    local cwd_match = false
    for _, info_path in ipairs(info_files) do
      local content_ok, content = pcall(vim.fn.readfile, info_path)
      if content_ok and content and content[1] then
        local parsed_ok, manifest = pcall(vim.json.decode, content[1])
        if parsed_ok and manifest then
          local sock_live = manifest.socket and socket_exists(manifest.socket)
          local is_cwd = manifest.cwd == cwd
          local name = vim.fn.fnamemodify(info_path, ":t")
          local status_parts = {}
          if sock_live then table.insert(status_parts, "socket live") end
          if is_cwd then table.insert(status_parts, "cwd match") cwd_match = true end
          if not sock_live then table.insert(status_parts, "socket DEAD") end
          local line = string.format("%s → %s [%s]",
            name, manifest.socket or "?", table.concat(status_parts, ", "))
          if sock_live then
            info(line)
          else
            warn(line, { "Stale manifest — pi session may have crashed" })
          end
        end
      end
    end
    if not cwd_match then
      info("No cwd match for: " .. cwd)
    end
  else
    info("No .info manifests found in " .. info_dir)
  end

  -- tmux session sockets
  if vim.env.TMUX then
    local handle = io.popen("tmux display-message -p '#{session_name}' 2>/dev/null")
    if handle then
      local session = handle:read("*l")
      handle:close()
      if session and session ~= "" then
        ok("Tmux session: " .. session)
        local pattern = string.format("%s/%s-%s-*.sock", config.socket.dir, config.socket.prefix, session)
        local tmux_socks = vim.fn.glob(pattern, false, true)
        if #tmux_socks > 0 then
          for _, s in ipairs(tmux_socks) do
            if socket_exists(s) then
              info("  " .. vim.fn.fnamemodify(s, ":t"))
            end
          end
        else
          info("No tmux-pattern sockets for session " .. session)
        end
      end
    end
  else
    info("Not in tmux")
  end

  -- Resolved target
  local target = get_socket_path()
  if target then
    ok("Resolved target: " .. target)
  else
    warn("No socket found", { "Start pi with tmux prefix+p", "Or set PI_SOCKET env var" })
  end

  ---------------------------------------------------------------------------
  -- Live Context Sync
  ---------------------------------------------------------------------------
  section("Pi Live Context")

  if config.live_context.enabled then
    ok("Live context sync enabled")
    info("Events: " .. table.concat(config.live_context.events, ", "))
    info(string.format("Debounce: %dms", config.live_context.debounce_ms))
    info("Include buffer text: " .. tostring(config.live_context.include_buffer_text))
    -- Check for high-traffic events
    for _, ev in ipairs(config.live_context.events) do
      if ev == "CursorMoved" then
        warn("CursorMoved is high-traffic", { "Consider CursorHold for lower frequency" })
      end
    end
  else
    info("Live context sync disabled")
  end

  ---------------------------------------------------------------------------
  -- Compose Mode
  ---------------------------------------------------------------------------
  section("Pi Compose Queue")

  if #compose_queue > 0 then
    info(string.format("%d item(s) queued", #compose_queue))
    for i, item in ipairs(compose_queue) do
      info(string.format("  %d. [%s] %s", i, item.type, item.file or "(no file)"))
    end
  else
    ok("Queue empty")
  end

  ---------------------------------------------------------------------------
  -- Auto-reload
  ---------------------------------------------------------------------------
  section("Pi Auto-reload")

  if config.auto_reload.enabled then
    ok(string.format("Checktime polling: every %ds", config.auto_reload.interval_s))
    if reload_timer then
      ok("Timer active")
    else
      warn("Timer not started", { "May start after connection" })
    end
    if vim.o.autoread then
      ok("autoread is on")
    else
      warn("autoread is off", { "Auto-reload won't pick up external changes" })
    end
  else
    info("Auto-reload disabled")
  end

  ---------------------------------------------------------------------------
  -- Pi LSP
  ---------------------------------------------------------------------------
  section("Pi LSP")

  if pi_lsp_client_id then
    local client = vim.lsp.get_client_by_id(pi_lsp_client_id)
    if client then
      ok("Pi LSP server running (id: " .. pi_lsp_client_id .. ")")
      local attached = vim.lsp.get_buffers_by_client_id(pi_lsp_client_id)
      if attached and #attached > 0 then
        ok(string.format("Attached to %d buffer(s)", #attached))
      else
        info("Not attached to any buffer")
      end
    else
      warn("Pi LSP client id set but client not found", { "Run :PiLspStart" })
    end
  else
    info("Pi LSP not started (start with :PiLspStart)")
  end

  ---------------------------------------------------------------------------
  -- Context Tracking
  ---------------------------------------------------------------------------
  section("Pi Context")

  local ctx_count = mega.p.pi.context_count()
  if ctx_count > 0 then
    info(string.format("%d file(s) in context", ctx_count))
    for _, filepath in ipairs(mega.p.pi.get_context_files()) do
      local cinfo = context_files[filepath]
      local rel = vim.fn.fnamemodify(filepath, ":~:.")
      local age = os.time() - cinfo.added_at
      info(string.format("  %s (%d lines, %ds ago)", rel, cinfo.lines, age))
    end
  else
    ok("No files in context")
  end

  ---------------------------------------------------------------------------
  -- Ping test (async — only in manual mode)
  ---------------------------------------------------------------------------
  if not use_health and conn.connected and conn.pipe then
    section("Pi Ping Test")
    info("Sending ping...")
    local ping_ok, _ = pcall(function()
      conn.pipe:write(vim.json.encode({ type = "ping" }) .. "\n")
    end)
    if ping_ok then
      ok("Ping sent (pong updates last_pong timestamp)")
    else
      err("Ping write failed", { "Connection may be broken" })
    end
  end

  -- Output results if not using vim.health
  if not use_health and #results > 0 then
    vim.notify(table.concat(results, "\n"), vim.log.levels.INFO)
  end
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@param opts table?
function mega.p.pi.setup(opts)
  if opts then config = vim.tbl_deep_extend("force", config, opts) end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command(
  "PiPanel",
  function() mega.p.pi.toggle_panel() end,
  { desc = "Toggle pi tmux pane" }
)

vim.api.nvim_create_user_command(
  "PiSelection",
  function(opts) mega.p.pi.send_selection(opts) end,
  { desc = "Send selection to pi", range = true }
)

vim.api.nvim_create_user_command(
  "PiCursor",
  function() mega.p.pi.send_cursor() end,
  { desc = "Send cursor line to pi" }
)

vim.api.nvim_create_user_command(
  "PiFile",
  function(opts) mega.p.pi.add_file(opts.args ~= "" and opts.args or nil) end,
  { desc = "Add file to pi context", nargs = "?", complete = "file" }
)

vim.api.nvim_create_user_command(
  "PiToggle",
  function() mega.p.pi.toggle_panel() end,
  { desc = "Toggle pi pane in tmux" }
)

vim.api.nvim_create_user_command(
  "PiStatus",
  function() vim.notify(mega.p.pi.status(), vim.log.levels.INFO) end,
  { desc = "Show pi connection status" }
)

vim.api.nvim_create_user_command(
  "PiContext",
  function() mega.p.pi.show_context() end,
  { desc = "Show pi context files" }
)

vim.api.nvim_create_user_command(
  "PiClearContext",
  function() mega.p.pi.clear_context() end,
  { desc = "Clear pi context" }
)

vim.api.nvim_create_user_command(
  "PiSessions",
  function() mega.p.pi.select_session() end,
  { desc = "Select pi session" }
)

vim.api.nvim_create_user_command("PiTarget", function(opts)
  if opts.args == "" then
    local target = mega.p.pi.get_target()
    if target then
      vim.notify("Current target: " .. target, vim.log.levels.INFO)
    else
      vim.notify("No target (disconnected)", vim.log.levels.INFO)
    end
  else
    mega.p.pi.set_target(opts.args)
  end
end, { desc = "Get/set pi target socket", nargs = "?", complete = "file" })

vim.api.nvim_create_user_command("PiLspStart", function()
  mega.p.pi.start_lsp()
  vim.notify("Pi LSP server started", vim.log.levels.INFO)
end, { desc = "Start pi in-process LSP server" })

vim.api.nvim_create_user_command("PiLspStop", function()
  mega.p.pi.stop_lsp()
  vim.notify("Pi LSP server stopped", vim.log.levels.INFO)
end, { desc = "Stop pi in-process LSP server" })

vim.api.nvim_create_user_command(
  "PiLspAttach",
  function() mega.p.pi.attach_lsp() end,
  { desc = "Attach pi LSP to current buffer" }
)

vim.api.nvim_create_user_command(
  "PiAdd",
  function(opts) mega.p.pi.compose_add(opts) end,
  { desc = "Add selection/file to compose queue", range = true }
)

vim.api.nvim_create_user_command(
  "PiFlush",
  function() mega.p.pi.compose_flush() end,
  { desc = "Send compose queue with prompt" }
)

vim.api.nvim_create_user_command(
  "PiClear",
  function() mega.p.pi.compose_clear() end,
  { desc = "Clear compose queue" }
)

vim.api.nvim_create_user_command("PiPrompt", function(opts)
  local msg = opts.args ~= "" and opts.args or nil
  mega.p.pi.prompt(msg)
end, { desc = "Send raw prompt to pi", nargs = "*" })

vim.api.nvim_create_user_command("PiHealth", function()
  mega.p.pi.health()
end, { desc = "Run pi health checks" })

vim.api.nvim_create_user_command("PiPing", function()
  if not conn.connected then
    vim.notify("Pi: not connected", vim.log.levels.WARN)
    return
  end
  local ok, _ = pcall(function()
    conn.pipe:write(vim.json.encode({ type = "ping" }) .. "\n")
  end)
  if ok then
    vim.notify("Pi: ping sent (watch for pong in health check)", vim.log.levels.INFO)
  else
    vim.notify("Pi: ping failed, connection may be dead", vim.log.levels.ERROR)
  end
end, { desc = "Ping pi agent" })

vim.api.nvim_create_user_command("PiConnect", function()
  if conn.connected then
    vim.notify("Pi: already connected to " .. (conn.socket_path or "unknown"), vim.log.levels.INFO)
    return
  end
  conn.reconnect_attempts = 0
  conn.reconnect_delay_s = 1
  connection_connect()
end, { desc = "Connect to pi socket" })

vim.api.nvim_create_user_command("PiDisconnect", function()
  connection_disconnect()
  vim.notify("Pi: disconnected", vim.log.levels.INFO)
end, { desc = "Disconnect from pi socket" })

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------

-- Panel
vim.keymap.set(
  "n",
  "<localleader>pp",
  function() mega.p.pi.toggle_panel() end,
  { silent = true, desc = "Pi: toggle panel" }
)

-- Selection
vim.keymap.set(
  "v",
  "<localleader>ps",
  function() mega.p.pi.send_selection(nil, true) end,
  { silent = true, desc = "Pi: send selection" }
)

vim.keymap.set(
  "v",
  "<localleader>pS",
  function() mega.p.pi.quick_send_selection(nil, true) end,
  { silent = true, desc = "Pi: quick send (no prompt)" }
)

-- Cursor
vim.keymap.set(
  "n",
  "<localleader>pc",
  function() mega.p.pi.send_cursor() end,
  { silent = true, desc = "Pi: send cursor line" }
)

vim.keymap.set(
  "n",
  "<localleader>ph",
  function() mega.p.pi.send_cursor_with_hover() end,
  { silent = true, desc = "Pi: send cursor with hover" }
)

-- File
vim.keymap.set(
  "n",
  "<localleader>pf",
  function() mega.p.pi.add_file() end,
  { silent = true, desc = "Pi: add file to context" }
)

-- Tmux
vim.keymap.set(
  "n",
  "<localleader>pt",
  function() mega.p.pi.toggle_panel() end,
  { silent = true, desc = "Pi: toggle tmux pane" }
)

-- Info
vim.keymap.set(
  "n",
  "<localleader>pi",
  function() vim.notify(mega.p.pi.status(), vim.log.levels.INFO) end,
  { silent = true, desc = "Pi: show status" }
)

vim.keymap.set(
  "n",
  "<localleader>px",
  function() mega.p.pi.show_context() end,
  { silent = true, desc = "Pi: show context files" }
)

vim.keymap.set(
  "n",
  "<localleader>pn",
  function() mega.p.pi.select_session() end,
  { silent = true, desc = "Pi: select session" }
)

-- Compose mode
vim.keymap.set(
  "v",
  "<localleader>pa",
  function() mega.p.pi.compose_add() end,
  { silent = true, desc = "Pi: add selection to queue" }
)

vim.keymap.set(
  "n",
  "<localleader>pa",
  function() mega.p.pi.compose_add() end,
  { silent = true, desc = "Pi: add file to queue" }
)

vim.keymap.set(
  "n",
  "<localleader>pF",
  function() mega.p.pi.compose_flush() end,
  { silent = true, desc = "Pi: flush queue with prompt" }
)

vim.keymap.set(
  "n",
  "<localleader>pX",
  function() mega.p.pi.compose_clear() end,
  { silent = true, desc = "Pi: clear queue" }
)

-- Raw prompt
vim.keymap.set(
  "n",
  "<localleader>pP",
  function() mega.p.pi.prompt() end,
  { silent = true, desc = "Pi: raw prompt" }
)

--------------------------------------------------------------------------------
-- Auto-connect & Cleanup
--------------------------------------------------------------------------------

-- Try to establish persistent connection on load
vim.defer_fn(function()
  if get_socket_path() then
    connection_connect()
  end
  -- Set up live context sync autocmds
  setup_live_context()
  -- Start auto-reload polling
  start_auto_reload()
end, 500)

-- Clean up on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    connection_disconnect()
    stop_auto_reload()
    if live_context_timer then
      live_context_timer:stop()
      live_context_timer:close()
      live_context_timer = nil
    end
  end,
})

