-- AI Agent Notification Send API
-- Unified entry point for all AI agent notifications
-- Handles attention detection, routing, and delivery
--
local M = {}

local types = require("lib.notifications.types")
local notifier = require("lib.notifications.notifier")

local ATTENTION = types.ATTENTION
local URGENCY = types.URGENCY

-- Get config with fallback defaults
local function getConfig()
  local cfg = C.notifier.agent or {}
  return {
    durations = cfg.durations or { normal = 5, high = 10, critical = 15 },
    questionRetry = cfg.questionRetry
      or { enabled = true, intervalSeconds = 300, maxRetries = 3, escalateOnRetry = true },
    pushover = cfg.pushover or { enabled = true },
    phone = cfg.phone or { enabled = true, cacheTTL = 604800 },
  }
end

-- STATE: Question tracking for retry system
local pendingQuestions = {} -- { [questionId] = { opts, timestamp, retryCount } }
local questionRetryTimer = nil

--------------------------------------------------------------------------------
-- ATTENTION DETECTION
--------------------------------------------------------------------------------

---Check display state (cheapest check, short-circuits everything)
---@return "awake"|"display_asleep"|"screen_locked"|"logged_out"
function M.checkDisplayState()
  -- Delegate to existing notifier function
  return notifier.checkDisplayState()
end

---Get the focused window title for terminal
---@return string|nil
function M.getFocusedWindowTitle() return notifier.getFocusedWindowTitle(TERMINAL) end

---Get the currently active tmux session:window:pane
---Queries tmux directly for authoritative pane-level detection
---Uses list-clients to find what the attached client is viewing
---@return string|nil Format: "session:window_index:pane_index" or nil if no tmux client
local function getActiveTmuxContext()
  -- Query tmux for the attached client's active session:window:pane
  -- list-clients gives us the actual context of what the user is viewing
  -- (display-message without -t target can return stale/wrong session)
  local cmd = "tmux list-clients -F '#{session_name}:#{window_index}:#{pane_index}' 2>/dev/null | head -1"
  local output, status = hs.execute(cmd)

  if status and output then
    local trimmed = output:match("^%s*(.-)%s*$")
    if trimmed and trimmed ~= "" then return trimmed end
  end

  return nil
end

---Check user attention state with context awareness
---@param context string|nil Calling context (e.g., "mega:1:0" for tmux session:window:pane)
---@return { state: string, shouldNotify: "full"|"subtle"|"remote_only" }
function M.checkAttention(context)
  -- 1. Check display state first (cheapest check, short-circuits everything)
  local displayState = M.checkDisplayState()
  if displayState ~= "awake" then return { state = displayState, shouldNotify = "remote_only" } end

  -- 2. Check if terminal is frontmost
  local frontmost = hs.application.frontmostApplication()
  if not frontmost or frontmost:bundleID() ~= TERMINAL then
    return { state = ATTENTION.TERMINAL_NOT_FOCUSED, shouldNotify = "full" }
  end

  -- 3. Terminal is focused - check if user viewing THIS exact pane
  if context then
    local activeContext = getActiveTmuxContext()
    if activeContext and activeContext == context then
      return { state = ATTENTION.PAYING_ATTENTION, shouldNotify = "subtle" }
    end
  end

  return { state = ATTENTION.NOT_PAYING_ATTENTION, shouldNotify = "full" }
end

--------------------------------------------------------------------------------
-- NOTIFICATION ROUTING
--------------------------------------------------------------------------------

-- Cache for environment variables (avoid repeated shell calls)
local envCache = {}
local envCacheTime = 0
local ENV_CACHE_TTL = 300 -- Cache for 5 minutes

