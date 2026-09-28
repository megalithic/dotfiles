-- Pidewave interop - Cmd+Shift+C handshake: bind the active tmux pi to the
-- Tidewave tab for its worktree, then focus Helium and engage inspect mode.
--
-- Flow on hotkey:
--   1. Resolve the focused Ghostty title to an exact, active tmux pane.
--   2. Require a fresh connected manifest owned by that tty's foreground Pi.
--   3. Cross-check the reported endpoint against the live Phoenix worktree.
--   4. Revalidate the focused registration before any browser side effects.
--   5. Find the unambiguous app tab on localhost:<port>, preferring the CDP
--      target saved by the previous handshake and never selecting /tidewave.
--   6. Write the optional Tidewave IDE Chat -> tmux pi binding.
--   7. Bring the app tab forward via CDP, focus Helium, wait until the toolbar
--      is ready in the foreground tab, then click Inspect.
--   8. Watch the clipboard briefly; forward copied Tidewave prompts
--      (<user_prompt> payloads) to the bound pi as follow_up messages.
--
-- Everything is best-effort and pcall-guarded: interop failures (tmux absent,
-- Helium closed, cdp.mjs missing, pi not running) must never crash Hammerspoon.

local M = {}
M.name = "pidewave"

local DOTFILES = os.getenv("HOME") .. "/.dotfiles"
local FOCUS_HELPER = DOTFILES .. "/config/hammerspoon/lib/interop/pidewave-focus.py"
local FOCUS_TIMEOUT = 0.20
-- The helper execs python plus several tmux calls inside FOCUS_TIMEOUT. A mise
-- shim costs ~0.5 s per exec, so it runs on the system python and a real tmux.
local FOCUS_PYTHON = "/usr/bin/python3"
local FOCUS_TMUX_DIRS = {
  os.getenv("HOME") .. "/.local/share/mise/installs/tmux/latest",
  "/opt/homebrew/bin",
  "/usr/local/bin",
}
local FOCUS_SYSTEM_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
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
  pcall(function() hs.notify.new({ title = "Pidewave", informativeText = text, withdrawAfter = 4 }):send() end)
  log("%s%s", isError and "ERROR: " or "", text)
end

local function shellQuote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end

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

local function focusedTerminal()
  local app = hs.application.frontmostApplication()
  if not app or app:bundleID() ~= "com.mitchellh.ghostty" then return nil end
  local win = hs.window.focusedWindow()
  local appWindow = app:focusedWindow()
  if not win or not appWindow or win:id() ~= appWindow:id() then return nil end
  return win:id(), win:title()
end

local function endpointPort(endpoint)
  if type(endpoint) ~= "table" or endpoint.pathname ~= "/tidewave/mcp" or type(endpoint.origin) ~= "string" then
    return nil
  end
  local scheme, host, digits = endpoint.origin:match("^(https?)://([^/:]+):(%d+)$")
  if not scheme then
    scheme, host = endpoint.origin:match("^(https?)://([^/:]+)$")
  end
  if not scheme or (host ~= "localhost" and host ~= "127.0.0.1") then return nil end
  local port = digits and tonumber(digits) or (scheme == "https" and 443 or 80)
  if port < 1 or port > 65535 or port == 9832 then return nil end
  return port
end

-- The watchdog bounds the entire gate, including filesystem reads and all
-- subprocesses. Slow/missing helpers pass the key through, never use a cache.
local function focusPath()
  for _, dir in ipairs(FOCUS_TMUX_DIRS) do
    if hs.fs.attributes(dir .. "/tmux") then return dir .. ":" .. FOCUS_SYSTEM_PATH end
  end
  return rawget(_G, "PATH") or os.getenv("PATH") or FOCUS_SYSTEM_PATH
end

local function focusedConnection()
  local windowId, title = focusedTerminal()
  if not title or not title:match("^[^:]+:%d+:%d+:%d+%s") then return nil end
  local started = hs.timer.absoluteTime()
  local raw = sh(
    string.format(
      "PATH=%s /opt/homebrew/bin/gtimeout --signal=KILL %.2f %s %s %s %s",
      shellQuote(focusPath()),
      FOCUS_TIMEOUT,
      FOCUS_PYTHON,
      shellQuote(FOCUS_HELPER),
      shellQuote(MANIFEST_DIR),
      shellQuote(title)
    )
  )
  if not raw or (hs.timer.absoluteTime() - started) / 1e9 > FOCUS_TIMEOUT then return nil end
  local currentWindow, currentTitle = focusedTerminal()
  if windowId ~= currentWindow or title ~= currentTitle then return nil end
  local ok, connection = pcall(hs.json.decode, raw)
  if
    not ok
    or type(connection) ~= "table"
    or type(connection.pane) ~= "table"
    or type(connection.manifest) ~= "table"
  then
    return nil
  end
  local pane, manifest = connection.pane, connection.manifest
  if
    type(pane.pane) ~= "string"
    or not pane.pane:match("^%%%d+$")
    or type(pane.pid) ~= "number"
    or type(pane.cwd) ~= "string"
    or manifest.pane ~= pane.pane
    or type(manifest.pid) ~= "number"
    or type(manifest.owner) ~= "string"
    or type(manifest.socket) ~= "string"
    or type(manifest.cwd) ~= "string"
    or manifest.tidewaveConnected ~= true
    or not endpointPort(manifest.tidewaveEndpoint)
  then
    return nil
  end
  pane.windowId = windowId
  return connection
