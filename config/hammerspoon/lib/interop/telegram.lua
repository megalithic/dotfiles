-- Telegram Bot Integration
-- Provides send/receive capabilities for AI agent notifications
--
-- Setup:
-- 1. Create bot via @BotFather on Telegram
-- 2. Message your bot to get chat_id (use getUpdates API)
-- 3. Add to agenix secrets:
--    export TELEGRAM_BOT_TOKEN="your-bot-token"
--    export TELEGRAM_CHAT_ID="your-chat-id"
--
local M = {}

-- State
M.initialized = false
M.pollTimer = nil
M.lastUpdateId = 0
M.messageCallback = nil -- Called when a message is received

-- Config defaults
local DEFAULT_POLL_INTERVAL = 10 -- seconds
local API_BASE = "https://api.telegram.org/bot"

-- Environment variable cache (shared pattern with send.lua)
local envCache = {}
local envCacheTime = 0
local ENV_CACHE_TTL = 300 -- 5 minutes

---Get environment variable with agenix secrets fallback
---@param name string
---@return string|nil
local function getEnvVar(name)
  local value = os.getenv(name)
  if value and value ~= "" then return value end

  local now = os.time()
  if envCacheTime + ENV_CACHE_TTL > now and envCache[name] then return envCache[name] end

  -- Source agenix secrets directly (Hammerspoon doesn't inherit shell env)
  -- Path: $(getconf DARWIN_USER_TEMP_DIR)/agenix/env-vars
  local cmd = string.format(
    '/bin/bash -c \'source "$(getconf DARWIN_USER_TEMP_DIR)/agenix/env-vars" 2>/dev/null && echo "${%s:-}"\'',
    name
  )
  local output, status = hs.execute(cmd)

  if status and output then
    -- Trim whitespace and check for reasonable length (tokens are ~50-100 chars, not thousands)
    value = output:match("^%s*(.-)%s*$")
    if value and value ~= "" and #value < 500 then
      envCache[name] = value
      envCacheTime = now
      return value
    end
  end

  return nil
end

---Get bot token from environment
---@return string|nil
local function getToken()
  return getEnvVar("TELEGRAM_BOT_TOKEN")
end

---Get chat ID from environment
---@return string|nil
local function getChatId()
  return getEnvVar("TELEGRAM_CHAT_ID")
end

---Build API URL
---@param method string API method name
---@return string|nil url, string|nil error
local function apiUrl(method)
  local token = getToken()
  if not token then return nil, "missing_token" end
  return API_BASE .. token .. "/" .. method, nil
end

--------------------------------------------------------------------------------
-- SEND MESSAGE
--------------------------------------------------------------------------------

---Send a message to Telegram
---@param text string Message text (supports Markdown)
---@param opts? { parse_mode?: string, reply_markup?: table }
---@return boolean success, string reason
function M.send(text, opts)
  opts = opts or {}

  local url, err = apiUrl("sendMessage")
  if not url then
    U.log.w("Telegram: " .. (err or "unknown error"))
    return false, err or "api_error"
  end

  local chatId = getChatId()
  if not chatId then
    U.log.w("Telegram: missing chat_id")
    return false, "missing_chat_id"
  end

  local payload = {
    chat_id = chatId,
    text = text,
    parse_mode = opts.parse_mode or "MarkdownV2",
  }

  -- Add reply keyboard if provided (useful for quick responses)
  if opts.reply_markup then
    payload.reply_markup = opts.reply_markup
  end

  local headers = { ["Content-Type"] = "application/json" }
  local body = hs.json.encode(payload)

  hs.http.asyncPost(url, body, headers, function(status, responseBody, responseHeaders)
    if status == 200 then
      U.log.f("Telegram: message sent successfully")
    else
      U.log.wf("Telegram: send failed, status=%d, body=%s", status, responseBody or "")
    end
  end)

  return true, "sent"
end

---Send a notification with title and message
---@param title string
---@param message string
---@param opts? { urgency?: string, questionId?: string }
---@return boolean success, string reason
function M.sendNotification(title, message, opts)
  opts = opts or {}

  -- Format message with title
  local text = "*" .. M.escapeMarkdown(title) .. "*\n\n" .. M.escapeMarkdown(message)

  -- Add question context if this is a question
  local replyMarkup = nil
  if opts.questionId then
    -- Add inline keyboard for quick yes/no responses
    replyMarkup = {
      inline_keyboard = {
        {
          { text = "✓ Yes", callback_data = "answer:" .. opts.questionId .. ":yes" },
          { text = "✗ No", callback_data = "answer:" .. opts.questionId .. ":no" },
        },
      },
    }
    text = text .. "\n\n_Reply to this message or tap a button to respond._"
  end

  return M.send(text, { reply_markup = replyMarkup })
end

---Escape special Markdown characters
---@param text string
---@return string
function M.escapeMarkdown(text)
  if not text then return "" end
  -- Escape Markdown special chars: _ * [ ] ( ) ~ ` > # + - = | { } . !
  return text:gsub("([_%*%[%]%(%)~`>#+%-=|{}%.!])", "\\%1")
end

---Send a pre-formatted MarkdownV2 message (no escaping)
---Use this for rich formatting - caller is responsible for proper escaping
---Falls back to plain text if MarkdownV2 parsing fails
---@param text string Pre-formatted MarkdownV2 text
---@param opts? { reply_markup?: table }
---@return boolean success, string reason
function M.sendFormatted(text, opts)
  opts = opts or {}

  local url, err = apiUrl("sendMessage")
  if not url then
    U.log.w("Telegram: " .. (err or "unknown error"))
    return false, err or "api_error"
  end

  local chatId = getChatId()
  if not chatId then
    U.log.w("Telegram: missing chat_id")
    return false, "missing_chat_id"
  end

  local headers = { ["Content-Type"] = "application/json" }

  -- Try MarkdownV2 first (synchronous so we can retry)
  local payload = {
    chat_id = chatId,
    text = text,
    parse_mode = "MarkdownV2",
  }
  if opts.reply_markup then
    payload.reply_markup = opts.reply_markup
  end

  local status, body = hs.http.post(url, hs.json.encode(payload), headers)

  if status == 200 then
    U.log.f("Telegram: formatted message sent successfully")
    return true, "sent"
  end

  -- If MarkdownV2 failed (likely parse error), retry as plain text
  if status == 400 and body and body:match("can't parse entities") then
    U.log.wf("Telegram: MarkdownV2 parse failed, retrying as plain text")
    payload.parse_mode = nil
    status, body = hs.http.post(url, hs.json.encode(payload), headers)

    if status == 200 then
      U.log.f("Telegram: plain text fallback sent successfully")
      return true, "sent_plain"
    end
  end

  U.log.wf("Telegram: sendFormatted failed, status=%d, body=%s", status, body or "")
  return false, "send_failed"
end

--------------------------------------------------------------------------------
-- RECEIVE MESSAGES (Long Polling)
--------------------------------------------------------------------------------

---Process incoming updates from Telegram
---@param updates table Array of update objects
local function processUpdates(updates)
  local allowedChatId = getChatId()
  
  for _, update in ipairs(updates) do
    -- Track the latest update ID for offset
    if update.update_id >= M.lastUpdateId then
      M.lastUpdateId = update.update_id + 1
    end

    -- Security: only process messages from allowed chat_id
    local msgChatId = nil
    if update.message and update.message.chat then
      msgChatId = tostring(update.message.chat.id)
    elseif update.callback_query and update.callback_query.message and update.callback_query.message.chat then
      msgChatId = tostring(update.callback_query.message.chat.id)
    end
    
    if msgChatId and msgChatId ~= allowedChatId then
      U.log.wf("Telegram: ignoring message from unauthorized chat_id: %s", msgChatId)
      goto continue
    end

    -- Handle regular messages
    if update.message and update.message.text then
      local msg = update.message
      U.log.df("Telegram: received message from %s: %s", msg.from and msg.from.username or "unknown", msg.text)

      if M.messageCallback then
        M.messageCallback({
          type = "message",
          text = msg.text,
          from = msg.from,
          chat = msg.chat,
          messageId = msg.message_id,
          replyToMessage = msg.reply_to_message,
        })
      end
    end

    -- Handle callback queries (inline button presses)
    if update.callback_query then
      local query = update.callback_query
      U.log.df("Telegram: received callback query: %s", query.data or "")

      -- Parse callback data (format: "action:questionId:value")
      local action, questionId, value = (query.data or ""):match("^(%w+):([^:]+):(.+)$")

      if action == "answer" and questionId then
        if M.messageCallback then
          M.messageCallback({
            type = "callback",
            action = action,
            questionId = questionId,
            value = value,
            from = query.from,
            messageId = query.message and query.message.message_id,
          })
        end

        -- Acknowledge the callback query
        M.answerCallbackQuery(query.id, "Response recorded: " .. (value or ""))
      end
    end
    
    ::continue::
  end
end

---Answer a callback query (acknowledge button press)
---@param callbackQueryId string
---@param text? string Optional notification text
function M.answerCallbackQuery(callbackQueryId, text)
  local url, err = apiUrl("answerCallbackQuery")
  if not url then return end

  local payload = {
    callback_query_id = callbackQueryId,
    text = text,
  }

  local headers = { ["Content-Type"] = "application/json" }
  hs.http.asyncPost(url, hs.json.encode(payload), headers, function() end)
end

-- Track if a poll is currently in flight (to avoid overlapping requests)
local pollInFlight = false

---Poll for new updates
local function poll()
  -- Skip if already polling (long polling can take up to 30s)
  if pollInFlight then return end
  
  local url, err = apiUrl("getUpdates")
  if not url then return end

  -- Add offset to only get new updates, and timeout for long polling
  -- Using 30s timeout for efficient long polling
  url = url .. "?offset=" .. M.lastUpdateId .. "&timeout=30"

  pollInFlight = true
  hs.http.asyncGet(url, nil, function(status, body, headers)
    pollInFlight = false
    
    if status == 200 and body then
      local ok, result = pcall(hs.json.decode, body)
      if ok and result and result.ok and result.result then
        processUpdates(result.result)
      end
    elseif status ~= 0 and status ~= 409 then
      -- Status 0 = timeout (normal for long polling)
      -- Status 409 = conflict (another request in flight, shouldn't happen now)
      U.log.wf("Telegram: poll failed, status=%d", status)
    end
  end)
end

--------------------------------------------------------------------------------
-- LIFECYCLE
--------------------------------------------------------------------------------

---Initialize Telegram integration
---@param opts? { pollInterval?: number, onMessage?: function }
---@return boolean success
function M.init(opts)
  opts = opts or {}

  if M.initialized then
    U.log.w("Telegram: already initialized")
    return true
  end

  -- Check for required credentials
  local token = getToken()
  local chatId = getChatId()

  if not token or not chatId then
    U.log.w("Telegram: missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID")
    return false
  end

  -- Set message callback
  M.messageCallback = opts.onMessage

  -- Start polling timer
  local interval = opts.pollInterval or DEFAULT_POLL_INTERVAL
  M.pollTimer = hs.timer.doEvery(interval, poll)

  -- Do an initial poll
  poll()

  M.initialized = true
  U.log.i("Telegram: initialized with " .. interval .. "s poll interval")

  return true
end

---Stop Telegram integration
function M.cleanup()
  if M.pollTimer then
    M.pollTimer:stop()
    M.pollTimer = nil
  end

  M.initialized = false
  M.messageCallback = nil
  U.log.i("Telegram: cleaned up")
end

---Check if Telegram is configured and ready
---@return boolean ready
function M.isReady()
  return M.initialized and getToken() ~= nil and getChatId() ~= nil
end

---Get bot info (useful for testing)
---@param callback function Called with (success, info)
function M.getMe(callback)
  local url, err = apiUrl("getMe")
  if not url then
    callback(false, err)
    return
  end

  hs.http.asyncGet(url, nil, function(status, body)
    if status == 200 and body then
      local ok, result = pcall(hs.json.decode, body)
      if ok and result and result.ok then
        callback(true, result.result)
        return
      end
    end
    callback(false, "api_error")
  end)
end

return M
