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
    U.log.w("telegram module not available")
    return false
  end
  -- Disable MarkdownV2 parsing - LLM responses have unescaped special chars
  local ok, err = pcall(function() telegram.send(text, { parse_mode = "" }) end)
  if not ok then
    U.log.wf("failed to send telegram: %s", tostring(err))
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

-- Provider/profile tracking (Phase 4)
M.initialProvider = nil -- Provider at startup (e.g., "anthropic")
M.initialModel = nil -- Model at startup (e.g., "claude-sonnet-4-20250514")
M.currentProvider = nil -- Current provider (may differ if fallback occurred)
M.currentModel = nil -- Current model
M.isUsingFallback = false -- True if we've switched from initial provider/model

-- Timers that need cleanup (prevents memory leaks from anonymous timers)
M.restartTimer = nil -- Auto-restart delay timer
M.cooldownTimer = nil -- Circuit breaker cooldown timer

-- Constants (avoid magic numbers)
local MAX_BUFFER_SIZE = 1024 * 1024 -- 1MB buffer limit
local RESTART_DELAY_SECONDS = 2 -- Delay before auto-restart

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

---Ensure directories exist (using hs.fs instead of shell)
local function ensureDirectories()
  local function mkdirp(path)
    if not path or path == "" then return end
    -- hs.fs.mkdir returns true if created, nil if exists, false on error
    local ok, err = hs.fs.mkdir(path)
    if ok == false and err then
      -- Try creating parent first
      local parent = path:match("(.+)/[^/]+$")
      if parent then
        mkdirp(parent)
        hs.fs.mkdir(path)
      end
    end
  end
  
  pcall(mkdirp, cfg.historyPath)
  pcall(mkdirp, cfg.archivePath)
  pcall(mkdirp, cfg.logPath and cfg.logPath:match("(.*)/"))
end

---Ensure queue tables exist (DRY helper)
local function ensureQueues()
  M.queue = M.queue or { normal = {}, priority = {} }
  M.queue.priority = M.queue.priority or {}
  M.queue.normal = M.queue.normal or {}
end

--------------------------------------------------------------------------------
-- HISTORY PERSISTENCE (Phase 4)
-- Saves conversation history to disk with configurable rotation
--------------------------------------------------------------------------------

---Get current history filename based on rotation setting
---@return string filename (e.g., "2026-02.jsonl" for monthly)
local function getHistoryFilename()
  local rotation = cfg and cfg.historyRotation or "monthly"
  local now = os.date("*t")
  
  if rotation == "daily" then
    return string.format("%04d-%02d-%02d.jsonl", now.year, now.month, now.day)
  elseif rotation == "weekly" then
    -- ISO week number
    local week = os.date("%W")
    return string.format("%04d-W%s.jsonl", now.year, week)
  elseif rotation == "yearly" then
    return string.format("%04d.jsonl", now.year)
  else -- monthly (default)
    return string.format("%04d-%02d.jsonl", now.year, now.month)
  end
end

---Append entry to history file (safe)
---@param entry table { type = "user"|"assistant", text = string, timestamp = number }
local function appendToHistory(entry)
  local ok, err = pcall(function()
    if not cfg or not cfg.historyPath then return end
    
    local filename = getHistoryFilename()
    local filepath = cfg.historyPath .. "/" .. filename
    
    -- Add metadata
    entry.timestamp = entry.timestamp or os.time()
    entry.provider = M.currentProvider
    entry.model = M.currentModel
    entry.fallback = M.isUsingFallback or false
    
    local json = safeEncode(entry)
    if not json then return end
    
    -- Append to file
    local file = io.open(filepath, "a")
    if file then
      file:write(json .. "\n")
      file:close()
    end
  end)
  
  if not ok then
    U.log.wf("error appending to history: %s", tostring(err))
  end
end

