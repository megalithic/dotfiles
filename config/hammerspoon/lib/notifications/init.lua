-- Notification delivery facade for bin/ntfy.
-- Native notification watching, rules, and dismissal live in notiwatchd.
--
local M = {}

-- Active notification delivery facade used by bin/ntfy.
M.initialized = false
M.sender = require("lib.notifications.send")

-- LIFECYCLE

---Initialize remote notification delivery integrations.
---@return boolean success True if initialization succeeded
---@usage N.init()
function M.init()
	if M.initialized then
		U.log.w("Notification delivery already initialized")
		return true
	end

	U.log.i("Initializing notification delivery...")

	M.initialized = true
	U.log.i("Notification delivery initialized ✓")
	return true
end

---Gracefully shut down notification delivery integrations.
---@return nil
function M.cleanup()
	U.log.i("Cleaning up notification delivery...")

	M.initialized = false
	U.log.i("Notification delivery cleaned up")
end

-- AI AGENT SEND API (convenience re-exports from sender module)

---Send a notification via the unified AI agent API
---Routes to appropriate channels based on attention state
---@param opts SendOpts { title, message, urgency?, phone?, question?, context? }
---@return SendResult { sent, channels, reason, questionId? }
---@usage N.send({ title = "Done", message = "Tests passed", urgency = "normal" })
---@usage N.send({ title = "Question", message = "Continue?", question = true, context = "main:claude" })
function M.send(opts)
	return M.sender.send(opts)
end

---Mark a question as answered (stops retry reminders)
---@param questionId string|nil Question ID returned by send()
---@param title string|nil Title to look up if no questionId
---@param message string|nil Message to look up if no questionId
---@return boolean success
---@usage N.answerQuestion(questionId)
---@usage N.answerQuestion(nil, "Question Title", "Question message")
function M.answerQuestion(questionId, title, message)
	return M.sender.answerQuestion(questionId, title, message)
end

---Get list of pending questions awaiting answers
---@return table[] Array of { id, title, timestamp, retryCount, age }
---@usage local pending = N.getPendingQuestions()
function M.getPendingQuestions()
	return M.sender.getPendingQuestions()
end

---Check current attention state
---@param context string|nil Calling context (e.g., "main:claude")
---@return { state: string, shouldNotify: string }
---@usage local attention = N.checkAttention("main:claude")
function M.checkAttention(context)
	return M.sender.checkAttention(context)
end

return M
