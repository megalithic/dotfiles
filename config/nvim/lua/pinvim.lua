-- lua/pinvim.lua
-- Fresh bootstrap for new nvim↔pi handshake work.
-- Keep module self-contained with obvious local tables.
-- Responsibility split:
--   * after/plugin/pi.lua: guard + require only
--   * lua/pinvim.lua: editor-side state, handshake targets, commands, autocmds
--   * extensions/pinvim.ts: primary pi-side socket + nvim extension
--   * bridge.ts: non-nvim ingress only while Hammerspoon/tell replacements land

local M = {}

local Config = {}
local State = {}
local Transport = {}
local Registry = {}
local EditorService = {}
local Handshake = {}
local Commands = {}
local Autocmds = {}

local did_setup = false
local defaults
local options
local compose_queue = {}
local compose_ns = vim.api.nvim_create_namespace("pinvim_compose")
local target_history = {}
local target_history_limit = 20
local tmux_context_cache = { at = 0, value = nil, running = false, callbacks = {} }
local discovery_cache = { at = 0, targets = {}, by_socket = {}, running = false, callbacks = {} }
local discovery_ttl_ms = 2000
local peer_manifest_timer = nil
local peer_manifest_path = nil
local editor_service_address = nil

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
  ephemeral_watch_timer = nil,
}

local function path_join(...) return table.concat({ ... }, "/") end

local function read_first_line(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  if not ok or not lines or not lines[1] then return nil end
  return lines[1]
end

local function write_json_atomic(path, value)
  local dir = vim.fs.dirname(path)
  if dir then pcall(vim.fn.mkdir, dir, "p") end
  local tmp = string.format("%s.tmp.%d.%d", path, vim.fn.getpid(), vim.uv.hrtime() % 1000000)
  local ok = pcall(vim.fn.writefile, { vim.json.encode(value) }, tmp)
  if not ok then return false end
  local rename_ok = vim.uv.fs_rename(tmp, path)
  if not rename_ok then
    pcall(vim.fn.delete, tmp)
    return false
  end
  return true
end

local function write_text_atomic(path, value)
  local dir = vim.fs.dirname(path)
  if dir then pcall(vim.fn.mkdir, dir, "p") end
  local tmp = string.format("%s.tmp.%d.%d", path, vim.fn.getpid(), vim.uv.hrtime() % 1000000)
  local ok = pcall(vim.fn.writefile, { value }, tmp)
  if not ok then return false end
  local rename_ok = vim.uv.fs_rename(tmp, path)
  if not rename_ok then
    pcall(vim.fn.delete, tmp)
    return false
  end
  return true
end

local function stable_hash(value)
  local ok, hash = pcall(vim.fn.sha256, value or "")
  if ok and type(hash) == "string" and hash ~= "" then return hash:sub(1, 16) end

  local acc = 5381
  for idx = 1, #(value or "") do
    acc = ((acc * 33) + string.byte(value, idx)) % 4294967296
  end
  return string.format("%08x", acc)
end

local refresh_tmux_context_async

local function tmux_value(format)
  local context = tmux_context_cache.value or {}
  local map = {
    ["#{session_name}"] = context.session,
    ["#{window_name}"] = context.window_name,
    ["#{window_index}"] = context.window_index,
    ["#{pane_id}"] = context.pane,
  }
  refresh_tmux_context_async()
  return map[format]
end

local function socket_exists(path)
  if not path or path == "" then return false end
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "socket" or false
end

local function is_child_socket(path)
  return path ~= nil and path:match("/pinvim/[^/]+/children/[^/]+/[^/]+%.sock$") ~= nil
end

local function is_ephemeral_socket(path)
  if not path then return false end
  if path:match("%-eph%-[^/]+%.sock$") then return true end
  -- Child sockets allocated under the registry are explicit-only too:
  -- never auto-picked as :PiPanel main and treated like ephemeral on close.
  if is_child_socket(path) then return true end
  return false
end

local function generate_ephemeral_socket_path(config)
  local session = tmux_value("#{session_name}") or "default"
  local window = tmux_value("#{window_name}") or tmux_value("#{window_index}") or "0"
  if window == "" or not window:match("^[a-zA-Z0-9_-]+$") then window = tmux_value("#{window_index}") or "0" end
  local epoch = os.time()
  local pid = vim.fn.getpid()
  return string.format(
    "%s/%s-%s-%s-eph-%d-%d.sock",
    config.transport.socket_dir,
    config.transport.prefix,
    session,
    window,
    epoch,
    pid
  )
end

local tmux_option_cache = { at = 0, values = {}, running = false }

local function refresh_tmux_options_async()
  local session = tmux_value("#{session_name}")
  if not session or tmux_option_cache.running or (vim.uv.now() - tmux_option_cache.at) < 1000 then return end
  tmux_option_cache.running = true
  vim.system({ "tmux", "show-option", "-qv", "-t", session, "@pimux.parked_sockets" }, { text = true }, function(result)
    vim.schedule(
      function()
        tmux_option_cache = {
          at = vim.uv.now(),
          running = false,
          values = { ["@pimux.parked_sockets"] = result.code == 0 and vim.trim(result.stdout or "") or nil },
        }
      end
    )
  end)
end

local function tmux_option(name)
  refresh_tmux_options_async()
  local value = tmux_option_cache.values[name]
  return (value and value ~= "") and value or nil
end

local function pid_alive(pid)
  pid = tonumber(pid)
  if not pid or pid <= 0 then return false end
  return vim.uv.kill(pid, 0) == 0
end

local function normalize_range(start_row, start_col, end_row, end_col)
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    return end_row, end_col, start_row, start_col
  end
  return start_row, start_col, end_row, end_col
end

local function extract_visual_selection(mode, start_row, start_col, end_row, end_col)
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then return nil end
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

local function get_live_visual_selection()
  local mode = vim.fn.mode()
  local vpos = vim.fn.getpos("v")
  local cpos = vim.fn.getpos(".")
  return extract_visual_selection(mode, vpos[2], vpos[3] - 1, cpos[2], cpos[3] - 1)
end

local function get_mark_visual_selection()
  local mode = vim.fn.visualmode()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  return extract_visual_selection(mode, start_pos[2], start_pos[3] - 1, end_pos[2], end_pos[3] - 1)
end

local function get_command_selection(command_opts)
  local selection, start_row, end_row = get_live_visual_selection()
  if selection and start_row and end_row then return selection, start_row, end_row end

  if command_opts and command_opts.range then
    if command_opts.range == true then
      selection, start_row, end_row = get_mark_visual_selection()
      if selection and start_row and end_row then return selection, start_row, end_row end
    elseif type(command_opts.range) == "number" and command_opts.range > 0 then
      start_row, end_row = command_opts.line1, command_opts.line2
      local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
      if #lines > 0 then return table.concat(lines, "\n"), start_row, end_row end
    end
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
  editor_service = {
    enabled = true,
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
  rollout = "pinvim.ts owns pi-side nvim socket, peer state, and explicit context delivery",
  restored_target = false,
  restored_from = nil,
}

function State.new(initial) return vim.tbl_deep_extend("force", vim.deepcopy(state_defaults), initial or {}) end

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

function State.snapshot(state) return vim.deepcopy(state) end

local function parse_info_manifest_content(_config, info_path, line)
  if not line or line == "" then return nil end

  local parsed_ok, info = pcall(vim.json.decode, line)
  if not parsed_ok or not info or not info.socket then return nil end

  if not socket_exists(info.socket) then return nil end
  if info.pid and not pid_alive(info.pid) then return nil end
  if info.ephemeral == nil then info.ephemeral = info.socket:match("%-eph%-[^/]+%.sock$") ~= nil end
  info.info_path = info_path

  return info
end

local function parse_info_manifest(config, info_path)
  local content_ok, content = pcall(vim.fn.readfile, info_path)
  if not content_ok or not content or not content[1] then return nil end
  return parse_info_manifest_content(config, info_path, content[1])
end

local function normalize_path(path)
  if not path or path == "" then return nil end
  local normalized = vim.fs and vim.fs.normalize and vim.fs.normalize(path)
    or vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  local real = normalized and vim.uv.fs_realpath(normalized) or nil
  return (real or normalized):gsub("/$", "")
end

local function same_path(a, b)
  a, b = normalize_path(a), normalize_path(b)
  return a ~= nil and b ~= nil and a == b
end

local function path_contains(parent, child)
  parent, child = normalize_path(parent), normalize_path(child)
  if not parent or not child then return false end
  if parent == child then return true end
  return child:sub(1, #parent + 1) == parent .. "/"
end

local function stat_mtime(path)
  local stat = path and vim.uv.fs_stat(path) or nil
  return stat and stat.mtime and stat.mtime.sec or 0
end

local function parse_time(value)
  if type(value) == "number" then return value end
  if type(value) ~= "string" then return nil end
  local year, month, day, hour, min, sec = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)")
  if not year then return nil end
  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
  })
end

local function parse_tmux_context(value)
  local session, window_name, window_index, pane = (value or ""):match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)")
  return {
    session = session and session ~= "" and session or nil,
    window_name = window_name and window_name ~= "" and window_name or nil,
    window_index = window_index and window_index ~= "" and window_index or nil,
    pane = pane and pane ~= "" and pane or nil,
  }
end

refresh_tmux_context_async = function(callback)
  if not vim.env.TMUX then
    if callback then callback({}) end
    return
  end

  local now = vim.uv.now()
  if tmux_context_cache.value and (now - tmux_context_cache.at) < 1000 then
    if callback then callback(tmux_context_cache.value) end
    return
  end

  if callback then table.insert(tmux_context_cache.callbacks, callback) end
  if tmux_context_cache.running then return end
  tmux_context_cache.running = true
  local cmd = { "tmux", "display-message", "-p", "#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}" }
  if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
    cmd = {
      "tmux",
      "display-message",
      "-t",
      vim.env.TMUX_PANE,
      "-p",
      "#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}",
    }
  end

  vim.system(cmd, { text = true }, function(result)
    local context = result.code == 0 and parse_tmux_context(vim.trim(result.stdout or "")) or {}
    vim.schedule(function()
      local callbacks = tmux_context_cache.callbacks or {}
      tmux_context_cache = { at = vim.uv.now(), value = context, running = false, callbacks = {} }
      for _, cb in ipairs(callbacks) do
        pcall(cb, context)
      end
    end)
  end)
end

local function current_tmux_context()
  refresh_tmux_context_async()
  return tmux_context_cache.value or {}
end

local function candidate_activity(info)
  return math.max(
    tonumber(info.heartbeatAt or 0) or 0,
    parse_time(info.startedAt) or 0,
    stat_mtime(info.socket),
    stat_mtime(info.info_path)
  )
end

