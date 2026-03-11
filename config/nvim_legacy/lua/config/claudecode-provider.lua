-- Multi-session terminal provider for claudecode.nvim
-- Enables independent Claude sessions per tab with side/float layout switching
-- Adapted from @alex35mil's implementation for megalithic's dotfiles

local Provider = {
  config = nil,
  initialized = false,
  layout = nil,
  on_hide = nil,
  on_exit = nil,
  on_layout_switch = nil,
}

---@alias SessionMode "continue" | "resume" | nil
---@alias LayoutMode "side" | "float"

---@class LayoutOpts
---@field default LayoutMode?
---@field side table?
---@field float table?
---@field common table?

local State = {
  terminals = {}, ---@type table<integer, {instance: snacks.win, bufnr: integer, client_id: string?}>
  clients = {}, ---@type table<integer, string>
  ghosts = {}, ---@type string[]
  layouts = {}, ---@type table<integer, LayoutMode>
  connecting = nil, ---@type integer?
  layout_switching = false,
  on_connect_patched = false,
  on_disconnect_patched = false,
  broadcast_patched = false,
}

local Terminal = {}
local Layout = {}
local CCInternal = {}

-- Simple logging wrapper (uses vim.notify when mega not available)
local function log(level, msg, data)
  if data then
    msg = msg .. ": " .. vim.inspect(data)
  end
  -- Use mega.notify if available, otherwise vim.notify
  if _G.mega and _G.mega.notify then
    _G.mega.notify(msg, { level = level, title = "ClaudeCode" })
  else
    vim.notify("[ClaudeCode] " .. msg, level)
  end
end

local function log_trace(msg, data)
  -- Only log trace in debug mode
  if vim.g.claudecode_debug then
    log(vim.log.levels.TRACE, msg, data)
  end
end

local function log_error(msg, data)
  log(vim.log.levels.ERROR, msg, data)
end

local function log_warn(msg, data)
  log(vim.log.levels.WARN, msg, data)
end

---
--- Public API
---

function Provider.init(opts)
  if Provider.initialized then
    return Provider
  end
  opts = opts or {}
  Provider.layout = vim.tbl_deep_extend("force", { default = "side" }, opts.layout or {})
  Provider.on_hide = opts.on_hide
  Provider.on_exit = opts.on_exit
  Provider.on_layout_switch = opts.on_layout_switch
  Provider.initialized = true
  return Provider
end

function Provider.focus()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]
  if tab_term then
    Terminal.focus(tab_term)
  end
end

---@param tab_id integer
---@return boolean
function Provider.is_connected(tab_id)
  local client = State.clients[tab_id]
  return client ~= nil
end

---@return boolean
function Provider.is_active()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = Terminal.get_instance(tab_id)
  if tab_term then
    local win = tab_term.win
    return win ~= nil and vim.api.nvim_win_is_valid(win)
  end
  return false
end

---
--- CC Interface (called by claudecode.nvim)
---

function Provider.setup(config)
  -- DEBUG: Confirm setup is called
  vim.notify("[CCProvider.setup] called", vim.log.levels.INFO)
  Provider.config = config
  State.register_autocmds()
end

function Provider.open(cmd, env, config, focus)
  -- DEBUG: Log what we receive from claudecode.nvim
  vim.notify(string.format(
    "[CCProvider.open] cmd=%s, has_env=%s, port=%s",
    tostring(cmd),
    tostring(env ~= nil),
    tostring(env and env.CLAUDE_CODE_SSE_PORT or "nil")
  ), vim.log.levels.INFO)

  State.patch_on_connect()
  State.patch_on_disconnect()
  State.patch_broadcast()

  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]
  local tab_client = State.clients[tab_id]

  if tab_term and Terminal.is_valid(tab_term) then
    tab_term.instance:show()
    if focus ~= false then
      Terminal.focus(tab_term)
    end
    return
  end

  if not tab_client then
    State.connecting = tab_id
  end

  local terminal = Terminal.new(cmd, env, config, focus)

  if not terminal then
    return
  end

  State.terminals[tab_id] = {
    instance = terminal,
    bufnr = terminal.buf,
    client_id = nil,
  }
end

function Provider.close()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]

  if tab_term then
    if tab_term.instance then
      pcall(function()
        tab_term.instance:close()
      end)
    end
    State.clients[tab_id] = nil
    State.terminals[tab_id] = nil
  end