---Archive old history files (safe)
---Call periodically (e.g., on startup) to move old files to archive
local function archiveOldHistory()
  local ok, err = pcall(function()
    if not cfg or not cfg.historyPath or not cfg.archivePath then return end
    
    local currentFile = getHistoryFilename()
    
    -- Use hs.fs.dir instead of shell ls
    local iter, dir = hs.fs.dir(cfg.historyPath)
    if not iter then return end
    
    for file in iter, dir do
      if file:match("%.jsonl$") and file ~= currentFile then
        local src = cfg.historyPath .. "/" .. file
        local dst = cfg.archivePath .. "/" .. file
        local success, err = os.rename(src, dst)
        if success then
          U.log.df("archived %s", file)
        end
      end
    end
  end)
  
  if not ok then
    U.log.wf("error archiving history: %s", tostring(err))
  end
end

--------------------------------------------------------------------------------
-- RPC COMMAND SENDING
--------------------------------------------------------------------------------

---Send a command to pi via stdin
---@param command table JSON-serializable command
---@return boolean success
local function sendCommand(command)
  -- Validate inputs
  if not command or type(command) ~= "table" then
    U.log.w("invalid command (nil or not table)")
    return false
  end
  
  if not M.process then
    U.log.w("process is nil, cannot send command")
    return false
  end
  
  -- Check if process is running (with pcall for safety)
  local isRunning = false
  pcall(function() isRunning = M.process:isRunning() end)
  if not isRunning then
    U.log.w("process not running, cannot send command")
    return false
  end
  
  local jsonStr = safeEncode(command)
  if not jsonStr then
    U.log.w("failed to encode command")
    return false
  end
  
  -- Write to stdin with error handling
  local ok, err = pcall(function()
    M.process:setInput(jsonStr .. "\n")
  end)
  
  if ok then
    U.log.df("sent command: %s", command.type or "unknown")
  else
    U.log.wf("failed to send command: %s (error: %s)", command.type or "unknown", tostring(err))
  end
  
  return ok
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

--------------------------------------------------------------------------------
-- PROVIDER/PROFILE TRACKING (Phase 4)
-- Tracks auth fallback and includes indicator in responses
--------------------------------------------------------------------------------

---Update current provider/model from get_state response
---@param stateData table The data field from get_state response
local function updateProviderState(stateData)
  local ok, err = pcall(function()
    if not stateData or type(stateData) ~= "table" then return end
    
    local model = stateData.model
    if not model or type(model) ~= "table" then return end
    
    local provider = model.provider or model.providerId
    local modelId = model.id or model.modelId
    
    if not provider or not modelId then return end
    
    -- Store initial values on first update
    if not M.initialProvider then
      M.initialProvider = provider
      M.initialModel = modelId
      U.log.df("initial provider=%s, model=%s", provider, modelId)
    end
    
    -- Update current values
    M.currentProvider = provider
    M.currentModel = modelId
    
    -- Detect fallback
    local wasFallback = M.isUsingFallback
    M.isUsingFallback = (provider ~= M.initialProvider) or (modelId ~= M.initialModel)
    
    -- Log when fallback state changes
    if M.isUsingFallback and not wasFallback then
      U.log.wf("FALLBACK DETECTED - now using %s/%s (was %s/%s)",
        provider, modelId, M.initialProvider, M.initialModel)
      safeTelegramSend(string.format("⚠️ Auth fallback: now using %s", provider))
    elseif wasFallback and not M.isUsingFallback then
      U.log.i("returned to preferred provider")
      safeTelegramSend("✅ Returned to preferred auth")
    end
  end)
  
  if not ok then
    U.log.wf("error in updateProviderState: %s", tostring(err))
  end
end

