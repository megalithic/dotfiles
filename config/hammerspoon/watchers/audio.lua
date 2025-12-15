local fmt = string.format
local enum = require("hs.fnutils")

local M = {}

local function output()
  local preferred = { "megabose", "MacBook Pro Speakers", "LG UltraFine Display Audio" }
  local device

  local found = enum.find(preferred, function(d)
    device = hs.audiodevice.findOutputByName(d)
    return d and device
  end)

  if found and device then
    device:setDefaultOutputDevice()
    local status = hs.execute(fmt("SwitchAudioSource -t output -s '%s' &", device:name()), true)
    local icon = device:name() == "megabose" and "🎧 " or "🔈 "

    U.log.of("%s%s", icon, string.gsub(status, "^%s*(.-)%s*$", "%1"))
    device = nil

    return 0
  end

  U.log.w("unable to set a default output device.")
  return 1
end

local function input()
  local preferred = { "Samson GoMic", "megabose", "MacBook Pro Microphone" }
  local device

  local found = enum.find(preferred, function(d)
    device = hs.audiodevice.findInputByName(d)
    return d and device
  end)

  if found and device then
    device:setDefaultInputDevice()
    local status = hs.execute(fmt("SwitchAudioSource -t input -s '%s' &", device:name()), true)
    local icon = device:name() == "Samson GoMic" and "🎙️ " or ""

    U.log.of("%s%s", icon, string.gsub(status, "^%s*(.-)%s*$", "%1"))
    -- U.log.of("%s", string.gsub(status, "^%s*(.-)%s*$", "%1"))
    device = nil

    return 0
  end

  U.log.w("unable to set a default input device.")
  return 1
end

local lastProcessedTime = 0
local DEBOUNCE_INTERVAL = 0.5 -- 500ms - ignore events within this window

local function audioDeviceChanged(arg)
  -- Add debug logging to see all events

  if arg == "dev#" then
    local now = hs.timer.secondsSinceEpoch()
    local timeSinceLastProcess = now - lastProcessedTime

    -- Debounce: ignore events that occur too soon after the last one
    if timeSinceLastProcess < DEBOUNCE_INTERVAL then return end

    lastProcessedTime = now

    local oRetval = 1
    local iRetval = 1

    -- Wrap in pcall for error handling
    local ok, err = pcall(function()
      iRetval = input()
      oRetval = output()

      if oRetval == 1 and iRetval == 1 then
        U.log.w("unable to set input or output devices. input: " .. iRetval .. ", output: " .. oRetval)
      end
    end)

    if not ok then U.log.e("failed to change device: %s", tostring(err)) end
  end
end

local function showCurrentlyConnected()
  local i = hs.audiodevice.current(true)
  local o = hs.audiodevice.current()

  local oIcon = o.name == "megabose" and "🎧 " or "🔈 "
  local iIcon = i.name == "Samson GoMic" and "🎙️ " or ""

  U.log.of("input: %s%s (%s)", iIcon, i.name, i.muted and "muted" or "unmuted")
  U.log.of("output: %s%s", oIcon, o.name)
end

function M:start()
  -- Stop any existing watcher first to ensure clean state
  if hs.audiodevice.watcher.isRunning() then hs.audiodevice.watcher.stop() end

  hs.audiodevice.watcher.setCallback(audioDeviceChanged)
  hs.audiodevice.watcher.start()

  showCurrentlyConnected()
end

function M:stop()
  if hs.audiodevice.watcher.isRunning() then hs.audiodevice.watcher.stop() end
end

return M
