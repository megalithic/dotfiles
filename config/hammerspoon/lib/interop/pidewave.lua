-- Pidewave interop - Cmd+Shift+C handshake: bind the active tmux pi to the
-- Tidewave tab for its worktree, then focus Helium and engage inspect mode.
--
-- Flow on hotkey:
--   1. Resolve the active tmux pane -> cwd (worktree root) + pane_id + pid.
--   2. Verify the pane's foreground process is `pi` (gate: "in a pi instance").
--   3. Derive the Phoenix port from cwd (phx-port.sh) and the worktree facts
--      (worktree-for-port.sh). Probe /tidewave/mcp for liveness (gate:
--      "connected via tidewave mcp"). Cross-checked by the pi manifest's
--      tidewaveConnected flag when present.
--   4. Resolve the pane's pi bridge socket from its manifest (match .pane).
--   5. Write the handshake binding the pidewave.ts conduit reads.
--   6. Focus Helium, find the tab on localhost:<port>, CDP-click Tidewave
--      inspect.
--
-- Everything is best-effort and pcall-guarded: interop failures (tmux absent,
-- Helium closed, cdp.mjs missing, pi not running) must never crash Hammerspoon.

local M = {}
M.name = "pidewave"

local DOTFILES = os.getenv("HOME") .. "/.dotfiles"
local PHX_PORT_SH = DOTFILES .. "/config/mise/tmpls/elixir/scripts/phx-port.sh"
local WT_FOR_PORT_SH = DOTFILES .. "/config/mise/tmpls/elixir/scripts/worktree-for-port.sh"
local CDP = os.getenv("HOME") .. "/.pi/agent/skills/chrome-cdp/scripts/cdp.mjs"

local home = os.getenv("HOME") or "~"
local xdgState = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
local PI_STATE_DIR = os.getenv("PI_STATE_DIR") or (xdgState .. "/pi")
local MANIFEST_DIR = PI_STATE_DIR .. "/manifests"
local BINDING_DIR = PI_STATE_DIR .. "/tidewave/bindings"

local HOTKEY_MODS = { "cmd", "shift" }
local HOTKEY_KEY = "c"

local function log(fmt, ...)
  local ok, msg = pcall(string.format, ":: [pidewave] " .. fmt, ...)
  if ok then print(msg) end
end

local function notify(text, isError)
  pcall(function()
    hs.notify.new({ title = "Pidewave", informativeText = text, withdrawAfter = 4 }):send()
  end)
  log("%s%s", isError and "ERROR: " or "", text)
end

-- Run a shell command, return trimmed stdout or nil. Never throws.
local function sh(cmd, cwd)
  local full = cmd
  if cwd then full = string.format("cd %q && %s", cwd, cmd) end
  local ok, out = pcall(function()
    -- Login shell so mise/fnox PATH shims resolve like a normal terminal.
    local h = io.popen(full .. " 2>/dev/null")
    if not h then return nil end
    local data = h:read("*a")
    h:close()
    return data
  end)
  if not ok or not out then return nil end
  return (out:gsub("%s+$", ""))
end

-- Active tmux pane facts as seen from a non-TMUX (Hammerspoon) context.
local function activePane()
  local raw = sh("tmux display-message -p '#{pane_id}\t#{pane_current_path}\t#{pane_pid}'")
  if not raw or raw == "" then return nil end
  local pane, cwd, pid = raw:match("^(%S+)\t(.-)\t(%d+)$")
  if not pane then return nil end
  return { pane = pane, cwd = cwd, pid = tonumber(pid) }
end

-- Is `pi` the foreground process under the pane's shell?
local function paneRunsPi(panePid)
  if not panePid then return false end
  local kids = sh(string.format("pgrep -P %d", panePid))
  if not kids then return false end
  for kid in kids:gmatch("%d+") do
    local cmd = sh(string.format("ps -o command= -p %s", kid))
    if cmd and cmd:match("^%s*pi%f[%s\0]") then return true end
    if cmd and cmd:match("/pi%f[%s\0]") then return true end
  end
  return false
end

-- Resolve the pane's pi bridge socket by matching the manifest `.pane` field.
local function socketForPane(pane)
  local sock = nil
  pcall(function()
    for file in hs.fs.dir(MANIFEST_DIR) do
      if file:match("%.info$") then
        local f = io.open(MANIFEST_DIR .. "/" .. file, "r")
        local raw = f and f:read("*a") or nil
        if f then f:close() end
        local ok, m = pcall(hs.json.decode, raw or "")
        if ok and m and m.pane == pane and m.socket and hs.fs.attributes(m.socket) then
          sock = m
          break
        end
      end
    end
  end)
  return sock -- full manifest table, or nil
end

-- Derive Phoenix port + worktree facts from the worktree cwd.
local function worktreeFacts(cwd)
  local port = sh(string.format("bash %q", PHX_PORT_SH), cwd)
  if not port or not port:match("^%d+$") then return nil end
  local factsJson = sh(string.format("bash %q %s", WT_FOR_PORT_SH, port))
  local facts = nil
  if factsJson and factsJson:match("^{") then
    local ok, decoded = pcall(hs.json.decode, factsJson)
    if ok then facts = decoded end
  end
  facts = facts or {}
  facts.port = facts.port or tonumber(port)
  return facts
