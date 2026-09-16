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
--   5. Find the unambiguous app tab on localhost:<port>, preferring the exact
--      URL saved by the previous handshake and never selecting /tidewave.
--   6. Write the optional Tidewave IDE Chat -> tmux pi binding.
--   7. Bring the app tab forward via CDP, focus Helium, wait until the toolbar
--      is ready in the foreground tab, then click Inspect.
--
-- Everything is best-effort and pcall-guarded: interop failures (tmux absent,
-- Helium closed, cdp.mjs missing, pi not running) must never crash Hammerspoon.

local M = {}
M.name = "pidewave"

local DOTFILES = os.getenv("HOME") .. "/.dotfiles"
local PHX_PORT_SH = DOTFILES .. "/config/mise/tmpls/elixir/scripts/phx-port.sh"
local WT_FOR_PORT_SH = DOTFILES .. "/config/mise/tmpls/elixir/scripts/worktree-for-port.sh"
local CDP = os.getenv("HOME") .. "/.pi/agent/skills/chrome-cdp/scripts/cdp.mjs"
local CDP_PORT = 9223

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

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function trim(text)
  if not text then return nil end
  local trimmed = text:gsub("%s+$", "")
  return trimmed ~= "" and trimmed or nil
end

-- Run a shell command, return trimmed stdout or nil. When requested, merge
-- stderr into the captured failure detail. Never throws.
local function sh(cmd, cwd, captureStderr)
  local shellPath = rawget(_G, "PATH") or os.getenv("PATH") or "/usr/bin:/bin:/usr/sbin:/sbin"
  local command = cmd
  if cwd then command = "cd " .. shellQuote(cwd) .. " && " .. cmd end
  local full = "PATH=" .. shellQuote(shellPath) .. "; export PATH; { " .. command .. "; }"
  local redirect = captureStderr and " 2>&1" or " 2>/dev/null"
  local ok, out, commandError = pcall(function()
    local h = io.popen(full .. redirect)
    if not h then return nil, "could not start command" end
    local data = h:read("*a")
    local closed = h:close()
    if not closed then return nil, data end
    return data, nil
  end)
  if not ok then return nil, tostring(out) end
  return trim(out), trim(commandError)
end

local function briefError(detail)
  if not detail then return "CDP error" end
  return detail:gsub("%s+", " "):sub(1, 240)
end

-- Active tmux pane facts as seen from a non-TMUX (Hammerspoon) context.
local function activePane()
  -- tmux replaces control-character separators with underscores when invoked
  -- from Hammerspoon, so use a printable delimiter and parse the last field.
  local raw = sh("tmux display-message -p '#{pane_id}|#{pane_current_path}|#{pane_pid}'")
  if not raw or raw == "" then return nil end
  local pane, cwd, pid = raw:match("^([^|]+)|(.*)|(%d+)$")
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
  local port = sh("bash " .. shellQuote(PHX_PORT_SH), cwd)
  if not port or not port:match("^%d+$") then return nil end
  local factsJson = sh("bash " .. shellQuote(WT_FOR_PORT_SH) .. " " .. port)
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
    "curl -s --connect-timeout 1 --max-time 3 -o /dev/null -w '%%{http_code}' -X POST http://localhost:%d/tidewave/mcp "
      .. "-H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' "
      .. "-d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-03-26\",\"capabilities\":{},\"clientInfo\":{\"name\":\"pidewave\",\"version\":\"0\"}}}'",
    port
  ))
  -- Any non-000/404/405 response means the MCP route answered.
  return code ~= nil and code ~= "000" and code ~= "404" and code ~= "405"
end

local function bindingSlug(facts)
  local slug = (facts.root or ""):match("([^/]+)$") or facts.worktree or "unknown"
  return slug:lower():gsub("[^a-z0-9]", "-"):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
end

local function bindingPath(facts)
  return BINDING_DIR .. "/" .. bindingSlug(facts) .. ".json"
end