local function score_manifest_candidate(config, info, context)
  local score = 0
  local reasons = {}
  local cwd = normalize_path(vim.uv.cwd())
  local root = normalize_path(config.resolve_root())
  local info_cwd = normalize_path(info.cwd)
  local info_root = normalize_path(info.root)
  local activity = candidate_activity(info)

  if info.ephemeral then
    score = score - 1000
    table.insert(reasons, "ephemeral explicit-only")
  else
    score = score + 10
    table.insert(reasons, "non-ephemeral")
  end

  if same_path(info_cwd, cwd) then
    score = score + 120
    table.insert(reasons, "cwd exact")
  elseif info_cwd and root and path_contains(root, info_cwd) then
    score = score + 85
    table.insert(reasons, "same root")
  elseif info_root and root and (same_path(info_root, root) or path_contains(info_root, cwd)) then
    score = score + 85
    table.insert(reasons, "root match")
  elseif info_cwd and cwd and path_contains(info_cwd, cwd) then
    score = score + 40
    table.insert(reasons, "cwd inside session cwd")
  end

  if context.session and info.session == context.session then
    score = score + 35
    table.insert(reasons, "same tmux session")
  end

  if context.window_name and info.window == context.window_name then
    score = score + 20
    table.insert(reasons, "same tmux window")
  elseif context.window_index and tostring(info.window or "") == tostring(context.window_index) then
    score = score + 15
    table.insert(reasons, "same tmux window index")
  end

  if context.pane and info.pane == context.pane then
    score = score + 10
    table.insert(reasons, "same tmux pane")
  end

  if activity > 0 then
    local age = math.max(os.time() - activity, 0)
    if age <= 120 then
      score = score + 25
      table.insert(reasons, "fresh <2m")
    elseif age <= 900 then
      score = score + 15
      table.insert(reasons, "recent <15m")
    elseif age <= 3600 then
      score = score + 5
      table.insert(reasons, "active <1h")
    else
      table.insert(reasons, "stale")
    end
  end

  return score, reasons, activity
end

local function rank_manifest_infos(config, infos, context, opts)
  opts = opts or {}
  local entries = {}
  local seen = {}

  for _, info in ipairs(infos or {}) do
    local same_tmux_session = not context.session or info.session == context.session
    local allowed_session = not opts.same_tmux_session or same_tmux_session
    if allowed_session and (opts.include_ephemeral or not info.ephemeral) and not seen[info.socket] then
      seen[info.socket] = true
      local score, reasons, activity = score_manifest_candidate(config, info, context)
      table.insert(entries, {
        path = info.socket,
        session = info.session,
        window = info.window,
        pane = info.pane,
        cwd = info.cwd,
        root = info.root,
        ephemeral = info.ephemeral,
        owner = info.owner,
        score = score,
        reasons = reasons,
        activity = activity,
        source = "manifest",
      })
    end
  end

  table.sort(entries, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    if (a.activity or 0) ~= (b.activity or 0) then return (a.activity or 0) > (b.activity or 0) end
    local a_ephemeral = a.ephemeral and 1 or 0
    local b_ephemeral = b.ephemeral and 1 or 0
    if a_ephemeral ~= b_ephemeral then return a_ephemeral < b_ephemeral end
    if (a.session or "") ~= (b.session or "") then return (a.session or "") < (b.session or "") end
    return (a.window or "") < (b.window or "")
  end)

  return entries
end

local function update_discovery_cache(targets)
  local by_socket = {}
  for _, target in ipairs(targets or {}) do
    by_socket[target.path] = target
  end
  discovery_cache.at = vim.uv.now()
  discovery_cache.targets = targets or {}
  discovery_cache.by_socket = by_socket
end

local function filter_cached_targets(opts)
  opts = opts or {}
  local context = current_tmux_context()
  local entries = {}
  for _, target in ipairs(discovery_cache.targets or {}) do
    local same_tmux_session = not context.session or target.session == context.session
    local allowed_session = not opts.same_tmux_session or same_tmux_session
    if allowed_session and (opts.include_ephemeral or not target.ephemeral) and socket_exists(target.path) then
      table.insert(entries, vim.deepcopy(target))
    end
  end
  return entries
end

local function discovery_stale() return (vim.uv.now() - (discovery_cache.at or 0)) > discovery_ttl_ms end

local function schedule_manifest_discovery(config, callback)
  if callback then table.insert(discovery_cache.callbacks, callback) end
  if discovery_cache.running then return end

  discovery_cache.running = true
  refresh_tmux_context_async(function(context)
    vim.system({
      "sh",
      "-c",
      'for f in "$1"/*.info; do [ -f "$f" ] || continue; printf \'\\036%s\\n\' "$f"; head -n 1 "$f"; done',
      "sh",
      config.transport.manifest_dir,
    }, { text = true }, function(result)
      local infos = {}
      local current_path = nil
      if result.code == 0 then
        for line in (result.stdout or ""):gmatch("[^\n]+") do
          if line:sub(1, 1) == "\036" then
            current_path = line:sub(2)
          elseif current_path then
            local info = parse_info_manifest_content(config, current_path, line)
            if info then table.insert(infos, info) end
            current_path = nil
          end
        end
      end

      local targets = rank_manifest_infos(config, infos, context, { include_ephemeral = true })
      vim.schedule(function()
        update_discovery_cache(targets)
        discovery_cache.running = false
        local callbacks = discovery_cache.callbacks
        discovery_cache.callbacks = {}
        for _, cb in ipairs(callbacks) do
          pcall(cb, targets)
        end
      end)
    end)
  end)
end

local function ranked_manifest_targets(config, opts)
  opts = opts or {}
  if discovery_stale() then schedule_manifest_discovery(config) end
  return filter_cached_targets(opts)
end

local function parked_socket_set()
  local parked = tmux_option("@pimux.parked_sockets")
  local set = {}
  if not parked then return set end
  for entry in parked:gmatch("[^|]+") do
    local sock = entry:match("^([^=]+)")
    if sock and sock ~= "" then set[sock] = true end
  end
  return set
end

local function target_link_mode(source, entry)
  if entry and entry.ephemeral then return "ephemeral" end
  if entry and entry.parked then return "parked" end
  if source == "env" then return "explicit" end
  if source == "ephemeral" then return "ephemeral" end
  if source == "registry-main" then return "main" end
  if source == "buffer" or source == "manual" then return "manual" end
  if source == "history-restore" then return "parked" end
  return "auto"
end

local function target_metadata(config, socket_path, source)
  if not socket_path then return nil end
  if vim.in_fast_event and vim.in_fast_event() then
    local ephemeral = socket_path:match("%-eph%-[^/]+%.sock$") ~= nil or is_child_socket(socket_path)
    return {
      path = socket_path,
      source = source or "unknown",
      ephemeral = ephemeral,
      parked = false,
      link_mode = ephemeral and "ephemeral" or target_link_mode(source, nil),
      recorded_at = os.time(),
    }
  end

  local parked = {}
  local found = discovery_cache.by_socket[socket_path] and vim.deepcopy(discovery_cache.by_socket[socket_path]) or nil
  found = found or { path = socket_path }
  found.source = source or found.source or "unknown"
  found.parked = parked[socket_path] == true
  found.ephemeral = found.ephemeral == true
    or socket_path:match("%-eph%-[^/]+%.sock$") ~= nil
    or is_child_socket(socket_path)
  found.link_mode = target_link_mode(found.source, found)
  found.recorded_at = os.time()
  return found
end

local function record_target_history(config, socket_path, source)
  local meta = target_metadata(config, socket_path, source)
  if not meta then return nil end

  for idx, entry in ipairs(target_history) do
    if entry.path == socket_path then
      table.remove(target_history, idx)
      break
    end
  end

  table.insert(target_history, 1, meta)
  while #target_history > target_history_limit do
    table.remove(target_history)
  end

  return meta
end

local function previous_alive_parked_target(exclude_socket)
  local parked = parked_socket_set()
  for _, entry in ipairs(target_history) do
    if entry.path ~= exclude_socket and socket_exists(entry.path) and parked[entry.path] and not entry.ephemeral then
      return entry
    end
  end
  return nil
end

local function manifest_for_socket(config, socket_path)
  if not socket_path then return nil end
  local socket_base = vim.fs.basename(socket_path):gsub("%.sock$", "")
  return parse_info_manifest(config, path_join(config.transport.manifest_dir, socket_base .. ".info"))
end

local function tmux_pane_exists(pane)
  return pane
    and pane ~= ""
    and vim.fn.system({ "tmux", "display-message", "-t", pane, "-p", "#{pane_id}" })
    and vim.v.shell_error == 0
end

local function focus_socket_pane(config, socket_path)
  local info = manifest_for_socket(config, socket_path)
  if not info or not tmux_pane_exists(info.pane) then return false end
  vim.fn.system({ "tmux", "select-pane", "-t", info.pane })
  return vim.v.shell_error == 0
end

local function discover_socket_by_tmux(config)
  local context = current_tmux_context()
  if not context.session then return nil end

  local agent_socket =
    string.format("%s/%s-%s-agent.sock", config.transport.socket_dir, config.transport.prefix, context.session)
  if socket_exists(agent_socket) then return agent_socket end

  local window = context.window_name or context.window_index
  if window then
    local window_socket =
      string.format("%s/%s-%s-%s.sock", config.transport.socket_dir, config.transport.prefix, context.session, window)
    if socket_exists(window_socket) then return window_socket end
  end

  return nil
end

function Transport.resolve_socket(config)
  if vim.env.PI_SOCKET and socket_exists(vim.env.PI_SOCKET) then return vim.env.PI_SOCKET, "env" end

  local buf_target = vim.b.pi_target_socket
  if buf_target and socket_exists(buf_target) then return buf_target, "buffer" end

  local registry_socket, registry_source = Registry.main_target(config.registry)
  if registry_source then return registry_socket, registry_source end

  if discovery_stale() then schedule_manifest_discovery(config) end

  local ranked = filter_cached_targets({ include_ephemeral = false, same_tmux_session = true })
  if ranked[1] then
    local local_pair_id = config.registry and config.registry.pair_id
    if local_pair_id and ranked[1].pairId and local_pair_id ~= ranked[1].pairId then return nil, "manifest-unpaired" end
    return ranked[1].path, "manifest-ranked"
  end

  local tmux_socket = discover_socket_by_tmux(config)
  if tmux_socket then return tmux_socket, "tmux" end

  local default_socket = string.format("%s/%s-default-0.sock", config.transport.socket_dir, config.transport.prefix)
  if socket_exists(default_socket) then return default_socket, "default" end

  return nil, "none"
end

function Transport.discovery_stale() return discovery_stale() end

function Transport.refresh_discovery(config, callback) schedule_manifest_discovery(config, callback) end

function Transport.auto_discovery_enabled(config) return not (config.registry and config.registry.parent_id) end

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

function Transport.list_targets(config, opts) return ranked_manifest_targets(config, opts) end