---Get provider indicator for Telegram messages
---@return string Indicator string (e.g., "[mega→openai]" on fallback, empty if default)
local function getProviderIndicator()
  if not M.isUsingFallback then return "" end
  
  local profile = cfg and cfg.defaultProfile or "gateway"
  local provider = M.currentProvider or "?"
  
  -- Short provider names for display
  local shortNames = {
    anthropic = "claude",
    openai = "openai", 
    google = "gemini",
    ["openai-codex"] = "codex",
  }
  local short = shortNames[provider] or provider
  
  return string.format("[%s→%s]", profile, short)
end

---Abort the current task
---@param reason string Reason for abort (timeout_hard, timeout_stuck, user)
local function abortTask(reason)
  local ok, err = pcall(function()
    U.log.wf("aborting task, reason=%s", reason or "unknown")
    
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
    U.log.wf("error in abortTask: %s", tostring(err))
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
          U.log.i("task still active, extending timeout")
          startTaskTimer()
        end
      end)
      
      if not checkOk then
        U.log.wf("error in task timer callback: %s", tostring(checkErr))
      end
    end)
  end)
  
  if not ok then
    U.log.wf("error starting task timer: %s", tostring(err))
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

---Check if text is a status query
---@param text string
---@return boolean
local function isStatusQuery(text)
  if not text then return false end
  local lower = text:lower():match("^%s*(.-)%s*$")
  return lower == "status?" or lower == "status" or lower == "queue?" or lower == "q?"
end

---Check if text is a clear queue command
---@param text string
---@return boolean
local function isClearQueueCommand(text)
  if not text then return false end
  local lower = text:lower():match("^%s*(.-)%s*$")
  return lower == "clear!" or lower == "clear queue!" or lower == "flush!"
end

---Get human-readable queue status
---@return string
local function getQueueStatusText()
  ensureQueues()
  
  local priorityCount = #M.queue.priority
  local normalCount = #M.queue.normal
  local total = priorityCount + normalCount
  
  local lines = {}
  
  -- Current state
  if M.busy then
    table.insert(lines, "🔄 Currently processing a task")
  elseif M.inCooldown then
    table.insert(lines, "⏸️ In cooldown (circuit breaker)")
  else
    table.insert(lines, "✅ Idle, ready for tasks")
  end
  
  -- Queue info
  if total == 0 then
    table.insert(lines, "📭 Queue empty")
  else
    table.insert(lines, string.format("📬 Queue: %d total", total))
    if priorityCount > 0 then
      table.insert(lines, string.format("  ⚡ %d priority", priorityCount))
    end
    if normalCount > 0 then
      table.insert(lines, string.format("  📥 %d normal", normalCount))
    end
  end
  
  -- Health
  local isRunning = M.process and pcall(function() return M.process:isRunning() end)
  if isRunning then
    table.insert(lines, "💚 Process healthy")
  else
    table.insert(lines, "💔 Process not running")
  end
  
  return table.concat(lines, "\n")
end

---Clear the message queue
---@return number Number of messages cleared
local function clearQueue()
  ensureQueues()
  local count = #M.queue.priority + #M.queue.normal
  M.queue = { normal = {}, priority = {} }
  return count
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