local function previousTabUrl(facts)
  local url = nil
  pcall(function()
    local f = io.open(bindingPath(facts), "r")
    if not f then return end
    local raw = f:read("*a")
    f:close()
    local decoded = hs.json.decode(raw)
    if decoded and tonumber(decoded.port) == tonumber(facts.port) and type(decoded.tabUrl) == "string" then
      url = decoded.tabUrl
    end
  end)
  return url
end

local function writeBinding(facts, manifest, tabUrl)
  pcall(function() hs.fs.mkdir(PI_STATE_DIR .. "/tidewave") end)
  pcall(function() hs.fs.mkdir(BINDING_DIR) end)
  local binding = {
    worktree = facts.worktree,
    cwd = facts.root or manifest.cwd,
    socket = manifest.socket,
    session = manifest.session,
    window = manifest.window,
    pane = manifest.pane,
    port = facts.port,
    tabUrl = tabUrl or string.format("http://localhost:%d", facts.port or 0),
    boundAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  local path = bindingPath(facts)
  local ok = pcall(function()
    local f = assert(io.open(path, "w"))
    f:write(hs.json.encode(binding))
    f:close()
  end)
  if ok then return binding, path end
  return nil, nil
end

local function appUrl(url, port)
  local _, host, urlPort, rest = url:match("^(https?)://([^/:?#]+):(%d+)(.*)$")
  if not host or (host ~= "localhost" and host ~= "127.0.0.1") then return nil end
  if tonumber(urlPort) ~= tonumber(port) then return nil end
  local path = (rest or ""):match("^([^?#]*)") or "/"
  if path == "" then path = "/" end
  return { path = path, tidewave = path == "/tidewave" or path:match("^/tidewave/") ~= nil }
end

-- Pick an app page without relying on CDP target enumeration order. A saved
-- exact URL resolves multiple same-port app pages; otherwise ambiguity fails
-- closed so Inspect is never clicked in a random tab.
local function selectAppTarget(port, preferredUrl)
  if not hs.fs.attributes(CDP) then return nil, "CDP helper is missing." end
  local list, listError = sh(string.format("CDP_PORT=%d node %s list", CDP_PORT, shellQuote(CDP)), nil, true)
  if not list then
    return nil, "Could not list Helium tabs on CDP port 9223 (" .. briefError(listError) .. ")."
  end

  local targets = {}
  for line in list:gmatch("[^\n]+") do
    local id = line:match("^(%x+)")
    local url = line:match("(https?://%S+)%s*$")
    local parsed = url and appUrl(url, port) or nil
    if id and parsed and not parsed.tidewave then
      table.insert(targets, { id = id, url = url, path = parsed.path })
    end
  end
  table.sort(targets, function(a, b)
    if a.url ~= b.url then return a.url < b.url end
    return a.id < b.id
  end)

  if preferredUrl then
    local exact = {}
    for _, target in ipairs(targets) do
      if target.url == preferredUrl then table.insert(exact, target) end
    end
    if #exact == 1 then return exact[1] end
    if #exact > 1 then
      return nil, string.format("Multiple Helium tabs have the saved app URL %s.", preferredUrl)
    end
  end
  if #targets == 1 then return targets[1] end
  if #targets == 0 then
    return nil, string.format("No normal app tab found on localhost:%d (Tidewave pages are ignored).", port)
  end
  return nil, string.format(
    "Multiple app tabs are open on localhost:%d; keep only the intended tab open, then retry.",
    port
  )
end

local function heliumOwnsCdp(app)
  local listeners = sh(string.format("/usr/sbin/lsof -nP -iTCP:%d -sTCP:LISTEN -Fp", CDP_PORT))
  if not listeners then return false end
  local appPid = app:pid()
  for pid in listeners:gmatch("p(%d+)") do
    if tonumber(pid) == appPid then return true end
  end
  return false
end

-- Page.bringToFront selects the Chromium tab before Helium itself is activated.
-- The in-page poll then refuses to click until that tab is visible, fully loaded,
-- and has an Inspect control in the Tidewave toolbar shadow root.
local function focusHeliumAndInspect(target)
  local app = hs.application.get("net.imput.helium")
  if not app then return false, "Helium is not running." end
  if not heliumOwnsCdp(app) then return false, "Helium does not own CDP port 9223." end

  local brought, bringError = sh(string.format(
    "CDP_PORT=%d node %s evalraw %s Page.bringToFront '{}'",
    CDP_PORT,
    shellQuote(CDP),
    shellQuote(target.id)
  ), nil, true)
  if not brought then
    return false, "Could not foreground the Helium app tab via CDP (" .. briefError(bringError) .. ")."
  end

  local activated = false
  local activationOk = pcall(function() activated = app:activate(true) ~= false end)
  if not activationOk or not activated then return false, "Could not focus Helium." end

  local targetJson = hs.json.encode({ url = target.url })
  local js = "(() => { const expectedUrl = (" .. targetJson .. ").url; return (" .. [[
    new Promise(resolve => {
      const deadline = Date.now() + 4000;
      let clicked = false;
      const inspect = () => {
        if (location.href !== expectedUrl) {
          resolve(`url-changed:${location.href}`);
          return;
        }
        const host = document.getElementById('tidewave-toolbar');
        const root = host && host.shadowRoot;
        const button = root && [...root.querySelectorAll('button,[role=button]')]
          .find(b => /inspect/i.test((b.getAttribute('aria-label') || b.title || b.textContent || '')));
        const enabled = button && !button.disabled && button.getAttribute('aria-disabled') !== 'true';
        const rect = button && button.getBoundingClientRect();
        const visible = enabled && button.isConnected && (button.checkVisibility
          ? button.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })
          : rect.width > 0 && rect.height > 0);
        const active = visible && button.classList.contains('bg-accent')
          && root.querySelector('[data-testid="inspector-panel"]');
        if (document.readyState === 'complete' && document.visibilityState === 'visible' && active) {
          resolve('active');
          return;
        }
        if (document.readyState === 'complete' && document.visibilityState === 'visible' && visible && !clicked) {
          button.click();
          clicked = true;
        }
        if (Date.now() >= deadline) {
          const buttonState = !button ? 'no-button' : !enabled ? 'button-disabled' : !visible ? 'button-hidden' : clicked ? 'click-unconfirmed' : 'button';
          resolve(`not-ready:${document.readyState}:${document.visibilityState}:${host ? 'toolbar' : 'no-toolbar'}:${buttonState}`);
          return;
        }
        setTimeout(inspect, 100);
      };
      inspect();
    })
  ); })() ]]
  local res, evalError = sh(string.format(
    "CDP_PORT=%d node %s eval %s %s",
    CDP_PORT,
    shellQuote(CDP),
    shellQuote(target.id),
    shellQuote(js)
  ), nil, true)
  local result = res or briefError(evalError)
  log("inspect-click target=%s url=%s result=%s", target.id, target.url, result)
  if res == "active" then return true end
  return false, "Selected app tab did not enter Tidewave Inspect mode (" .. result .. ")."
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
    local preferredUrl = facts.appUrl or previousTabUrl(facts)
    local target, targetError = selectAppTarget(facts.port, preferredUrl)
    local binding = writeBinding(facts, manifest, target and target.url or preferredUrl)
    if not binding then
      notify("Optional Tidewave IDE Chat binding failed; continuing with toolbar routing.", true)
    end
    local bindingNote = binding and " Optional IDE Chat binding was updated." or ""
    if not target then
      notify("Toolbar routing stopped: " .. targetError .. bindingNote, true)
      return
    end
    local inspected, inspectError = focusHeliumAndInspect(target)
    if not inspected then
      notify("Toolbar routing stopped: " .. inspectError .. bindingNote, true)
      return
    end
    notify(string.format("Tidewave Inspect ready in %s", target.url))
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