end

local function sameConnection(a, b)
  return a
    and b
    and a.pane.pane == b.pane.pane
    and a.pane.pid == b.pane.pid
    and a.pane.windowId == b.pane.windowId
    and a.pane.cwd == b.pane.cwd
    and a.manifest.pid == b.manifest.pid
    and a.manifest.owner == b.manifest.owner
    and a.manifest.socket == b.manifest.socket
    and a.manifest.cwd == b.manifest.cwd
    and a.manifest.tidewaveEndpoint.origin == b.manifest.tidewaveEndpoint.origin
end

local function worktreeFacts(manifest)
  local port = endpointPort(manifest.tidewaveEndpoint)
  if not port then return nil end
  local root = sh("git rev-parse --show-toplevel", manifest.cwd)
  local factsJson = sh("bash " .. shellQuote(WT_FOR_PORT_SH) .. " " .. port)
  if not root or not factsJson then return nil end
  local ok, facts = pcall(hs.json.decode, factsJson)
  if
    not ok
    or type(facts) ~= "table"
    or facts.port ~= port
    or facts.root ~= root
    or type(facts.pid) ~= "number"
    or facts.pid <= 0
  then
    return nil
  end
  facts.appUrl = manifest.tidewaveEndpoint.origin
  return facts
end

local function bindingSlug(facts)
  local slug = (facts.root or ""):match("([^/]+)$") or facts.worktree or "unknown"
  return slug:lower():gsub("[^a-z0-9]", "-"):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
end

local function bindingPath(facts) return BINDING_DIR .. "/" .. bindingSlug(facts) .. ".json" end

local function previousTarget(facts)
  local target = nil
  pcall(function()
    local f = io.open(bindingPath(facts), "r")
    if not f then return end
    local raw = f:read("*a")
    f:close()
    local decoded = hs.json.decode(raw)
    if decoded and tonumber(decoded.port) == tonumber(facts.port) then
      target = {
        prefix = type(decoded.targetPrefix) == "string" and decoded.targetPrefix
          or type(decoded.targetId) == "string" and decoded.targetId
          or nil,
        -- Retained until a legacy binding successfully resolves to a target.
        url = type(decoded.migrationUrl) == "string" and decoded.migrationUrl
          or type(decoded.tabUrl) == "string" and decoded.tabUrl
          or nil,
      }
    end
  end)
  return target
end

local function writeBinding(facts, manifest, targetPrefix)
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
    appUrl = facts.appUrl,
    targetPrefix = targetPrefix,
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

local function appUrl(url, origin)
  local actualOrigin, rest = url:match("^(https?://[^/?#]+)(.*)$")
  if actualOrigin ~= origin then return nil end
  local path = (rest or ""):match("^([^?#]*)") or "/"
  if path == "" then path = "/" end
  return { path = path, tidewave = path == "/tidewave" or path:match("^/tidewave/") ~= nil }
end

