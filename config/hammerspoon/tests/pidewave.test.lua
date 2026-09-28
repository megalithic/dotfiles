-- Run from config/hammerspoon: lua tests/pidewave.test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local mockHs = require("tests.mock_hs")
local passes, failures = 0, 0
local originalOpen, originalPopen = io.open, io.popen

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

local function setup()
  local mock = mockHs.new()
  mock.install()
  local state = {
    title = "project:2:1:100 pi", windowId = 7, clock = 0,
    commands = {}, root = "/work/project",
    facts = { port = 4123, root = "/work/project", pid = 300, worktree = "project" },
    tabs = "ABC123 App http://localhost:4123/orders", inspect = "active", cdpOwner = true,
    connection = {
      pane = { pane = "%42", cwd = "/work/project", pid = 100, tty = "/dev/ttys010" },
      manifest = { pane = "%42", pid = 200, owner = "owner-a", cwd = "/work/project",
        socket = "/state/pi-%42.sock", session = "project", tidewaveConnected = true,
        tidewaveEndpoint = { origin = "http://localhost:4123", pathname = "/tidewave/mcp" } },
    },
    writes = 0, inspected = 0, activated = 0, forwarded = {}, watchers = {}, taps = {},
    focusCalls = 0, cdpCalls = 0, ownerChecks = 0, brought = 0, sendResult = true,
  }
  local window = { id = function() return state.windowId end, title = function() return state.title end }
  state.ghostty = mock.makeApp({ bundleID = "com.mitchellh.ghostty", windows = { window } })
  state.helium = mock.makeApp({ bundleID = "net.imput.helium", pid = 900 })
  function state.helium:activate()
    state.activated = state.activated + 1
    if state.activationFails then return false end
    mock.frontmost = self
    return true
  end
  mock.frontmost = state.ghostty
  state.mock = mock
  hs.window.focusedWindow = function()
    if state.noFocusedWindow then return nil end
    if state.otherFocusedWindow then return { id = function() return 99 end } end
    return window
  end
  hs.timer.absoluteTime = function() return state.clock end
  hs.keycodes = { map = { c = 8 } }
  hs.eventtap.event = { types = { keyDown = 10 } }
  hs.eventtap.new = function(_, callback)
    local tap = { callback = callback }
    function tap:start() self.started = true; return self end
    function tap:stop() self.started = false; return self end
    table.insert(state.taps, tap)
    return tap
  end
  function state.press(flags, key)
    return state.taps[#state.taps].callback({
      getKeyCode = function() return key or 8 end,
      getFlags = function() return { containExactly = function() return flags ~= false end } end,
    })
  end
  hs.pasteboard = { watcher = { new = function(callback)
    local watcher = { callback = callback }
    function watcher:stop() self.stopped = true end
    table.insert(state.watchers, watcher)
    return watcher
  end } }
  package.loaded["lib.interop.pi"] = { sendPayload = function(socket, payload)
    table.insert(state.forwarded, { socket = socket, payload = payload })
    if state.sendThrows then error("socket unavailable") end
    return state.sendResult
  end }
  local encoded = {}
  hs.json.encode = function(value)
    local token = "{json:" .. tostring(#encoded + 1) .. "}"
    encoded[#encoded + 1] = token
    encoded[token] = copy(value)
    return token
  end
  hs.json.decode = function(value)
    if encoded[value] == nil then error("invalid JSON") end
    return copy(encoded[value])
  end
  hs.fs.attributes = function(path)
    if path:match("cdp%.mjs$") and not state.missingCdp then return {} end
    if path == "/opt/homebrew/bin/tmux" and state.homebrewTmux then return {} end
  end
  hs.fs.mkdir = function() return true end
  io.open = function(_, mode)
    if mode == "w" then
      state.writes = state.writes + 1
      if state.writeFails then return nil, "permission denied" end
      return { write = function(_, raw) state.binding = hs.json.decode(raw) end, close = function() end }
    end
    if state.binding then return { read = function() return hs.json.encode(state.binding) end, close = function() end } end
  end
  io.popen = function(command)
    table.insert(state.commands, command)
    local output, succeeded = nil, true
    if command:find("pidewave-focus.py", 1, true) then
      state.focusCalls = state.focusCalls + 1
      state.focusCommand = command
      state.clock = state.clock + (state.focusDuration or 0) * 1e9
      output = state.focusRaw or hs.json.encode(state.connection)
      succeeded = not state.helperFails
      if state.onFocus then state.onFocus() end
    elseif command:find("git rev-parse --show-toplevel", 1, true) then output = state.root
    elseif command:find("worktree-for-port.sh", 1, true) then
      output = state.factsRaw or (state.facts and hs.json.encode(state.facts))
    elseif command:find("-iTCP:9223", 1, true) then
      state.ownerChecks = state.ownerChecks + 1
      output = state.cdpOwner and "p900" or "p901"
      if state.onOwnerCheck then state.onOwnerCheck() end
    elseif command:find("cdp.mjs", 1, true) then
      state.cdpCalls = state.cdpCalls + 1
      if command:find(" list", 1, true) then
        output = state.tabs
        if state.onList then state.onList() end
      elseif command:find(" evalraw ", 1, true) and command:find(" Page.bringToFront '{}'", 1, true) then
        state.brought = state.brought + 1
        output = not state.bringFails and "{}" or nil
      elseif command:find(" eval ", 1, true) then
        state.inspected = state.inspected + 1
        output = state.inspect
      else state.unexpectedCommand = command end
    else state.unexpectedCommand = command end
    return { read = function() return output or "" end, close = function() return succeeded and output ~= nil end }
  end
  package.loaded["lib.interop.pidewave"] = nil
  state.module = require("lib.interop.pidewave"):init()
  return state
end

local function test(name, fn)
  local state
  local ok, err = pcall(function()
    state = setup()
    fn(state)
    assert(not state.unexpectedCommand, "unexpected command: " .. tostring(state.unexpectedCommand))
    assert(#state.mock.launched == 0, "must never launch an application")
  end)
  if state then state.module:stop() end
  io.open, io.popen = originalOpen, originalPopen
  if ok then passes = passes + 1; print("ok: " .. name)
  else failures = failures + 1; print("FAIL: " .. name .. ": " .. tostring(err)) end
end

local function noBrowserEffects(s)
  assert(s.activated == 0 and s.brought == 0 and s.inspected == 0 and #s.watchers == 0)
end

local function rejected(s)
  assert(s.press() == false, "ineligible chord must pass through")
  s.mock.advance(0)
  assert(s.writes == 0 and s.cdpCalls == 0, "no routing side effects")
  noBrowserEffects(s)
end

for name, mutate in pairs({
  ["non-Ghostty frontmost"] = function(s) s.mock.frontmost = s.helium end,
  ["no frontmost app"] = function(s) s.mock.frontmost = nil end,
  ["unparseable title"] = function(s) s.title = "project shell" end,
  ["no focused window"] = function(s) s.noFocusedWindow = true end,
  ["other focused window"] = function(s) s.otherFocusedWindow = true end,
}) do test(name, function(s) mutate(s); rejected(s); assert(s.focusCalls == 0) end) end

-- Process, tty, manifest freshness, and tmux eligibility belong to the Python
-- helper's tests. Lua tests only its bounded subprocess and response contract.
for name, mutate in pairs({
  ["missing helper or watchdog"] = function(s) s.helperFails = true end,
  ["watchdog timeout"] = function(s) s.helperFails = true; s.focusDuration = 0.20 end,
  ["late successful helper"] = function(s) s.focusDuration = 0.21 end,
  ["empty helper response"] = function(s) s.focusRaw = "" end,
  ["malformed helper JSON"] = function(s) s.focusRaw = "not JSON" end,
  ["non-object response"] = function(s) s.connection = "not a connection" end,
  ["missing pane"] = function(s) s.connection.pane = nil end,
  ["missing manifest"] = function(s) s.connection.manifest = nil end,
  ["invalid pane identity"] = function(s) s.connection.pane.pane = "42" end,
  ["mismatched pane identity"] = function(s) s.connection.manifest.pane = "%43" end,
  ["missing owner"] = function(s) s.connection.manifest.owner = nil end,
  ["missing socket"] = function(s) s.connection.manifest.socket = nil end,
  ["disconnected response"] = function(s) s.connection.manifest.tidewaveConnected = false end,
  ["missing endpoint"] = function(s) s.connection.manifest.tidewaveEndpoint = nil end,
  ["wrong endpoint path"] = function(s) s.connection.manifest.tidewaveEndpoint.pathname = "/mcp" end,
  ["remote endpoint"] = function(s) s.connection.manifest.tidewaveEndpoint.origin = "http://example.com:4123" end,
  ["proxy endpoint"] = function(s) s.connection.manifest.tidewaveEndpoint.origin = "http://localhost:9832" end,
  ["out-of-range endpoint"] = function(s) s.connection.manifest.tidewaveEndpoint.origin = "http://localhost:65536" end,
  ["focus changed during helper"] = function(s) s.onFocus = function() s.mock.frontmost = s.helium end end,
  ["title changed during helper"] = function(s) s.onFocus = function() s.title = "project:2:2:101 pi" end end,
  ["window changed during helper"] = function(s) s.onFocus = function() s.windowId = 8 end end,
}) do test(name, function(s) mutate(s); rejected(s); assert(s.focusCalls == 1) end) end

test("eligible chord uses bounded helper and defers browser work", function(s)
  assert(#s.mock.hotkeys == 0, "no global hotkey")
  assert(s.press() == true)
  assert(s.focusCommand:find("/opt/homebrew/bin/gtimeout --signal=KILL 0.20 /usr/bin/python3", 1, true))
  assert(s.focusCommand:find("'project:2:1:100 pi'", 1, true))
  assert(s.cdpCalls == 0 and s.writes == 0)
  s.mock.advance(0)
  assert(s.activated == 1 and s.inspected == 1 and s.binding.targetPrefix == "ABC123")
  assert(s.binding.appUrl == "http://localhost:4123" and #s.watchers == 1)
end)

test("helper runs on a real tmux and the system PATH, never mise shims", function(s)
  s.homebrewTmux = true
  assert(s.press() == true)
  assert(s.focusCommand:find("PATH='/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin' /opt/homebrew/bin/gtimeout", 1, true))
  local helper = s.focusCommand:sub(s.focusCommand:find("{ PATH=", 1, true))
  assert(not helper:find("mise/shims", 1, true))
end)

test("helper falls back to the global PATH when no real tmux is found", function(s)
  PATH = "/Users/x/.local/share/mise/shims:/usr/bin:/bin"
  assert(s.press() == true)
  assert(s.focusCommand:find("PATH='/Users/x/.local/share/mise/shims:/usr/bin:/bin' /opt/homebrew/bin/gtimeout", 1, true))
  PATH = nil
end)

test("unrelated keys and modifiers pass through", function(s)
  assert(not s.press(false) and not s.press(true, 9))
  assert(#s.commands == 0)
end)

test("repeated eligible chords coalesce into one handshake", function(s)
  assert(s.press() and s.press() and s.press())
  assert(s.mock.pendingTimers() == 1 and s.cdpCalls == 0)
  s.mock.advance(0)
  assert(s.inspected == 1 and s.writes == 1 and #s.watchers == 1)
end)

for _, when in ipairs({ "queued", "routing" }) do
  for name, mutate in pairs({
    disconnect = function(s) s.connection.manifest.tidewaveConnected = false end,
    owner = function(s) s.connection.manifest.owner = "owner-b" end,
    endpoint = function(s) s.connection.manifest.tidewaveEndpoint.origin = "http://localhost:4124" end,
    focus = function(s) s.mock.frontmost = s.helium end,
    window = function(s) s.windowId = 8 end,
    cwd = function(s) s.connection.manifest.cwd = "/other" end,
    socket = function(s) s.connection.manifest.socket = "/other.sock" end,
    pid = function(s) s.connection.manifest.pid = 201 end,
  }) do test(when .. " revalidation: " .. name, function(s)
    assert(s.press())
    if when == "queued" then mutate(s) else s.onList = function() mutate(s) end end
    s.mock.advance(0)
    assert(s.writes == 0)
    if when == "queued" then assert(s.cdpCalls == 0) end
    noBrowserEffects(s)
  end) end
end

for name, mutate in pairs({
  ["missing git root"] = function(s) s.root = nil end,
  ["missing live server"] = function(s) s.facts = false end,
  ["malformed server facts"] = function(s) s.factsRaw = "not JSON" end,
  ["wrong live root"] = function(s) s.facts.root = "/other" end,
  ["wrong live port"] = function(s) s.facts.port = 4999 end,
  ["missing live pid"] = function(s) s.facts.pid = nil end,
  ["invalid live pid"] = function(s) s.facts.pid = 0 end,
}) do test(name, function(s)
  mutate(s)
  s.module.handshake()
  assert(s.writes == 0 and s.cdpCalls == 0)
  noBrowserEffects(s)
end) end

test("manifest subdirectory resolves to matching worktree root", function(s)
  s.connection.manifest.cwd = "/work/project/apps/web"
  s.module.handshake()
  assert(s.inspected == 1 and s.binding.cwd == "/work/project")
end)

test("stop cancels queued handshake; init is idempotent", function(s)
  assert(s.press())
  s.module:stop()
  s.mock.advance(0)
  assert(s.inspected == 0 and not s.taps[1].started)
  s.module:init()
  assert(#s.taps == 2 and s.taps[2].started)
end)

for name, tabs in pairs({
  missing = "", ambiguous = "ABC123 A http://localhost:4123/a\nDEF456 B http://localhost:4123/b",
  tidewave = "ABC123 Tidewave http://localhost:4123/tidewave",
  tidewaveChild = "ABC123 Tidewave http://localhost:4123/tidewave/mcp?x=1",
  wrongPort = "ABC123 App http://localhost:4999/", wrongScheme = "ABC123 App https://localhost:4123/",
  wrongHost = "ABC123 App http://127.0.0.1:4123/", remote = "ABC123 App http://example.com:4123/",
}) do test("tab routing refuses " .. name, function(s)
  s.tabs = tabs
  s.module.handshake()
  noBrowserEffects(s)
  assert(s.writes == 0 and #s.mock.notifications > 0)
end) end

for _, origin in ipairs({ "http://localhost:4123", "https://localhost:4123", "http://127.0.0.1:4123" }) do
  test("tab routing matches exact origin " .. origin, function(s)
    s.connection.manifest.tidewaveEndpoint.origin = origin
    s.tabs = "DEF456 Other http://localhost:4999/a\nABC123 App " .. origin .. "/orders?sort=asc#selected"
    s.module.handshake()
    assert(s.inspected == 1 and s.binding.appUrl == origin and s.binding.targetPrefix == "ABC123")
  end)
end

test("saved target survives in-tab navigation and wins over other same-origin pages", function(s)
  s.binding = { port = 4123, targetPrefix = "ABC123" }
  s.tabs = "DEF456 Other http://localhost:4123/a\nABC123 App http://localhost:4123/new-route"
  s.module.handshake()
  assert(s.inspected == 1 and s.binding.targetPrefix == "ABC123")
end)

test("saved identity is retained when no matching app page remains", function(s)
  s.binding = { port = 4123, targetPrefix = "ABC123" }
  s.tabs = "ABC123 App http://localhost:4123/tidewave"
  s.module.handshake()
  noBrowserEffects(s)
  assert(s.writes == 0 and s.binding.targetPrefix == "ABC123")
end)

test("legacy URL retained on failure, migrated after successful Inspect", function(s)
  local previous = { port = 4123, tabUrl = "http://localhost:4123/orders" }
  s.binding = previous
  s.tabs = ""
  s.module.handshake()
  assert(s.writes == 0 and s.binding == previous and s.binding.tabUrl == "http://localhost:4123/orders")
  s.tabs = "ABC123 App http://localhost:4123/orders\nDEF456 Other http://localhost:4123/other"
  s.module.handshake()
  assert(s.inspected == 1 and s.writes == 1 and s.binding.targetPrefix == "ABC123")
  assert(not s.binding.tabUrl and not s.binding.migrationUrl)
end)

test("ambiguous saved prefix fails closed", function(s)
  s.binding = { port = 4123, targetPrefix = "ABC" }
  s.tabs = "ABC123 A http://localhost:4123/a\nABC456 B http://localhost:4123/b"
  s.module.handshake()
  noBrowserEffects(s)
  assert(s.writes == 0 and s.binding.targetPrefix == "ABC")
end)

test("duplicate legacy URLs fail closed", function(s)
  s.binding = { port = 4123, tabUrl = "http://localhost:4123/orders" }
  s.tabs = "ABC123 A http://localhost:4123/orders\nDEF456 B http://localhost:4123/orders"
  s.module.handshake()
  noBrowserEffects(s)
  assert(s.writes == 0 and s.binding.tabUrl == "http://localhost:4123/orders")
end)

for _, failure in ipairs({ "closed Helium", "wrong CDP owner" }) do
  test(failure .. " never lists CDP or changes binding", function(s)
    local previous = { port = 4123, targetPrefix = "OLD123" }
    s.binding = previous
    if failure == "closed Helium" then s.helium._dead = true else s.cdpOwner = false end
    s.module.handshake()
    assert(s.cdpCalls == 0 and s.writes == 0 and s.binding == previous)
    noBrowserEffects(s)
  end)
end

test("CDP ownership is rechecked before foregrounding", function(s)
  s.onList = function() s.cdpOwner = false end
  s.module.handshake()
  assert(s.cdpCalls == 1 and s.writes == 0)
  noBrowserEffects(s)
end)

test("focus revoked during final CDP owner check prevents foregrounding", function(s)
  s.onOwnerCheck = function()
    if s.ownerChecks == 2 then s.mock.frontmost = s.helium end
  end
  s.module.handshake()
  assert(s.ownerChecks == 2 and s.cdpCalls == 1 and s.writes == 0)
  noBrowserEffects(s)
end)

for name, mutate in pairs({
  ["missing CDP helper"] = function(s) s.missingCdp = true end,
  ["CDP list failure"] = function(s) s.tabs = nil end,
  ["foreground failure"] = function(s) s.bringFails = true end,
  ["activation failure"] = function(s) s.activationFails = true end,
  ["Inspect failure"] = function(s) s.inspect = "not-ready:complete:visible:no-toolbar:no-button" end,
}) do test(name .. " preserves binding and never arms relay", function(s)
  local previous = { port = 4123, migrationUrl = "http://localhost:4123/orders" }
  s.binding = previous
  mutate(s)
  s.module.handshake()
  assert(s.writes == 0 and s.binding == previous)
  assert(s.binding.migrationUrl == "http://localhost:4123/orders")
  assert(#s.watchers == 0 and #s.mock.notifications > 0)
end) end

test("clipboard relay filters, deduplicates successful sends, and expires", function(s)
  s.module.handshake()
  local callback = s.watchers[1].callback
  callback(nil)
  callback("ordinary clipboard")
  callback("<user_prompt>hello</user_prompt>")
  callback("<user_prompt>hello</user_prompt>")
  assert(#s.forwarded == 1)
  local sent = s.forwarded[1]
  assert(sent.socket == "/state/pi-%42.sock")
  assert(sent.payload.protocol == "pi.control.v1" and sent.payload.operation == "message.send")
  assert(sent.payload.params.mode == "follow_up" and sent.payload.params.from == "tidewave")
  callback("<user_prompt>other</user_prompt>")
  callback("<user_prompt>hello</user_prompt>")
  assert(#s.forwarded == 3, "different prompts reset consecutive deduplication")
  s.mock.advance(299)
  assert(not s.watchers[1].stopped)
  s.mock.advance(1)
  assert(s.watchers[1].stopped)
end)

for _, failure in ipairs({ "false", "exception" }) do
  test("relay retries identical prompt after send " .. failure, function(s)
    s.module.handshake()
    if failure == "false" then s.sendResult = false else s.sendThrows = true end
    s.watchers[1].callback("<user_prompt>retry</user_prompt>")
    s.sendResult, s.sendThrows = true, false
    s.watchers[1].callback("<user_prompt>retry</user_prompt>")
    s.watchers[1].callback("<user_prompt>retry</user_prompt>")
    assert(#s.forwarded == 2)
  end)
end

test("optional binding write failure still arms relay from manifest", function(s)
  s.writeFails = true
  s.module.handshake()
  assert(s.inspected == 1 and not s.binding and #s.watchers == 1)
  s.watchers[1].callback("<user_prompt>hello</user_prompt>")
  assert(#s.forwarded == 1 and s.forwarded[1].socket == s.connection.manifest.socket)
end)

test("failed re-handshake cancels previous relay", function(s)
  s.module.handshake()
  assert(#s.watchers == 1)
  s.module.handshake() -- Helium is now frontmost, so this must fail.
  assert(s.watchers[1].stopped and s.inspected == 1)
end)

test("stop cancels relay and its expiry timer", function(s)
  s.module.handshake()
  s.module:stop()
  assert(s.watchers[1].stopped and s.mock.pendingTimers() == 0)
end)

print(string.format("\n%d passed, %d failed", passes, failures))
if failures > 0 then os.exit(1) end
