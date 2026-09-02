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

	local telegram = require("lib.interop.telegram")
	local telegramOk, telegramErr = pcall(function()
		return telegram.init({
			pollInterval = C.notifier and C.notifier.telegramPollInterval or 10,
			onMessage = function(msg)
				M.handleTelegramMessage(msg)
			end,
		})
	end)

	if not telegramOk then
		U.log.wf("Failed to initialize Telegram: %s", tostring(telegramErr))
	elseif not telegramErr then
		U.log.i("Telegram not configured (missing env vars)")
	else
		U.log.i("Telegram integration initialized ✓")
	end

	local gatewayEnabled = C.piGateway and C.piGateway.enabled ~= false
	if gatewayEnabled then
		local gatewayOk, piGateway = pcall(require, "lib.interop.pi-gateway")
		if gatewayOk and piGateway then
			local initOk, initErr = pcall(piGateway.init)
			if initOk then
				U.log.i("Pi Gateway initialized ✓")
			else
				U.log.wf("Failed to initialize Pi Gateway: %s", tostring(initErr))
			end
		else
			U.log.wf("Failed to load Pi Gateway: %s", tostring(piGateway))
		end
	end

	M.initialized = true
	U.log.i("Notification delivery initialized ✓")
	return true
end

---Gracefully shut down notification delivery integrations.
---@return nil
function M.cleanup()
	U.log.i("Cleaning up notification delivery...")

	local gatewayOk, piGateway = pcall(require, "lib.interop.pi-gateway")
	if gatewayOk and piGateway then
		piGateway.cleanup()
	end

	local telegramOk, telegram = pcall(require, "lib.interop.telegram")
	if telegramOk and telegram then
		telegram.cleanup()
	end

	M.initialized = false
	U.log.i("Notification delivery cleaned up")
end

-- AI AGENT SEND API (convenience re-exports from sender module)

---Send a notification via the unified AI agent API
---Routes to appropriate channels based on attention state
---@param opts SendOpts { title, message, urgency?, phone?, telegram?, question?, context? }
---@return SendResult { sent, channels, reason, questionId? }
---@usage N.send({ title = "Done", message = "Tests passed", urgency = "normal" })
---@usage N.send({ title = "Question", message = "Continue?", question = true, context = "main:claude" })
function M.send(opts)
	return M.sender.send(opts)
end

---Send a pre-formatted MarkdownV2 message directly to Telegram
---Use for rich formatting (code blocks, lists, etc.)
---@param text string Pre-formatted MarkdownV2 text
---@return boolean success, string reason
function M.sendTelegramFormatted(text)
	return M.sender.sendTelegramFormatted(text)
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

-- TELEGRAM INTEGRATION