---Handle an event from pi stdout (wrapped in pcall for safety)
---@param event table Parsed JSON event
local function handleEvent(event)
  -- Wrap entire handler in pcall to prevent crashes
  local ok, err = pcall(function()
    if not event or type(event) ~= "table" then return end
    if not event.type then return end
    
    U.log.df("received event: %s", tostring(event.type))
    
    if event.type == "response" then
      -- Command response (prompt accepted, etc.)
      if event.success then
        U.log.df("command '%s' succeeded", event.command or "?")
        
        -- If this is a get_state response, acknowledge health check and update provider state
        if event.command == "get_state" then
          pcall(M.onHealthCheckResponse)
          if event.data then
            pcall(updateProviderState, event.data)
          end
        end
      else
        U.log.wf("command '%s' failed: %s", event.command or "?", event.error or "unknown")
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
          -- Save to history (before adding indicator)
          appendToHistory({ type = "assistant", text = responseText })
          
          -- Add provider indicator if using fallback auth
          local indicator = getProviderIndicator()
          if indicator and #indicator > 0 then
            responseText = responseText .. "\n\n—" .. indicator
          end
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
      U.log.df("tool started: %s", event.toolName or "?")
      
    elseif event.type == "tool_execution_end" then
      recordActivity() -- Tool completed = legitimate work
      U.log.df("tool ended: %s", event.toolName or "?")
      
    elseif event.type == "tool_execution_update" then
      recordActivity() -- Tool progress = legitimate work
      
    elseif event.type == "extension_error" then
      U.log.wf("extension error in %s: %s", event.extensionPath or "?", event.error or "?")
      
    elseif event.type == "auto_retry_start" then
      recordActivity() -- Retry = legitimate work
      U.log.wf("auto-retry started (attempt %d)", event.attempt or 0)
      
    elseif event.type == "auto_retry_end" then
      recordActivity()
      if event.success then
        U.log.i("auto-retry succeeded")
      else
        U.log.wf("auto-retry failed: %s", event.finalError or "?")
      end
    end
  end)
  
  if not ok then
    U.log.wf("error handling event: %s", tostring(err))
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
  U.log.wf("error extracting response: %s", tostring(result))
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
    if #M.buffer > MAX_BUFFER_SIZE then
      U.log.w("buffer overflow, truncating")
      M.buffer = M.buffer:sub(-MAX_BUFFER_SIZE)
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
          U.log.df("non-JSON line: %s", line:sub(1, 100))
        end
      end
    end
    
    if iterations >= maxIterations then
      U.log.w("hit max iterations processing output")
    end
  end)
  
  if not ok then
    U.log.wf("error in onOutput: %s", tostring(err))
  end
  
  return true -- Always keep streaming
end

---Handle process exit (safe)
---@param exitCode number
---@param signal number
local function onExit(exitCode, signal)
  local ok, err = pcall(function()
    U.log.wf("process exited (code=%s, signal=%s)", tostring(exitCode or -1), tostring(signal or -1))
    M.process = nil
    M.busy = false
    M.buffer = ""
    
    -- Auto-restart unless in cooldown (with delay to prevent rapid restarts)
    if not M.inCooldown then
      U.log.i("scheduling auto-restart in " .. RESTART_DELAY_SECONDS .. "s...")
      -- Cancel any existing restart timer
      if M.restartTimer then pcall(function() M.restartTimer:stop() end) end
      M.restartTimer = hs.timer.doAfter(RESTART_DELAY_SECONDS, function()
        M.restartTimer = nil
        local startOk, startErr = pcall(function() M.start() end)
        if not startOk then
          U.log.wf("auto-restart failed: %s", tostring(startErr))
        end
      end)
    end
  end)
  
  if not ok then
    U.log.wf("error in onExit: %s", tostring(err))
  end
end