end

function Provider.simple_toggle(cmd, env, config)
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]

  if tab_term and Terminal.is_valid(tab_term) then
    tab_term.instance:toggle()
  else
    Provider.open(cmd, env, config, true)
  end
end

function Provider.focus_toggle(cmd, env, config)
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]

  if not tab_term or not Terminal.is_valid(tab_term) then
    Provider.open(cmd, env, config, true)
    return
  end

  local term_win = tab_term.instance.win
  local current_win = vim.api.nvim_get_current_win()

  if term_win and vim.api.nvim_win_is_valid(term_win) then
    if current_win == term_win then
      tab_term.instance:hide()
    else
      vim.api.nvim_set_current_win(term_win)
      vim.cmd("startinsert")
    end
  else
    tab_term.instance:show()
    Terminal.focus(tab_term)
  end
end

function Provider.get_active_bufnr()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]

  if tab_term and tab_term.bufnr and vim.api.nvim_buf_is_valid(tab_term.bufnr) then
    return tab_term.bufnr
  end

  return nil
end

function Provider.is_available()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks.terminal ~= nil
end

---
--- Layout
---

---@return LayoutMode
function Layout.current()
  local tab_id = vim.api.nvim_get_current_tabpage()
  return State.layouts[tab_id] or Provider.layout.default
end

---@param mode LayoutMode
function Layout.set(mode)
  local tab_id = vim.api.nvim_get_current_tabpage()
  State.layouts[tab_id] = mode
end

---@param mode SessionMode
function Provider.open_on_side(mode)
  Layout.set("side")
  vim.cmd(Provider.cmd(mode))
end

---@param mode SessionMode
function Provider.open_float(mode)
  Layout.set("float")
  vim.cmd(Provider.cmd(mode))
end

---@param mode SessionMode
---@return string
function Provider.cmd(mode)
  if mode == "continue" then
    return "ClaudeCode --continue"
  elseif mode == "resume" then
    return "ClaudeCode --resume"
  end
  return "ClaudeCode"
end

function Provider.toggle_layout()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local tab_term = State.terminals[tab_id]

  if not tab_term or not Terminal.is_valid(tab_term) then
    return
  end

  local current_mode = Layout.current()
  local new_mode = current_mode == "side" and "float" or "side"
  local instance = tab_term.instance
  local new_opts = Terminal.build_layout_opts(new_mode)

  instance.opts = vim.tbl_deep_extend("force", instance.opts, new_opts)

  State.layout_switching = true
  instance:hide()
  State.layout_switching = false
  instance:show()

  Layout.set(new_mode)

  local new_win = instance.win
  if new_win and vim.api.nvim_win_is_valid(new_win) then
    -- Signal terminal to reflow content for new window size
    local bufnr = tab_term.bufnr
    local chan = vim.bo[bufnr].channel
    if chan and chan > 0 then
      local win_width = vim.api.nvim_win_get_width(new_win)
      local win_height = vim.api.nvim_win_get_height(new_win)
      pcall(vim.fn.jobresize, chan, win_width, win_height)
    end
  end

  vim.defer_fn(function()
    Terminal.focus(tab_term)
    if Provider.on_layout_switch then
      Provider.on_layout_switch(tab_id, new_mode)
    end
  end, 100)
end

---
--- Patches (for multi-session support)
---

function State.patch_on_connect()
  if State.on_connect_patched then
    return
  end

  local tcp_server = CCInternal.get_tcp_server()

  if not tcp_server then
    log_trace("Can't get CC TCP server for on_connect patch")
    return
  end

  local original_on_connect = tcp_server.on_connect

  tcp_server.on_connect = function(client)
    original_on_connect(client)

    vim.schedule(function()
      log_trace("New CC client connection", { client_id = client.id })

      local root_set = {}
      for _, id in ipairs(CCInternal.get_root_client_ids()) do
        root_set[id] = true
      end

      local tcp_set = {}
      for _, id in ipairs(CCInternal.get_tcp_client_ids()) do
        tcp_set[id] = true
      end

      -- Ghost client detection (appears during session termination)
      if root_set[client.id] and not tcp_set[client.id] then
        log_trace("Ghost client detected, ignoring", { client_id = client.id })
        table.insert(State.ghosts, client.id)
        return
      end

      local tab_id = State.connecting

      if not tab_id then
        return
      end

      if State.terminals[tab_id] then
        local tab_client_id = State.clients[tab_id]

        if not tab_client_id then
          log_trace("Storing new client", { tab_id = tab_id, client_id = client.id })
          State.clients[tab_id] = client.id
          State.connecting = nil
        else
          log_warn("New client connection, but tab already has connected client", {
            existing_client_id = tab_client_id,
            new_client_id = client.id,
          })
        end
      else
        log_warn("New client connection, but no CC terminals in tab", {
          tab_id = tab_id,
          new_client_id = client.id,
        })
      end
    end)
  end

  State.on_connect_patched = true
