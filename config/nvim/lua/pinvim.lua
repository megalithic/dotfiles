-- lua/pinvim.lua
-- Fresh bootstrap for new nvim↔pi handshake work.
-- Keep module self-contained with obvious local tables.
-- Responsibility split:
--   * after/plugin/pi.lua: guard + require only
--   * lua/pinvim.lua: editor-side state, handshake targets, commands, autocmds
--   * bridge.ts: audited transport shim + Telegram/tell ingress
--   * extensions/pinvim.ts: primary pi-side nvim extension
--   * after/plugin/pi_legacy.lua + extensions/pinvim_legacy.ts: legacy transport path + shim

local M = {}

local Config = {}
local State = {}
local Transport = {}
local Handshake = {}
local Commands = {}
local Autocmds = {}

local did_setup = false
local defaults
local options
local live_context_timer = nil
local live_context_pending = false

local conn = {
  pipe = nil,
  connected = false,
  connecting = false,
  socket_path = nil,
  socket_source = nil,
  read_buffer = "",
  ping_timer = nil,
  heartbeat_timer = nil,
  reconnect_timer = nil,
  reconnect_attempts = 0,
  reconnect_delay_s = 1,
}

local function path_join(...) return table.concat({ ... }, "/") end

local function tmux_value(format)
  if not vim.env.TMUX then return nil end
  local handle = io.popen(string.format("tmux display-message -p '%s' 2>/dev/null", format))
  if not handle then return nil end
  local value = handle:read("*l")
  handle:close()
  return (value and value ~= "") and value or nil
end

local function socket_exists(path) return path and vim.fn.getftype(path) == "socket" end

local function pid_alive(pid)
  if not pid or pid <= 0 then return false end
  return os.execute(string.format("kill -0 %d 2>/dev/null", pid)) == 0
end

local function normalize_range(start_row, start_col, end_row, end_col)
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    return end_row, end_col, start_row, start_col
  end
  return start_row, start_col, end_row, end_col
end

