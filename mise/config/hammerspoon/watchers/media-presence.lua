-- media-presence: Unix-socket consumer for media-presenced daemon.
-- Polls the daemon for presence state and dispatches transitions.
-- Replaces camera.lua heuristics with authoritative AV + CDP signals.

local M = {}
local SOCKET = os.getenv("HOME") .. "/.local/state/media-presence/sock"
local POLL_INTERVAL = 3 -- seconds between polls
local STATE_TTL = POLL_INTERVAL * 3

local timer = nil
local prev = nil -- previous presence snapshot, used for edge detection
local lastSuccessAt = nil
local generation = 0

-- Latest presence snapshot, readable by other modules (e.g. notification
-- attention checks suppress HUDs while sharing). Nil until first poll.
M.state = nil

-- Whether this watcher enabled DND for an active meeting screenshare.
local dndForced = false

--- Poll the daemon for current presence, detect transitions, dispatch actions.
local function poll()
	if lastSuccessAt and hs.timer.secondsSinceEpoch() - lastSuccessAt > STATE_TTL then
		M.state = nil
		lastSuccessAt = nil
		if dndForced then
			dndForced = false
			U.dnd(false)
			U.log.w("[media-presence] state expired; DND restored")
		end
	end
	if not hs.fs.attributes(SOCKET) then
		return
	end

	local getCmd = string.format('echo \'{"cmd":"get"}\' | /usr/bin/nc -w 1 -U %s', SOCKET)
	local pollGeneration = generation
	hs.task
		.new("/bin/sh", function(exitCode, stdOut, _)
			if pollGeneration ~= generation then
				return
			end
			if exitCode ~= 0 or not stdOut then
				return
			end

			local ok, p = pcall(hs.json.decode, stdOut)
			if not ok or not p then
				return
			end

			M.state = p
			lastSuccessAt = hs.timer.secondsSinceEpoch()

			if not prev then
				prev = p
				U.log.df(
					"[media-presence] initial state: meeting=%s, mic=%s, camera=%s, sharing=%s",
					p.meetingState or "?",
					tostring(p.micActive),
					tostring(p.cameraActive),
					tostring(p.sharing)
				)
				return
			end

			-- Detect transitions by comparing with previous snapshot
			local wasInMeeting = prev.inMeeting
			local wasSharing = prev.sharing

			-- PTT mode enforcement moved to miccheckd, which subscribes to
			-- media-presenced's socket directly. Hammerspoon keeps music/DND only
			-- (manual control still available via require("lib.micctl")).

			-- meeting start: idle/lobby → joined
			if p.inMeeting and not wasInMeeting then
				U.log.i("[media-presence] meeting started → music paused")
				pcall(function()
					hs.osascript.applescript('tell application "Music" to pause')
				end)
			end

			-- screenshare start: only enforce DND for meeting screenshares.
			-- replayd also logs one-shot screenshots as ScreenCaptureKit activity.
			if p.sharing and p.inMeeting and not dndForced then
				dndForced = true
				U.dnd(true, "meeting")
				U.log.i("[media-presence] meeting screenshare started → DND on")
			end

			-- screenshare stop or meeting exit: restore only if we forced DND.
			if dndForced and (not p.sharing or not p.inMeeting) then
				dndForced = false
				U.dnd(false)
				U.log.i("[media-presence] meeting screenshare stopped → DND restored")
			end

			-- Log state changes
			if p.meetingState ~= prev.meetingState then
				U.log.df("[media-presence] meetingState: %s → %s", prev.meetingState, p.meetingState)
			end
			if p.micActive ~= prev.micActive then
				U.log.df("[media-presence] mic: %s → %s", tostring(prev.micActive), tostring(p.micActive))
			end
			if p.cameraActive ~= prev.cameraActive then
				U.log.df("[media-presence] camera: %s → %s", tostring(prev.cameraActive), tostring(p.cameraActive))
			end

			prev = p
		end, { "-c", getCmd })
		:start()
end

function M:start()
	U.log.i("[media-presence] starting watcher (polling every " .. POLL_INTERVAL .. "s)")
	generation = generation + 1
	prev = nil
	M.state = nil
	lastSuccessAt = nil
	dndForced = false
	poll() -- immediate first poll
	timer = hs.timer.doEvery(POLL_INTERVAL, poll)
end

function M:stop()
	U.log.i("[media-presence] stopping watcher")
	generation = generation + 1
	if timer then
		timer:stop()
		timer = nil
	end
	prev = nil
	M.state = nil
	lastSuccessAt = nil
	if dndForced then
		dndForced = false
		U.dnd(false)
		U.log.i("[media-presence] watcher stopped; DND restored")
	end
end

return M