end

function State.patch_on_disconnect()
  if State.on_disconnect_patched then
    return
  end

  local tcp_server = CCInternal.get_tcp_server()

  if not tcp_server then
    log_trace("Can't get CC TCP server for on_disconnect patch")
    return
  end

  local original_on_disconnect = tcp_server.on_disconnect

  tcp_server.on_disconnect = function(client, code, reason)
    original_on_disconnect(client, code, reason)

    for _, ghost_id in ipairs(State.ghosts) do
      if client.id == ghost_id then
        log_trace("Ignoring ghost client disconnection", { client_id = client.id })
        return
      end
    end

    local current_tab = vim.api.nvim_get_current_tabpage()

    log_trace("CC client disconnected", {
      tab_id = current_tab,
      client_id = client.id,
      code = code,
      reason = reason,
    })

    local our_client_id = State.clients[current_tab]

    if our_client_id == client.id then
      log_trace("Our client disconnected", { tab_id = current_tab, client_id = client.id })
      State.clients[current_tab] = nil
    else
      log_warn("Unexpected client disconnection", {
        our_client_id = our_client_id,
        disconnected_client_id = client.id,
      })
    end
  end

  State.on_disconnect_patched = true
end

function State.patch_broadcast()
  if State.broadcast_patched then
    return
  end

  local server = CCInternal.get_root_server()
  if not server or not server.broadcast then
    return
  end

  server.broadcast = function(event, data)
    local current_tab = vim.api.nvim_get_current_tabpage()
    local client_id = State.clients[current_tab]

    if client_id then
      if server.state and server.state.clients then
        local client = server.state.clients[client_id]
        if client then
          return server.send(client, event, data)
        else
          log_error("Can't find client in server state", {
            client_id = client_id,
            server_clients = server.state.clients,
          })
          return false
        end
      else
        log_error("Can't broadcast - server clients unavailable", {
          tab_id = current_tab,
          client_id = client_id,
        })
        return false
      end
    else
      -- No active client in current tab
      return false
    end
  end

  State.broadcast_patched = true
end

---
--- CC Internal access
---

function CCInternal.get_root_server()
  local ok, claudecode = pcall(require, "claudecode")
  if ok and claudecode.state and claudecode.state.server then
    return claudecode.state.server
  end
  return nil
end

function CCInternal.get_tcp_server()
  local ok, claudecode = pcall(require, "claudecode")
  if
    ok
    and claudecode.state
    and claudecode.state.server
    and claudecode.state.server.state
    and claudecode.state.server.state.server
  then
    return claudecode.state.server.state.server
  end
  return nil
end

---@return string[]
function CCInternal.get_root_client_ids()
  local server = CCInternal.get_root_server()
  if server and server.state and server.state.clients then
    return vim.tbl_keys(server.state.clients)
  end
  return {}
end

---@return string[]
function CCInternal.get_tcp_client_ids()
  local server = CCInternal.get_tcp_server()
  if server and server.clients then
    return vim.tbl_keys(server.clients)
  end
  return {}
end

---
--- Terminal management
---

function Terminal.new(cmd, env, config, focus)
  local tab_id = vim.api.nvim_get_current_tabpage()
  local opts = Terminal.build_opts(config, env, focus, tab_id)

  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.terminal then
    log_error("Snacks.terminal not available")
    return nil
  end

  -- DEBUG: Log terminal command and env
  local full_cmd = cmd .. " --ide"
  vim.notify(string.format(
    "[Terminal.new] cmd='%s', env.port=%s",
    full_cmd,
    tostring(opts.env and opts.env.CLAUDE_CODE_SSE_PORT or "nil")
  ), vim.log.levels.INFO)

  local success, terminal = pcall(snacks.terminal.open, full_cmd, opts)

  if success and terminal then
    -- DEBUG: Check what snacks stored
    vim.defer_fn(function()
      if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
        local stored = vim.b[terminal.buf].snacks_terminal
        vim.notify(string.format(
          "[Terminal] snacks stored env.port=%s",
          tostring(stored and stored.env and stored.env.CLAUDE_CODE_SSE_PORT or "nil")
        ), vim.log.levels.INFO)
      end
    end, 100)
    return terminal
  else
    vim.notify("[Terminal.new] FAILED to open terminal", vim.log.levels.ERROR)
  end

  return nil