function Transport.build_peer_identity(config)
  local context = current_tmux_context()
  local registry = config.registry or {}
  return {
    id = string.format(
      "nvim:%s:%s:%d",
      context.session or "local",
      context.window_name or context.window_index or "0",
      vim.fn.getpid()
    ),
    kind = "nvim",
    cwd = vim.uv.cwd(),
    root = config.resolve_root(),
    tmux = {
      session = context.session,
      window = context.window_name or context.window_index,
      pane = context.pane,
    },
    linkMode = config.transport.link_mode,
    parentId = registry.parent_id,
    pairId = registry.pair_id or vim.env.PINVIM_PAIR_ID,
    workspaceId = registry.workspace_id,
    instanceId = registry.instance_id,
    registryRoot = registry.workspace_root,
    role = vim.env.PINVIM_SESSION_ROLE or "main",
    nvimListenAddress = editor_service_address or vim.v.servername,
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

local function read_manifest_infos_sync(config)
  local infos = {}
  local pattern = path_join(config.transport.manifest_dir, "*.info")
  for _, info_path in ipairs(vim.fn.glob(pattern, false, true)) do
    local info = parse_info_manifest(config, info_path)
    if info then table.insert(infos, info) end
  end
  return infos
end

local function legacy_registry_runtime(config)
  local socket_path, source = Transport.resolve_socket(config)
  local info = socket_path and manifest_for_socket(config, socket_path) or nil

  if not socket_path then
    local ranked = rank_manifest_infos(
      config,
      read_manifest_infos_sync(config),
      current_tmux_context(),
      { include_ephemeral = false }
    )
    local first = ranked[1]
    if first then
      socket_path = first.path
      source = "manifest-import"
      info = first.raw or manifest_for_socket(config, first.path)
    end
  end

  if not socket_path then return nil end
  info = info or {}
  return {
    schema = "pinvim.registry.v1",
    writer = "nvim-import",
    role = "main",
    importedFrom = "legacy-manifest-or-tmux",
    importedAt = os.time(),
    socket = socket_path,
    socketSource = source,
    pid = info.pid,
    session = info.session,
    window = info.window,
    pane = info.pane,
    tmux = info.tmux,
    cwd = info.cwd,
    root = info.root,
    heartbeatAt = info.heartbeatAt,
    startedAt = info.startedAt,
  }
end

function Registry.setup(config)
  local root = normalize_path(config.resolve_root()) or normalize_path(vim.uv.cwd()) or vim.uv.cwd()
  local workspace_id = stable_hash(root)
  local pair_id = string.format(
    "nvim-%d-%s",
    vim.fn.getpid(),
    stable_hash(vim.fn.getpid() .. "\0" .. (vim.g.pinvim_started_at or os.time())):sub(1, 12)
  )
  vim.env.PINVIM_PAIR_ID = pair_id
  local registry_root = path_join(config.transport.state_dir, "pinvim", workspace_id)
  local existed = vim.uv.fs_stat(registry_root) ~= nil
  pcall(vim.fn.mkdir, path_join(registry_root, "instances"), "p")
  pcall(vim.fn.mkdir, path_join(registry_root, "children"), "p")

  local parent_path = path_join(registry_root, "parent.id")
  local parent_id = read_first_line(parent_path)
  if not parent_id or parent_id == "" then
    parent_id = "parent:" .. stable_hash(root .. "\0" .. tostring(os.time()) .. "\0" .. tostring(vim.fn.getpid()))
    write_text_atomic(parent_path, parent_id)
  end

  local started_at = vim.g.pinvim_started_at or os.time()
  vim.g.pinvim_started_at = started_at
  local instance_id =
    string.format("nvim-%d-%s", vim.fn.getpid(), stable_hash(root .. "\0" .. tostring(started_at)):sub(1, 8))
  local instance_root = path_join(registry_root, "instances", instance_id)
  pcall(vim.fn.mkdir, instance_root, "p")

  local registry = {
    schema = "pinvim.registry.v1",
    workspace_id = workspace_id,
    workspace_hash = workspace_id,
    workspace_root = registry_root,
    project_root = root,
    parent_id = parent_id,
    parent_id_path = parent_path,
    instance_id = instance_id,
    instance_root = instance_root,
    pair_id = pair_id,
    children_root = path_join(registry_root, "children"),
    main_socket_path = path_join(instance_root, "main-" .. instance_id .. ".sock"),
    main_session_socket_path = path_join(registry_root, "main.sock"),
    main_session_intent_path = path_join(registry_root, "main.intent.json"),
    main_session_runtime_path = path_join(registry_root, "main.runtime.json"),
    main_intent_path = path_join(instance_root, "main.intent.json"),
    main_runtime_path = path_join(instance_root, "main.runtime.json"),
    launch_lock_path = path_join(registry_root, "main.launch.lock"),
    imported_legacy = false,
  }

  if not existed then
    local imported = legacy_registry_runtime(config)
    if imported then
      imported.workspace = { id = workspace_id, root = registry_root, projectRoot = root }
      imported.parent = { id = parent_id }
      write_json_atomic(registry.main_runtime_path, imported)
      registry.imported_legacy = true
    end
  end

  return registry
end

function Registry.main_target(registry)
  if not registry or not registry.parent_id then return nil, nil end
  if socket_exists(registry.main_socket_path) then return registry.main_socket_path, "registry-main" end
  return nil, "registry-main"
end

local function registry_base_record(registry, config)
  local identity = Transport.build_peer_identity(config)
  return {
    schema = "pinvim.registry.v1",
    writer = "nvim",
    role = "main",
    updatedAt = os.time(),
    pairId = registry.pair_id,
    workspace = {
      id = registry.workspace_id,
      hash = registry.workspace_hash,
      root = registry.workspace_root,
      projectRoot = registry.project_root,
    },
    parent = { id = registry.parent_id, path = registry.parent_id_path },
    instance = {
      id = registry.instance_id,
      root = registry.instance_root,
      pid = vim.fn.getpid(),
      pairId = registry.pair_id,
      tmux = identity.tmux,
      cwd = identity.cwd,
      projectRoot = identity.root,
    },
    editorService = {
      address = identity.nvimListenAddress,
      transport = "msgpack-rpc",
    },
  }
end

function Registry.write_main_intent(registry, runtime, config)
  if not registry then return false end
  local record = registry_base_record(registry, config)
  record.intent = {
    kind = "editor-main-session-view",
    desired = "present",
    socket = runtime.socket,
    socketSource = runtime.socket_source,
    linkMode = runtime.link_mode or config.transport.link_mode,
  }
  return write_json_atomic(registry.main_intent_path, record)
end

function Registry.write_main_session_intent(registry, runtime, config, socket_path, reason)
  if not registry then return false end
  local record = registry_base_record(registry, config)
  record.intent = {
    kind = "main-session",
    desired = "present",
    socket = socket_path or registry.main_socket_path,
    socketSource = socket_path and "registry-main" or runtime.socket_source,
    linkMode = "main",
    reason = reason or "panel",
  }
  return write_json_atomic(registry.main_session_intent_path, record)
end

function Registry.allocate_child(registry, config, opts)
  if not registry then return nil end
  opts = opts or {}
  local epoch = os.time()
  local pid = vim.fn.getpid()
  local seed = string.format("%s|%d|%d|%s", registry.instance_id, pid, epoch, tostring(opts.tag or ""))
  local child_id = string.format("child-%s-%d-%d", stable_hash(seed):sub(1, 8), pid, epoch)
  local child_root = path_join(registry.children_root, child_id)
  pcall(vim.fn.mkdir, child_root, "p")
  local child = {
    id = child_id,
    root = child_root,
    socket_path = path_join(child_root, "child.sock"),
    intent_path = path_join(child_root, "intent.json"),
    runtime_path = path_join(child_root, "runtime.json"),
  }
  local record = registry_base_record(registry, config)
  record.role = "child"
  record.intent = {
    kind = "child-session",
    desired = "present",
    childId = child_id,
    socket = child.socket_path,
    socketSource = "registry-child",
    linkMode = "child",
    reason = opts.reason or "split",
    createdAt = epoch,
    creatorPid = pid,
  }
  write_json_atomic(child.intent_path, record)
  return child
end

function Registry.cleanup_child(child)
  if not child or not child.root then return end
  pcall(vim.fn.delete, child.intent_path)
  pcall(vim.fn.delete, child.runtime_path)
  pcall(vim.fn.delete, child.socket_path)
  pcall(vim.uv.fs_rmdir, child.root)
end

function EditorService.setup(config, registry)
  local service = {
    enabled = config.editor_service.enabled ~= false,
    address = nil,
    transport = "msgpack-rpc",
    started = false,
    stale = false,
    last_error = nil,
  }

  if not service.enabled then return service end

  local current = vim.v.servername
  if current and current ~= "" then
    service.address = current
    service.started = true
  else
    local preferred = registry and registry.instance_root and path_join(registry.instance_root, "editor.sock") or nil
    local ok, address = pcall(function()
      if preferred then return vim.fn.serverstart(preferred) end
      return vim.fn.serverstart()
    end)
    if ok and address and address ~= "" then
      service.address = address
      service.started = true
    else
      service.stale = true
      service.last_error = tostring(address or "serverstart failed")
    end
  end

  if service.address and service.address ~= "" then
    editor_service_address = service.address
    vim.env.PINVIM_NVIM_LISTEN_ADDRESS = service.address
  end

  return service
end

function Registry.with_launch_lock(registry, fn)
  if not registry then return fn() end
  local lock_path = registry.launch_lock_path
  local ok = vim.uv.fs_mkdir(lock_path, 493)
  if not ok then
    local owner_path = path_join(lock_path, "owner.json")
    local owner_line = read_first_line(owner_path)
    local owner_ok, owner = pcall(vim.json.decode, owner_line or "")
    if owner_ok and owner and owner.pid and not pid_alive(owner.pid) then
      pcall(vim.fn.delete, owner_path)
      pcall(vim.uv.fs_rmdir, lock_path)
      ok = vim.uv.fs_mkdir(lock_path, 493)
    end
  end

  if not ok then
    vim.notify("pinvim: main launch already in progress", vim.log.levels.WARN)
    return false
  end

  write_json_atomic(path_join(lock_path, "owner.json"), {
    pid = vim.fn.getpid(),
    instanceId = registry.instance_id,
    parentId = registry.parent_id,
    acquiredAt = os.time(),
  })

  local success, result = xpcall(fn, debug.traceback)
  pcall(vim.fn.delete, path_join(lock_path, "owner.json"))
  pcall(vim.uv.fs_rmdir, lock_path)
  if not success then error(result) end
  return result
end

local function nvim_peer_manifest_path(config)
  local identity = Transport.build_peer_identity(config)
  local session = identity.tmux.session or "local"
  local window = identity.tmux.window or "0"
  local safe = string.format("nvim-%s-%s-%d", session, window, vim.fn.getpid()):gsub("[^%w_.-]", "_")
  return path_join(config.transport.manifest_dir, safe .. ".info")
end

local function write_nvim_peer_manifest(runtime, config)
  local ok_mkdir = pcall(vim.fn.mkdir, config.transport.manifest_dir, "p")
  if not ok_mkdir then return end

  local identity = Transport.build_peer_identity(config)
  local pair_id = vim.env.PINVIM_PAIR_ID or nil
  local manifest = {
    kind = "nvim",
    owner = "pinvim.lua",
    id = identity.id,
    pairId = pair_id,
    cwd = identity.cwd,
    root = identity.root,
    pid = vim.fn.getpid(),
    session = identity.tmux.session,
    window = identity.tmux.window,
    pane = identity.tmux.pane,
    tmux = identity.tmux,
    heartbeatAt = os.time(),
    linkMode = runtime.link_mode or config.transport.link_mode,
    parentId = identity.parentId,
    workspaceId = identity.workspaceId,
    instanceId = identity.instanceId,
    registryRoot = identity.registryRoot,
    role = identity.role,
    nvimListenAddress = identity.nvimListenAddress,
    editorService = {
      address = identity.nvimListenAddress,
      transport = "msgpack-rpc",
    },
    socket = runtime.socket or conn.socket_path,
    socketSource = runtime.socket_source or conn.socket_source,
    connected = conn.connected,
    peerId = runtime.last_hello_ack and runtime.last_hello_ack.peer and runtime.last_hello_ack.peer.id or nil,
    startedAt = vim.g.pinvim_started_at or os.time(),
  }

  peer_manifest_path = peer_manifest_path or nvim_peer_manifest_path(config)
  pcall(vim.fn.writefile, { vim.json.encode(manifest) }, peer_manifest_path)
end

local function stop_nvim_peer_manifest_timer()
  if peer_manifest_timer then
    peer_manifest_timer:stop()
    peer_manifest_timer:close()
    peer_manifest_timer = nil
  end
end

local function start_nvim_peer_manifest_timer(runtime, config)
  stop_nvim_peer_manifest_timer()
  vim.g.pinvim_started_at = vim.g.pinvim_started_at or os.time()
  write_nvim_peer_manifest(runtime, config)
  peer_manifest_timer = vim.uv.new_timer()
  if not peer_manifest_timer then return end
  peer_manifest_timer:start(5000, 5000, vim.schedule_wrap(function() write_nvim_peer_manifest(runtime, config) end))
end

local function cleanup_nvim_peer_manifest()
  stop_nvim_peer_manifest_timer()
  if peer_manifest_path then pcall(vim.fn.delete, peer_manifest_path) end
  peer_manifest_path = nil
end

local function detect_symbol_kind(bufnr, row, col)
  local ok, node = pcall(function() return vim.treesitter.get_node({ bufnr = bufnr, pos = { row - 1, col } }) end)
  if not ok or not node then return nil end

  local kind_map = {
    ["function"] = "function",
    ["function_declaration"] = "function",
    ["function_definition"] = "function",
    ["method"] = "method",
    ["method_declaration"] = "method",
    ["method_definition"] = "method",
    ["variable_declaration"] = "variable",
    ["local_variable"] = "variable",
    ["variable_assignment"] = "variable",
    ["assignment"] = "variable",
    ["type"] = "type",
    ["type_definition"] = "type",
    ["struct"] = "struct",
    ["struct_expression"] = "struct",
    ["enum"] = "enum",
    ["enum_definition"] = "enum",
    ["interface"] = "interface",
    ["interface_definition"] = "interface",
    ["module"] = "module",
    ["import"] = "import",
    ["call"] = "call",
    ["function_call"] = "call",
    ["field"] = "field",
    ["field_identifier"] = "field",
    ["property"] = "property",
    ["property_identifier"] = "property",
    ["parameter"] = "parameter",
    ["constant"] = "constant",
    ["constant_declaration"] = "constant",
    ["class"] = "class",
    ["class_definition"] = "class",
    ["trait"] = "trait",
  }

  local n = node
  while n do
    local mapped = kind_map[n:type()]
    if mapped then return mapped end
    n = n:parent()
  end

  return nil
end

local function detect_cursor_semantics(bufnr, cursor, word)
  local semantics = {}

  if word and word ~= "" then
    semantics.symbol_kind = detect_symbol_kind(bufnr, cursor[1], cursor[2])

    local ok_diag, diags = pcall(vim.diagnostic.get, bufnr, { lnum = cursor[1] - 1 })
    if ok_diag and diags and #diags > 0 then semantics.has_diagnostics = true end

    local clients = vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = bufnr })
      or (vim.lsp.buf_get_clients and vim.lsp.buf_get_clients(bufnr))
      or {}
    if type(clients) ~= "table" then clients = {} end
    semantics.lsp_active = #clients > 0
  end

  return semantics