end

-- Probe the tidewave MCP endpoint for liveness (belt to the manifest flag's suspenders).
local function tidewaveLive(port)
  if not port then return false end
  local code = sh(string.format(
    "curl -s -o /dev/null -w '%%{http_code}' -X POST http://localhost:%d/tidewave/mcp "
      .. "-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' "
      .. "-d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-03-26\",\"capabilities\":{},\"clientInfo\":{\"name\":\"pidewave\",\"version\":\"0\"}}}'",
    port
  ))
  -- Any non-000/404/405 response means the MCP route answered.
  return code ~= nil and code ~= "000" and code ~= "404" and code ~= "000"
end

local function writeBinding(facts, manifest)
  pcall(function() hs.fs.mkdir(PI_STATE_DIR .. "/tidewave") end)
  pcall(function() hs.fs.mkdir(BINDING_DIR) end)
  local slug = (facts.root or ""):match("([^/]+)$") or facts.worktree or "unknown"
  slug = slug:lower():gsub("[^a-z0-9]", "-"):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  local binding = {
    worktree = facts.worktree,
    cwd = facts.root or manifest.cwd,
    socket = manifest.socket,
    session = manifest.session,
    window = manifest.window,
    pane = manifest.pane,
    port = facts.port,
    tabUrl = string.format("http://localhost:%d", facts.port or 0),
    boundAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  local path = BINDING_DIR .. "/" .. slug .. ".json"
  local ok = pcall(function()
    local f = assert(io.open(path, "w"))
    f:write(hs.json.encode(binding))
    f:close()
  end)
  if ok then return binding, path end
  return nil, nil
end

-- Focus Helium and CDP-click the Tidewave inspect button on the tab for this port.
local function focusHeliumAndInspect(port)
  pcall(function()
    local app = hs.application.get("Helium") or hs.application.get("net.imput.helium")
    if app then app:activate() end
  end)
  if not hs.fs.attributes(CDP) then
    log("cdp.mjs not found at %s; skipped inspect-click", CDP)
    return false
  end
  -- Find the tab targetId whose URL is on localhost:<port>, then eval a click on
  -- the toolbar's shadow-DOM "Inspect element" control.
  local list = sh(string.format("node %q list", CDP))
  if not list then
    log("cdp list failed; is Helium remote-debugging on :9223?")
    return false
  end
  local target = nil
  for line in list:gmatch("[^\n]+") do
    if line:match("localhost:" .. port) then
      target = line:match("^(%x+)")
      if target then break end
    end
  end
  if not target then
    log("no Helium tab found on localhost:%d", port)
    return false
  end
  local js = [[
    (() => {
      const host = document.getElementById('tidewave-toolbar');
      const sr = host && host.shadowRoot;
      if (!sr) return 'no-toolbar';
      const btn = [...sr.querySelectorAll('button,[role=button]')]
        .find(b => /inspect/i.test((b.getAttribute('aria-label')||b.title||b.textContent||'')));
      if (!btn) return 'no-inspect-btn';
      btn.click();
      return 'clicked';
    })()
  ]]
  -- shell-escape the JS payload in single quotes
  local jsEsc = js:gsub("'", "'\\''")
  local res = sh(string.format("node %q eval %s '%s'", CDP, target, jsEsc))
  log("inspect-click result: %s", res or "nil")
  return res ~= nil and res:match("clicked") ~= nil
end

function M.handshake()
  local ok, err = pcall(function()
    local pane = activePane()
    if not pane then
      notify("No active tmux pane found.", true)
      return
    end
    if not paneRunsPi(pane.pid) then
      notify("Active pane is not running pi. Focus a pi instance first.", true)
      return
    end
    local manifest = socketForPane(pane.pane)
    if not manifest then
      notify("No pi bridge socket for this pane (is PI_BRIDGE_LEGACY_SOCKET=1?).", true)
      return
    end
    local facts = worktreeFacts(pane.cwd)
    if not facts or not facts.port then
      notify("Could not derive Phoenix port for this worktree.", true)
      return
    end
    -- Gate: tidewave must be live. Prefer manifest flag, fall back to probe.
    local gated = manifest.tidewaveConnected == true or tidewaveLive(facts.port)
    if not gated then
      notify(string.format("Tidewave MCP not connected on :%d.", facts.port), true)
      return
    end
    local binding = writeBinding(facts, manifest)
    if not binding then
      notify("Failed to write handshake binding.", true)
      return
    end
    notify(string.format("Bound %s (%s) -> :%d", manifest.session or "pi", pane.pane, facts.port))
    focusHeliumAndInspect(facts.port)
  end)
  if not ok then
    notify("handshake crashed (guarded): " .. tostring(err), true)
  end
end

function M:init()
  pcall(function()
    if M._hotkey then M._hotkey:delete() end
    M._hotkey = hs.hotkey.bind(HOTKEY_MODS, HOTKEY_KEY, function() M.handshake() end)
    log("bound %s+%s", table.concat(HOTKEY_MODS, "+"), HOTKEY_KEY)
  end)
  return M
end

function M:stop()
  pcall(function()
    if M._hotkey then
      M._hotkey:delete()
      M._hotkey = nil
    end
  end)
end

return M