---Handle incoming Telegram messages
---Routes to question answering or other handlers
---@param msg table Message from Telegram { type, text?, questionId?, value?, from? }
function M.handleTelegramMessage(msg)
	U.log.f("Telegram message received: type=%s, text=%s", msg.type, msg.text or "(none)")

	-- Handle callback queries (button presses) for question responses
	if msg.type == "callback" and msg.action == "answer" and msg.questionId then
		local success = M.answerQuestion(msg.questionId)
		if success then
			U.log.f("telegram - answered question %s with '%s'", msg.questionId, msg.value or "")
			-- Send confirmation
			local telegram = require("lib.interop.telegram")
			telegram.send("✓ Response recorded: " .. (msg.value or "acknowledged"))
		else
			U.log.wf("telegram - question %s not found or already answered", msg.questionId)
		end
		return
	end

	-- Handle voice/audio messages (transcribe and forward)
	if msg.type == "voice" or msg.type == "audio" then
		local telegram = require("lib.interop.telegram")
		local filePath = msg.filePath

		if not filePath then
			U.log.w("telegram - voice/audio message has no filePath")
			telegram.send("⚠️ Failed to process audio: no file path", { parse_mode = false })
			return
		end

		U.log.f("telegram - transcribing %s: %s", msg.type, filePath)
		telegram.send("🎤 Transcribing audio...", { parse_mode = false })

		-- Run whisperkit-cli to transcribe
		local task = hs.task.new("/usr/bin/env", function(exitCode, stdout, stderr)
			if exitCode ~= 0 then
				U.log.wf("whisperkit-cli failed (exit=%d): %s", exitCode, stderr or "")
				telegram.send("⚠️ Transcription failed", { parse_mode = false })
				return
			end

			local transcription = stdout and stdout:match("^%s*(.-)%s*$") -- trim
			if not transcription or #transcription == 0 then
				U.log.w("telegram - empty transcription")
				telegram.send("⚠️ Transcription was empty", { parse_mode = false })
				return
			end

			U.log.f("telegram - transcribed: %s", transcription:sub(1, 100))

			-- Forward transcription as if it were a text message
			local gatewayOk, piGateway = pcall(require, "lib.interop.pi-gateway")
			if gatewayOk and piGateway and piGateway.isAvailable() then
				local handled = piGateway.handleTelegramMessage(transcription)
				if handled then
					U.log.f("telegram - transcription routed to pi-gateway")
					return
				end
			end

			-- Fallback: Forward to active pi session
			local pi = require("lib.interop.pi")
			if pi.lastActiveSession then
				local success = pi.forwardMessage(transcription, "telegram-voice")
				if success then
					U.log.f("telegram - transcription forwarded to pi: %s", pi.lastActiveSession)
				else
					U.log.wf("telegram - failed to forward transcription")
					telegram.send("⚠️ Failed to forward transcription to pi", { parse_mode = false })
				end
			else
				U.log.f("telegram - transcription received but no pi session: %s", transcription)
				telegram.send("📝 Transcription (no active pi):\n" .. transcription, { parse_mode = false })
			end

			-- Clean up temp file
			os.remove(filePath)
		end, { "whisperkit-cli", "transcribe", "--audio-path", filePath })

		if task then
			task:start()
		else
			U.log.e("telegram - failed to create whisperkit-cli task")
			telegram.send("⚠️ Failed to start transcription", { parse_mode = false })
		end

		return
	end

	-- Handle text messages
	if msg.type == "message" and msg.text then
		local text = msg.text:lower()

		-- Check for pending questions command
		if text == "/pending" or text == "pending" then
			local pending = M.getPendingQuestions()
			local telegram = require("lib.interop.telegram")

			if #pending == 0 then
				telegram.send("No pending questions.")
			else
				local lines = { "*Pending Questions:*" }
				for i, q in ipairs(pending) do
					table.insert(
						lines,
						string.format("%d\\. %s \\(age: %ds\\)", i, telegram.escapeMarkdown(q.title), q.age)
					)
				end
				telegram.send(table.concat(lines, "\n"))
			end
			return
		end

		-- Check for status command
		if text == "/status" or text == "status" then
			local telegram = require("lib.interop.telegram")
			local pending = M.getPendingQuestions()
			telegram.send(string.format("✓ Notification system ready\\.\n%d pending questions\\.", #pending))
			return
		end

		-- If replying to a question, try to answer the most recent one
		if msg.replyToMessage then
			local pending = M.getPendingQuestions()
			if #pending > 0 then
				-- Answer the most recent pending question
				local q = pending[1]
				local success = M.answerQuestion(q.id)
				if success then
					local telegram = require("lib.interop.telegram")
					telegram.send("✓ Answered: " .. telegram.escapeMarkdown(q.title))
				end
			end
			return
		end

		-- Try pi-gateway first (dedicated RPC orchestrator)
		local gatewayOk, piGateway = pcall(require, "lib.interop.pi-gateway")
		if gatewayOk and piGateway and piGateway.isAvailable() then
			local handled = piGateway.handleTelegramMessage(msg.text)
			if handled then
				U.log.f("telegram - routed to pi-gateway")
				return
			end
		end

		-- Fallback: Forward to active pi session via socket (pi.lua)
		local pi = require("lib.interop.pi")
		if pi.lastActiveSession then
			local success = pi.forwardMessage(msg.text, "telegram")
			if success then
				U.log.f("telegram - forwarded to pi session: %s", pi.lastActiveSession)
				-- Acknowledge receipt
				local telegram = require("lib.interop.telegram")
				telegram.send("↪ Forwarded to pi")
			else
				U.log.wf("telegram - failed to forward to pi session")
			end
		else
			U.log.f('Telegram received (no active pi session, no gateway): "%s"', msg.text)
		end
	end
end

return M
