-- Pi Gateway - RPC Orchestrator for Telegram
--
-- Manages a dedicated pi agent process via JSON-RPC over stdin/stdout.
-- Routes Telegram messages to pi and responses back to Telegram.
--
-- Architecture:
--   Telegram → pi-gateway (this) → pi --mode rpc → tell skill → other agents
--
-- Features:
--   - Immediate ack on message receipt (never blocks)
--   - Priority queue (!! prefix jumps queue)
--   - Emergency abort (abort!, stop!, etc.)
--   - Process supervision with health checks
--   - Robust error handling (never crashes Hammerspoon)
--
local M = {}

-- Safe require with fallback
local function safeRequire(mod)
  local ok, result = pcall(require, mod)
  if ok then return result end
  return nil
end

local telegram = safeRequire("lib.interop.telegram")
local json = hs.json

-- Safe JSON encode/decode wrappers
local function safeEncode(data)
  if not data then return nil end
  local ok, result = pcall(json.encode, data)
  if ok then return result end
  return nil
end

local function safeDecode(str)
  if not str or str == "" then return nil end
  local ok, result = pcall(json.decode, str)
  if ok then return result end
  return nil
end

-- Safe telegram send wrapper
local function safeTelegramSend(text)
  if not telegram or not telegram.send then
    U.log.w("PiGateway: telegram module not available")
    return false
  end
  local ok, err = pcall(function() telegram.send(text) end)
  if not ok then
    U.log.wf("PiGateway: failed to send telegram: %s", tostring(err))
    return false
  end
  return true
end

-- State
M.process = nil -- hs.task handle
M.buffer = "" -- Partial JSON line buffer
M.busy = false -- Is pi currently processing?
M.currentTaskId = nil -- For abort tracking
M.queue = { normal = {}, priority = {} } -- Message queues
M.consecutiveFailures = 0
M.inCooldown = false
M.healthCheckTimer = nil

-- Task timeout state (Phase 2)
M.taskTimer = nil -- Hard timeout timer
M.lastActivityTime = nil -- Last activity timestamp (for stuck detection)
M.activityTimeoutSeconds = 60 -- No activity for 60s = potentially stuck
M.pendingHealthCheck = false -- Awaiting health check response
M.healthCheckResponseTimer = nil -- Timeout for health check response

-- Config (loaded from C.piGateway)
local cfg = nil

---Initialize config from global C
local function loadConfig()
  cfg = _G.C and _G.C.piGateway or {}
  -- Defaults
  cfg.enabled = cfg.enabled ~= false
  cfg.defaultProfile = cfg.defaultProfile or "mega"
  cfg.authProfiles = cfg.authProfiles or { "mega", "rx" }
  cfg.prioritySignal = cfg.prioritySignal or "!!"
  cfg.abortPhrases = cfg.abortPhrases or { "abort!", "stop!", "kill!", "cancel!" }
  cfg.taskTimeoutMinutes = cfg.taskTimeoutMinutes or 15
  cfg.circuitBreakerThreshold = cfg.circuitBreakerThreshold or 5
  cfg.circuitBreakerCooldownSeconds = cfg.circuitBreakerCooldownSeconds or 60
  cfg.healthCheckIntervalSeconds = cfg.healthCheckIntervalSeconds or 30
  cfg.healthCheckTimeoutSeconds = cfg.healthCheckTimeoutSeconds or 10
  cfg.activityTimeoutSeconds = cfg.activityTimeoutSeconds or 60 -- No activity = stuck
  cfg.historyPath = cfg.historyPath or (os.getenv("HOME") .. "/.local/share/pi/telegram/history")
  cfg.archivePath = cfg.archivePath or (os.getenv("HOME") .. "/.local/share/pi/telegram/archives")
  cfg.logPath = cfg.logPath or (os.getenv("HOME") .. "/.local/state/pi/telegram/orchestrator.log")
end