local function get_live_visual_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then return nil end

  local vpos = vim.fn.getpos("v")
  local cpos = vim.fn.getpos(".")
  local start_row, start_col = vpos[2], vpos[3] - 1
  local end_row, end_col = cpos[2], cpos[3] - 1

  if start_row == 0 or end_row == 0 then return nil end

  start_row, start_col, end_row, end_col = normalize_range(start_row, start_col, end_row, end_col)

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then return nil end

  if mode == "V" then
    return table.concat(lines, "\n"), start_row, end_row
  elseif mode == "\22" then
    local result = {}
    for _, line in ipairs(lines) do
      local s = math.min(start_col + 1, #line + 1)
      local e = math.min(end_col + 1, #line)
      table.insert(result, string.sub(line, s, e))
    end
    return table.concat(result, "\n"), start_row, end_row
  else
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col + 1, end_col + 1)
    else
      lines[1] = string.sub(lines[1], start_col + 1)
      lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
    end
    return table.concat(lines, "\n"), start_row, end_row
  end
end

local function resolve_root()
  local buf = vim.api.nvim_get_current_buf()
  local root = vim.fs.root(buf, { ".jj", ".git", "flake.nix" })
  return root or vim.uv.cwd()
end

local xdg_state_home = vim.env.XDG_STATE_HOME or path_join(vim.env.HOME or "~", ".local", "state")
local pi_state_dir = vim.env.PI_STATE_DIR or path_join(xdg_state_home, "pi")

defaults = {
  protocol = {
    name = "pinvim.peer.v1",
    hello = "hello",
    hello_ack = "hello_ack",
    heartbeat = "heartbeat",
    editor_state = "editor_state",
    editor_disconnect = "editor_disconnect",
  },
  transport = {
    state_dir = pi_state_dir,
    socket_dir = path_join(pi_state_dir, "sockets"),
    manifest_dir = path_join(pi_state_dir, "manifests"),
    prefix = "pi",
    link_mode = vim.env.PINVIM_LINK_MODE or "bootstrap",
    enable_peer_frames = true,
  },
  connection = {
    ping_interval_s = 30,
    reconnect_initial_delay_s = 1,
    reconnect_max_delay_s = 30,
    reconnect_max_retries = 8,
  },
  live_context = {
    enabled = true,
    debounce_ms = 150,
    events = { "BufEnter", "BufWritePost", "InsertLeave", "ModeChanged", "CursorMoved" },
    include_buffer_text = false,
    max_buffer_bytes = 16000,
    max_selection_bytes = 8000,
  },
}

options = vim.deepcopy(defaults)

function Config.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  options.resolve_root = resolve_root
  return options
end

function Config.get()
  if not options.resolve_root then options.resolve_root = resolve_root end
  return options
end

local state_defaults = {
  lifecycle = "bootstrap",
  file = nil,
  abs_file = nil,
  cwd = nil,
  root = nil,
  socket = nil,
  socket_source = nil,
  link_mode = "bootstrap",
  peer = nil,
  last_hello = nil,
  last_hello_ack = nil,
  last_heartbeat = nil,
  last_editor_state = nil,
  last_editor_push_at = nil,
  last_ping_at = nil,
  last_pong_at = nil,
  last_error = nil,
  connected = false,
  connecting = false,
  rollout = "pinvim.ts owns pi-side nvim state; bridge.ts passes peer frames without owning semantics",
}

function State.new(initial)
  return vim.tbl_deep_extend("force", vim.deepcopy(state_defaults), initial or {})
end

function State.patch(state, patch)
  for key, value in pairs(patch) do
    state[key] = value
  end
end

function State.set_buffer(state, patch)
  state.file = patch.file
  state.abs_file = patch.abs_file
  state.cwd = patch.cwd
  state.root = patch.root
  state.socket = patch.socket
  state.socket_source = patch.socket_source
  state.link_mode = patch.link_mode or state.link_mode
end

function State.snapshot(state)
  return vim.deepcopy(state)
end

local function parse_info_manifest(config, info_path)
  local content_ok, content = pcall(vim.fn.readfile, info_path)
  if not content_ok or not content or not content[1] then return nil end

  local parsed_ok, info = pcall(vim.json.decode, content[1])
  if not parsed_ok or not info or not info.socket then return nil end

  if not socket_exists(info.socket) then return nil end
  if info.pid and not pid_alive(info.pid) then return nil end
  if info.ephemeral == nil then info.ephemeral = info.socket:match("%-eph%-[^/]+%.sock$") ~= nil end

  return info
end

local function discover_socket_by_cwd(config)
  local ok, files = pcall(vim.fn.glob, config.transport.manifest_dir .. "/*.info", false, true)
  if not ok or not files or #files == 0 then return nil end

  local cwd = vim.uv.cwd()
  local best_socket = nil
  local best_mtime = 0

  for _, info_path in ipairs(files) do
    local info = parse_info_manifest(config, info_path)
    if info and not info.ephemeral and info.cwd == cwd then
      local stat = vim.uv.fs_stat(info.socket)
      if stat and stat.mtime.sec > best_mtime then
        best_mtime = stat.mtime.sec
        best_socket = info.socket
      end
    end
  end
  if best_socket then return best_socket end

  local tmux_session = tmux_value("#{session_name}")
  if not tmux_session then return nil end

  for _, info_path in ipairs(files) do
    local info = parse_info_manifest(config, info_path)
    if info and not info.ephemeral and info.session == tmux_session then
      local stat = vim.uv.fs_stat(info.socket)
      if stat and stat.mtime.sec > best_mtime then
        best_mtime = stat.mtime.sec
        best_socket = info.socket
      end
    end
  end

  return best_socket
end

local function discover_socket_by_tmux(config)
  local session = tmux_value("#{session_name}")
  if not session then return nil end

  local agent_socket = string.format(
    "%s/%s-%s-agent.sock",
    config.transport.socket_dir,
    config.transport.prefix,
    session
  )
  if socket_exists(agent_socket) then return agent_socket end

  local pattern = string.format("%s/%s-%s-*.sock", config.transport.socket_dir, config.transport.prefix, session)
  local sockets = vim.fn.glob(pattern, false, true)
  for _, found in ipairs(sockets) do
    if not found:match("%-eph%-[^/]+%.sock$") and socket_exists(found) then return found end
  end

  return nil
end

function Transport.resolve_socket(config)
  if vim.env.PI_SOCKET and socket_exists(vim.env.PI_SOCKET) then return vim.env.PI_SOCKET, "env" end

  local buf_target = vim.b.pi_target_socket
  if buf_target and socket_exists(buf_target) then return buf_target, "buffer" end

  local cwd_socket = discover_socket_by_cwd(config)
  if cwd_socket then return cwd_socket, "manifest" end

  local tmux_socket = discover_socket_by_tmux(config)
  if tmux_socket then return tmux_socket, "tmux" end

  local default_socket = string.format(
    "%s/%s-default-0.sock",
    config.transport.socket_dir,
    config.transport.prefix
  )
  if socket_exists(default_socket) then return default_socket, "default" end

  return nil, "none"
end

function Transport.describe_target(config)
  local socket_path, source = Transport.resolve_socket(config)
  return {
    socket_path = socket_path,
    source = source,
    socket_dir = config.transport.socket_dir,
    manifest_dir = config.transport.manifest_dir,
    link_mode = config.transport.link_mode,
    peer_frames_enabled = config.transport.enable_peer_frames,
  }
end

function Transport.build_peer_identity(config)
  return {
    id = string.format(
      "nvim:%s:%s:%d",
      tmux_value("#{session_name}") or "local",
      tmux_value("#{window_name}") or "0",
      vim.fn.getpid()
    ),
    kind = "nvim",
    cwd = vim.uv.cwd(),
    root = config.resolve_root(),
    tmux = {
      session = tmux_value("#{session_name}"),
      window = tmux_value("#{window_name}"),
    },
    linkMode = config.transport.link_mode,
    heartbeatAt = os.time(),
  }
end

function Transport.build_hello(_state, config)
  return {
    type = config.protocol.hello,
    protocol = config.protocol.name,
    peer = Transport.build_peer_identity(config),
    capabilities = {
      liveContext = true,
      compose = false,
      explicitSend = false,
    },
  }
end

function Transport.build_heartbeat(state, config)
  return {
    type = config.protocol.heartbeat,
    protocol = config.protocol.name,
    peerId = state.peer and state.peer.id or nil,
    sentAt = os.time(),
  }
end

function Transport.build_editor_state(config)
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local state = {
    file = file ~= "" and vim.fn.fnamemodify(file, ":~:.") or nil,
    absFile = file,
    filetype = vim.bo[bufnr].filetype,
    modified = vim.bo[bufnr].modified,
    buftype = vim.bo[bufnr].buftype,
    cursor = { line = cursor[1], col = cursor[2] },
  }

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local selection, start_row, end_row = get_live_visual_selection()
    if selection and start_row and end_row then
      if #selection > config.live_context.max_selection_bytes then
        selection = selection:sub(1, config.live_context.max_selection_bytes)
      end
      state.selection = selection
      state.selectionRange = { start_row, end_row }
      state.visualmode = mode
    end
  end

  if config.live_context.include_buffer_text then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local text = table.concat(lines, "\n")
    if #text > config.live_context.max_buffer_bytes then text = text:sub(1, config.live_context.max_buffer_bytes) end
    state.buftext = text
  end

  return state
end

function Handshake.refresh(state, transport, config)
  state.peer = transport.build_peer_identity(config)
  state.last_hello = transport.build_hello(state, config)
end

function Handshake.describe(state, transport, config)
  return {
    protocol = config.protocol.name,
    enabled = config.transport.enable_peer_frames,
    send = transport.build_hello(state, config),
    expect = {
      type = config.protocol.hello_ack,
      peer_metadata = {
        "id",
        "cwd",
        "root",
        "tmux.session",
        "tmux.window",
        "linkMode",
        "heartbeatAt",
      },
    },
    compatibility = {
      legacy_live_context = "bridge.ts -> pinvim.ts",
      legacy_messages = {
        config.protocol.editor_state,
        config.protocol.editor_disconnect,
      },
      cutover = "peer hello/heartbeat now pass through bridge.ts; compose/raw prompt parity still pending",
    },
    next_heartbeat = transport.build_heartbeat(state, config),
  }
end

local function stop_ping_timer()
  if conn.ping_timer then
    conn.ping_timer:stop()
    conn.ping_timer:close()
    conn.ping_timer = nil
  end
end

local function stop_heartbeat_timer()
  if conn.heartbeat_timer then
    conn.heartbeat_timer:stop()
    conn.heartbeat_timer:close()
    conn.heartbeat_timer = nil
  end
end

local function stop_reconnect_timer()
  if conn.reconnect_timer then
    conn.reconnect_timer:stop()
    conn.reconnect_timer:close()
    conn.reconnect_timer = nil
  end
end

local function handle_response(runtime, config, line)
  local ok, resp = pcall(vim.json.decode, line)
  if not ok or not resp then return end

  if resp.type == "pong" then
    runtime.last_pong_at = os.time()
    return
  end

  if resp.type == config.protocol.hello_ack then
    runtime.last_hello_ack = resp
  elseif resp.type == config.protocol.heartbeat then
    runtime.last_heartbeat = resp
  end

  if resp.ok == false and resp.error then
    runtime.last_error = resp.error
    vim.notify("pinvim: " .. resp.error, vim.log.levels.ERROR)
  end
end

local function connection_disconnect(runtime)
  stop_ping_timer()
  stop_heartbeat_timer()
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

  State.patch(runtime, {
    connected = false,
    connecting = false,
    lifecycle = "disconnected",
  })
end

local function schedule_reconnect(api, runtime, config)
  if conn.reconnect_timer then return end

  conn.reconnect_attempts = conn.reconnect_attempts + 1
  if conn.reconnect_attempts > config.connection.reconnect_max_retries then
    State.patch(runtime, {
      lifecycle = "reconnect_failed",
      last_error = string.format("reconnect limit reached (%d)", config.connection.reconnect_max_retries),
    })
    return
  end

  local delay_s = math.min(conn.reconnect_delay_s, config.connection.reconnect_max_delay_s)
  conn.reconnect_delay_s = conn.reconnect_delay_s * 2

  conn.reconnect_timer = vim.uv.new_timer()
  conn.reconnect_timer:start(
    delay_s * 1000,
    0,
    vim.schedule_wrap(function()
      stop_reconnect_timer()
      api.ensure_connected(true)
    end)
  )
end

local function start_ping_timer(api, runtime, config)
  stop_ping_timer()
  conn.ping_timer = vim.uv.new_timer()
  conn.ping_timer:start(
    config.connection.ping_interval_s * 1000,
    config.connection.ping_interval_s * 1000,
    vim.schedule_wrap(function()
      if not conn.pipe or not conn.connected then return end
      runtime.last_ping_at = os.time()
      local ok = pcall(function() conn.pipe:write(vim.json.encode({ type = "ping" }) .. "\n") end)
      if not ok then
        connection_disconnect(runtime)
        schedule_reconnect(api, runtime, config)
      end
    end)
  )
end

local function start_heartbeat_timer(api, runtime, config)
  stop_heartbeat_timer()
  if not config.transport.enable_peer_frames then return end

  conn.heartbeat_timer = vim.uv.new_timer()
  conn.heartbeat_timer:start(
    config.connection.ping_interval_s * 1000,
    config.connection.ping_interval_s * 1000,
    vim.schedule_wrap(function()
      api.send_payload(Transport.build_heartbeat(runtime, config), { silent = true, auto_connect = false })
    end)
  )
end

local function connection_connect(api, runtime, config, socket_path, source)
  if conn.connected or conn.connecting then return end
  if not socket_path then return end

  conn.connecting = true
  conn.socket_path = socket_path
  conn.socket_source = source

  State.patch(runtime, {
    connected = false,
    connecting = true,
    socket = socket_path,
    socket_source = source,
    lifecycle = "connecting",
    last_error = nil,
  })

  local pipe = vim.uv.new_pipe(false)
  if not pipe then
    conn.connecting = false
    State.patch(runtime, {
      connecting = false,
      lifecycle = "connect_failed",
      last_error = "uv pipe allocation failed",
    })
    return
  end

  pipe:connect(socket_path, function(err)
    if err then
      if not pipe:is_closing() then pipe:close() end
      conn.connecting = false
      State.patch(runtime, {
        connecting = false,
        lifecycle = "connect_failed",
        last_error = tostring(err),
      })
      vim.schedule(function() schedule_reconnect(api, runtime, config) end)
      return
    end

    conn.pipe = pipe
    conn.connected = true
    conn.connecting = false
    conn.reconnect_attempts = 0
    conn.reconnect_delay_s = config.connection.reconnect_initial_delay_s
    conn.read_buffer = ""

    State.patch(runtime, {
      connected = true,
      connecting = false,
      socket = socket_path,
      socket_source = source,
      lifecycle = "connected",
      last_error = nil,
    })

    pipe:read_start(function(read_err, data)
      if read_err or not data then
        vim.schedule(function()
          connection_disconnect(runtime)
          schedule_reconnect(api, runtime, config)
        end)
        return
      end

      conn.read_buffer = conn.read_buffer .. data
      local idx = conn.read_buffer:find("\n")
      while idx do
        local line = conn.read_buffer:sub(1, idx - 1)
        conn.read_buffer = conn.read_buffer:sub(idx + 1)
        if line ~= "" then vim.schedule(function() handle_response(runtime, config, line) end) end
        idx = conn.read_buffer:find("\n")
      end
    end)

    vim.schedule(function()
      Handshake.refresh(runtime, Transport, config)
      if config.transport.enable_peer_frames then
        api.send_payload(runtime.last_hello, { silent = true, auto_connect = false })
      end
      start_ping_timer(api, runtime, config)
      start_heartbeat_timer(api, runtime, config)
      api.push_editor_state({ force = true, silent = true })
    end)
  end)
end

function Commands.setup(api, config)
  vim.api.nvim_create_user_command("PinvimInfo", function()
    local info = api.info()
    local lines = {
      "pinvim state",
      string.format("lifecycle: %s", info.lifecycle),
      string.format("file: %s", info.state.file or "(none)"),
      string.format("root: %s", info.state.root or "(none)"),
      string.format("socket: %s", info.target.socket_path or "(none)"),
      string.format("socket source: %s", info.target.source),
      string.format("connected: %s", tostring(info.state.connected)),
      string.format("connecting: %s", tostring(info.state.connecting)),
      string.format("link mode: %s", info.target.link_mode),
      string.format("peer frames enabled: %s", tostring(info.target.peer_frames_enabled)),
      string.format("protocol: %s", info.handshake.protocol),
      string.format("live sync events: %s", table.concat(config.live_context.events, ", ")),
      string.format("cutover: %s", info.handshake.compatibility.cutover),
      "hello payload:",
      vim.inspect(info.handshake.send),
    }

    if info.state.last_error then table.insert(lines, "last error: " .. info.state.last_error) end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show pinvim state + target" })
end

function Autocmds.setup(api, config)
  local group = vim.api.nvim_create_augroup("mega.pinvim", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = group,
    callback = function()
      api.refresh_buffer_state()
      api.ensure_connected(true)
    end,
  })

  vim.api.nvim_create_autocmd({ "VimEnter", "BufReadPost" }, {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].buftype ~= "" then return end
      api.refresh_buffer_state()
      api.ensure_connected(true)
    end,
  })

  for _, event in ipairs(config.live_context.events) do
    vim.api.nvim_create_autocmd(event, {
      group = group,
      callback = function()
        if event == "CursorMoved" then
          local mode = vim.fn.mode()
          if mode ~= "v" and mode ~= "V" and mode ~= "\22" then return end
        end
        api.refresh_buffer_state()
        api.push_editor_state({ silent = true })
      end,
    })
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if conn.pipe and conn.connected then
        pcall(function() conn.pipe:write(vim.json.encode({ type = config.protocol.editor_disconnect }) .. "\n") end)
      end
      connection_disconnect(api.runtime)
      if live_context_timer then
        live_context_timer:stop()
        live_context_timer:close()
        live_context_timer = nil
      end
    end,
  })