end

function Transport.build_explicit_send(config, command_opts)
  command_opts = command_opts or {}
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

  local context = {
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
    userInput = command_opts.user_input or nil,
    modified = vim.bo[bufnr].modified,
  }

  local semantics = detect_cursor_semantics(bufnr, cursor, word)
  if semantics.symbol_kind then context.symbolKind = semantics.symbol_kind end
  if semantics.has_diagnostics then context.hasDiagnostics = true end
  if semantics.lsp_active then context.lspActive = true end

  return {
    type = config.protocol.explicit_send,
    delivery = command_opts.delivery or "attach",
    context = context,
  }
end

local function editor_service_buffers_for_path(file)
  local normalized = normalize_path(file)
  if not normalized then return {} end
  local matches = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name ~= "" and same_path(name, normalized) then table.insert(matches, bufnr) end
  end
  return matches
end

local function editor_service_reload_file(file)
  local normalized = normalize_path(file)
  local response = {
    ok = true,
    path = normalized,
    reloaded = {},
    conflicts = {},
    missing = {},
  }
  if not normalized then return response end

  local bufs = editor_service_buffers_for_path(normalized)
  if #bufs == 0 then
    table.insert(response.missing, { path = normalized, reason = "buffer not open" })
    return response
  end

  local current = vim.api.nvim_get_current_buf()
  for _, bufnr in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    local modified = vim.bo[bufnr].modified == true
    local entry = {
      bufnr = bufnr,
      path = name,
      current = bufnr == current,
      modified = modified,
    }

    if modified then
      table.insert(response.conflicts, entry)
    else
      local checktime_ok, checktime_err = pcall(vim.api.nvim_buf_call, bufnr, function()
        vim.cmd("checktime")
        if vim.api.nvim_get_current_buf() == bufnr and vim.bo[bufnr].modified == false and name ~= "" then
          pcall(vim.cmd, "edit")
        end
      end)
      entry.reloaded = checktime_ok
      if not checktime_ok then entry.error = tostring(checktime_err) end
      table.insert(response.reloaded, entry)
    end
  end

  if #response.conflicts > 0 then
    local label = vim.fn.fnamemodify(normalized, ":~:.")
    local count = #response.conflicts
    vim.notify(
      string.format(
        "pinvim: external change left %d dirty buffer%s untouched (%s)",
        count,
        count == 1 and "" or "s",
        label
      ),
      vim.log.levels.WARN
    )
  end

  return response
end

local function diagnostic_to_table(diagnostic)
  local severity_names = {
    [vim.diagnostic.severity.ERROR] = "ERROR",
    [vim.diagnostic.severity.WARN] = "WARN",
    [vim.diagnostic.severity.INFO] = "INFO",
    [vim.diagnostic.severity.HINT] = "HINT",
  }
  return {
    bufnr = diagnostic.bufnr,
    lnum = diagnostic.lnum + 1,
    col = diagnostic.col,
    end_lnum = diagnostic.end_lnum and (diagnostic.end_lnum + 1) or nil,
    end_col = diagnostic.end_col,
    severity = severity_names[diagnostic.severity] or tostring(diagnostic.severity or ""),
    source = diagnostic.source,
    code = diagnostic.code,
    message = diagnostic.message,
  }
end

function EditorService.current_context(config)
  local payload = Transport.build_explicit_send(config, { delivery = "attach" })
  return payload.context
end

function EditorService.current_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)
  local result = {}
  for _, diagnostic in ipairs(diagnostics or {}) do
    table.insert(result, diagnostic_to_table(diagnostic))
  end
  return result
end

function EditorService.handle_request(api, config, method, params)
  params = params or {}
  if method == "status" then
    local info = api.info()
    return {
      ok = true,
      editor_service = info.editor_service,
      state = info.state,
      registry = info.registry,
      context = EditorService.current_context(config),
    }
  end

  if method == "context.current" then return EditorService.current_context(config) end

  if method == "diagnostics.current" then return EditorService.current_diagnostics() end

  if method == "open_file" or method == "reveal_file" then
    local file = params.path or params.file or params.absFile
    if type(file) ~= "string" or file == "" then error("open_file requires path") end
    vim.cmd.edit(vim.fn.fnameescape(file))
    if params.line then
      local line = math.max(1, tonumber(params.line) or 1)
      local col = math.max(0, tonumber(params.col) or 0)
      pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
    end
    return EditorService.current_context(config)
  end

  if method == "reload_buffer" then
    local file = params.path or params.file or params.absFile
    if type(file) == "string" and file ~= "" then
      local result = editor_service_reload_file(file)
      result.context = EditorService.current_context(config)
      return result
    end
    if vim.bo.modified then
      return {
        ok = true,
        conflicts = {
          {
            bufnr = vim.api.nvim_get_current_buf(),
            path = vim.api.nvim_buf_get_name(0),
            current = true,
            modified = true,
          },
        },
        reloaded = {},
        missing = {},
        context = EditorService.current_context(config),
      }
    end
    vim.cmd("checktime")
    if vim.bo.modified == false and vim.api.nvim_buf_get_name(0) ~= "" then pcall(vim.cmd, "edit") end
    return {
      ok = true,
      conflicts = {},
      reloaded = {
        {
          bufnr = vim.api.nvim_get_current_buf(),
          path = vim.api.nvim_buf_get_name(0),
          current = true,
          modified = false,
          reloaded = true,
        },
      },
      missing = {},
      context = EditorService.current_context(config),
    }
  end

  if method == "refresh_diagnostics" then
    pcall(vim.diagnostic.show, nil, 0)
    return EditorService.current_diagnostics()
  end

  if method == "checktime" then
    vim.cmd("checktime")
    return { ok = true }
  end

  if method == "review.open" then
    -- Pi-side /review -> open :PiReview in the paired Nvim (ticket dot-xooa).
    -- Delegates to pinvim.review so scope detection stays Nvim-local.
    local scope = params.scope or params.args or "uncommitted"
    local ok, review = pcall(require, "pinvim.review")
    if not ok then return { ok = false, error = "pinvim.review not available" } end
    local ran = review.run(scope, { cwd = params.cwd })
    return { ok = true, ran = ran, metadata = review.metadata() }
  end

  error("unsupported pinvim editor method: " .. tostring(method))
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
        "parentId",
        "workspaceId",
        "instanceId",
        "registryRoot",
        "role",
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

