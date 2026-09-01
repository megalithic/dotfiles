-- avwatchd: persistent Unix-socket consumer for AV and meeting state.
-- Policy stays here: Music pause, meeting-share DND, and exported HUD state.

local M = {}
local SOCKET = os.getenv("HOME") .. "/.local/state/avwatchd/sock"
local RECONNECT_DELAY = 2
local STATE_TTL = 15

local socket = nil
local reconnectTimer = nil
local staleTimer = nil
local generation = 0
local prev = nil
local dndForced = false

-- Latest daemon snapshot. Notification attention checks read this directly.
M.state = nil

local function stopTimer(timer)
	if timer then
		timer:stop()
	end
	return nil
end

local function restoreDND(reason)
	if not dndForced then
		return
	end
	dndForced = false
	U.dnd(false)
	U.log.i("[avwatchd] " .. reason .. "; DND restored")
end

local function clearState(reason)
	staleTimer = stopTimer(staleTimer)
	M.state = nil
	prev = nil
	restoreDND(reason)
end

local function applyPolicies(p)
	local wasInMeeting = prev and prev.inMeeting or false

	if p.inMeeting and not wasInMeeting then
		U.log.i("[avwatchd] meeting started; Music paused")
		pcall(function()
			hs.osascript.applescript('tell application "Music" to pause')
		end)
	end

	if p.sharing and p.inMeeting and not dndForced then
		dndForced = true
		U.dnd(true, "meeting")
		U.log.i("[avwatchd] meeting share started; DND on")
	elseif dndForced and (not p.sharing or not p.inMeeting) then
		restoreDND("meeting share stopped")
	end

	if prev then
		if p.meetingState ~= prev.meetingState then
			U.log.df("[avwatchd] meetingState: %s -> %s", prev.meetingState, p.meetingState)
		end
		if p.micActive ~= prev.micActive then
			U.log.df("[avwatchd] mic: %s -> %s", tostring(prev.micActive), tostring(p.micActive))
		end
		if p.cameraActive ~= prev.cameraActive then
			U.log.df("[avwatchd] camera: %s -> %s", tostring(prev.cameraActive), tostring(p.cameraActive))
		end
	else
		U.log.df(
			"[avwatchd] initial state: meeting=%s, mic=%s, camera=%s, sharing=%s",
			p.meetingState or "?",
			tostring(p.micActive),
			tostring(p.cameraActive),
			tostring(p.sharing)
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
	applyPolicies(p)
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
		U.log.i("[avwatchd] connected")
		sock:write('{"cmd":"get"}\n')
		sock:read("\n")
	end)

	if not started then
		socket = nil
		scheduleReconnect(currentGeneration)
	end
end

function M:start()
	U.log.i("[avwatchd] starting persistent subscriber")
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
	U.log.i("[avwatchd] stopping subscriber")
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