---Check circuit breaker and enter cooldown if needed (safe)
local function checkCircuitBreaker()
  local ok, err = pcall(function()
    local threshold = cfg and cfg.circuitBreakerThreshold or 5
    local cooldownSecs = cfg and cfg.circuitBreakerCooldownSeconds or 60
    
    if (M.consecutiveFailures or 0) >= threshold then
      U.log.wf("circuit breaker triggered after %d failures", M.consecutiveFailures or 0)
      M.inCooldown = true
      safeTelegramSend("⚠️ Pi gateway entering cooldown after " .. (M.consecutiveFailures or 0) .. " failures")
      
      -- Cancel any existing cooldown timer
      if M.cooldownTimer then pcall(function() M.cooldownTimer:stop() end) end
      M.cooldownTimer = hs.timer.doAfter(cooldownSecs, function()
        M.cooldownTimer = nil
        local resetOk, resetErr = pcall(function()
          U.log.i("cooldown ended, resetting")
          M.inCooldown = false
          M.consecutiveFailures = 0
          M.start()
        end)
        if not resetOk then
          U.log.wf("error resetting after cooldown: %s", tostring(resetErr))
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
    U.log.wf("error in checkCircuitBreaker: %s", tostring(err))
  end
end

---Process next message in queue (safe)
local function processNextInQueue()
  local ok, err = pcall(function()
    if M.busy then return end
    
    ensureQueues()
    
    -- Priority queue first
    local isPriority = #M.queue.priority > 0
    local msg = table.remove(M.queue.priority, 1)
    if not msg then
      msg = table.remove(M.queue.normal, 1)
    end
    
    if msg and type(msg) == "table" and msg.text then
      -- Calculate how long it was queued
      local waitTime = msg.timestamp and (os.time() - msg.timestamp) or 0
      local remaining = #M.queue.priority + #M.queue.normal
      
      -- Notify user that queued task is starting
      local emoji = isPriority and "⚡" or "🔄"
      local statusParts = { emoji .. " Processing" }
      if waitTime > 5 then
        statusParts[#statusParts + 1] = string.format("(waited %ds)", waitTime)
      end
      if remaining > 0 then
        statusParts[#statusParts + 1] = string.format("• %d more in queue", remaining)
      end
      safeTelegramSend(table.concat(statusParts, " "))
      
      M.busy = true
      sendCommand({
        type = "prompt",
        message = tostring(msg.text),
      })
    end
  end)
  
  if not ok then
    U.log.wf("error in processNextInQueue: %s", tostring(err))
    M.busy = false -- Reset busy state on error
  end
end

---Queue a message for processing (safe)
---@param text string Message text
---@param isPriority boolean Whether this is a priority message
---@return number position
local function queueMessage(text, isPriority)
  local ok, result = pcall(function()
    ensureQueues()
    
    local queueName = isPriority and "priority" or "normal"
    table.insert(M.queue[queueName], { text = tostring(text or ""), timestamp = os.time() })
    
    local position = #M.queue.priority + #M.queue.normal
    U.log.df("queued message (priority=%s, position=%d)", tostring(isPriority), position)
    
    -- Try to process immediately if idle
    if not M.busy then
      processNextInQueue()
    end
    
    return position
  end)
  
  if ok then return result or 1 end
  U.log.wf("error queueing message: %s", tostring(result))
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
    U.log.wf("error sending ack: %s", tostring(err))
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
      U.log.w("received empty or invalid message")
      return false
    end
    
    -- Check for status query
    if isStatusQuery(text) then
      U.log.d("status query received")
      safeTelegramSend(getQueueStatusText())
      return true
    end
    
    -- Check for clear queue command
    if isClearQueueCommand(text) then
      local cleared = clearQueue()
      U.log.i("cleared queue, removed " .. cleared .. " messages")
      safeTelegramSend(string.format("🗑️ Cleared %d queued message%s", cleared, cleared == 1 and "" or "s"))
      return true
    end
    
    -- Check for abort command
    if isAbortCommand(text) then
      U.log.i("abort command received")
      sendCommand({ type = "abort" })
      M.busy = false
      M.clearTaskTimer()
      safeTelegramSend("🛑 Aborted current task")
      -- Don't clear queue - just abort current
      pcall(processNextInQueue)
      return true
    end
    
    -- Check for priority
    local isPriority, cleanText = checkPriority(text)
    cleanText = cleanText or text
    
    -- If priority and we're busy, steer the current task
    if isPriority and M.busy then
      U.log.i("priority message received while busy, steering")
      sendCommand({
        type = "steer",
        message = tostring(cleanText),
      })
      safeTelegramSend("⚡ Steering current task with priority message")
      -- Also queue in case steer doesn't fully handle it
      queueMessage(cleanText, true)
      return true
    end
    
    -- Queue the message
    local position = queueMessage(cleanText, isPriority)
    
    -- Log receipt
    local preview = #cleanText > 40 and (cleanText:sub(1, 40) .. "...") or cleanText
    U.log.f("Message received: \"%s\" (priority=%s, pos=%d)", preview, tostring(isPriority), position)
    
    -- Save to history
    appendToHistory({ type = "user", text = cleanText, priority = isPriority })
    
    -- Send immediate ack
    sendAck(isPriority, position)
    
    return true
  end)
  
  if not ok then
    U.log.wf("error handling message: %s", tostring(handled))
    return false
  end
  
  return handled or false
end

---Handle unhealthy process
local function handleUnhealthy()
  local ok, err = pcall(function()
    M.recordFailure()
    if not M.inCooldown then
      U.log.i("restarting unhealthy process")
      M.stop()
      M.start()
    end
  end)
  
  if not ok then
    U.log.wf("error in handleUnhealthy: %s", tostring(err))
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
      U.log.w("health check timeout - no response from previous ping")
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
      U.log.w("health check failed - process not running")
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
        U.log.w("health check response timeout")
        M.pendingHealthCheck = false
        handleUnhealthy()
      end
    end)
    
    -- Send get_state command as ping
    sendCommand({ type = "get_state" })
  end)
  
  if not ok then
    U.log.wf("error in healthCheck: %s", tostring(err))
  end
end

---Start the pi RPC process (safe)
---@return boolean success
function M.start()
  loadConfig()
  
  if not cfg or not cfg.enabled then
    U.log.i("disabled in config")
    return false
  end
  
  U.log.f("Starting (profile=%s)", cfg.defaultProfile or "default")
  
  local ok, result = pcall(function()
    
    -- Check if already running (safely)
    local isRunning = false
    if M.process then
      pcall(function() isRunning = M.process:isRunning() end)
    end
    
    if isRunning then
      U.log.i("already running")
      return true
    end
    
    if M.inCooldown then
      U.log.w("in cooldown, not starting")
      return false
    end
    
    -- Ensure directories exist (don't fail if this errors)
    pcall(ensureDirectories)
    
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
        -- Start health check timer
        if M.healthCheckTimer then
          pcall(function() M.healthCheckTimer:stop() end)
        end
        local interval = cfg.healthCheckIntervalSeconds or 30
        M.healthCheckTimer = hs.timer.doEvery(interval, healthCheck)
        
        return true
      else
        U.log.e("failed to start process")
        M.process = nil
        return false
      end
    else
      U.log.e("failed to create process")
      return false
    end
  end)
  
  if not ok then
    U.log.wf("error in start: %s", tostring(result))
    return false
  end
  
  if result then
    U.log.f("Started ✓ (health check every %ds)", cfg.healthCheckIntervalSeconds or 30)
  end
  
  return result or false
end

---Stop the pi RPC process (safe)
function M.stop()
  local ok, err = pcall(function()
    -- Stop all timers
    local timers = { "healthCheckTimer", "healthCheckResponseTimer", "restartTimer", "cooldownTimer" }
    for _, name in ipairs(timers) do
      if M[name] then
        pcall(function() M[name]:stop() end)
        M[name] = nil
      end
    end
    
    -- Stop task timeout timer
    M.clearTaskTimer()
    
    -- Terminate process if running
    if M.process then
      pcall(function()
        if M.process:isRunning() then
          U.log.i("stopping process")
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
    U.log.wf("error in stop: %s", tostring(err))
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
    ensureQueues()
    
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
      ensureDirectories()
      archiveOldHistory() -- Move old history files to archive
      M.start()
    else
      U.log.i("not enabled, skipping init")
    end
  end)
  
  if not ok then
    U.log.wf("error in init: %s", tostring(err))
  end
end

---Cleanup on reload (safe)
function M.cleanup()
  local ok, err = pcall(function()
    M.stop()
  end)
  
  if not ok then
    U.log.wf("error in cleanup: %s", tostring(err))
  end
end

return M