local function stop_ephemeral_watch_timer()
  if conn.ephemeral_watch_timer then
    conn.ephemeral_watch_timer:stop()
    conn.ephemeral_watch_timer:close()
    conn.ephemeral_watch_timer = nil
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
  stop_ephemeral_watch_timer()

  if conn.pipe then
    if not conn.pipe:is_closing() then
      conn.pipe:read_stop()
      conn.pipe:close()
    end
    conn.pipe = nil
  end

  conn.connected = false
  conn.connecting = false
  conn.socket_path = nil
  conn.socket_source = nil
  conn.read_buffer = ""

  State.patch(runtime, {
    connected = false,
    connecting = false,
    lifecycle = "disconnected",
  })
end

local function schedule_reconnect(api, runtime, config)
  if conn.reconnect_timer then return end

  -- Ephemeral sockets that disappeared should not be reconnected;
  -- restore the previous alive target instead.
  if is_ephemeral_socket(conn.socket_path) and not socket_exists(conn.socket_path) then
    conn.reconnect_attempts = config.connection.reconnect_max_retries + 1
    State.patch(runtime, {
      lifecycle = "ephemeral_closed",
      last_error = "ephemeral socket closed",
    })
    vim.schedule(function() api.restore_previous_target(conn.socket_path, { notify = true }) end)
    return
  end

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