end

function M.setup(opts)
  if did_setup then return M.api end
  did_setup = true

  local config = Config.setup(opts)
  local runtime = State.new()

  local api = {}
  api.runtime = runtime

  function api.refresh_buffer_state()
    local current = vim.api.nvim_buf_get_name(0)
    local socket_path, source = Transport.resolve_socket(config)
    State.set_buffer(runtime, {
      file = current ~= "" and vim.fn.fnamemodify(current, ":~:.") or nil,
      abs_file = current ~= "" and current or nil,
      cwd = vim.uv.cwd(),
      root = config.resolve_root(),
      socket = socket_path,
      socket_source = source,
      link_mode = config.transport.link_mode,
    })
    Handshake.refresh(runtime, Transport, config)
  end

  function api.ensure_connected(force_target_check)
    local socket_path, source = Transport.resolve_socket(config)

    if force_target_check and conn.connected and socket_path and socket_path ~= conn.socket_path then
      connection_disconnect(runtime)
    end

    if conn.connected or conn.connecting then
      State.patch(runtime, {
        connected = conn.connected,
        connecting = conn.connecting,
      })
      return conn.connected
    end

    if not socket_path then
      State.patch(runtime, {
        socket = nil,
        socket_source = source,
        connected = false,
        connecting = false,
        lifecycle = "waiting_for_socket",
      })
      return false
    end

    connection_connect(api, runtime, config, socket_path, source)
    return false
  end

  function api.send_payload(payload, send_opts)
    send_opts = send_opts or {}
    local silent = send_opts.silent == true
    local auto_connect = send_opts.auto_connect ~= false

    if auto_connect and (not conn.connected and not conn.connecting) then
      api.ensure_connected(true)
    end

    if not conn.pipe or not conn.connected then return false end

    local ok, err = pcall(function() conn.pipe:write(vim.json.encode(payload) .. "\n") end)
    if ok then return true end

    State.patch(runtime, { last_error = tostring(err) })
    connection_disconnect(runtime)
    schedule_reconnect(api, runtime, config)
    if not silent then vim.notify("pinvim: write failed", vim.log.levels.WARN) end
    return false
  end

  function api.push_editor_state(push_opts)
    push_opts = push_opts or {}
    if not config.live_context.enabled then return end

    local function push_now()
      live_context_pending = false
      if not conn.connected then return end

      local editor_state = Transport.build_editor_state(config)
      if editor_state.buftype ~= "" then return end
      if not editor_state.absFile or editor_state.absFile == "" then return end

      runtime.last_editor_state = editor_state
      runtime.last_editor_push_at = os.time()
      api.send_payload({ type = config.protocol.editor_state, state = editor_state }, {
        silent = push_opts.silent ~= false,
        auto_connect = false,
      })
    end

    if push_opts.force then
      push_now()
      return
    end

    live_context_pending = true
    if not live_context_timer then live_context_timer = vim.uv.new_timer() end
    live_context_timer:stop()
    live_context_timer:start(
      config.live_context.debounce_ms,
      0,
      vim.schedule_wrap(function()
        if not live_context_pending then return end
        push_now()
      end)
    )
  end

  function api.info()
    return {
      lifecycle = runtime.lifecycle,
      state = State.snapshot(runtime),
      target = Transport.describe_target(config),
      handshake = Handshake.describe(runtime, Transport, config),
      responsibilities = {
        loader = "config/nvim/after/plugin/pi.lua",
        module = "config/nvim/lua/pinvim.lua",
        bridge = "home/common/programs/pi-coding-agent/extensions/bridge.ts",
        extension = "home/common/programs/pi-coding-agent/extensions/pinvim.ts",
        legacy = "config/nvim/after/plugin/pi_legacy.lua + extensions/pinvim_legacy.ts",
      },
    }
  end

  api.refresh_buffer_state()
  Commands.setup(api, config)
  Autocmds.setup(api, config)

  vim.defer_fn(function()
    api.refresh_buffer_state()
    api.ensure_connected(true)
  end, 250)

  M.api = api
  M.state = runtime
  M.config = config

  return api
end

return M
