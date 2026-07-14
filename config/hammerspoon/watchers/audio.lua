local enum = require("hs.fnutils")

local M = {}

-- Hook system for device change notifications
M.hooks = {
  onInputDeviceChange = {},
  onOutputDeviceChange = {},
}

--- Register a hook for input device changes
--- @param callback function Called when input device changes
function M.onInputDeviceChange(callback)
  table.insert(M.hooks.onInputDeviceChange, callback)
end

--- Register a hook for output device changes
--- @param callback function Called when output device changes
function M.onOutputDeviceChange(callback)
  table.insert(M.hooks.onOutputDeviceChange, callback)
end

local function fireHooks(hookList)
  for _, hook in ipairs(hookList) do
    pcall(hook)
  end
end

local function output()
  local preferred = { "megabose", "Seth R-Phonak hearing aid", "MacBook Pro Speakers", "LG UltraFine Display Audio" }
  local device

  local found = enum.find(preferred, function(d)
    device = hs.audiodevice.findOutputByName(d)
    return d and device
  end)

  if found and device then
    local name = device:name()
    local current = hs.audiodevice.current()
    if current and current.name == name then
      device = nil
      return false
    end

    device:setDefaultOutputDevice()
    local icon = name == "megabose" and "🎧 " or "🔈 "
    icon = name == "Seth R-Phonak hearing aid" and "📢 " or icon

    U.log.of('%soutput audio device set to "%s"', icon, name)
    device = nil

    return true
  end

  U.log.w("unable to set a default output device.")
  return nil
end

local function input()
  local preferred = { "Samson GoMic", "megabose", "Seth R-Phonak hearing aid", "MacBook Pro Microphone" }
  local device

  local found = enum.find(preferred, function(d)
    device = hs.audiodevice.findInputByName(d)
    return d and device
  end)

  if found and device then
    local name = device:name()
    local current = hs.audiodevice.current(true)
    if current and current.name == name then
      device = nil
      return false
    end

    device:setDefaultInputDevice()
    local icon = name == "Samson GoMic" and "🎙️ " or ""
    icon = name == "Seth R-Phonak hearing aid" and "📢 " or icon

    U.log.of('%sinput audio device set to "%s"', icon, name)
    device = nil

    return true
  end

  U.log.w("unable to set a default input device.")
  return nil
end

local DEBOUNCE_INTERVAL = 1.0 -- device events arrive in bursts; process after quiet period
local debounceTimer = nil

local function processAudioDeviceChanged()
  -- Wrap in pcall for error handling
  local ok, err = pcall(function()
    local iChanged = input()
    local oChanged = output()

    if oChanged == nil and iChanged == nil then U.log.w("unable to set input or output devices") end

    -- Fire hooks only when defaults actually changed.
    if iChanged then fireHooks(M.hooks.onInputDeviceChange) end
    if oChanged then fireHooks(M.hooks.onOutputDeviceChange) end
  end)

  if not ok then U.log.e("failed to change device: %s", tostring(err)) end
end

local function audioDeviceChanged(arg)
  if arg ~= "dev#" then return end

  if debounceTimer then debounceTimer:stop() end
  debounceTimer = hs.timer.doAfter(DEBOUNCE_INTERVAL, function()
    debounceTimer = nil
    processAudioDeviceChanged()
  end)
end

local function showCurrentlyConnected()
  local i = hs.audiodevice.current(true)
  local o = hs.audiodevice.current()

  -- local oIcon = o.name == "Seth R-Phonak hearing aid" and "📢 " or "🔈 "
  local oIcon = o.name == "megabose" and "🎧 " or "🔈 "
  oIcon = o.name == "Seth R-Phonak hearing aid" and "📢 " or oIcon

  local iIcon = i.name == "Samson GoMic" and "🎙️ " or ""
  iIcon = i.name == "Seth R-Phonak hearing aid" and "📢 " or iIcon

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
