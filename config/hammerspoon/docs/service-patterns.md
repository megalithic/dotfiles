# Hammerspoon Service Patterns

Reusable patterns for building reliable background services in Hammerspoon.
Used by: pi-gateway, notifications, clipper, hud, flash.

## Table of Contents

- [Process Supervision](#process-supervision)
- [Timeout Handling](#timeout-handling)
- [Circuit Breaker](#circuit-breaker)
- [Health Checks](#health-checks)
- [Safe Error Handling](#safe-error-handling)
- [Message Queues](#message-queues)
- [State Management](#state-management)
- [Launchd Integration](#launchd-integration)

---

## Process Supervision

### Pattern: Self-healing process manager

```lua
local M = {
  process = nil,
  restartAttempts = 0,
  maxRestartAttempts = 5,
  restartBackoffMs = { 1000, 2000, 5000, 10000, 30000 }, -- Exponential backoff
}

local function onExit(exitCode, signal)
  M.process = nil
  
  -- Don't restart if intentionally stopped
  if M.intentionallyStopped then return end
  
  -- Exponential backoff
  M.restartAttempts = M.restartAttempts + 1
  if M.restartAttempts > M.maxRestartAttempts then
    U.log.e("Max restart attempts reached, entering cooldown")
    M.enterCooldown()
    return
  end
  
  local delay = M.restartBackoffMs[M.restartAttempts] or 30000
  U.log.wf("Process exited, restarting in %dms (attempt %d)", delay, M.restartAttempts)
  
  hs.timer.doAfter(delay / 1000, function()
    M.start()
  end)
end

function M.start()
  if M.process and M.process:isRunning() then return true end
  
  M.process = hs.task.new(path, onExit, onOutput, args)
  if M.process then
    M.process:start()
    M.restartAttempts = 0 -- Reset on successful start
    return true
  end
  return false
end
```

### Best practices

- **Exponential backoff**: Prevent rapid restart loops
- **Max attempts**: Enter cooldown after N failures
- **Intentional stop flag**: Don't restart if user requested stop
- **Reset on success**: Clear restart counter when healthy

---

## Timeout Handling

### Pattern: Task timeout with activity detection

The challenge: distinguish "stuck" from "legitimately busy".

```lua
local M = {
  taskTimer = nil,
  lastActivityTime = nil,
  taskTimeoutSeconds = 900, -- 15 minutes
  activityTimeoutSeconds = 60, -- No activity for 60s = stuck
}

-- Called whenever there's activity (tool calls, streaming, etc.)
function M.recordActivity()
  M.lastActivityTime = os.time()
end

-- Check if task is stuck (no activity) vs just slow
function M.isStuck()
  if not M.lastActivityTime then return false end
  local elapsed = os.time() - M.lastActivityTime
  return elapsed > M.activityTimeoutSeconds
end

function M.startTaskTimer()
  M.lastActivityTime = os.time()
  
  if M.taskTimer then M.taskTimer:stop() end
  
  M.taskTimer = hs.timer.doAfter(M.taskTimeoutSeconds, function()
    if M.isStuck() then
      U.log.w("Task timed out (no activity)")
      M.abortTask("timeout_stuck")
    else
      -- Still active, extend timeout
      U.log.i("Task still active, extending timeout")
      M.startTaskTimer()
    end
  end)
end

function M.clearTaskTimer()
  if M.taskTimer then
    M.taskTimer:stop()
    M.taskTimer = nil
  end
  M.lastActivityTime = nil
end
```

### Activity signals

Events that indicate legitimate work:
- `tool_execution_start` / `tool_execution_end`
- `message_update` (streaming)
- `auto_retry_start`

Events that don't count as activity:
- Idle waiting for user input
- Stuck in interactive command

### Best practices

- **Two-tier timeout**: Hard limit + activity-based detection
- **Record activity**: Update timestamp on meaningful events
- **Extend on activity**: Don't kill legitimately busy tasks
- **Distinguish stuck vs slow**: Activity gap vs total time

---

## Circuit Breaker

### Pattern: Failure isolation with cooldown

```lua
local M = {
  consecutiveFailures = 0,
  circuitBreakerThreshold = 5,
  cooldownSeconds = 60,
  inCooldown = false,
  cooldownTimer = nil,
}

function M.recordSuccess()
  M.consecutiveFailures = 0
end

function M.recordFailure(isGuardrailFailure)
  -- Don't count guardrail blocks as failures
  if isGuardrailFailure then return end
  
  M.consecutiveFailures = M.consecutiveFailures + 1
  
  if M.consecutiveFailures >= M.circuitBreakerThreshold then
    M.tripCircuitBreaker()
  end
end

function M.tripCircuitBreaker()
  U.log.w("Circuit breaker tripped")
  M.inCooldown = true
  M.stop()
  
  -- Notify user
  safeTelegramSend("⚠️ Service entering cooldown")
  
  M.cooldownTimer = hs.timer.doAfter(M.cooldownSeconds, function()
    U.log.i("Cooldown ended, resetting")
    M.inCooldown = false
    M.consecutiveFailures = 0
    M.start()
  end)
end

function M.isAvailable()
  return not M.inCooldown and M.process and M.process:isRunning()
end
```

### What counts as failure

- API errors (5xx, rate limits)
- Process crashes
- Command rejections

### What doesn't count

- Guardrail blocks (expected behavior)
- User aborts
- Successful completions with empty response

---

## Health Checks

### Pattern: Periodic ping with response timeout

```lua
local M = {
  healthCheckTimer = nil,
  healthCheckIntervalSeconds = 30,
  healthCheckTimeoutSeconds = 10,
  pendingHealthCheck = false,
  healthCheckResponseTimer = nil,
}

function M.performHealthCheck()
  if M.pendingHealthCheck then
    -- Previous health check didn't respond
    U.log.w("Health check timeout - no response")
    M.handleUnhealthy()
    return
  end
  
  M.pendingHealthCheck = true
  
  -- Set response timeout
  M.healthCheckResponseTimer = hs.timer.doAfter(M.healthCheckTimeoutSeconds, function()
    if M.pendingHealthCheck then
      U.log.w("Health check response timeout")
      M.pendingHealthCheck = false
      M.handleUnhealthy()
    end
  end)
  
  -- Send ping
  M.sendCommand({ type = "get_state" })
end

function M.onHealthCheckResponse()
  M.pendingHealthCheck = false
  if M.healthCheckResponseTimer then
    M.healthCheckResponseTimer:stop()
    M.healthCheckResponseTimer = nil
  end
end

function M.handleUnhealthy()
  M.recordFailure()
  if not M.inCooldown then
    U.log.i("Restarting unhealthy process")
    M.restart()
  end
end

function M.startHealthCheck()
  if M.healthCheckTimer then M.healthCheckTimer:stop() end
  M.healthCheckTimer = hs.timer.doEvery(M.healthCheckIntervalSeconds, function()
    pcall(M.performHealthCheck)
  end)
end
```

### Best practices

- **Response timeout**: Don't just send, verify response
- **Pending flag**: Detect missed responses
- **Integrate with circuit breaker**: Health failures count
- **Wrap in pcall**: Health check itself shouldn't crash

---

## Safe Error Handling

### Pattern: Defensive wrappers

```lua
-- Safe require
local function safeRequire(mod)
  local ok, result = pcall(require, mod)
  return ok and result or nil
end

-- Safe JSON
local function safeEncode(data)
  if not data then return nil end
  local ok, result = pcall(hs.json.encode, data)
  return ok and result or nil
end

local function safeDecode(str)
  if not str or str == "" then return nil end
  local ok, result = pcall(hs.json.decode, str)
  return ok and result or nil
end

-- Safe callback execution
local function safeCallback(fn, ...)
  if not fn then return nil end
  local ok, result = pcall(fn, ...)
  if not ok then
    U.log.wf("Callback error: %s", tostring(result))
    return nil
  end
  return result
end

-- Safe timer
local function safeTimer(seconds, fn)
  return hs.timer.doAfter(seconds, function()
    local ok, err = pcall(fn)
    if not ok then
      U.log.wf("Timer callback error: %s", tostring(err))
    end
  end)
end
```

### Function wrapper pattern

```lua
function M.publicFunction(arg)
  local ok, result = pcall(function()
    -- Validate inputs
    if not arg or type(arg) ~= "string" then
      return nil, "invalid argument"
    end
    
    -- Do work...
    return actualResult
  end)
  
  if not ok then
    U.log.wf("Error in publicFunction: %s", tostring(result))
    return nil
  end
  
  return result
end
```

### Best practices

- **Wrap all public functions**: Never let errors escape
- **Validate inputs**: Check nil, type, bounds
- **Log errors**: Don't silently swallow
- **Return safe defaults**: nil, false, empty table

---

## Message Queues

### Pattern: Priority queue with FIFO

```lua
local M = {
  queue = {
    priority = {},  -- !! prefix messages
    normal = {},    -- Regular messages
  },
  processing = false,
}

function M.enqueue(message, isPriority)
  local q = isPriority and M.queue.priority or M.queue.normal
  table.insert(q, {
    text = message,
    timestamp = os.time(),
    id = M.generateId(),
  })
  
  M.processNext()
  return #M.queue.priority + #M.queue.normal
end

function M.dequeue()
  -- Priority first
  if #M.queue.priority > 0 then
    return table.remove(M.queue.priority, 1)
  end
  if #M.queue.normal > 0 then
    return table.remove(M.queue.normal, 1)
  end
  return nil
end

function M.processNext()
  if M.processing then return end
  
  local msg = M.dequeue()
  if not msg then return end
  
  M.processing = true
  M.processMessage(msg, function(success)
    M.processing = false
    M.processNext()  -- Process next in queue
  end)
end
```

### Best practices

- **Separate queues**: Priority vs normal
- **Timestamps**: For ordering and age tracking
- **IDs**: For tracking and cancellation
- **Non-blocking**: Always return immediately, process async

---

## State Management

### Pattern: Centralized state with reset

```lua
local DEFAULT_STATE = {
  process = nil,
  busy = false,
  buffer = "",
  queue = { normal = {}, priority = {} },
  consecutiveFailures = 0,
  inCooldown = false,
  lastActivityTime = nil,
}

local M = {}
for k, v in pairs(DEFAULT_STATE) do
  M[k] = v
end

function M.reset()
  for k, v in pairs(DEFAULT_STATE) do
    if type(v) == "table" then
      M[k] = {}
      for k2, v2 in pairs(v) do M[k][k2] = v2 end
    else
      M[k] = v
    end
  end
end
```

### Best practices

- **Default state object**: Easy to reset
- **Deep copy tables**: Avoid shared references
- **Reset on cleanup**: Prevent stale state across reloads

---

## Launchd Integration

### Pattern: User agent for auto-start

Create `~/Library/LaunchAgents/com.user.service-name.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.pi-telegram-gateway</string>
  
  <key>ProgramArguments</key>
  <array>
    <string>/path/to/pi</string>
    <string>--mode</string>
    <string>rpc</string>
    <string>--profile</string>
    <string>mega</string>
  </array>
  
  <key>RunAtLoad</key>
  <true/>
  
  <key>KeepAlive</key>
  <true/>
  
  <key>StandardOutPath</key>
  <string>/tmp/pi-gateway.log</string>
  
  <key>StandardErrorPath</key>
  <string>/tmp/pi-gateway.log</string>
  
  <key>WorkingDirectory</key>
  <string>/Users/username</string>
  
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>/Users/username</string>
  </dict>
</dict>
</plist>
```

### Hammerspoon-managed approach

For services managed by Hammerspoon (not standalone):

```lua
-- Hammerspoon IS the supervisor
-- Use hs.task with onExit callback for restart
-- launchd only manages Hammerspoon itself
```

### Best practices

- **KeepAlive**: Auto-restart on crash
- **RunAtLoad**: Start on login
- **Log paths**: For debugging
- **Environment**: Ensure HOME is set
- **WorkingDirectory**: Predictable cwd

---

## Component Architecture

Future refactoring target - shared UI components:

### HUD (Heads-Up Display)

Persistent overlay for status/cheatsheets:
- Clipper service status
- Active shortcuts
- System stats

### Flash

Transient notifications:
- Notification redirects
- Agent messages
- Quick confirmations

### Shared patterns

Both should use:
- Canvas lifecycle management
- Theme integration (light/dark)
- Position/anchor system
- Animation helpers

---

## References

- [Hammerspoon docs: hs.task](https://www.hammerspoon.org/docs/hs.task.html)
- [Hammerspoon docs: hs.timer](https://www.hammerspoon.org/docs/hs.timer.html)
- [launchd.plist man page](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [Circuit Breaker pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff)
