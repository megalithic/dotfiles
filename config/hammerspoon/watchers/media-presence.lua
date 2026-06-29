-- media-presence: Unix-socket consumer for media-presenced daemon.
-- Replaces camera.lua heuristics with authoritative AV + CDP signals.
--
-- Events consumed:
--   meeting.lobby     → force PTT mute, pause music
--   meeting.joined    → same as lobby (state update)
--   meeting.left      → reset PTT mute, re-enable notifications
--   screenshare.start → enforce DND focus mode
--   screenshare.stop  → restore previous DND state
--   mic.on/off        → update menubar / PTT state
--   camera.on/off     → (future: owner attribution)

local M = {}
local SOCKET = os.getenv("HOME") .. "/.local/state/media-presence/sock"
local RECONNECT_DELAY = 5

local task = nil       -- persistent nc -U task for event reads
local reconnectTimer = nil

-- Previous DND state before screenshare forced it
local dndWasOn = false

--- Read a line from the task's stdout buffer.
--- Returns line (without trailing newline) or nil.
local function readLine(stdoutBuffer)
  local nl = stdoutBuffer:find("\n")
  if not nl then return nil end
  local line = stdoutBuffer:sub(1, nl - 1)
  local rest = stdoutBuffer:sub(nl + 1)
  return line, rest
end

--- Parse a JSON event line. Returns (event, presence) or nil.
local function parseEvent(line)
  local ok, obj = pcall(hs.json.decode, line)
  if not ok or not obj then return nil end
  local event = obj.event
  return event, obj
end

--- Handle a single event from the daemon.
local function handleEvent(event, p)
  if not event then return end

  U.log.df("[media-presence] event: %s (meeting: %s, sharing: %s)", event, p.meetingState or "?", tostring(p.sharing))

  if event == "meeting.lobby" or event == "meeting.joined" then
    -- Force push-to-talk mute
    pcall(function() require("miccheck").setPTTMode("push-to-talk") end)
    -- Pause music
    pcall(function() hs.osascript.applescript('tell application "Music" to pause') end)
    U.log.i("[media-presence] meeting started → PTT mute + music paused")
  elseif event == "meeting.left" then
    -- Reset PTT (restore push-to-talk as default)
    pcall(function() require("miccheck").setPTTMode("push-to-talk") end)
    U.log.i("[media-presence] meeting ended → PTT reset")
  elseif event == "screenshare.start" then
    -- Force DND on; record previous state
    -- TODO: query actual DND state before forcing. For now assume off.
    dndWasOn = false
    U.dnd(true, "meeting")
    U.log.i("[media-presence] screenshare started → DND on")
  elseif event == "screenshare.stop" then
    -- Restore DND
    if not dndWasOn then U.dnd(false) end
    U.log.i("[media-presence] screenshare stopped → DND restored")
  end
end

--- Start or restart the nc -U connection.
local function connect()
  if task then task:terminate(); task = nil end

  if not hs.fs.attributes(SOCKET) then
    U.log.df("[media-presence] socket not found at %s, will retry in %ds", SOCKET, RECONNECT_DELAY)
    scheduleReconnect()
    return
  end

  local stdoutBuffer = ""

  task = hs.task.new("/usr/bin/nc", function(exitCode, _)
    U.log.df("[media-presence] nc exited code %d, reconnecting in %ds", exitCode, RECONNECT_DELAY)
    task = nil
    scheduleReconnect()
    return true
  end, function(t, stdout, stderr)
    if stdout then
      stdoutBuffer = stdoutBuffer .. stdout
      while true do
        local line, rest = readLine(stdoutBuffer)
        if not line then break end
        stdoutBuffer = rest
        if #line > 0 then
          local event, pPresence = parseEvent(line)
          if event then handleEvent(event, pPresence) end
        end
      end
    end
    return true
  end, { "-U", SOCKET })
  task:start()

  U.log.i("[media-presence] connected to daemon")
end

local function scheduleReconnect()
  if reconnectTimer then reconnectTimer:stop() end
  reconnectTimer = hs.timer.doAfter(RECONNECT_DELAY, connect)
end

function M:start()
  U.log.i("[media-presence] starting watcher")
  connect()
end

function M:stop()
  U.log.i("[media-presence] stopping watcher")
  if reconnectTimer then reconnectTimer:stop(); reconnectTimer = nil end
  if task then task:terminate(); task = nil end
end

return M