-- Pick an app page without relying on CDP target enumeration order. A saved
-- target prefix survives in-tab navigation. An old exact URL is retained until
-- it successfully migrates; otherwise ambiguity fails closed so Inspect is
-- never clicked in a random tab.
local function selectAppTarget(origin, preferred)
  if not hs.fs.attributes(CDP) then return nil, "CDP helper is missing." end
  local list, listError = sh(string.format("CDP_PORT=%d node %s list", CDP_PORT, shellQuote(CDP)), nil, true)
  if not list then return nil, "Could not list Helium tabs on CDP port 9223 (" .. briefError(listError) .. ")." end

  local targets = {}
  for line in list:gmatch("[^\n]+") do
    local id = line:match("^(%x+)")
    local url = line:match("(https?://%S+)%s*$")
    local parsed = url and appUrl(url, origin) or nil
    if id and parsed and not parsed.tidewave then table.insert(targets, { id = id, url = url, path = parsed.path }) end
  end
  table.sort(targets, function(a, b)
    if a.url ~= b.url then return a.url < b.url end
    return a.id < b.id
  end)

  if preferred and preferred.prefix then
    local saved = {}
    for _, target in ipairs(targets) do
      if
        target.id:sub(1, #preferred.prefix) == preferred.prefix
        or preferred.prefix:sub(1, #target.id) == target.id
      then
        table.insert(saved, target)
      end
    end
    if #saved == 1 then return saved[1] end
    if #saved > 1 then
      return nil, string.format("Saved Helium target prefix %s is no longer unique.", preferred.prefix)
    end
  end
  if preferred and preferred.url then
    local exact = {}
    for _, target in ipairs(targets) do
      if target.url == preferred.url then table.insert(exact, target) end
    end
    if #exact == 1 then return exact[1] end
    if #exact > 1 then return nil, string.format("Multiple Helium tabs have the saved app URL %s.", preferred.url) end
  end
  if #targets == 1 then return targets[1] end
  if #targets == 0 then
    return nil, string.format("No normal app tab found on %s (Tidewave pages are ignored).", origin)
  end
  return nil, string.format("Multiple app tabs are open on %s; keep only the intended tab open, then retry.", origin)
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
-- and has an Inspect control in the Tidewave toolbar shadow root. The toolbar
-- collapses to its logo pill until hovered (React onMouseEnter), so a hidden
-- button gets one synthetic mouseover on the pill before the poll continues.
local function focusHeliumAndInspect(target, origin, connection)
  local app = hs.application.get("net.imput.helium")
  if not app then return false, "Helium is not running." end
  if not heliumOwnsCdp(app) then return false, "Helium does not own CDP port 9223." end
  if not sameConnection(connection, focusedConnection()) then
    return false, "Focused Pi or Tidewave connection changed; retry from Pi."
  end

  local brought, bringError = sh(
    string.format(
      "CDP_PORT=%d node %s evalraw %s Page.bringToFront '{}'",
      CDP_PORT,
      shellQuote(CDP),
      shellQuote(target.id)
    ),
    nil,
    true
  )
  if not brought then
    return false, "Could not foreground the Helium app tab via CDP (" .. briefError(bringError) .. ")."
  end

  local activated = false
  local activationOk = pcall(function() activated = app:activate(true) ~= false end)
  if not activationOk or not activated then return false, "Could not focus Helium." end

  local expectedJson = hs.json.encode({ origin = origin })
  local js = "(() => { const expectedOrigin = ("
    .. expectedJson
    .. ").origin; return ("
    .. [[
    new Promise(resolve => {
      const deadline = Date.now() + 4000;
      let clicked = false;
      let expanded = false;
      const inspect = () => {
        const localApp = location.origin === expectedOrigin
          && location.pathname !== '/tidewave'
          && !location.pathname.startsWith('/tidewave/');
        if (!localApp) {
          resolve(`location-mismatch:${location.href}`);
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
        const selected = visible && button.classList.contains('bg-accent');
        const active = selected && root.querySelector('[data-testid="inspector-panel"]');
        const ready = document.readyState === 'complete' && document.visibilityState === 'visible';
        if (ready && active) {
          resolve('active');
          return;
        }
        const logo = root && root.querySelector('[aria-label="Tidewave"]');
        const pill = logo && logo.parentElement;
        if (ready && enabled && !visible && pill && !expanded) {
          pill.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
          expanded = true;
        }
        if (ready && visible && !selected && !clicked) {
          button.click();
          clicked = true;
        }
        if (Date.now() >= deadline) {
          const buttonState = !button ? 'no-button' : !enabled ? 'button-disabled' : !visible ? (expanded ? 'expand-unconfirmed' : 'button-hidden') : clicked ? 'click-unconfirmed' : 'button';
          resolve(`not-ready:${document.readyState}:${document.visibilityState}:${host ? 'toolbar' : 'no-toolbar'}:${buttonState}`);
          return;
        }
        setTimeout(inspect, 100);
      };
      inspect();
    })
  ); })() ]]
  local res, evalError = sh(
    string.format("CDP_PORT=%d node %s eval %s %s", CDP_PORT, shellQuote(CDP), shellQuote(target.id), shellQuote(js)),
    nil,
    true
  )
  local result = res or briefError(evalError)
  log("inspect-click target=%s url=%s result=%s", target.id, target.url, result)
  if res == "active" then return true end
  return false, "Selected app tab did not enter Tidewave Inspect mode (" .. result .. ")."
end

