-- after/plugin/pi.lua
-- Pi Coding Agent integrations
--
-- Pi runs as a tmux pane managed by tmux-toggle-pi (not inside nvim).
-- Nvim communicates with pi via unix socket.
--
-- Features:
--   1. Context sending (selection, diagnostics, file info) via socket
--   2. Tmux integration (toggle pi split via tmux-toggle-pi)
--   3. Buffer tracking (remember what's been shared)
--   4. File context (add entire files to context)
--   5. LSP hover info inclusion
--   6. In-process LSP server for code actions

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
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- Track files that have been added to context
-- Key: absolute file path, Value: { added_at: timestamp, lines: count }
local context_files = {}

local detect_language -- forward declaration (defined in Selection & Context Helpers)

--------------------------------------------------------------------------------
-- Socket Communication
--------------------------------------------------------------------------------

--- Get socket path using nix-defined pattern
---@return string|nil
local function get_socket_path()
  -- Explicit override (set by pinvim/pisock wrapper)
  if vim.env.PI_SOCKET then return vim.env.PI_SOCKET end

  local socket_dir = config.socket.dir
  local socket_prefix = config.socket.prefix

  -- Helper to check if socket exists
  local function socket_exists(path) return vim.fn.filereadable(path) == 1 or vim.fn.getftype(path) == "socket" end

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
        local glob_handle =
          io.popen(string.format("ls %s/%s-%s-*.sock 2>/dev/null | head -1", socket_dir, socket_prefix, session))
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

--- Send a JSON payload to the pi socket (tmux agent)
--- Respects buffer-local target (vim.b.pi_target_socket) if set
---@param payload table
---@param opts? { auto_toggle?: boolean }
---@return boolean success
local function send_payload(payload, opts)
  opts = opts or {}
  -- Default: auto-toggle pi pane after sending from nvim
  if opts.auto_toggle == nil then opts.auto_toggle = true end

  if vim.fn.executable("nc") ~= 1 then
    vim.notify("nc not found in PATH", vim.log.levels.ERROR)
    return false
  end

  -- Check buffer-local target first, then fall back to auto-discovery
  local socket_path = vim.b.pi_target_socket
  if socket_path and vim.fn.getftype(socket_path) ~= "socket" then
    socket_path = nil -- Invalid, fall back
  end
  socket_path = socket_path or get_socket_path()

  if not socket_path then
    vim.notify("No pi socket found. Use tmux prefix+p to start pi.", vim.log.levels.WARN)
    return false
  end

  local json = vim.fn.json_encode(payload) .. "\n"
  local chan = vim.fn.jobstart({ "nc", "-U", socket_path }, { stdin = "pipe" })
  if chan <= 0 then
    vim.notify("pi socket not available: " .. socket_path, vim.log.levels.ERROR)
    return false
  end

  vim.fn.chansend(chan, json)
  vim.fn.chanclose(chan, "stdin")
  vim.notify("Sent to pi", vim.log.levels.INFO)

  -- Ring tmux bell on the agent's pane
  local fname = vim.fn.fnamemodify(socket_path, ":t:r")
  local session, win = fname:match("^pi%-(.+)%-(%w+)$")
  if session and win then
    local tty = vim.fn.system(string.format("tmux display -p -t '%s:%s' '#{pane_tty}' 2>/dev/null", session, win))
    tty = vim.trim(tty)
    if tty ~= "" then vim.fn.system(string.format("printf '\\a' > %s 2>/dev/null", vim.fn.shellescape(tty))) end
  end

  -- Toggle pi pane after successful send
  if opts.auto_toggle and vim.env.TMUX then
    vim.fn.jobstart({ "tmux-toggle-pi", "--ensure" }, { detach = true })
  end

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

--- Check if connected to a pi agent (socket available)
---@return boolean
function mega.p.pi.is_connected() return mega.p.pi.get_target() ~= nil end

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

--- List all available pi sockets
---@return string[]
function mega.p.pi.list_sockets()
  local socket_dir = config.socket.dir
  local socket_prefix = config.socket.prefix
  local pattern = string.format("%s/%s-*.sock", socket_dir, socket_prefix)

  local sockets = vim.fn.glob(pattern, false, true)
  -- Filter to only actual sockets
  return vim.tbl_filter(function(path) return vim.fn.getftype(path) == "socket" end, sockets)
end

--- Get current target socket (explicit or auto-discovered)
---@return string?
function mega.p.pi.get_target()
  -- Check buffer-local override first
  local buf_target = vim.b.pi_target_socket
  if buf_target and vim.fn.getftype(buf_target) == "socket" then return buf_target end
  -- Fall back to auto-discovery
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
---@return { connected: boolean, session: string?, context_count: number }
function mega.p.pi.statusline_data()
  local socket = mega.p.pi.get_target()
  local session = socket and get_session_name(socket)

  return {
    connected = socket ~= nil,
    session = session,
    context_count = mega.p.pi.context_count(),
  }
end

--- Get statusline string (for direct use)
---@return string
function mega.p.pi.statusline()
  local data = mega.p.pi.statusline_data()
  local icon = mega.ui.icons.pi.symbol

  if not data.connected then return string.format("%%#StComment#%s%%*", icon) end

  local session = data.session or "pi"
  local ctx = data.context_count > 0 and string.format(" %d", data.context_count) or ""

  return string.format("%%#StIdentifier#%s%%* %%#StComment#%s%s%%*", icon, session, ctx)
end

--- Get statusline component for lualine/custom statusline
--- Returns table with text and highlight info
---@return table[]
function mega.p.pi.statusline_component()
  local data = mega.p.pi.statusline_data()
  local icon = mega.ui.icons.pi.symbol

  if not data.connected then return {
    { icon, hl = "Comment" },
  } end

  local session = data.session or "pi"
  local components = {
    { icon .. " ", hl = "StIdentifier" },
    { session, hl = "StComment" },
  }

  if data.context_count > 0 then table.insert(components, { " " .. data.context_count, hl = "StBufferCount" }) end

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

