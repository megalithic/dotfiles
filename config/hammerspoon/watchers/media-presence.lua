-- media-presence: Unix-socket consumer for media-presenced daemon.
-- Polls the daemon for presence state and dispatches transitions.
-- Replaces camera.lua heuristics with authoritative AV + CDP signals.

local M = {}
local SOCKET = os.getenv("HOME") .. "/.local/state/media-presence/sock"
local POLL_INTERVAL = 3 -- seconds between polls

local timer = nil
local prev = nil -- previous presence snapshot, used for edge detection

-- Previous DND state before screenshare forced it
local dndWasOn = false

--- Poll the daemon for current presence, detect transitions, dispatch actions.
local function poll()
  if not hs.fs.attributes(SOCKET) then return end

  local getCmd = string.format('echo \'{"cmd":"get"}\' | /usr/bin/nc -w 1 -U %s', SOCKET)
  hs.task
    .new("/bin/sh", function(exitCode, stdOut, _)
      if exitCode ~= 0 or not stdOut then return end

      local ok, p = pcall(hs.json.decode, stdOut)
      if not ok or not p then return end

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
        pcall(function() hs.osascript.applescript('tell application "Music" to pause') end)
      end

      -- screenshare start
      if p.sharing and not wasSharing then
        dndWasOn = false
        U.dnd(true, "meeting")
        U.log.i("[media-presence] screenshare started → DND on")
      end

      -- screenshare stop
      if not p.sharing and wasSharing then
        if not dndWasOn then U.dnd(false) end
        U.log.i("[media-presence] screenshare stopped → DND restored")
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
  prev = nil
  poll() -- immediate first poll
  timer = hs.timer.doEvery(POLL_INTERVAL, poll)
end

function M:stop()
  U.log.i("[media-presence] stopping watcher")
  if timer then
    timer:stop()
    timer = nil
  end
  prev = nil
end

return M