---Ensure directories exist
local function ensureDirectories()
  os.execute("mkdir -p " .. cfg.historyPath)
  os.execute("mkdir -p " .. cfg.archivePath)
  os.execute("mkdir -p " .. (cfg.logPath:match("(.*/)")))
end

--------------------------------------------------------------------------------
-- TASK TIMEOUT & ACTIVITY TRACKING (Phase 2)
-- See docs/service-patterns.md for pattern documentation
--------------------------------------------------------------------------------

---Record activity (call on meaningful events like tool calls, streaming)
local function recordActivity()
  M.lastActivityTime = os.time()
end

---Check if task appears stuck (no activity for activityTimeoutSeconds)
---@return boolean
local function isTaskStuck()
  if not M.lastActivityTime then return false end
  if not M.busy then return false end
  
  local activityTimeout = cfg and cfg.activityTimeoutSeconds or 60
  local elapsed = os.time() - M.lastActivityTime
  return elapsed > activityTimeout
end

---Abort the current task
---@param reason string Reason for abort (timeout_hard, timeout_stuck, user)
local function abortTask(reason)
  local ok, err = pcall(function()
    U.log.wf("PiGateway: aborting task, reason=%s", reason or "unknown")
    
    sendCommand({ type = "abort" })
    M.busy = false
    
    -- Notify user
    local emoji = "⏰"
    local msg = "Task timed out"
    if reason == "timeout_stuck" then
      msg = "Task appears stuck (no activity)"
      emoji = "🔄"
    elseif reason == "user" then
      msg = "Aborted by user"
      emoji = "🛑"
    end
    
    safeTelegramSend(emoji .. " " .. msg)
    
    -- Clear timeout state
    M.clearTaskTimer()
    
    -- Process next in queue
    pcall(processNextInQueue)
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in abortTask: %s", tostring(err))
  end
end

---Start the task timeout timer
local function startTaskTimer()
  local ok, err = pcall(function()
    M.lastActivityTime = os.time()
    
    -- Clear existing timer
    if M.taskTimer then
      pcall(function() M.taskTimer:stop() end)
    end
    
    local timeoutSeconds = (cfg and cfg.taskTimeoutMinutes or 15) * 60
    
    M.taskTimer = hs.timer.doAfter(timeoutSeconds, function()
      local checkOk, checkErr = pcall(function()
        if not M.busy then return end -- Task already completed
        
        if isTaskStuck() then
          -- No recent activity - definitely stuck
          abortTask("timeout_stuck")
        else
          -- Still has activity - extend the timeout
          U.log.i("PiGateway: task still active, extending timeout")
          startTaskTimer()
        end
      end)
      
      if not checkOk then
        U.log.wf("PiGateway: error in task timer callback: %s", tostring(checkErr))
      end
    end)
  end)
  
  if not ok then
    U.log.wf("PiGateway: error starting task timer: %s", tostring(err))
  end
end

---Clear the task timeout timer
function M.clearTaskTimer()
  if M.taskTimer then
    pcall(function() M.taskTimer:stop() end)
    M.taskTimer = nil
  end
  M.lastActivityTime = nil
end

--------------------------------------------------------------------------------

---Check if text matches any abort phrase
---@param text string
---@return boolean
local function isAbortCommand(text)
  if not text then return false end
  local lower = text:lower():match("^%s*(.-)%s*$") -- trim and lowercase
  for _, phrase in ipairs(cfg.abortPhrases) do
    if lower == phrase:lower() then
      return true
    end
  end
  return false
end

---Check if text is a priority message
---@param text string
---@return boolean, string -- isPriority, cleanedText
local function checkPriority(text)
  if not text then return false, text end
  local signal = cfg.prioritySignal
  if text:sub(1, #signal) == signal then
    return true, text:sub(#signal + 1):match("^%s*(.-)%s*$") -- trim
  end
  return false, text
end

---Send a command to pi via stdin
---@param command table JSON-serializable command
---@return boolean success
local function sendCommand(command)
  -- Validate inputs
  if not command or type(command) ~= "table" then
    U.log.w("PiGateway: invalid command (nil or not table)")
    return false
  end
  
  if not M.process then
    U.log.w("PiGateway: process is nil, cannot send command")
    return false
  end
  
  -- Check if process is running (with pcall for safety)
  local isRunning = false
  pcall(function() isRunning = M.process:isRunning() end)
  if not isRunning then
    U.log.w("PiGateway: process not running, cannot send command")
    return false
  end
  
  local jsonStr = safeEncode(command)
  if not jsonStr then
    U.log.w("PiGateway: failed to encode command")
    return false
  end
  
  -- Write to stdin with error handling
  local ok, err = pcall(function()
    M.process:setInput(jsonStr .. "\n")
  end)
  
  if ok then
    U.log.df("PiGateway: sent command: %s", command.type or "unknown")
  else
    U.log.wf("PiGateway: failed to send command: %s (error: %s)", command.type or "unknown", tostring(err))
  end
  
  return ok
end

---Handle an event from pi stdout (wrapped in pcall for safety)
---@param event table Parsed JSON event
local function handleEvent(event)
  -- Wrap entire handler in pcall to prevent crashes
  local ok, err = pcall(function()
    if not event or type(event) ~= "table" then return end
    if not event.type then return end
    
    U.log.df("PiGateway: received event: %s", tostring(event.type))
    
    if event.type == "response" then
      -- Command response (prompt accepted, etc.)
      if event.success then
        U.log.df("PiGateway: command '%s' succeeded", event.command or "?")
        
        -- If this is a get_state response, acknowledge health check
        if event.command == "get_state" then
          pcall(M.onHealthCheckResponse)
        end
      else
        U.log.wf("PiGateway: command '%s' failed: %s", event.command or "?", event.error or "unknown")
        M.consecutiveFailures = (M.consecutiveFailures or 0) + 1
        pcall(checkCircuitBreaker)
      end
      
    elseif event.type == "agent_start" then
      M.busy = true
      startTaskTimer() -- Start timeout tracking
      recordActivity()
      
    elseif event.type == "agent_end" then
      M.busy = false
      M.consecutiveFailures = 0 -- Reset on success
      M.clearTaskTimer() -- Clear timeout tracking
      
      -- Extract response text and send to Telegram
      if event.messages and type(event.messages) == "table" then
        local responseText = extractAssistantResponse(event.messages)
        if responseText and type(responseText) == "string" and #responseText > 0 then
          safeTelegramSend(responseText)
        end
      end
      
      -- Process next message in queue (safely)
      pcall(processNextInQueue)
      
    elseif event.type == "message_update" then
      -- Streaming update - record as activity
      recordActivity()
      local delta = event.assistantMessageEvent
      if delta and type(delta) == "table" and delta.type == "text_delta" then
        -- Streaming text - we'll wait for agent_end for full response
      end
      
    elseif event.type == "tool_execution_start" then
      recordActivity() -- Tool starting = legitimate work
      U.log.df("PiGateway: tool started: %s", event.toolName or "?")
      
    elseif event.type == "tool_execution_end" then
      recordActivity() -- Tool completed = legitimate work
      U.log.df("PiGateway: tool ended: %s", event.toolName or "?")
      
    elseif event.type == "tool_execution_update" then
      recordActivity() -- Tool progress = legitimate work
      
    elseif event.type == "extension_error" then
      U.log.wf("PiGateway: extension error in %s: %s", event.extensionPath or "?", event.error or "?")
      
    elseif event.type == "auto_retry_start" then
      recordActivity() -- Retry = legitimate work
      U.log.wf("PiGateway: auto-retry started (attempt %d)", event.attempt or 0)
      
    elseif event.type == "auto_retry_end" then
      recordActivity()
      if event.success then
        U.log.i("PiGateway: auto-retry succeeded")
      else
        U.log.wf("PiGateway: auto-retry failed: %s", event.finalError or "?")
      end
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error handling event: %s", tostring(err))
  end
end

---Extract assistant response text from messages (safe)
---@param messages table Array of messages from agent_end
---@return string|nil
function extractAssistantResponse(messages)
  local ok, result = pcall(function()
    if not messages or type(messages) ~= "table" then return nil end
    
    local parts = {}
    for _, msg in ipairs(messages) do
      if type(msg) == "table" and msg.role == "assistant" and msg.content then
        if type(msg.content) == "string" then
          table.insert(parts, msg.content)
        elseif type(msg.content) == "table" then
          for _, block in ipairs(msg.content) do
            if type(block) == "table" and block.type == "text" and block.text then
              table.insert(parts, tostring(block.text))
            end
          end
        end
      end
    end
    
    if #parts == 0 then return nil end
    return table.concat(parts, "\n")
  end)
  
  if ok then return result end
  U.log.wf("PiGateway: error extracting response: %s", tostring(result))
  return nil
end

---Process stdout data from pi (robust error handling)
---@param task hs.task
---@param stdout string
---@param stderr string
---@return boolean -- true to keep streaming
local function onOutput(task, stdout, stderr)
  -- Wrap entire handler in pcall
  local ok, err = pcall(function()
    -- Log stderr if present (but don't crash)
    if stderr and type(stderr) == "string" and #stderr > 0 then
      U.log.wf("PiGateway stderr: %s", stderr:sub(1, 500))
    end
    
    if not stdout or type(stdout) ~= "string" or #stdout == 0 then return end
    
    -- Ensure buffer is initialized
    M.buffer = M.buffer or ""
    
    -- Append to buffer and process complete lines
    M.buffer = M.buffer .. stdout
    
    -- Limit buffer size to prevent memory issues
    local maxBufferSize = 1024 * 1024 -- 1MB
    if #M.buffer > maxBufferSize then
      U.log.w("PiGateway: buffer overflow, truncating")
      M.buffer = M.buffer:sub(-maxBufferSize)
    end
    
    -- Process complete JSON lines
    local iterations = 0
    local maxIterations = 100 -- Prevent infinite loops
    
    while iterations < maxIterations do
      iterations = iterations + 1
      
      local newlinePos = M.buffer:find("\n")
      if not newlinePos then break end
      
      local line = M.buffer:sub(1, newlinePos - 1)
      M.buffer = M.buffer:sub(newlinePos + 1)
      
      if line and #line > 0 then
        local event = safeDecode(line)
        if event then
          handleEvent(event)
        else
          -- Only log first 100 chars to avoid spam
          U.log.df("PiGateway: non-JSON line: %s", line:sub(1, 100))
        end
      end
    end
    
    if iterations >= maxIterations then
      U.log.w("PiGateway: hit max iterations processing output")
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in onOutput: %s", tostring(err))
  end
  
  return true -- Always keep streaming
end

---Handle process exit (safe)
---@param exitCode number
---@param signal number
local function onExit(exitCode, signal)
  local ok, err = pcall(function()
    U.log.wf("PiGateway: process exited (code=%s, signal=%s)", tostring(exitCode or -1), tostring(signal or -1))
    M.process = nil
    M.busy = false
    M.buffer = ""
    
    -- Auto-restart unless in cooldown (with delay to prevent rapid restarts)
    if not M.inCooldown then
      U.log.i("PiGateway: scheduling auto-restart in 2s...")
      hs.timer.doAfter(2, function()
        local startOk, startErr = pcall(function() M.start() end)
        if not startOk then
          U.log.wf("PiGateway: auto-restart failed: %s", tostring(startErr))
        end
      end)
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in onExit: %s", tostring(err))
  end
end

---Check circuit breaker and enter cooldown if needed (safe)
local function checkCircuitBreaker()
  local ok, err = pcall(function()
    local threshold = cfg and cfg.circuitBreakerThreshold or 5
    local cooldownSecs = cfg and cfg.circuitBreakerCooldownSeconds or 60
    
    if (M.consecutiveFailures or 0) >= threshold then
      U.log.wf("PiGateway: circuit breaker triggered after %d failures", M.consecutiveFailures or 0)
      M.inCooldown = true
      safeTelegramSend("⚠️ Pi gateway entering cooldown after " .. (M.consecutiveFailures or 0) .. " failures")
      
      hs.timer.doAfter(cooldownSecs, function()
        local resetOk, resetErr = pcall(function()
          U.log.i("PiGateway: cooldown ended, resetting")
          M.inCooldown = false
          M.consecutiveFailures = 0
          M.start()
        end)
        if not resetOk then
          U.log.wf("PiGateway: error resetting after cooldown: %s", tostring(resetErr))
        end
      end)
      
      -- Stop current process (safely)
      pcall(function()
        if M.process and M.process:isRunning() then
          M.process:terminate()
        end
      end)
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in checkCircuitBreaker: %s", tostring(err))
  end
end

---Process next message in queue (safe)
local function processNextInQueue()
  local ok, err = pcall(function()
    if M.busy then return end
    
    -- Ensure queues exist
    M.queue = M.queue or { normal = {}, priority = {} }
    M.queue.priority = M.queue.priority or {}
    M.queue.normal = M.queue.normal or {}
    
    -- Priority queue first
    local msg = table.remove(M.queue.priority, 1)
    if not msg then
      msg = table.remove(M.queue.normal, 1)
    end
    
    if msg and type(msg) == "table" and msg.text then
      M.busy = true
      sendCommand({
        type = "prompt",
        message = tostring(msg.text),
      })
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in processNextInQueue: %s", tostring(err))
    M.busy = false -- Reset busy state on error
  end
end

---Queue a message for processing (safe)
---@param text string Message text
---@param isPriority boolean Whether this is a priority message
---@return number position
local function queueMessage(text, isPriority)
  local ok, result = pcall(function()
    -- Ensure queues exist
    M.queue = M.queue or { normal = {}, priority = {} }
    M.queue.priority = M.queue.priority or {}
    M.queue.normal = M.queue.normal or {}
    
    local queueName = isPriority and "priority" or "normal"
    table.insert(M.queue[queueName], { text = tostring(text or ""), timestamp = os.time() })
    
    local position = #M.queue.priority + #M.queue.normal
    U.log.df("PiGateway: queued message (priority=%s, position=%d)", tostring(isPriority), position)
    
    -- Try to process immediately if idle
    if not M.busy then
      processNextInQueue()
    end
    
    return position
  end)
  
  if ok then return result or 1 end
  U.log.wf("PiGateway: error queueing message: %s", tostring(result))
  return 1
end

---Send immediate ack to Telegram (safe)
---@param isPriority boolean
---@param position number Queue position
local function sendAck(isPriority, position)
  local ok, err = pcall(function()
    local emoji = isPriority and "⚡" or "📥"
    local status = isPriority and "Priority queued" or "Queued"
    
    if (position or 1) == 1 and not M.busy then
      status = "Processing"
      emoji = "🔄"
    elseif (position or 0) > 1 then
      status = status .. string.format(" (position %d)", position)
    end
    
    safeTelegramSend(emoji .. " " .. status)
  end)
  
  if not ok then
    U.log.wf("PiGateway: error sending ack: %s", tostring(err))
  end
end

---Handle incoming Telegram message (safe, never throws)
---@param text string Message text
---@return boolean handled Whether the message was handled
function M.handleTelegramMessage(text)
  local ok, handled = pcall(function()
    -- Validate config
    if not cfg or not cfg.enabled then
      return false -- Fall back to pi.lua socket forwarding
    end
    
    -- Validate input
    if not text or type(text) ~= "string" or #text == 0 then
      U.log.w("PiGateway: received empty or invalid message")
      return false
    end
    
    -- Check for abort command
    if isAbortCommand(text) then
      U.log.i("PiGateway: abort command received")
      sendCommand({ type = "abort" })
      M.busy = false
      safeTelegramSend("🛑 Aborted current task")
      -- Don't clear queue - just abort current
      pcall(processNextInQueue)
      return true
    end
    
    -- Check for priority
    local isPriority, cleanText = checkPriority(text)
    cleanText = cleanText or text
    
    -- Queue the message
    local position = queueMessage(cleanText, isPriority)
    
    -- Send immediate ack
    sendAck(isPriority, position)
    
    -- If priority and we're busy, steer the current task
    if isPriority and M.busy then
      sendCommand({
        type = "steer",
        message = tostring(cleanText),
      })
    end
    
    return true
  end)
  
  if not ok then
    U.log.wf("PiGateway: error handling message: %s", tostring(handled))
    return false
  end
  
  return handled or false
end

---Handle unhealthy process
local function handleUnhealthy()
  local ok, err = pcall(function()
    M.recordFailure()
    if not M.inCooldown then
      U.log.i("PiGateway: restarting unhealthy process")
      M.stop()
      M.start()
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in handleUnhealthy: %s", tostring(err))
  end
end

---Record failure for circuit breaker (without counting guardrails)
function M.recordFailure(isGuardrailFailure)
  if isGuardrailFailure then return end
  M.consecutiveFailures = (M.consecutiveFailures or 0) + 1
  pcall(checkCircuitBreaker)
end

---Called when we receive a response to health check
function M.onHealthCheckResponse()
  M.pendingHealthCheck = false
  if M.healthCheckResponseTimer then
    pcall(function() M.healthCheckResponseTimer:stop() end)
    M.healthCheckResponseTimer = nil
  end
end

---Health check - ping pi to ensure it's responsive (safe)
local function healthCheck()
  local ok, err = pcall(function()
    -- Check if previous health check timed out
    if M.pendingHealthCheck then
      U.log.w("PiGateway: health check timeout - no response from previous ping")
      M.pendingHealthCheck = false
      handleUnhealthy()
      return
    end
    
    -- Check if process exists and is running
    local isRunning = false
    if M.process then
      pcall(function() isRunning = M.process:isRunning() end)
    end
    
    if not isRunning then
      U.log.w("PiGateway: health check failed - process not running")
      -- Only restart if not in cooldown
      if not M.inCooldown then
        M.start()
      end
      return
    end
    
    -- Set pending flag and start response timeout
    M.pendingHealthCheck = true
    local responseTimeout = cfg and cfg.healthCheckTimeoutSeconds or 10
    
    M.healthCheckResponseTimer = hs.timer.doAfter(responseTimeout, function()
      if M.pendingHealthCheck then
        U.log.w("PiGateway: health check response timeout")
        M.pendingHealthCheck = false
        handleUnhealthy()
      end
    end)
    
    -- Send get_state command as ping
    sendCommand({ type = "get_state" })
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in healthCheck: %s", tostring(err))
  end
end

---Start the pi RPC process (safe)
---@return boolean success
function M.start()
  local ok, result = pcall(function()
    loadConfig()
    
    if not cfg or not cfg.enabled then
      U.log.i("PiGateway: disabled in config")
      return false
    end
    
    -- Check if already running (safely)
    local isRunning = false
    if M.process then
      pcall(function() isRunning = M.process:isRunning() end)
    end
    
    if isRunning then
      U.log.i("PiGateway: already running")
      return true
    end
    
    if M.inCooldown then
      U.log.w("PiGateway: in cooldown, not starting")
      return false
    end
    
    -- Ensure directories exist (don't fail if this errors)
    pcall(ensureDirectories)
    
    U.log.i("PiGateway: starting pi RPC process")
    
    -- Build command - find pi binary
    local piPath = "/run/current-system/sw/bin/pi"
    
    -- Check if pi exists at nix path
    local piExists = false
    pcall(function() piExists = hs.fs.attributes(piPath) ~= nil end)
    
    if not piExists then
      -- Fall back to which
      local handle = io.popen("which pi 2>/dev/null")
      if handle then
        local result = handle:read("*l")
        handle:close()
        if result and #result > 0 then
          piPath = result
        end
      end
    end
    
    local args = {
      "--mode", "rpc",
      "--profile", cfg.defaultProfile or "mega",
      "--no-session", -- Don't persist session for orchestrator
    }
    
    M.process = hs.task.new(
      piPath,
      onExit, -- Exit callback
      onOutput, -- Streaming callback
      args
    )
    
    if M.process then
      local startOk = pcall(function() M.process:start() end)
      if startOk then
        U.log.i("PiGateway: process started with profile: " .. (cfg.defaultProfile or "mega"))
        
        -- Start health check timer
        if M.healthCheckTimer then
          pcall(function() M.healthCheckTimer:stop() end)
        end
        local interval = cfg.healthCheckIntervalSeconds or 30
        M.healthCheckTimer = hs.timer.doEvery(interval, healthCheck)
        
        return true
      else
        U.log.e("PiGateway: failed to start process")
        M.process = nil
        return false
      end
    else
      U.log.e("PiGateway: failed to create process")
      return false
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in start: %s", tostring(result))
    return false
  end
  
  return result or false
end

---Stop the pi RPC process (safe)
function M.stop()
  local ok, err = pcall(function()
    -- Stop health check timer
    if M.healthCheckTimer then
      pcall(function() M.healthCheckTimer:stop() end)
      M.healthCheckTimer = nil
    end
    
    -- Stop health check response timer
    if M.healthCheckResponseTimer then
      pcall(function() M.healthCheckResponseTimer:stop() end)
      M.healthCheckResponseTimer = nil
    end
    
    -- Stop task timeout timer
    M.clearTaskTimer()
    
    -- Terminate process if running
    if M.process then
      pcall(function()
        if M.process:isRunning() then
          U.log.i("PiGateway: stopping process")
          M.process:terminate()
        end
      end)
      M.process = nil
    end
    
    -- Reset state
    M.busy = false
    M.buffer = ""
    M.queue = { normal = {}, priority = {} }
    M.consecutiveFailures = 0
    M.pendingHealthCheck = false
    M.lastActivityTime = nil
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in stop: %s", tostring(err))
  end
end

---Check if gateway is available (safe, never throws)
---@return boolean
function M.isAvailable()
  local ok, result = pcall(function()
    if not cfg or not cfg.enabled then return false end
    if M.inCooldown then return false end
    if not M.process then return false end
    
    local isRunning = false
    pcall(function() isRunning = M.process:isRunning() end)
    return isRunning
  end)
  
  if ok then return result or false end
  return false
end

---Check if gateway is busy (safe)
---@return boolean
function M.isBusy()
  return M.busy or false
end

---Get queue status (safe)
---@return table { priority = number, normal = number, total = number }
function M.getQueueStatus()
  local ok, result = pcall(function()
    M.queue = M.queue or { normal = {}, priority = {} }
    M.queue.priority = M.queue.priority or {}
    M.queue.normal = M.queue.normal or {}
    
    return {
      priority = #M.queue.priority,
      normal = #M.queue.normal,
      total = #M.queue.priority + #M.queue.normal,
    }
  end)
  
  if ok and result then return result end
  return { priority = 0, normal = 0, total = 0 }
end

---Initialize the gateway (safe)
function M.init()
  local ok, err = pcall(function()
    loadConfig()
    if cfg and cfg.enabled then
      M.start()
    else
      U.log.i("PiGateway: not enabled, skipping init")
    end
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in init: %s", tostring(err))
  end
end

---Cleanup on reload (safe)
function M.cleanup()
  local ok, err = pcall(function()
    M.stop()
  end)
  
  if not ok then
    U.log.wf("PiGateway: error in cleanup: %s", tostring(err))
  end
end

return M