end

function Terminal.build_opts(config, env, focus, tab_id)
  local mode = State.layouts[tab_id] or Provider.layout.default
  local layout_opts = Terminal.build_layout_opts(mode)
  local should_focus = focus ~= false

  -- Capture user's on_close if provided
  local user_on_close = layout_opts.on_close

  local win_opts = vim.tbl_deep_extend("force", layout_opts, {
    on_close = function(terminal)
      if State.layout_switching then
        return
      end

      log_trace("Terminal closed", { tab_id = tab_id, terminal_id = terminal.id })

      local tab_client_id = State.clients[tab_id]

      if tab_client_id then
        log_trace("Client still connected - terminal just hidden", { client_id = tab_client_id })

        if Provider.on_hide then
          Provider.on_hide(tab_id)
        end
      else
        log_trace("Client disconnected - removing terminal from state", { terminal_id = terminal.id })
        State.terminals[tab_id] = nil
        State.layouts[tab_id] = nil

        if Provider.on_exit then
          Provider.on_exit(tab_id)
        end
      end

      if user_on_close then
        user_on_close(terminal)
      end
    end,
  })

  local opts = {
    count = tab_id,
    cwd = config.cwd or vim.fn.getcwd(),
    start_insert = should_focus,
    auto_insert = should_focus,
    auto_close = true,
    win = win_opts,
  }

  if env and next(env) then
    opts.env = env
  end

  return opts
end

---@param mode LayoutMode
---@return table
function Terminal.build_layout_opts(mode)
  local defaults = {
    side = {
      position = "right",
      width = 0.3,
      wo = {
        winfixwidth = true,
      },
    },
    float = {
      position = "float",
      width = 0.6,
      height = 0.8,
      backdrop = false,
      border = "rounded",
    },
  }

  return vim.tbl_deep_extend("force", defaults[mode] or {}, Provider.layout.common or {}, Provider.layout[mode] or {})
end

function Terminal.get_instance(tab_id)
  local terminal = State.terminals[tab_id]

  if terminal then
    return terminal.instance
  end

  return nil
end

function Terminal.is_valid(tab_term)
  if not tab_term or not tab_term.instance then
    return false
  end
  if not tab_term.bufnr or not vim.api.nvim_buf_is_valid(tab_term.bufnr) then
    return false
  end
  return true
end

function Terminal.focus(tab_term)
  local win = tab_term.instance.win
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    vim.cmd("startinsert")
  end
end

---
--- Autocmds
---

function State.register_autocmds()
  vim.api.nvim_create_autocmd("TabClosed", {
    group = vim.api.nvim_create_augroup("ClaudeCodeProvider", { clear = true }),
    callback = State.cleanup,
    desc = "Cleanup Claude terminals on tab close",
  })
end

function State.cleanup()
  local active_tabs = vim.api.nvim_list_tabpages()
  local active_set = {}
  for _, tab in ipairs(active_tabs) do
    active_set[tab] = true
  end

  for tab_id, tab_term in pairs(State.terminals) do
    if not active_set[tab_id] then
      if tab_term.instance then
        pcall(function()
          tab_term.instance:close()
        end)
      end
      State.clients[tab_id] = nil
      State.terminals[tab_id] = nil
    end
  end
end

---
--- Debugging
---

function Provider.debug()
  local tab_id = vim.api.nvim_get_current_tabpage()
  local server = CCInternal.get_root_server()

  vim.print({
    tab_id = tab_id,
    terminal = {
      terminal_id = State.terminals[tab_id] and State.terminals[tab_id].id,
      is_valid = Terminal.is_valid(State.terminals[tab_id]),
    },
    client = {
      client_id = State.clients[tab_id],
    },
    ghosts = State.ghosts,
    server_root_clients = CCInternal.get_root_client_ids(),
    server_tcp_clients = CCInternal.get_tcp_client_ids(),
  })
end

return Provider