---Get environment variable, falling back to login shell if not in Hammerspoon env
---@param name string Environment variable name
---@return string|nil
local function getEnvVar(name)
  -- Try Hammerspoon's environment first
  local value = os.getenv(name)
  if value and value ~= "" then return value end

  -- Check cache
  local now = os.time()
  if envCacheTime + ENV_CACHE_TTL > now and envCache[name] then return envCache[name] end

  -- Fall back to reading from login shell (for GUI apps that don't inherit shell env)
  -- Use printenv with the specific variable name through a login shell
  local cmd = string.format('/bin/zsh -l -c "printenv %s" 2>/dev/null', name)
  local output, status = hs.execute(cmd, true)

  if status and output then
    value = output:match("^%s*(.-)%s*$") -- trim whitespace
    if value and value ~= "" then
      envCache[name] = value
      envCacheTime = now
      return value
    end
  end

  return nil
end

---Send via Pushover API
---@param title string
---@param message string
---@param urgency string
---@return boolean success, string reason
function M.sendPushover(title, message, urgency)
  local cfg = getConfig().pushover
  if not cfg.enabled then return false, "disabled" end

  -- Get tokens from environment variables (set by agenix)
  local userToken = getEnvVar("PUSHOVER_USER_TOKEN")
  local appToken = getEnvVar("PUSHOVER_APP_TOKEN")

  if not userToken or not appToken then
    U.log.w("Pushover tokens not available in environment")
    return false, "missing_tokens"
  end

  -- Map urgency to Pushover priority
  local priority = 0
  if urgency == URGENCY.CRITICAL then
    priority = 1
  elseif urgency == URGENCY.HIGH then
    priority = 1
  end

  -- Build request body
  local body = string.format(
    "token=%s&user=%s&title=%s&message=%s&priority=%d",
    hs.http.encodeForQuery(appToken),
    hs.http.encodeForQuery(userToken),
    hs.http.encodeForQuery(title),
    hs.http.encodeForQuery(message),
    priority
  )

  -- Send async HTTP request
  hs.http.asyncPost(
    "https://api.pushover.net/1/messages.json",
    body,
    { ["Content-Type"] = "application/x-www-form-urlencoded" },
    function(status, responseBody, headers)
      if status == 200 then
        U.log.d("Pushover notification sent successfully")
      else
        U.log.wf("Pushover notification failed: status=%d, body=%s", status, responseBody or "")
      end
    end
  )

  return true, "sent"
end

-- Phone number cache (fetched from Contacts app)
local phoneCache = {
  number = nil,
  timestamp = 0,
}

---Get phone number from macOS Contacts (with caching)
---Looks up current user's contact card and finds iPhone number
---@return string|nil
local function getPhoneNumber()
  local cfg = getConfig().phone
  local cacheTTL = cfg.cacheTTL or 604800 -- 7 days default

  -- Check cache first
  local now = os.time()
  if phoneCache.number and (now - phoneCache.timestamp) < cacheTTL then return phoneCache.number end

  -- Get current user's full name from dscl
  local fullName, status = hs.execute("dscl . -read /Users/$(whoami) RealName | tail -1 | sed 's/^ //'")
  if not status or not fullName or fullName == "" then
    U.log.w("Could not retrieve full name for current user")
    return nil
  end
  fullName = fullName:match("^%s*(.-)%s*$") -- trim

  -- Fetch phone number from Contacts via osascript shell command
  -- Uses single-line AppleScript to avoid escaping issues
  local cmd = string.format(
    [[osascript -e 'tell application "Contacts"' -e 'set p to first person whose name is "%s"' -e 'set ph to missing value' -e 'repeat with a in phones of p' -e 'if (label of a as text) contains "iPhone" then' -e 'set ph to value of a' -e 'exit repeat' -e 'end if' -e 'end repeat' -e 'if ph is missing value then set ph to value of first phone of p' -e 'quit' -e 'return ph' -e 'end tell' 2>/dev/null]],
    fullName
  )

  local phoneNumber, ok = hs.execute(cmd)

  if not ok or not phoneNumber or phoneNumber == "" then
    U.log.w("Could not retrieve phone number from Contacts")
    return nil
  end

  phoneNumber = phoneNumber:match("^%s*(.-)%s*$") -- trim

  -- Cache the result
  phoneCache.number = phoneNumber
  phoneCache.timestamp = now

  U.log.f("Phone number cached from Contacts for %s", fullName)
  return phoneNumber
end

---Escape message for AppleScript (hs.messages.iMessage uses AppleScript internally)
---Escapes double quotes with backslash to prevent AppleScript syntax errors
---@param str string The string to escape
---@return string The escaped string safe for AppleScript
local function escapeForAppleScript(str)
  if not str then return "" end
  -- Escape backslashes first, then double quotes
  -- AppleScript in hs.messages expects backslash-escaped quotes
  return str:gsub("\\", "\\\\"):gsub('"', '\\"')
end

---Send via iMessage to phone
---@param title string
---@param message string
---@return boolean success, string reason
function M.sendPhone(title, message)
  local cfg = getConfig().phone
  if not cfg.enabled then return false, "disabled" end

  -- Get phone number from Contacts (cached)
  local phoneNumber = getPhoneNumber()
  if not phoneNumber then return false, "missing_phone" end

  -- Escape title and message for AppleScript (prevents quote escaping errors)
  local safeTitle = escapeForAppleScript(title)
  local safeMessage = escapeForAppleScript(message)

  -- Format message for SMS/iMessage with hammerspork prefix
  local fullMessage = string.format("🤖 [from hammerspork] %s: %s", safeTitle, safeMessage)

  -- Use hs.messages for iMessage with timeout protection
  -- The pcall catches Lua errors, but AppleScript errors are logged separately
  local success, err = pcall(function() hs.messages.iMessage(phoneNumber, fullMessage) end)

  if success then
    U.log.d("Phone notification sent via iMessage")
    return true, "sent"
  else
    U.log.wf("Failed to send iMessage: %s", tostring(err))
    return false, "imessage_failed"
  end
end

---Send canvas notification (visual overlay)
---@param title string
---@param message string
---@param opts? {duration?: number, appImageID?: string, includeProgram?: boolean, [string]: any}
---@return boolean success
function M.sendCanvas(title, message, opts)
  opts = U.defaults(opts, {
    duration = 5,
    appImageID = "hal9000",
    includeProgram = true,
  })

  notifier.sendCanvasNotification(title, message, opts)
  return true
end

---Send macOS notification center notification
---@param title string
---@param message string
---@return boolean success
function M.sendMacOS(title, message)
  notifier.sendMacOSNotification(title, "", message)
  return true
end

---Route notification to appropriate channels based on attention state
---@param opts SendOpts
---@param attention { state: string, shouldNotify: string }
---@return string[] channels List of channels used
function M.routeNotification(opts, attention)
  local channels = {}
  local cfg = getConfig()

  -- Determine which channels to use based on attention state
  local shouldNotify = attention.shouldNotify

  -- ALWAYS send to macOS Notification Center
  -- This ensures all notifications go through the unified watcher/rule system
  -- The watcher will then route to canvas based on rules
  if shouldNotify == "full" or shouldNotify == "subtle" then
    M.sendMacOS(opts.title, opts.message)
    table.insert(channels, "macos")
  end
  -- "remote_only" = no local notifications (display asleep/locked)

  -- Phone: send if critical, explicitly requested, or remote_only (replaces Pushover)
  local shouldSendPhone = opts.phone or opts.urgency == URGENCY.CRITICAL or shouldNotify == "remote_only"

  if shouldSendPhone then
    local ok, _ = M.sendPhone(opts.title, opts.message)
    if ok then table.insert(channels, "phone") end
  end

  -- Pushover: DISABLED - only send if explicitly requested with -P flag
  if opts.pushover then
    local ok, _ = M.sendPushover(opts.title, opts.message, opts.urgency)
    if ok then table.insert(channels, "pushover") end
  end

  return channels
end

--------------------------------------------------------------------------------
-- QUESTION RETRY SYSTEM
--------------------------------------------------------------------------------

---Generate a question ID from title and message
---@param title string
---@param message string
---@return string
local function generateQuestionId(title, message)
  -- Use hs.hash if available, otherwise simple concatenation
  local content = title .. "|" .. message
  if hs.hash then
    return hs.hash.MD5(content)
  else
    -- Fallback: simple hash-like string
    local hash = 0
    for i = 1, #content do
      hash = ((hash * 31) + string.byte(content, i)) % 2147483647
    end
    return string.format("%08x", hash)
  end
end

---Track a question for retry
---@param opts SendOpts
---@return string questionId
function M.trackQuestion(opts)
  local questionId = generateQuestionId(opts.title, opts.message)

  pendingQuestions[questionId] = {
    opts = opts,
    timestamp = os.time(),
    retryCount = 0,
  }

  -- Start retry timer if not running
  if not questionRetryTimer then M.startQuestionRetryTimer() end

  U.log.df("Question tracked: %s - %s", questionId, opts.title)
  return questionId
end

---Mark a question as answered (remove from pending)
---@param questionId string|nil If nil, clears by title+message lookup
---@param title string|nil Used for lookup if questionId is nil
---@param message string|nil Used for lookup if questionId is nil
---@return boolean success
function M.answerQuestion(questionId, title, message)
  -- If no questionId provided, try to find by title+message
  if not questionId and title and message then questionId = generateQuestionId(title, message) end

  if not questionId or not pendingQuestions[questionId] then return false end

  pendingQuestions[questionId] = nil
  U.log.df("Question answered: %s", questionId)

  -- Stop timer if no more questions
  if next(pendingQuestions) == nil and questionRetryTimer then
    questionRetryTimer:stop()
    questionRetryTimer = nil
    U.log.d("Question retry timer stopped - no pending questions")
  end

  return true
end

---Start the question retry timer
function M.startQuestionRetryTimer()
  local cfg = getConfig().questionRetry

  if not cfg.enabled then return end

  -- Check every 60 seconds for questions that need retry
  questionRetryTimer = hs.timer.doEvery(60, function()
    local now = os.time()

    for id, q in pairs(pendingQuestions) do
      local elapsed = now - q.timestamp

      if elapsed >= cfg.intervalSeconds then
        if q.retryCount >= cfg.maxRetries then
          -- Give up after max retries
          pendingQuestions[id] = nil
          U.log.wf("Question retry limit reached: %s", q.opts.title)
        else
          -- Retry with escalation
          q.retryCount = q.retryCount + 1
          q.timestamp = now

          U.log.f("Retrying question (%d/%d): %s", q.retryCount, cfg.maxRetries, q.opts.title)

          -- Send reminder (don't re-track as question)
          M.send({
            title = "⏰ REMINDER: " .. q.opts.title,
            message = q.opts.message,
            urgency = URGENCY.HIGH,
            phone = cfg.escalateOnRetry,
            question = false, -- Don't re-track
          })
        end
      end
    end

    -- Stop timer if no more questions
    if next(pendingQuestions) == nil then
      questionRetryTimer:stop()
      questionRetryTimer = nil
      U.log.d("Question retry timer stopped - no pending questions")
    end
  end)

  U.log.d("Question retry timer started")
end

---Get list of pending questions (for debugging/status)
---@return table
function M.getPendingQuestions()
  local result = {}
  for id, q in pairs(pendingQuestions) do
    table.insert(result, {
      id = id,
      title = q.opts.title,
      timestamp = q.timestamp,
      retryCount = q.retryCount,
      age = os.time() - q.timestamp,
    })
  end
  return result
end

--------------------------------------------------------------------------------
-- MAIN SEND API
--------------------------------------------------------------------------------

---Send a notification through the unified API
---@param opts SendOpts
---@return SendResult
function M.send(opts)
  -- Validate required fields
  if not opts.title or opts.title == "" then return { sent = false, channels = {}, reason = "missing_title" } end
  if not opts.message or opts.message == "" then return { sent = false, channels = {}, reason = "missing_message" } end

  -- Normalize urgency
  opts.urgency = opts.urgency or URGENCY.NORMAL
  if opts.urgency ~= URGENCY.NORMAL and opts.urgency ~= URGENCY.HIGH and opts.urgency ~= URGENCY.CRITICAL then
    opts.urgency = URGENCY.NORMAL
  end

  -- Check attention state
  local attention = M.checkAttention(opts.context)

  -- Route notification
  local channels = M.routeNotification(opts, attention)

  -- Track question if requested
  local questionId = nil
  if opts.question then questionId = M.trackQuestion(opts) end

  -- Build result
  local result = {
    sent = #channels > 0,
    channels = channels,
    reason = attention.state,
    questionId = questionId,
  }
  -- NOTE: too much noise for now
  -- -- Log the notification
  -- U.log.f(
  --   "N.send: title=%s, urgency=%s, attention=%s, channels=[%s]",
  --   opts.title:sub(1, 30),
  --   opts.urgency,
  --   attention.state,
  --   table.concat(channels, ",")
  -- )

  return result
end

return M