-- After Inspect activates, Tidewave's "Copy prompt" only writes the composed
-- prompt to the clipboard. Relay those copies to the bound pi over its bridge
-- socket so the prompt lands in tmux without a manual paste.
local PROMPT_RELAY_TTL = 300 -- seconds

local function stopPromptRelay()
  pcall(function()
    if M._promptWatcher then
      M._promptWatcher:stop()
      M._promptWatcher = nil
    end
    if M._promptRelayTimer then
      M._promptRelayTimer:stop()
      M._promptRelayTimer = nil
    end
  end)
  M._lastForwardedPrompt = nil
end

local function forwardPrompt(binding, text)
  local sent = false
  pcall(function()
    local piInterop = require("lib.interop.pi")
    sent = piInterop.sendPayload(binding.socket, {
      type = "control",
      protocol = "pi.control.v1",
      id = string.format("pidewave-%d-%d", os.time(), math.random(1000, 9999)),
      operation = "message.send",
      params = { text = text, mode = "follow_up", from = "tidewave" },
    }) == true
  end)
  return sent
end

local function armPromptRelay(binding)
  stopPromptRelay()
  if not binding or not binding.socket then return end
  local ok = pcall(function()
    M._promptWatcher = hs.pasteboard.watcher.new(function(contents)
      if type(contents) ~= "string" then return end
      if not contents:find("<user_prompt>", 1, true) then return end
      if contents == M._lastForwardedPrompt then return end
      if forwardPrompt(binding, contents) then
        M._lastForwardedPrompt = contents
        -- Write-initiated only: bridge errors surface asynchronously in logs.
        notify(
          string.format(
            "Tidewave prompt forwarded to %s (%s); confirm in tmux.",
            binding.session or "pi",
            binding.pane or "?"
          )
        )
      else
        notify("Copied Tidewave prompt was not delivered to the bound pi.", true)
      end
    end)
    M._promptRelayTimer = hs.timer.doAfter(PROMPT_RELAY_TTL, stopPromptRelay)
  end)
  if not ok or not M._promptWatcher then
    stopPromptRelay()
    notify("Could not watch the clipboard for copied Tidewave prompts.", true)
  end
end

function M.handshake(expected)
  -- A new handshake invalidates any armed relay immediately: a failed run must
  -- not leave a previous binding's watcher forwarding prompts.
  stopPromptRelay()
  local ok, err = pcall(function()
    local connection = focusedConnection()
    if not connection or (expected and not sameConnection(expected, connection)) then
      notify("Focus a Pi with a current Tidewave connection first.", true)
      return
    end
    local manifest = connection.manifest
    local facts = worktreeFacts(manifest)
    if not facts or not facts.port then
      notify("Connected Tidewave endpoint does not match a live Phoenix server in this worktree.", true)
      return
    end
    local app = hs.application.get("net.imput.helium")
    if not app or not heliumOwnsCdp(app) then
      notify("Helium must already be running and own CDP port 9223.", true)
      return
    end
    local preferred = previousTarget(facts)
    local target, targetError = selectAppTarget(facts.appUrl, preferred)
    if not target then
      notify("Toolbar routing stopped: " .. targetError, true)
      return
    end
    local inspected, inspectError = focusHeliumAndInspect(target, facts.appUrl, connection)
    if not inspected then
      notify("Toolbar routing stopped: " .. inspectError, true)
      return
    end
    local binding = writeBinding(facts, manifest, target.id)
    if not binding then notify("Optional IDE Chat binding failed; clipboard relay still targets this Pi.", true) end
    notify("Tidewave Inspect ready on " .. facts.appUrl)
    armPromptRelay(binding or manifest)
  end)
  if not ok then notify("handshake crashed (guarded): " .. tostring(err), true) end
end

function M:init()
  self:stop()
  M._keyWatcher = hs.eventtap
    .new({ hs.eventtap.event.types.keyDown }, function(event)
      if event:getKeyCode() ~= hs.keycodes.map[HOTKEY_KEY] or not event:getFlags():containExactly(HOTKEY_MODS) then
        return false
      end
      local ok, connection = pcall(focusedConnection)
      if not ok or not connection then return false end
      if not M._pending then
        -- Keep CDP/worktree work outside the event tap. Execution revalidates
        -- the captured registration, never silently switching to another Pi.
        M._pending = hs.timer.doAfter(0, function()
          M._pending = nil
          M.handshake(connection)
        end)
      end
      return true
    end)
    :start()
  return M
end

function M:stop()
  stopPromptRelay()
  if M._keyWatcher then
    M._keyWatcher:stop()
    M._keyWatcher = nil
  end
  if M._pending then
    M._pending:stop()
    M._pending = nil
  end
end

return M
