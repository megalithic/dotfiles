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
local compose_queue = {}

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

local function get_command_selection(command_opts)
  local selection, start_row, end_row = get_live_visual_selection()
  if selection and start_row and end_row then return selection, start_row, end_row end

  if command_opts and command_opts.range and command_opts.range > 0 then
    start_row, end_row = command_opts.line1, command_opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    if #lines > 0 then return table.concat(lines, "\n"), start_row, end_row end
  end

  return nil
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
    prompt = "prompt",
    explicit_send = "explicit_send",
  },
  transport = {
    state_dir = pi_state_dir,
    socket_dir = path_join(pi_state_dir, "sockets"),
    manifest_dir = path_join(pi_state_dir, "manifests"),
    prefix = "pi",
    link_mode = vim.env.PINVIM_LINK_MODE or "auto",
    enable_peer_frames = true,
  },
  connection = {
    ping_interval_s = 30,
    reconnect_initial_delay_s = 1,
    reconnect_max_delay_s = 30,
    reconnect_max_retries = 8,
  },
  explicit_context = {
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
  link_mode = "auto",
  peer = nil,
  last_hello = nil,
  last_hello_ack = nil,
  last_heartbeat = nil,
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

function Transport.list_targets(config, opts)
  opts = opts or {}
  local entries = {}
  local seen = {}
  local ok, files = pcall(vim.fn.glob, config.transport.manifest_dir .. "/*.info", false, true)
  if not ok or not files then return entries end

  for _, info_path in ipairs(files) do
    local info = parse_info_manifest(config, info_path)
    if info and (opts.include_ephemeral or not info.ephemeral) and not seen[info.socket] then
      seen[info.socket] = true
      table.insert(entries, {
        path = info.socket,
        session = info.session,
        window = info.window,
        cwd = info.cwd,
        ephemeral = info.ephemeral,
      })
    end
  end

  table.sort(entries, function(a, b)
    local a_ephemeral = a.ephemeral and 1 or 0
    local b_ephemeral = b.ephemeral and 1 or 0
    if a_ephemeral ~= b_ephemeral then return a_ephemeral < b_ephemeral end
    if (a.session or "") ~= (b.session or "") then return (a.session or "") < (b.session or "") end
    return (a.window or "") < (b.window or "")
  end)

  return entries
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
      pane = tmux_value("#{pane_id}"),
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
      compose = true,
      explicitSend = true,
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

function Transport.build_explicit_send(config, command_opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local rel_file = file ~= "" and vim.fn.fnamemodify(file, ":~:.") or nil
  local cursor = vim.api.nvim_win_get_cursor(0)
  local selection, start_row, end_row = get_command_selection(command_opts)
  local word = vim.fn.expand("<cword>")
  local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""

  if selection and #selection > config.explicit_context.max_selection_bytes then
    selection = selection:sub(1, config.explicit_context.max_selection_bytes)
  end

  return {
    type = config.protocol.explicit_send,
    context = {
      kind = selection and "selection" or "cursor",
      file = rel_file,
      absFile = file ~= "" and file or nil,
      filetype = vim.bo[bufnr].filetype,
      cursor = { line = cursor[1], col = cursor[2] },
      cwd = vim.uv.cwd(),
      root = config.resolve_root(),
      word = word ~= "" and word or nil,
      selection = selection or line,
      selectionRange = selection and { start_row, end_row } or { cursor[1], cursor[1] },
      modified = vim.bo[bufnr].modified,
    },
  }
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
        "tmux.pane",
        "linkMode",
        "heartbeatAt",
      },
    },
    compatibility = {
      legacy_context = "removed; use explicit_send only",
      legacy_messages = {},
      cutover = "peer hello/heartbeat active; raw prompt, compose queue, and explicit send route through pinvim.ts",
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
    vim.notify("pinvim: reconnect limit reached", vim.log.levels.WARN)
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
      vim.schedule(function()
        vim.notify("pinvim: connect failed " .. tostring(err), vim.log.levels.WARN)
        schedule_reconnect(api, runtime, config)
      end)
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
          vim.notify("pinvim: disconnected", vim.log.levels.WARN)
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
      vim.notify("pinvim: connected " .. vim.fs.basename(socket_path), vim.log.levels.INFO)
      start_ping_timer(api, runtime, config)
      start_heartbeat_timer(api, runtime, config)
    end)
  end)