local function start_ephemeral_watch_timer(api, runtime, config)
  stop_ephemeral_watch_timer()
  if not is_ephemeral_socket(conn.socket_path) then return end

  conn.ephemeral_watch_timer = vim.uv.new_timer()
  conn.ephemeral_watch_timer:start(
    2000,
    2000,
    vim.schedule_wrap(function()
      if not conn.socket_path then
        stop_ephemeral_watch_timer()
        return
      end
      if not is_ephemeral_socket(conn.socket_path) then
        stop_ephemeral_watch_timer()
        return
      end
      if not socket_exists(conn.socket_path) then
        stop_ephemeral_watch_timer()
        connection_disconnect(runtime)
        api.restore_previous_target(conn.socket_path, { notify = true })
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
    vim.schedule_wrap(
      function() api.send_payload(Transport.build_heartbeat(runtime, config), { silent = true, auto_connect = false }) end
    )
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

    local meta = record_target_history(config, socket_path, source)
    State.patch(runtime, {
      connected = true,
      connecting = false,
      socket = socket_path,
      socket_source = source,
      link_mode = meta and meta.link_mode or runtime.link_mode,
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
      start_ephemeral_watch_timer(api, runtime, config)
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

    vim.ui.input({ prompt = "pinvim prompt: " }, function(input) send_message(input) end)
  end

  local function compose_add_command(command_opts) api.compose_add(command_opts) end

  local function compose_flush_command(command_opts)
    api.compose_flush(command_opts.args ~= "" and command_opts.args or nil)
  end

  local function compose_clear_command() api.compose_clear() end

  local function compose_comment_command(command_opts) api.compose_comment(command_opts) end

  local function status_command()
    local info = api.info()
    local health = api.health()
    local lines = {
      "pinvim status",
      string.format("socket: %s", info.target.socket_path or "(none)"),
      string.format("socket source: %s", info.target.source),
      string.format("workspace id: %s", info.registry.workspace_id),
      string.format("parent id: %s", info.registry.parent_id),
      string.format("instance id: %s", info.registry.instance_id),
      string.format("registry root: %s", info.registry.workspace_root),
      string.format("editor service: %s", info.editor_service.address or "(none)"),
      string.format("editor service stale: %s", tostring(info.editor_service.stale)),
      string.format("connected: %s", tostring(info.state.connected)),
      string.format("connecting: %s", tostring(info.state.connecting)),
      string.format("link mode: %s", info.state.link_mode or "auto"),
      string.format("restored target: %s", info.state.restored_target and "yes" or "no"),
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
      string.format("editor service: %s", health.editor_service.address or "(none)"),
      string.format("editor service stale: %s", tostring(health.editor_service.stale)),
    }
    vim.notify(table.concat(lines, "\n"), level)
  end

  local function list_manifest_candidates(manifest_dir)
    if not manifest_dir or vim.fn.isdirectory(manifest_dir) == 0 then return {} end
    local entries = vim.fn.globpath(manifest_dir, "*.info", false, true) or {}
    table.sort(entries)
    return entries
  end

  local function tmux_pane_info()
    if vim.env.TMUX == nil or vim.env.TMUX == "" then return nil end
    local function tmux(fmt)
      local out = vim.fn.system({ "tmux", "display-message", "-p", fmt })
      if vim.v.shell_error ~= 0 then return nil end
      return vim.trim(out)
    end
    return {
      session = tmux("#{session_name}"),
      window = tmux("#{window_name}"),
      window_index = tmux("#{window_index}"),
      pane = tmux("#{pane_id}"),
    }
  end

  local function doctor_command()
    -- Read-only diagnostics: must not trigger connect or discovery side effects.
    local info = api.info()
    local health = api.health()
    local svc = info.editor_service or {}
    local registry_info = info.registry or {}
    local target = info.target or {}
    local state = info.state or {}
    local ok = svc.address ~= nil and not svc.stale
    local lines = {
      ok and "pinvim doctor: ok" or "pinvim doctor: attention needed",
      string.format("lifecycle: %s", info.lifecycle or "(unknown)"),
      string.format("workspace id: %s", registry_info.workspace_id or "(none)"),
      string.format("parent id: %s", registry_info.parent_id or "(none)"),
      string.format("instance id: %s", registry_info.instance_id or "(none)"),
      string.format("registry root: %s", registry_info.workspace_root or "(none)"),
      string.format("peer socket: %s", target.socket_path or "(none)"),
      string.format("target source: %s", target.source or "(none)"),
      string.format("link mode: %s", state.link_mode or target.link_mode or "auto"),
      string.format("peer connected: %s", tostring(state.connected)),
      string.format("peer id: %s", health.peer_id or "(none)"),
      string.format("heartbeat age: %s", health.heartbeat_age and (health.heartbeat_age .. "s") or "(none)"),
      string.format("hello acked: %s", tostring(health.hello_ack)),
      string.format("restored target: %s", state.restored_target and "yes" or "no"),
      string.format("editor service: %s", svc.address or "(none)"),
      string.format("editor transport: %s", svc.transport or "(none)"),
      string.format("editor service stale: %s", tostring(svc.stale)),
    }
    if svc.last_error then table.insert(lines, "editor error: " .. svc.last_error) end

    local tmux = tmux_pane_info()
    if tmux then
      table.insert(
        lines,
        string.format(
          "tmux: %s @ %s/%s (%s)",
          tmux.session or "?",
          tmux.window_index or "?",
          tmux.window or "?",
          tmux.pane or "?"
        )
      )
    else
      table.insert(lines, "tmux: (not in tmux)")
    end

    local manifests = list_manifest_candidates(target.manifest_dir)
    table.insert(lines, string.format("manifest candidates: %d (%s)", #manifests, target.manifest_dir or "(none)"))
    for i = 1, math.min(#manifests, 5) do
      table.insert(lines, "  - " .. manifests[i])
    end
    if #manifests > 5 then table.insert(lines, string.format("  ... +%d more", #manifests - 5)) end

    if registry_info.workspace_root then
      for _, rel in ipairs({ "parent.id", "workspace.json" }) do
        local p = registry_info.workspace_root .. "/" .. rel
        if vim.fn.filereadable(p) == 1 then table.insert(lines, "registry file: " .. p) end
      end
    end
    if registry_info.instance_root then
      for _, rel in ipairs({ "main.intent.json", "main.runtime.json", "main.session.intent.json", "launch.lock" }) do
        local p = registry_info.instance_root .. "/" .. rel
        if vim.fn.filereadable(p) == 1 then table.insert(lines, "registry file: " .. p) end
      end
    end

    -- Cleanup hints
    if svc.stale then
      table.insert(lines, "hint: editor service stale; restart nvim or check PINVIM_NVIM_LISTEN_ADDRESS")
    end
    if state.connected and health.heartbeat_age and health.heartbeat_age > 120 then
      table.insert(lines, "hint: peer heartbeat is older than 120s; pi side may be wedged")
    end
    if target.socket_path and not state.connected then
      table.insert(lines, "hint: socket resolved but not connected; run :PiTarget auto or check pi process")
    end

    vim.notify(table.concat(lines, "\n"), ok and vim.log.levels.INFO or vim.log.levels.WARN)
  end

  local function previous_command() api.restore_previous_target(conn.socket_path or runtime.socket, { notify = true }) end

  local function restore_command() api.restore_previous_target(conn.socket_path or runtime.socket, { notify = true }) end

  local function target_command(command_opts)
    local arg = command_opts.args and vim.trim(command_opts.args) or ""
    if arg == "" then
      if Transport.discovery_stale() then
        Transport.refresh_discovery(config, function()
          vim.schedule(function() vim.notify("pinvim: discovery refreshed", vim.log.levels.INFO) end)
        end)
      end
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

  vim.api.nvim_create_user_command("PiInfo", function()
    local info = api.info()
    local lines = {
      "pinvim state",
      string.format("lifecycle: %s", info.lifecycle),
      string.format("file: %s", info.state.file or "(none)"),
      string.format("root: %s", info.state.root or "(none)"),
      string.format("socket: %s", info.target.socket_path or "(none)"),
      string.format("socket source: %s", info.target.source),
      string.format("workspace id: %s", info.registry.workspace_id),
      string.format("parent id: %s", info.registry.parent_id),
      string.format("instance id: %s", info.registry.instance_id),
      string.format("registry root: %s", info.registry.workspace_root),
      string.format("editor service: %s", info.editor_service.address or "(none)"),
      string.format("editor service stale: %s", tostring(info.editor_service.stale)),
      string.format("connected: %s", tostring(info.state.connected)),
      string.format("connecting: %s", tostring(info.state.connecting)),
      string.format("link mode: %s", info.state.link_mode or info.target.link_mode),
      string.format("restored target: %s", info.state.restored_target and "yes" or "no"),
      string.format("peer frames enabled: %s", tostring(info.target.peer_frames_enabled)),
      string.format("protocol: %s", info.handshake.protocol),
      "implicit context: removed; use gps/gpa/:PiSend explicit context",
      string.format("cutover: %s", info.handshake.compatibility.cutover),
      "hello payload:",
      vim.inspect(info.handshake.send),
    }

    if info.state.last_error then table.insert(lines, "last error: " .. info.state.last_error) end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show pinvim state + target" })

  vim.api.nvim_create_user_command("PiStatus", status_command, {
    desc = "Show current pinvim link status",
  })

  vim.api.nvim_create_user_command("PiHealth", health_command, {
    desc = "Check pinvim hello/heartbeat health",
  })

  vim.api.nvim_create_user_command("PiDoctor", doctor_command, {
    desc = "Diagnose pinvim peer and editor-service transports",
  })

  vim.api.nvim_create_user_command("PiPrompt", prompt_command, {
    nargs = "*",
    desc = "Send raw prompt through pinvim.ts",
  })

  vim.api.nvim_create_user_command("PiSend", function(command_opts) api.send_explicit(command_opts) end, {
    range = true,
    desc = "Send explicit selection or cursor context through pinvim.ts",
  })

  vim.api.nvim_create_user_command("PiTarget", target_command, {
    nargs = "?",
    complete = "file",
    desc = "Get/set buffer-local pinvim target socket",
  })

  vim.api.nvim_create_user_command("PiPrevious", previous_command, {
    desc = "Switch to previous alive parked pinvim target",
  })

  vim.api.nvim_create_user_command("PiRestore", restore_command, {
    desc = "Restore previous alive parked pinvim target",
  })

  vim.api.nvim_create_user_command("PiSessions", function() api.select_session() end, {
    desc = "Select pinvim session from manifests",
  })

  vim.api.nvim_create_user_command("PiPanel", function(command_opts)
    if command_opts.bang then
      api.toggle_panel()
    else
      api.ensure_panel_visible()
    end
  end, {
    bang = true,
    desc = "Ensure pi split visible (! toggles)",
  })

  vim.api.nvim_create_user_command("PiSplit", function() api.spawn_ephemeral_split() end, {
    desc = "Spawn fresh ephemeral pi split",
  })

  vim.api.nvim_create_user_command("PiAdd", compose_add_command, {
    range = true,
    desc = "Add selection or file reference to pinvim compose queue",
  })

  vim.api.nvim_create_user_command("PiFlush", compose_flush_command, {
    nargs = "*",
    desc = "Send pinvim compose queue through pinvim.ts",
  })

  vim.api.nvim_create_user_command("PiClear", compose_clear_command, {
    desc = "Clear pinvim compose queue",
  })

  vim.api.nvim_create_user_command("PiComment", compose_comment_command, {
    range = true,
    desc = "Annotate selection or cursor line and add to pinvim compose queue",
  })

  vim.api.nvim_create_user_command("PiComments", function() api.compose_comments_list() end, {
    desc = "List queued pinvim comments in quickfix/trouble",
  })

  vim.api.nvim_create_user_command("PiReview", function(command_opts)
    local args = vim.trim(command_opts.args or "")
    if args == "" then args = "uncommitted" end
    require("pinvim.review").run(args)
  end, {
    nargs = "?",
    complete = function() return require("pinvim.review").complete() end,
    desc = "Open worktree-aware review (uncommitted|unpushed|branch|pr|ticket|worktrees)",
  })

  vim.keymap.set(
    "n",
    "gpc",
    function() api.compose_comment() end,
    { silent = true, desc = "pinvim comment on cursor line (queued)" }
  )

  vim.keymap.set(
    "x",
    "gpc",
    function() api.compose_comment({ range = true }) end,
    { silent = true, desc = "pinvim comment on selection (queued)" }
  )

  vim.keymap.set(
    "n",
    "gpR",
    function() api.restore_previous_target(nil, { notify = true }) end,
    { silent = true, desc = "pinvim restore previous parked target" }
  )

  vim.keymap.set("n", "<leader>grr", function() require("pinvim.review").run("uncommitted") end, { desc = "review: uncommitted" })
  vim.keymap.set("n", "<leader>gru", function() require("pinvim.review").run("unpushed") end, { desc = "review: unpushed" })
  vim.keymap.set("n", "<leader>grb", function() require("pinvim.review").run("branch") end, { desc = "review: branch vs base" })
  vim.keymap.set("n", "<leader>grp", function() require("pinvim.review").run("pr") end, { desc = "review: GitHub PR (guh)" })
  vim.keymap.set("n", "<leader>grt", function() require("pinvim.review").run("ticket") end, { desc = "review: ticket-scoped" })
  vim.keymap.set("n", "<leader>grw", function() require("pinvim.review").run("worktrees") end, { desc = "review: pick worktree" })

  local function spawn_ephemeral_with_cursor_context() api.spawn_ephemeral_split({ send_explicit_after = true }) end

  local function spawn_ephemeral_with_selection_context()
    api.spawn_ephemeral_split({ send_explicit_after = true, command_opts = { range = true } })
  end

  vim.keymap.set(
    "n",
    "gpp",
    spawn_ephemeral_with_cursor_context,
    { silent = true, desc = "pinvim spawn/focus child pi split and send cursor context" }
  )

  vim.keymap.set(
    "x",
    "gpp",
    spawn_ephemeral_with_selection_context,
    { silent = true, desc = "pinvim spawn/focus child pi split and send selection" }
  )

  local function pi_visible_in_current_window()
    if not vim.env.TMUX then return false end
    local cmd = {
      "tmux",
      "list-panes",
      "-F",
      "#{pane_title}\t#{pane_current_command}\t#{pane_start_command}",
    }
    if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
      cmd = {
        "tmux",
        "list-panes",
        "-t",
        vim.env.TMUX_PANE,
        "-F",
        "#{pane_title}\t#{pane_current_command}\t#{pane_start_command}",
      }
    end
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then return false end
    for line in tostring(out):gmatch("[^\n]+") do
      local title, cmd, start = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
      title = title or ""
      cmd = cmd or ""
      start = start or ""
      if
        title:sub(1, 2) == "π"
        or cmd == "pi"
        or cmd == "pinvim"
        or start:find("pinvim", 1, true)
        or start:find(" pi", 1, true)
      then
        return true
      end
    end
    return false
  end

  local function toggle_panel_with_context(command_opts)
    local was_visible = pi_visible_in_current_window()
    if was_visible then
      api.toggle_panel()
      return
    end
    -- Capture selection/cursor context BEFORE the tmux split steals focus.
    local payload =
      Transport.build_explicit_send(config, vim.tbl_extend("force", command_opts or {}, { delivery = "attach" }))
    api.clear_stale_target(true)
    api.ensure_panel_visible()
    -- First-launch pi bootstrap can take several seconds before the instance
    -- main socket binds; send_explicit_payload polls until connected or budget elapses.
    api.send_explicit_payload(payload, { focus_after = false, await_connect_ms = 8000 })
  end

  vim.keymap.set(
    "n",
    "<C-p>",
    function() toggle_panel_with_context() end,
    { silent = true, desc = "pinvim toggle main PiPanel (attach cursor context on open)" }
  )

  vim.keymap.set(
    "x",
    "<C-p>",
    function() toggle_panel_with_context({ range = true }) end,
    { silent = true, desc = "pinvim toggle main PiPanel (attach selection on open)" }
  )

  vim.keymap.set(
    "n",
    "gps",
    function() api.prompt_explicit() end,
    { silent = true, desc = "pinvim send cursor context with prompt" }
  )

  vim.keymap.set(
    "x",
    "gps",
    function() api.prompt_explicit({ range = true }) end,
    { silent = true, desc = "pinvim send selection with prompt" }
  )

  vim.keymap.set("n", "gpa", function() api.send_explicit() end, { silent = true, desc = "pinvim send cursor context" })

  vim.keymap.set(
    "x",
    "gpa",
    function() api.send_explicit({ range = true }) end,
    { silent = true, desc = "pinvim send selection" }
  )
end

function Autocmds.setup(api, config)
  local group = vim.api.nvim_create_augroup("mega.pinvim", { clear = true })
  local refresh_timer = nil

  local function stop_refresh_timer()
    if refresh_timer then
      refresh_timer:stop()
      refresh_timer:close()
      refresh_timer = nil
    end
  end

  local function schedule_refresh(delay_ms)
    stop_refresh_timer()
    refresh_timer = vim.uv.new_timer()
    if not refresh_timer then return end
    refresh_timer:start(
      delay_ms or 150,
      0,
      vim.schedule_wrap(function()
        stop_refresh_timer()
        api.refresh_buffer_state()
        api.ensure_connected(true)
      end)
    )
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = group,
    callback = function(args)
      if args.buf and vim.bo[args.buf].buftype ~= "" then return end
      schedule_refresh(150)
    end,
  })

  vim.api.nvim_create_autocmd({ "VimEnter", "BufReadPost" }, {
    group = group,
    callback = function(args)
      if args.buf and vim.bo[args.buf].buftype ~= "" then return end
      schedule_refresh(250)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      stop_refresh_timer()
      cleanup_nvim_peer_manifest()
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
  local registry = Registry.setup(config)
  config.registry = registry
  local editor_service = EditorService.setup(config, registry)
  config.editor_service_state = editor_service

  local api = {}
  api.runtime = runtime
  api.registry = registry
  api.editor_service = editor_service

  function api.editor_rpc(method, params) return EditorService.handle_request(api, config, method, params) end

  local function current_peer()
    if runtime.last_hello_ack and runtime.last_hello_ack.peer then return runtime.last_hello_ack.peer end
    if runtime.last_hello and runtime.last_hello.peer then return runtime.last_hello.peer end
    return runtime.peer
  end

  function api.restore_previous_target(exclude_socket, restore_opts)
    restore_opts = restore_opts or {}
    local previous = previous_alive_parked_target(exclude_socket)
    if not previous then
      if restore_opts.notify ~= false then
        vim.notify("pinvim: no previous alive parked target", vim.log.levels.WARN)
      end
      return false
    end

    vim.b.pi_target_socket = previous.path
    connection_disconnect(runtime)
    record_target_history(config, previous.path, "history-restore")
    State.patch(runtime, {
      socket = previous.path,
      socket_source = "history-restore",
      link_mode = "parked",
      restored_target = true,
      restored_from = exclude_socket,
      last_error = nil,
    })

    if restore_opts.notify ~= false then
      vim.notify("pinvim: restored parked target " .. vim.fs.basename(previous.path), vim.log.levels.INFO)
    end
    api.refresh_buffer_state()
    api.ensure_connected(true)
    return true
  end

  function api.previous_target()
    local current = conn.socket_path or runtime.socket
    return api.restore_previous_target(current, { notify = true })
  end

  function api.clear_stale_target(notify_user)
    local buf_target = vim.b.pi_target_socket
    if not buf_target or socket_exists(buf_target) then return false end

    vim.b.pi_target_socket = nil
    if conn.socket_path == buf_target then connection_disconnect(runtime) end

    if api.restore_previous_target(buf_target, { notify = notify_user ~= false }) then return true end

    State.patch(runtime, {
      socket = nil,
      socket_source = "buffer",
      link_mode = "auto",
      restored_target = false,
      restored_from = nil,
      last_error = "stale buffer target: " .. buf_target,
    })

    if notify_user ~= false then vim.notify("pinvim: stale buffer target cleared", vim.log.levels.WARN) end
    return true
  end

  function api.refresh_buffer_state()
    api.clear_stale_target(false)
    local current = vim.api.nvim_buf_get_name(0)
    local socket_path, source = Transport.resolve_socket(config)
    local meta = socket_path and record_target_history(config, socket_path, source) or nil
    State.set_buffer(runtime, {
      file = current ~= "" and vim.fn.fnamemodify(current, ":~:.") or nil,
      abs_file = current ~= "" and current or nil,
      cwd = vim.uv.cwd(),
      root = config.resolve_root(),
      socket = socket_path,
      socket_source = source,
      link_mode = meta and meta.link_mode or config.transport.link_mode,
    })
    Handshake.refresh(runtime, Transport, config)
    Registry.write_main_intent(registry, runtime, config)
  end

  function api.ensure_connected(force_target_check)
    api.clear_stale_target(false)
    local active_socket = conn.socket_path or runtime.socket
    if active_socket and not socket_exists(active_socket) then
      connection_disconnect(runtime)
      api.restore_previous_target(active_socket, { notify = true })
    end
    local socket_path, source = Transport.resolve_socket(config)

    if Transport.auto_discovery_enabled(config) and Transport.discovery_stale() then
      Transport.refresh_discovery(config, function()
        vim.schedule(function()
          api.refresh_buffer_state()
          api.ensure_connected(force_target_check)
        end)
      end)
    end

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
        lifecycle = Transport.discovery_stale() and "discovering_socket" or "waiting_for_socket",
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
      local meta = record_target_history(config, socket_path, "manual")
      State.patch(runtime, {
        link_mode = meta and meta.link_mode or "manual",
        restored_target = false,
        restored_from = nil,
      })
      vim.notify("pinvim: target set " .. vim.fs.basename(socket_path), vim.log.levels.INFO)
    else
      State.patch(runtime, {
        link_mode = "auto",
        restored_target = false,
        restored_from = nil,
      })
      vim.notify("pinvim: target cleared; auto-discovery active", vim.log.levels.INFO)
    end

    api.refresh_buffer_state()
    api.ensure_connected(true)
    return true
  end

  function api.list_targets(opts) return Transport.list_targets(config, opts) end

  function api.select_session()
    if Transport.discovery_stale() then
      Transport.refresh_discovery(config, function()
        vim.schedule(function() api.select_session() end)
      end)
      vim.notify("pinvim: discovering pi sessions", vim.log.levels.INFO)
      return false
    end

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
      local reason = table.concat(target.reasons or {}, ", ")
      local age = target.activity and target.activity > 0 and math.max(os.time() - target.activity, 0) or nil
      local meta = string.format("score %d", target.score or 0)
      if age then meta = string.format("%s · %ds", meta, age) end
      if reason ~= "" then meta = string.format("%s · %s", meta, reason) end
      if target.cwd and target.cwd ~= "" then meta = string.format("%s · %s", meta, target.cwd) end
      table.insert(items, {
        text = string.format("%s · %s", label, meta),
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

  function api.spawn_ephemeral_split(spawn_opts)
    spawn_opts = spawn_opts or {}
    if not vim.env.TMUX then
      vim.notify("pinvim: child split requires tmux", vim.log.levels.WARN)
      return false
    end

    local payload = nil
    if spawn_opts.send_explicit_after then
      local command_opts = vim.tbl_extend("force", spawn_opts.command_opts or {}, { delivery = "prompt" })
      payload = Transport.build_explicit_send(config, command_opts)
    end

    local function select_target(socket_path, source)
      vim.b.pi_target_socket = socket_path
      vim.b.pi_child_socket = socket_path
      vim.b.pi_ephemeral_socket = socket_path -- back-compat alias
      local meta = record_target_history(config, socket_path, source)
      State.patch(runtime, {
        socket = socket_path,
        socket_source = source,
        link_mode = "child",
        restored_target = false,
        restored_from = nil,
        last_error = nil,
      })
      return meta
    end

    local function connect_and_maybe_send(socket_path)
      connection_disconnect(runtime)
      connection_connect(api, runtime, config, socket_path, "child")
      if payload then
        vim.defer_fn(function()
          api.send_explicit_payload(payload, { focus_after = false })
          focus_socket_pane(config, socket_path)
        end, 150)
      end
    end

    local existing = vim.b.pi_child_socket or vim.b.pi_ephemeral_socket
    if existing and socket_exists(existing) and focus_socket_pane(config, existing) then
      select_target(existing, "child")
      connect_and_maybe_send(existing)
      vim.notify("pinvim: focused child split " .. vim.fs.basename(existing), vim.log.levels.INFO)
      return true
    end

    -- Allocate an explicit child session under the registry. Falls back to
    -- legacy ephemeral-socket basename when no registry exists (headless edge).
    local child = registry and Registry.allocate_child(registry, config, { tag = vim.b.pi_target_socket or "" })
    local child_socket = child and child.socket_path or generate_ephemeral_socket_path(config)
    local child_id = child and child.id or vim.fs.basename(child_socket):gsub("%.sock$", "")

    -- Record previous target before switching
    local prev_socket = conn.socket_path or runtime.socket
    if prev_socket and socket_exists(prev_socket) then
      record_target_history(config, prev_socket, conn.socket_source or runtime.socket_source or "auto")
    end

    local pane_id = vim.env.TMUX_PANE or ""
    if pane_id == "" then pane_id = vim.fn.trim(vim.fn.system({ "tmux", "display-message", "-p", "#{pane_id}" })) end
    local cmd = { "pimux", "--new", "--socket", child_socket }
    local job_env = {
      PINVIM_PARENT_ID = registry and registry.parent_id or nil,
      PINVIM_WORKSPACE_ID = registry and registry.workspace_id or nil,
      PINVIM_INSTANCE_ID = registry and registry.instance_id or nil,
      PINVIM_REGISTRY_ROOT = registry and registry.workspace_root or nil,
      PINVIM_SESSION_ROLE = "child",
      PINVIM_PAIR_ID = registry and registry.pair_id or vim.env.PINVIM_PAIR_ID,
      PINVIM_SESSION_ID = child_id,
      PI_SOCKET = child_socket,
      TMUX = vim.env.TMUX,
      TMUX_PANE = vim.env.TMUX_PANE,
      PATH = vim.env.PATH,
    }
    if pane_id ~= "" then job_env.PIMUX_PANE = pane_id end
    local job = vim.fn.jobstart(cmd, { detach = true, env = job_env })
    if job <= 0 then
      vim.notify("pinvim: child split spawn failed", vim.log.levels.ERROR)
      if child then Registry.cleanup_child(child) end
      return false
    end

    -- Set buffer-local target to the new child socket
    select_target(child_socket, "child")

    vim.notify("pinvim: child split " .. child_id, vim.log.levels.INFO)

    -- Wait briefly for the pi process to create the socket, then connect
    vim.defer_fn(function()
      if socket_exists(child_socket) then
        connect_and_maybe_send(child_socket)
      else
        -- Poll a few times for socket to appear
        local attempts = 0
        local poll
        poll = vim.schedule_wrap(function()
          attempts = attempts + 1
          if socket_exists(child_socket) then
            connect_and_maybe_send(child_socket)
          elseif attempts < 20 then
            vim.defer_fn(poll, 150)
          else
            vim.notify("pinvim: child socket not created", vim.log.levels.WARN)
            if child then Registry.cleanup_child(child) end
          end
        end)
        vim.defer_fn(poll, 150)
      end
    end, 200)

    return true
  end

  function api.run_panel_command(ensure_visible)
    if not vim.env.TMUX then
      vim.notify("pinvim: tmux split unavailable outside tmux", vim.log.levels.WARN)
      return false
    end

    local socket_path = registry and registry.main_socket_path or api.get_target()
    local cmd = { "pimux" }
    if ensure_visible then table.insert(cmd, "--ensure") end
    if socket_path then
      table.insert(cmd, "--socket")
      table.insert(cmd, socket_path)
    end

    local pane_id = vim.env.TMUX_PANE or ""
    if pane_id == "" then pane_id = vim.fn.trim(vim.fn.system({ "tmux", "display-message", "-p", "#{pane_id}" })) end
    local job_env = {
      PIMUX_FROM_NVIM = "1",
      PI_STATE_DIR = config.transport.state_dir,
      PINVIM_PARENT_ID = registry and registry.parent_id or nil,
      PINVIM_WORKSPACE_ID = registry and registry.workspace_id or nil,
      PINVIM_INSTANCE_ID = registry and registry.instance_id or nil,
      PINVIM_REGISTRY_ROOT = registry and registry.workspace_root or nil,
      PINVIM_PAIR_ID = registry and registry.pair_id or vim.env.PINVIM_PAIR_ID,
      PINVIM_SESSION_ROLE = "main",
      PINVIM_LINK_MODE = "main",
      PI_SOCKET = socket_path,
      TMUX = vim.env.TMUX,
      TMUX_PANE = vim.env.TMUX_PANE,
      PATH = vim.env.PATH,
    }
    if pane_id ~= "" then job_env.PIMUX_PANE = pane_id end
    local job_opts = { detach = true, env = job_env }

    local function launch()
      if registry and socket_path then
        Registry.write_main_session_intent(registry, runtime, config, socket_path, "panel")
      end
      local needs_registration = socket_path and not socket_exists(socket_path)
      if needs_registration and vim.system then
        local result = vim.system(cmd, { env = job_env, text = true }):wait()
        if result.code ~= 0 then
          vim.notify("pinvim: pimux failed", vim.log.levels.ERROR)
          return false
        end
      else
        local job = vim.fn.jobstart(cmd, job_opts)
        if job <= 0 then
          vim.notify("pinvim: pimux failed", vim.log.levels.ERROR)
          return false
        end
      end

      if socket_path then
        vim.b.pi_target_socket = socket_path
        State.patch(runtime, {
          socket = socket_path,
          socket_source = "registry-main",
          link_mode = "main",
          restored_target = false,
          restored_from = nil,
        })
      end

      if ensure_visible then
        vim.notify("pinvim: opening main pi split", vim.log.levels.INFO)
        vim.defer_fn(function()
          api.refresh_buffer_state()
          api.ensure_connected(true)
          -- Prefer the pane id pimux just activated; poll briefly for detached
          -- pimux paths, then fall back to direction-based focus.
          local focus_attempts = 0
          local function try_focus()
            local pane = vim.fn.trim(vim.fn.system({ "tmux", "show-option", "-vq", "@pimux.active_pane" }))
            if pane ~= "" then
              vim.fn.jobstart({ "tmux", "select-pane", "-t", pane }, { detach = true })
            elseif focus_attempts < 10 then
              focus_attempts = focus_attempts + 1
              vim.defer_fn(try_focus, 100)
            else
              vim.fn.jobstart({ "tmux", "select-pane", "-R" }, { detach = true })
            end
          end
          try_focus()
        end, 180)
      end

      return true
    end

    if socket_path and not socket_exists(socket_path) then return Registry.with_launch_lock(registry, launch) end
    return launch()
  end

  function api.ensure_panel_visible() return api.run_panel_command(true) end

  function api.toggle_panel() return api.run_panel_command(false) end

  function api.send_payload(payload, send_opts)
    send_opts = send_opts or {}
    local silent = send_opts.silent == true
    local auto_connect = send_opts.auto_connect ~= false

    if auto_connect and (not conn.connected and not conn.connecting) then api.ensure_connected(true) end

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

  function api.send_explicit_payload(payload, send_opts)
    send_opts = send_opts or {}
    local kind = payload.context.kind or "cursor"
    local focus_after = send_opts.focus_after ~= false

    local function complete(ok, message)
      if ok then
        local default_message = payload.delivery == "attach" and ("pinvim: attached " .. kind .. " context")
          or ("pinvim: sent " .. kind .. " context")
        vim.notify(message or default_message, vim.log.levels.INFO)
        if focus_after then api.ensure_panel_visible() end
      else
        vim.notify(message or "pinvim: send failed; no live pi target", vim.log.levels.WARN)
      end
    end

    if api.send_payload(payload, { silent = true }) then
      complete(true)
      return true
    end

    -- Poll for connection. Also drives ensure_connected so we cover the case
    -- where the socket file does not exist yet (e.g. PiPanel just spawned pi
    -- and the instance main socket has not bound). Caller can pass `await_connect_ms` to
    -- extend the budget for first-launch flows; default preserves prior 2s.
    local timer = vim.uv.new_timer()
    if not timer then
      complete(false, "pinvim: target still connecting")
      return false
    end

    local deadline = vim.uv.now() + (send_opts.await_connect_ms or 2000)
    timer:start(
      80,
      80,
      vim.schedule_wrap(function()
        if not conn.connected and not conn.connecting then api.ensure_connected(true) end
        if conn.connected then
          timer:stop()
          timer:close()
          complete(api.send_payload(payload, { silent = true, auto_connect = false }))
        elseif vim.uv.now() >= deadline then
          timer:stop()
          timer:close()
          complete(false, "pinvim: target not ready")
        end
      end)
    )
    return true
  end

  function api.send_explicit(command_opts, send_opts)
    api.clear_stale_target(true)
    command_opts = vim.tbl_extend("force", command_opts or {}, { delivery = "attach" })
    local payload = Transport.build_explicit_send(config, command_opts)
    return api.send_explicit_payload(payload, send_opts)
  end

  function api.prompt_explicit(command_opts)
    api.clear_stale_target(true)
    command_opts = vim.tbl_extend("force", command_opts or {}, { delivery = "prompt" })
    local payload = Transport.build_explicit_send(config, command_opts)
    vim.ui.input({ prompt = "pi: ", relative = "cursor", row = 1 }, function(input)
      if input == nil then return end
      if vim.trim(input) ~= "" then payload.context.userInput = input end
      api.send_explicit_payload(payload, { focus_after = true })
    end)
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

  --- Remove all comment indicator extmarks for queued items.
  local function clear_compose_marks()
    for _, item in ipairs(compose_queue) do
      if item.bufnr and item.extmark and vim.api.nvim_buf_is_valid(item.bufnr) then
        pcall(vim.api.nvim_buf_del_extmark, item.bufnr, compose_ns, item.extmark)
      end
      item.bufnr, item.extmark = nil, nil
    end
  end

  --- Place (or replace) the indicator extmark for one queued comment item:
  --- sign-column glyph plus end-of-line virtual text with a comment preview.
  local function place_compose_mark(item)
    if not (item.bufnr and vim.api.nvim_buf_is_valid(item.bufnr)) then return end
    if item.extmark then pcall(vim.api.nvim_buf_del_extmark, item.bufnr, compose_ns, item.extmark) end
    local preview = item.note or ""
    if #preview > 48 then preview = preview:sub(1, 47) .. "\u{2026}" end
    item.extmark = vim.api.nvim_buf_set_extmark(item.bufnr, compose_ns, item.range[1] - 1, 0, {
      sign_text = "\u{f075}", -- comment glyph
      sign_hl_group = "DiagnosticSignInfo",
      virt_text = { { " \u{f075} " .. preview, "DiagnosticVirtualTextInfo" } },
      virt_text_pos = "eol",
    })
  end

  --- Find a queued comment whose range covers the given buffer line.
  local function compose_comment_at(bufnr, row)
    for idx, item in ipairs(compose_queue) do
      if item.note and item.bufnr == bufnr and item.range and row >= item.range[1] and row <= item.range[2] then
        return idx, item
      end
    end
    return nil, nil
  end

  --- Capture selection (or cursor line) plus a typed comment, queue both as one
  --- annotated context item. Re-running on a commented line edits that comment
  --- in place (prefilled input; empty input deletes it). Flush with :PiFlush.
  function api.compose_comment(command_opts)
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("pinvim: no file to comment on", vim.log.levels.WARN)
      return false
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local rel_path = vim.fn.fnamemodify(file, ":~:.")
    local selection, start_row, end_row = get_command_selection(command_opts)
    if not (selection and start_row and end_row) then
      local cursor = vim.api.nvim_win_get_cursor(0)
      start_row, end_row = cursor[1], cursor[1]
      selection = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1] or ""
    end

    -- Edit-in-place when the line already carries a queued comment.
    local existing_idx, existing = compose_comment_at(bufnr, start_row)

    local filetype = vim.bo.filetype
    vim.ui.input({ prompt = "comment: ", default = existing and existing.note or nil }, function(input)
      if input == nil then
        vim.notify("pinvim: comment cancelled", vim.log.levels.INFO)
        return
      end
      if vim.trim(input) == "" then
        if existing_idx then
          if existing.bufnr and existing.extmark then
            pcall(vim.api.nvim_buf_del_extmark, existing.bufnr, compose_ns, existing.extmark)
          end
          table.remove(compose_queue, existing_idx)
          vim.notify("pinvim: comment removed", vim.log.levels.INFO)
        else
          vim.notify("pinvim: comment cancelled", vim.log.levels.INFO)
        end
        return
      end
      if existing then
        existing.note = input
        place_compose_mark(existing)
        vim.notify("pinvim: comment updated", vim.log.levels.INFO)
        return
      end
      local item = {
        type = "selection",
        content = selection,
        file = rel_path,
        range = { start_row, end_row },
        filetype = filetype,
        note = input,
        bufnr = bufnr,
      }
      table.insert(compose_queue, item)
      place_compose_mark(item)
      vim.notify(string.format("pinvim: queued comment %d", #compose_queue), vim.log.levels.INFO)
    end)
    return true
  end

  --- Populate the quickfix list with queued comments (file/line/annotation).
  --- Opens trouble.nvim's quickfix view when available, else :copen.
  function api.compose_comments_list()
    local entries = {}
    for _, item in ipairs(compose_queue) do
      if item.note then
        table.insert(entries, {
          filename = vim.fn.fnamemodify(item.file, ":p"),
          lnum = item.range and item.range[1] or 1,
          end_lnum = item.range and item.range[2] or nil,
          text = item.note,
          type = "I",
        })
      end
    end
    if #entries == 0 then
      vim.notify("pinvim: no queued comments", vim.log.levels.INFO)
      return false
    end
    vim.fn.setqflist({}, " ", { title = "pinvim comments", items = entries })
    local ok = pcall(function() require("trouble").open("qflist") end)
    if not ok then vim.cmd("copen") end
    return true
  end

  --- Build a concise `Review scope` header from active pinvim.review metadata.
  --- Returns nil when no review session is active (ticket dot-jl46).
  local function review_scope_header()
    local ok, review = pcall(require, "pinvim.review")
    if not ok then return nil end
    local meta = review.metadata()
    if not meta then return nil end
    local lines = { string.format("Review scope: %s", meta.scope or "unknown") }
    if meta.worktree then table.insert(lines, "Worktree: " .. meta.worktree) end
    if meta.branch then table.insert(lines, "Branch: " .. meta.branch) end
    if meta.upstream then table.insert(lines, "Upstream: " .. meta.upstream) end
    if meta.base then table.insert(lines, "Base: " .. meta.base) end
    if meta.pr and meta.pr.url then
      table.insert(lines, string.format("PR: #%s %s", meta.pr.number or "?", meta.pr.url))
    end
    if meta.ticket then table.insert(lines, "Ticket: " .. meta.ticket) end
    return table.concat(lines, "\n")
  end

  function api.compose_flush(prompt)
    local function send_now(message)
      local parts = {}

      local header = review_scope_header()
      if header and header ~= "" then
        table.insert(parts, header)
        table.insert(parts, "")
      end

      for idx, item in ipairs(compose_queue) do
        if item.type == "selection" then
          local header = item.file or "unknown"
          if item.range then header = string.format("%s lines %d-%d", header, item.range[1], item.range[2]) end
          table.insert(parts, string.format("Context %d - %s:", idx, header))
          table.insert(parts, string.format("```%s", item.filetype or ""))
          table.insert(parts, item.content)
          table.insert(parts, "```")
          if item.note and vim.trim(item.note) ~= "" then
            table.insert(parts, string.format("Comment %d: %s", idx, item.note))
          end
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
        clear_compose_marks()
        compose_queue = {}
        vim.notify("pinvim: compose queue sent", vim.log.levels.INFO)
      end
      return ok
    end

    if prompt ~= nil then return send_now(prompt) end

    vim.ui.input({ prompt = "pinvim compose prompt: " }, function(input) send_now(input) end)
    return true
  end

  function api.compose_clear()
    local count = #compose_queue
    clear_compose_marks()
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
      ok = conn.connected
        and runtime.last_hello_ack ~= nil
        and (heartbeat_age == nil or heartbeat_age < (config.connection.ping_interval_s * 4)),
      peer_id = peer and peer.id or nil,
      hello_ack = runtime.last_hello_ack ~= nil,
      heartbeat_age = heartbeat_age,
      socket_path = runtime.socket,
      editor_service = vim.deepcopy(editor_service),
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
      link_mode = runtime.link_mode or "auto",
      restored_target = runtime.restored_target == true,
      ephemeral = is_ephemeral_socket(runtime.socket or conn.socket_path),
    }
  end

  function api.info()
    return {
      lifecycle = runtime.lifecycle,
      state = State.snapshot(runtime),
      target = Transport.describe_target(config),
      handshake = Handshake.describe(runtime, Transport, config),
      compose_count = #compose_queue,
      target_history = vim.deepcopy(target_history),
      registry = vim.deepcopy(registry),
      editor_service = vim.deepcopy(editor_service),
      responsibilities = {
        loader = "config/nvim/after/plugin/pinvim.lua",
        module = "config/nvim/lua/pinvim.lua",
        bridge = "non-nvim ingress only while Hammerspoon/tell replacements land",
        extension = "home/common/programs/pi-coding-agent/extensions/pinvim.ts",
      },
    }
  end

  Commands.setup(api, config)
  Autocmds.setup(api, config)
  start_nvim_peer_manifest_timer(runtime, config)
  Registry.write_main_intent(registry, runtime, config)

  vim.defer_fn(function()
    api.refresh_buffer_state()
    api.ensure_connected(true)
  end, 250)

  M.api = api
  M.state = runtime
  M.config = config
  M.registry = registry

  return api
end

return M
