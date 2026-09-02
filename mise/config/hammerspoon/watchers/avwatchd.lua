-- avwatchd: persistent Unix-socket consumer for AV and meeting state.
-- Observes transitions and exports state for notification HUD suppression.

local M = {}
local log = U.logFor("avwatchd")
local SOCKET = os.getenv("HOME") .. "/.local/state/avwatchd/sock"
local RECONNECT_DELAY = 2
local STATE_TTL = 15

local socket = nil
local reconnectTimer = nil
local staleTimer = nil
local generation = 0
local prev = nil

-- Latest daemon snapshot. Notification attention checks read this directly.
M.state = nil

local function stopTimer(timer)
	if timer then
		timer:stop()
	end
	return nil
end

local function value(value)
	return value == nil and "?" or tostring(value)
end

local function micOwners(p)
	if type(p.micOwners) ~= "table" then
		return "<invalid:" .. type(p.micOwners) .. ">"
	end
	local owners = {}
	for _, owner in ipairs(p.micOwners) do
		table.insert(owners, tostring(owner))
	end
	return table.concat(owners, ",")
end

local function context(p)
	return string.format(
		"event=%s daemonTime=%s meeting=%s app=%s target=%s sharing=%s source=%s",
		p.event or "?",
		p.t or "?",
		p.meetingState or "?",
		p.meetingApp or "-",
		p.meetingTargetId or "-",
		value(p.sharing),
		p.sharingSource or "?"
	)
end

local function clearState(reason)
	staleTimer = stopTimer(staleTimer)
	if M.state then
		log.wf("state cleared: reason=%s, last={%s}", reason, context(M.state))
	end
	M.state = nil
	prev = nil
end

local function applyState(p)
	if prev then
		if
			p.inMeeting ~= prev.inMeeting
			or p.meetingState ~= prev.meetingState
			or p.meetingApp ~= prev.meetingApp
			or p.meetingTargetId ~= prev.meetingTargetId
		then
			log.f(
				"meeting transition detected: %s/%s -> %s/%s (%s)",
				value(prev.inMeeting),
				prev.meetingState or "?",
				value(p.inMeeting),
				p.meetingState or "?",
				context(p)
			)
		end

		local previousOwners = micOwners(prev)
		local currentOwners = micOwners(p)
		if p.micActive ~= prev.micActive or currentOwners ~= previousOwners then
			log.f(
				"microphone transition detected: %s [%s] -> %s [%s] (%s)",
				value(prev.micActive),
				previousOwners,
				value(p.micActive),
				currentOwners,
				context(p)
			)
		end

		if p.cameraActive ~= prev.cameraActive then
			log.f(
				"camera transition detected: %s -> %s (%s)",
				value(prev.cameraActive),
				value(p.cameraActive),
				context(p)
			)
		end

		if
			p.sharing ~= prev.sharing
			or p.sharingSource ~= prev.sharingSource
			or p.browserTabSharing ~= prev.browserTabSharing
			or p.osCaptureSharing ~= prev.osCaptureSharing
		then
			log.f(
				"sharing transition detected: %s/%s -> %s/%s (browser=%s, os=%s, %s)",
				value(prev.sharing),
				prev.sharingSource or "?",
				value(p.sharing),
				p.sharingSource or "?",
				value(p.browserTabSharing),
				value(p.osCaptureSharing),
				context(p)
			)
		end
	else
		log.f(
			"initial state detected: mic=%s [%s], camera=%s, browserShare=%s, osShare=%s (%s)",
			value(p.micActive),
			micOwners(p),
			value(p.cameraActive),
			value(p.browserTabSharing),
			value(p.osCaptureSharing),
			context(p)
		)
	end

	M.state = p
	prev = p
end

local function armStaleTimer(currentGeneration)
	staleTimer = stopTimer(staleTimer)
	staleTimer = hs.timer.doAfter(STATE_TTL, function()
		if generation ~= currentGeneration then
			return
		end
		clearState("state expired")
		if socket then
			socket:disconnect()
			socket = nil
		end
		M:_connect(currentGeneration)
	end)
end

local function handleLine(line, currentGeneration)
	if generation ~= currentGeneration or line == "" then
		return
	end
	local ok, p = pcall(hs.json.decode, line)
	if not ok or not p or type(p.inMeeting) ~= "boolean" then
		return
	end
	applyState(p)
	armStaleTimer(currentGeneration)
end

local function scheduleReconnect(currentGeneration)
	if generation ~= currentGeneration or reconnectTimer then
		return
	end
	reconnectTimer = hs.timer.doAfter(RECONNECT_DELAY, function()
		reconnectTimer = nil
		M:_connect(currentGeneration)
	end)
end

function M:_connect(currentGeneration)
	if generation ~= currentGeneration or socket then
		return
	end
	if not hs.fs.attributes(SOCKET) then
		scheduleReconnect(currentGeneration)
		return
	end

	local sock
	sock = hs.socket.new(function(data)
		if generation ~= currentGeneration then
			return
		end
		if not data or data == "" then
			if socket then
				socket:disconnect()
				socket = nil
			end
			clearState("daemon disconnected")
			scheduleReconnect(currentGeneration)
			return
		end
		for line in data:gmatch("[^\n]+") do
			handleLine(line, currentGeneration)
		end
		if socket and socket:connected() then
			socket:read("\n")
		end
	end)

	socket = sock
	local started = sock:connect(SOCKET, function()
		if generation ~= currentGeneration or socket ~= sock then
			sock:disconnect()
			return
		end
		log.i("connected")
		sock:write('{"cmd":"get"}\n')
		sock:read("\n")
	end)

	if not started then
		socket = nil
		scheduleReconnect(currentGeneration)
	end
end

function M:start()
	log.i("starting persistent subscriber")
	generation = generation + 1
	local currentGeneration = generation
	clearState("watcher reset")
	reconnectTimer = stopTimer(reconnectTimer)
	if socket then
		socket:disconnect()
		socket = nil
	end
	M:_connect(currentGeneration)
end

function M:stop()
	log.i("stopping subscriber")
	generation = generation + 1
	reconnectTimer = stopTimer(reconnectTimer)
	staleTimer = stopTimer(staleTimer)
	if socket then
		socket:disconnect()
		socket = nil
	end
	clearState("watcher stopped")
end

return M