end

function Commands.setup(api, config)
  local function prompt_command(command_opts)
    local function send_message(message)
      if not message or vim.trim(message) == "" then return end
      local ok = api.send_prompt(message, { silent = false })
      if ok then vim.notify("pinvim: prompt sent", vim.log.levels.INFO) end
    end

    if command_opts.args and command_opts.args ~= "" then
      send_message(command_opts.args)
      return
    end

    vim.ui.input({ prompt = "pinvim prompt: " }, function(input)
      send_message(input)
    end)
  end

  local function compose_add_command(command_opts)
    api.compose_add(command_opts)
  end

  local function compose_flush_command(command_opts)
    api.compose_flush(command_opts.args ~= "" and command_opts.args or nil)
  end

  local function compose_clear_command()
    api.compose_clear()
  end

  local function status_command()
    local info = api.info()
    local health = api.health()
    local lines = {
      "pinvim status",
      string.format("socket: %s", info.target.socket_path or "(none)"),
      string.format("socket source: %s", info.target.source),
      string.format("connected: %s", tostring(info.state.connected)),
      string.format("connecting: %s", tostring(info.state.connecting)),
      string.format("peer linked: %s", health.peer_id or "(none)"),
      string.format("hello_ack: %s", health.hello_ack and "yes" or "no"),
      string.format("heartbeat age: %s", health.heartbeat_age and (tostring(health.heartbeat_age) .. "s") or "(none)"),
      string.format("compose queue: %d", info.compose_count),
    }
    if info.state.last_error then table.insert(lines, "last error: " .. info.state.last_error) end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end

  local function health_command()
    local health = api.health()
    local ok = health.ok
    local level = ok and vim.log.levels.INFO or vim.log.levels.WARN
    local lines = {
      ok and "pinvim health: ok" or "pinvim health: attention needed",
      string.format("peer: %s", health.peer_id or "(none)"),
      string.format("hello_ack: %s", health.hello_ack and "yes" or "no"),
      string.format("heartbeat age: %s", health.heartbeat_age and (tostring(health.heartbeat_age) .. "s") or "(none)"),
      string.format("socket: %s", health.socket_path or "(none)"),
    }
    vim.notify(table.concat(lines, "\n"), level)
  end

  local function target_command(command_opts)
    local arg = command_opts.args and vim.trim(command_opts.args) or ""
    if arg == "" then
      local target = api.get_target()
      if target then
        vim.notify("pinvim: target " .. target, vim.log.levels.INFO)
      else
        vim.notify("pinvim: no target", vim.log.levels.WARN)
      end
      return
    end

    if arg == "auto" or arg == "clear" then
      api.set_target(nil)
      return
    end

    api.set_target(arg)
  end

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
      "implicit context: removed; use gps/:PinvimSend/:PiSend explicit context",
      string.format("cutover: %s", info.handshake.compatibility.cutover),
      "hello payload:",
      vim.inspect(info.handshake.send),
    }

    if info.state.last_error then table.insert(lines, "last error: " .. info.state.last_error) end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show pinvim state + target" })

  vim.api.nvim_create_user_command("PinvimStatus", status_command, {
    desc = "Show current pinvim link status",
  })
  vim.api.nvim_create_user_command("PiStatus", status_command, {
    desc = "Show current pinvim link status",
  })

  vim.api.nvim_create_user_command("PinvimHealth", health_command, {
    desc = "Check pinvim hello/heartbeat health",
  })
  vim.api.nvim_create_user_command("PiHealth", health_command, {
    desc = "Check pinvim hello/heartbeat health",
  })

  vim.api.nvim_create_user_command("PiInfo", function()
    vim.cmd("PinvimInfo")
  end, { desc = "Show pinvim state + target" })

  vim.api.nvim_create_user_command("PinvimPrompt", prompt_command, {
    nargs = "*",
    desc = "Send raw prompt through pinvim.ts",
  })
  vim.api.nvim_create_user_command("PiPrompt", prompt_command, {
    nargs = "*",
    desc = "Send raw prompt through pinvim.ts",
  })

  vim.api.nvim_create_user_command("PinvimSend", function(command_opts)
    api.send_explicit(command_opts)
  end, {
    range = true,
    desc = "Send explicit selection or cursor context through pinvim.ts",
  })
  vim.api.nvim_create_user_command("PiSend", function(command_opts)
    api.send_explicit(command_opts)
  end, {
    range = true,
    desc = "Send explicit selection or cursor context through pinvim.ts",
  })

  vim.api.nvim_create_user_command("PinvimTarget", target_command, {
    nargs = "?",
    complete = "file",
    desc = "Get/set buffer-local pinvim target socket",
  })
  vim.api.nvim_create_user_command("PiTarget", target_command, {
    nargs = "?",
    complete = "file",
    desc = "Get/set buffer-local pinvim target socket",
  })

  vim.api.nvim_create_user_command("PinvimSessions", function()
    api.select_session()
  end, {
    desc = "Select pinvim session from manifests",
  })
  vim.api.nvim_create_user_command("PiSessions", function()
    api.select_session()
  end, {
    desc = "Select pinvim session from manifests",
  })

  vim.api.nvim_create_user_command("PinvimPanel", function(command_opts)
    if command_opts.bang then
      api.toggle_panel()
    else
      api.ensure_panel_visible()
    end
  end, {
    bang = true,
    desc = "Ensure pi split visible (! toggles)",
  })

  vim.api.nvim_create_user_command("PinvimAdd", compose_add_command, {
    range = true,
    desc = "Add selection or file reference to pinvim compose queue",
  })
  vim.api.nvim_create_user_command("PiAdd", compose_add_command, {
    range = true,
    desc = "Add selection or file reference to pinvim compose queue",
  })

  vim.api.nvim_create_user_command("PinvimFlush", compose_flush_command, {
    nargs = "*",
    desc = "Send pinvim compose queue through pinvim.ts",
  })
  vim.api.nvim_create_user_command("PiFlush", compose_flush_command, {
    nargs = "*",
    desc = "Send pinvim compose queue through pinvim.ts",
  })

  vim.api.nvim_create_user_command("PinvimClear", compose_clear_command, {
    desc = "Clear pinvim compose queue",
  })
  vim.api.nvim_create_user_command("PiClear", compose_clear_command, {
    desc = "Clear pinvim compose queue",
  })

  vim.keymap.set("n", "gps", function()
    api.send_explicit()
  end, { silent = true, desc = "pinvim send cursor context" })

  vim.keymap.set("v", "gps", function()
    api.send_explicit({ range = true })
  end, { silent = true, desc = "pinvim send selection" })
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

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      connection_disconnect(api.runtime)
      vim.notify("pinvim: cleanup complete", vim.log.levels.INFO)
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

  local function current_peer()
    if runtime.last_hello_ack and runtime.last_hello_ack.peer then return runtime.last_hello_ack.peer end
    if runtime.last_hello and runtime.last_hello.peer then return runtime.last_hello.peer end
    return runtime.peer
  end

  function api.clear_stale_target(notify_user)
    local buf_target = vim.b.pi_target_socket
    if not buf_target or socket_exists(buf_target) then return false end

    vim.b.pi_target_socket = nil
    if conn.socket_path == buf_target then connection_disconnect(runtime) end

    State.patch(runtime, {
      socket = nil,
      socket_source = "buffer",
      last_error = "stale buffer target: " .. buf_target,
    })

    if notify_user ~= false then
      vim.notify("pinvim: stale buffer target cleared", vim.log.levels.WARN)
    end
    return true
  end

  function api.refresh_buffer_state()
    api.clear_stale_target(false)
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
    api.clear_stale_target(false)
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

  function api.get_target()
    api.clear_stale_target(false)
    if conn.connected and conn.socket_path then return conn.socket_path end
    local socket_path = Transport.resolve_socket(config)
    return socket_path
  end

  function api.set_target(socket_path)
    if socket_path and not socket_exists(socket_path) then
      vim.notify("pinvim: target socket missing", vim.log.levels.WARN)
      return false
    end

    vim.b.pi_target_socket = socket_path
    if socket_path then
      vim.notify("pinvim: target set " .. vim.fs.basename(socket_path), vim.log.levels.INFO)
    else
      vim.notify("pinvim: target cleared; auto-discovery active", vim.log.levels.INFO)
    end

    api.refresh_buffer_state()
    api.ensure_connected(true)
    return true
  end

  function api.list_targets(opts)
    return Transport.list_targets(config, opts)
  end

  function api.select_session()
    local targets = api.list_targets({ include_ephemeral = true })
    if #targets == 0 then
      vim.notify("pinvim: no discovered pi sessions", vim.log.levels.WARN)
      return false
    end

    local items = {
      {
        text = "󰁔 auto-discover",
        kind = "auto",
      },
    }

    for _, target in ipairs(targets) do
      local label = target.session or vim.fs.basename(target.path)
      if target.window and target.window ~= "" then label = string.format("%s:%s", label, target.window) end
      if target.ephemeral then label = label .. " · eph" end
      if target.cwd and target.cwd ~= "" then label = label .. " · " .. target.cwd end
      table.insert(items, {
        text = label,
        kind = "socket",
        path = target.path,
      })
    end

    local function apply_choice(item)
      if not item then return end
      if item.kind == "auto" then
        api.set_target(nil)
      elseif item.kind == "socket" then
        api.set_target(item.path)
      end
    end

    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.picker then
      Snacks.picker.pick({
        source = items,
        prompt = "Select pinvim target",
        format = function(item)
          return {
            { item.text, hl = "Normal" },
          }
        end,
        confirm = function(picker, item)
          picker:close()
          apply_choice(item)
        end,
      })
    else
      vim.ui.select(items, {
        prompt = "Select pinvim target:",
        format_item = function(item) return item.text end,
      }, apply_choice)
    end

    return true
  end

  function api.run_panel_command(ensure_visible)
    if not vim.env.TMUX then
      vim.notify("pinvim: tmux split unavailable outside tmux", vim.log.levels.WARN)
      return false
    end

    local cmd = { "tmux-toggle-pi" }
    if ensure_visible then table.insert(cmd, "--ensure") end

    local socket_path = api.get_target()
    if socket_path then
      table.insert(cmd, "--socket")
      table.insert(cmd, socket_path)
    end

    local job = vim.fn.jobstart(cmd, { detach = true })
    if job <= 0 then
      vim.notify("pinvim: tmux-toggle-pi failed", vim.log.levels.ERROR)
      return false
    end

    if ensure_visible then
      vim.notify(socket_path and "pinvim: focusing linked pi split" or "pinvim: opening pi split", vim.log.levels.INFO)
      vim.defer_fn(function()
        api.refresh_buffer_state()
        api.ensure_connected(true)
        vim.fn.jobstart({ "tmux", "select-pane", "-R" }, { detach = true })
      end, 180)
    end

    return true
  end

  function api.ensure_panel_visible()
    return api.run_panel_command(true)
  end

  function api.toggle_panel()
    return api.run_panel_command(false)
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

  function api.send_prompt(message, prompt_opts)
    prompt_opts = prompt_opts or {}
    if not message or vim.trim(message) == "" then return false end
    return api.send_payload({ type = config.protocol.prompt, message = message }, {
      silent = prompt_opts.silent == true,
      auto_connect = prompt_opts.auto_connect ~= false,
    })
  end

  function api.send_explicit(command_opts)
    api.clear_stale_target(true)
    local payload = Transport.build_explicit_send(config, command_opts)
    local kind = payload.context.kind or "cursor"

    local function complete(ok, message)
      if ok then
        vim.notify(message or ("pinvim: sent " .. kind .. " context"), vim.log.levels.INFO)
        api.ensure_panel_visible()
      else
        vim.notify(message or "pinvim: send failed; no live pi target", vim.log.levels.WARN)
      end
    end

    if api.send_payload(payload, { silent = true }) then
      complete(true)
      return true
    end

    if not conn.connecting then
      complete(false)
      return false
    end

    local timer = vim.uv.new_timer()
    if not timer then
      complete(false, "pinvim: target still connecting")
      return false
    end

    local attempts = 0
    timer:start(
      80,
      80,
      vim.schedule_wrap(function()
        attempts = attempts + 1
        if conn.connected then
          timer:stop()
          timer:close()
          complete(api.send_payload(payload, { silent = true, auto_connect = false }))
        elseif attempts >= 25 then
          timer:stop()
          timer:close()
          complete(false, "pinvim: target not ready")
        end
      end)
    )
    return true
  end

  function api.compose_add(command_opts)
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("pinvim: no file or selection to queue", vim.log.levels.WARN)
      return false
    end

    local rel_path = vim.fn.fnamemodify(file, ":~:.")
    local selection, start_row, end_row = get_command_selection(command_opts)

    if selection and start_row and end_row then
      table.insert(compose_queue, {
        type = "selection",
        content = selection,
        file = rel_path,
        range = { start_row, end_row },
        filetype = vim.bo.filetype,
      })
    else
      table.insert(compose_queue, {
        type = "file",
        content = rel_path,
        file = rel_path,
      })
    end

    vim.notify(string.format("pinvim: queued %d item(s)", #compose_queue), vim.log.levels.INFO)
    return true
  end

  function api.compose_flush(prompt)
    local function send_now(message)
      local parts = {}

      for idx, item in ipairs(compose_queue) do
        if item.type == "selection" then
          local header = item.file or "unknown"
          if item.range then header = string.format("%s lines %d-%d", header, item.range[1], item.range[2]) end
          table.insert(parts, string.format("Context %d - %s:", idx, header))
          table.insert(parts, string.format("```%s", item.filetype or ""))
          table.insert(parts, item.content)
          table.insert(parts, "```")
        elseif item.type == "file" then
          table.insert(parts, string.format("Context %d - File: %s", idx, item.content))
        end
        table.insert(parts, "")
      end

      if message and vim.trim(message) ~= "" then table.insert(parts, message) end
      local payload = table.concat(parts, "\n")
      if vim.trim(payload) == "" then
        vim.notify("pinvim: nothing to send", vim.log.levels.WARN)
        return false
      end

      local ok = api.send_prompt(payload, { silent = false })
      if ok then
        compose_queue = {}
        vim.notify("pinvim: compose queue sent", vim.log.levels.INFO)
      end
      return ok
    end

    if prompt ~= nil then return send_now(prompt) end

    vim.ui.input({ prompt = "pinvim compose prompt: " }, function(input)
      send_now(input)
    end)
    return true
  end

  function api.compose_clear()
    local count = #compose_queue
    compose_queue = {}
    vim.notify(string.format("pinvim: cleared %d queued item(s)", count), vim.log.levels.INFO)
    return true
  end

  function api.health()
    local peer = current_peer()
    local heartbeat_age = nil
    if runtime.last_heartbeat and runtime.last_heartbeat.sentAt then
      heartbeat_age = math.max(os.time() - runtime.last_heartbeat.sentAt, 0)
    end

    return {
      ok = conn.connected and runtime.last_hello_ack ~= nil and (heartbeat_age == nil or heartbeat_age < (config.connection.ping_interval_s * 4)),
      peer_id = peer and peer.id or nil,
      hello_ack = runtime.last_hello_ack ~= nil,
      heartbeat_age = heartbeat_age,
      socket_path = runtime.socket,
    }
  end

  function api.statusline_data()
    local peer = current_peer()
    local session = nil
    if peer and peer.tmux and peer.tmux.session then
      session = peer.tmux.session
      if peer.tmux.window and peer.tmux.window ~= "" then
        session = string.format("%s:%s", session, peer.tmux.window)
      end
    elseif runtime.socket then
      session = vim.fs.basename(runtime.socket):gsub("%.sock$", "")
    end

    return {
      connected = conn.connected or runtime.socket ~= nil,
      reconnecting = conn.reconnect_attempts > 0 and not conn.connected,
      session = session,
      compose_count = #compose_queue,
    }
  end

  function api.info()
    return {
      lifecycle = runtime.lifecycle,
      state = State.snapshot(runtime),
      target = Transport.describe_target(config),
      handshake = Handshake.describe(runtime, Transport, config),
      compose_count = #compose_queue,
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
