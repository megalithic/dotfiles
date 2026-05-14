-- lua/pinvim.lua
-- Fresh bootstrap for new nvim↔pi handshake work.
-- Keep module self-contained with obvious local tables.
-- Responsibility split:
--   * after/plugin/pi.lua: guard + require only
--   * lua/pinvim.lua: editor-side state, handshake targets, commands, autocmds
--   * bridge.ts: socket transport + legacy compatibility
--   * extensions/pinvim.ts: pi-side handshake/state entrypoint
--   * after/plugin/pi_legacy.lua + extensions/pinvim_legacy.ts: legacy live context

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

local function path_join(...) return table.concat({ ... }, "/") end

local function tmux_value(format)
  if not vim.env.TMUX then return nil end
  local handle = io.popen(string.format("tmux display-message -p '%s' 2>/dev/null", format))
  if not handle then return nil end
  local value = handle:read("*l")
  handle:close()
  return (value and value ~= "") and value or nil
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
  },
  heartbeat = {
    interval_s = 30,
    stale_after_s = 90,
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
  link_mode = "bootstrap",
  peer = nil,
  last_hello = nil,
  last_hello_ack = nil,
  last_heartbeat = nil,
  rollout = "legacy bridge/editor_state stays active until hello/hello_ack cutover",
}

function State.new(initial)
  return vim.tbl_deep_extend("force", vim.deepcopy(state_defaults), initial or {})
end

function State.set_buffer(state, patch)
  state.file = patch.file
  state.abs_file = patch.abs_file
  state.cwd = patch.cwd
  state.root = patch.root
  state.socket = patch.socket
  state.link_mode = patch.link_mode or state.link_mode
end

function State.snapshot(state)
  return vim.deepcopy(state)
end

function Transport.describe_target(config)
  return {
    socket_path = vim.env.PI_SOCKET,
    socket_dir = config.transport.socket_dir,
    manifest_dir = config.transport.manifest_dir,
    link_mode = config.transport.link_mode,
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

function Handshake.setup(state, transport, config)
  state.peer = transport.build_peer_identity(config)
  state.last_hello = transport.build_hello(state, config)
end

function Handshake.describe(state, transport, config)
  return {
    protocol = config.protocol.name,
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
      legacy_live_context = "bridge.ts -> pinvim_legacy.ts",
      legacy_messages = {
        config.protocol.editor_state,
        config.protocol.editor_disconnect,
      },
      cutover = "new pinvim.ts takes over after explicit hello/hello_ack path lands",
    },
    next_heartbeat = transport.build_heartbeat(state, config),
  }
end

function Commands.setup(api)
  vim.api.nvim_create_user_command("PinvimInfo", function()
    local info = api.info()
    local lines = {
      "pinvim bootstrap",
      string.format("lifecycle: %s", info.lifecycle),
      string.format("file: %s", info.state.file or "(none)"),
      string.format("root: %s", info.state.root or "(none)"),
      string.format("socket: %s", info.target.socket_path or "(auto)"),
      string.format("link mode: %s", info.target.link_mode),
      string.format("protocol: %s", info.handshake.protocol),
      string.format("legacy live context: %s", info.handshake.compatibility.legacy_live_context),
      string.format("cutover: %s", info.handshake.compatibility.cutover),
      "hello payload:",
      vim.inspect(info.handshake.send),
    }

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show pinvim bootstrap + handshake target" })
end

function Autocmds.setup(api)
  local group = vim.api.nvim_create_augroup("mega.pinvim", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = group,
    callback = function()
      api.refresh_buffer_state()
    end,
  })
end

function M.setup(opts)
  if did_setup then return M.api end
  did_setup = true

  local config = Config.setup(opts)
  local runtime = State.new()

  local api = {}

  function api.refresh_buffer_state()
    local current = vim.api.nvim_buf_get_name(0)
    local target = Transport.describe_target(config)
    State.set_buffer(runtime, {
      file = current ~= "" and vim.fn.fnamemodify(current, ":~:.") or nil,
      abs_file = current ~= "" and current or nil,
      cwd = vim.uv.cwd(),
      root = config.resolve_root(),
      socket = target.socket_path,
      link_mode = config.transport.link_mode,
    })
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
  Handshake.setup(runtime, Transport, config)
  Commands.setup(api)
  Autocmds.setup(api)

  M.api = api
  M.state = runtime
  M.config = config

  return api
end

return M
