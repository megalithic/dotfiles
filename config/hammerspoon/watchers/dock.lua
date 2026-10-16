local fmt = string.format
local enum = req("hs.fnutils")

local M = {}

M.is_docked = nil
M.is_keyboard_connected = nil
M._stopped = true
M._switch_lock = false
M._desired_profile = nil
M._switchTask = nil
M._keyboardTimer = nil
M._pendingSwitchResult = nil
M._keyboardScanFailed = false

local KANATA_SWITCH_SCRIPT = [[
profile=$1
main_config=$2
label=$3
err_log=$4

if [ ! -f "$profile" ]; then
  printf 'Kanata config file not found: %s\n' "$profile" >&2
  exit 66
fi

uid=$(/usr/bin/id -u) || exit 1
state=$(/bin/launchctl print "gui/$uid/$label" 2>/dev/null || true)
current=$(/usr/bin/readlink "$main_config" 2>/dev/null || true)

case "$state" in
  *"state = running"*) running=1 ;;
  *) running=0 ;;
esac

if [ "$current" = "$profile" ] && [ "$running" -eq 1 ]; then
  printf 'already\n'
  exit 0
fi

before=$(/usr/bin/stat -f '%m:%z' "$err_log" 2>/dev/null || printf '0:0')
/bin/ln -sf "$profile" "$main_config" || exit 1
/bin/launchctl kickstart -k "gui/$uid/$label" || exit 1
/bin/sleep 2

state=$(/bin/launchctl print "gui/$uid/$label" 2>/dev/null || true)
case "$state" in
  *"state = running"*)
    printf 'switched\n'
    exit 0
    ;;
esac

after=$(/usr/bin/stat -f '%m:%z' "$err_log" 2>/dev/null || printf '0:0')
if [ "$after" != "$before" ]; then
  /usr/bin/tail -3 "$err_log" >&2
else
  printf 'Kanata did not restart. No new stderr since restart attempt.\n' >&2
fi
exit 1
]]

local function trim(value)
  if not value then return "" end
  return value:gsub("^%s*(.-)%s*$", "%1")
end

local function stopTask(slot)
  local task = M[slot]
  M[slot] = nil
  if not task then return end

  local ok, running = pcall(function() return task:isRunning() end)
  if ok and running then pcall(function() task:terminate() end) end
end

local function startTrackedTask(slot, launchPath, args, callback)
  local task
  local ok, err = pcall(function()
    task = hs.task.new(launchPath, function(exitCode, stdOut, stdErr)
      if M[slot] ~= task then return end
      M[slot] = nil
      callback(exitCode, stdOut or "", stdErr or "")
    end, args)
  end)

  if not ok or not task then
    callback(127, "", ok and "could not create task" or tostring(err))
    return nil
  end

  M[slot] = task
  if task:start() == false then
    if M[slot] == task then M[slot] = nil end
    callback(127, "", fmt("could not start %s", launchPath))
    return nil
  end

  return task
end

local startKanataSwitch

local function notifyKanataFailure(profile, detail)
  local message = fmt("Kanata could not switch to %s after one retry", profile)
  U.log.wf("%s: %s", message, detail)
  hs.notify.new({ title = "Hammerspoon dock", subTitle = message }):send()
end

local function resumeKanataSwitch()
  if M._stopped or M._keyboardTimer or M._switchTask then return end
  local result = M._pendingSwitchResult
  if not result then return end
  M._pendingSwitchResult = nil

  if M._desired_profile ~= result.profile then
    startKanataSwitch(M._desired_profile, 0)
  elseif result.exitCode ~= 0 and result.attempt < 1 then
    startKanataSwitch(result.profile, result.attempt + 1)
  elseif result.exitCode ~= 0 then
    notifyKanataFailure(result.profile, result.detail)
  end
end

local function reconcileKanata(profile, attempt, exitCode, stdOut, stdErr)
  M._switch_lock = false
  if M._stopped then return end

  if exitCode == 0 then
    if trim(stdOut) == "already" then
      U.log.of("Kanata already using profile %s", profile)
    else
      U.log.of("Kanata profile switched to %s", profile)
    end
  else
    U.log.wf("Kanata switch to %s failed (attempt %d): %s", profile, attempt + 1, trim(stdErr))
  end

  -- Keep the result until USB settles; even a retry could target a stale profile.
  M._pendingSwitchResult = { profile = profile, attempt = attempt, exitCode = exitCode, detail = trim(stdErr) }
  resumeKanataSwitch()
end

startKanataSwitch = function(profile, attempt)
  if M._stopped or not C.dock.kanata.enabled or not profile then return end

  local configPath = C.dock.kanata.configPath
  local profilePath = fmt("%s/%s", configPath, profile)
  local mainConfig = fmt("%s/kanata.kbd", configPath)
  local label = C.dock.kanata.daemonLabel or "org.kanata.daemon"
  local errLog = fmt("%s/Library/Logs/kanata/stderr.log", os.getenv("HOME"))

  M._switch_lock = true
  U.log.of("Switching Kanata profile to %s (attempt %d)", profile, attempt + 1)

  startTrackedTask(
    "_switchTask",
    "/bin/sh",
    { "-c", KANATA_SWITCH_SCRIPT, "hammerspoon-kanata", profilePath, mainConfig, label, errLog },
    function(exitCode, stdOut, stdErr) reconcileKanata(profile, attempt, exitCode, stdOut, stdErr) end
  )
end

local function requestKanataProfile(profile)
  if not C.dock.kanata.enabled then return end
  M._desired_profile = profile
  if not M._switchTask and not M._pendingSwitchResult and not M._keyboardTimer then startKanataSwitch(profile, 0) end
end

local function dockChangedState(connected)
  if M._stopped or M.is_docked == connected then return end

  M.is_docked = connected
  -- Wi-Fi stays on in both states; watchers/hotspot.lua owns network priority.
  U.log.i(connected and "Dock connected" or "Dock disconnected")
end

local function keyboardChangedState(state, force)
  local connected
  if state == "added" then
    connected = true
  elseif state == "removed" then
    connected = false
  else
    U.log.wf("unknown keyboard state: %s", tostring(state))
    return
  end

  if not force and M.is_keyboard_connected == connected then
    U.log.df("keyboard state unchanged: %s", state)
    return
  end

  M.is_keyboard_connected = connected
  U.log.of("External keyboard %s", connected and "connected" or "disconnected")
  requestKanataProfile(connected and C.dock.kanata.connected or C.dock.kanata.disconnected)
end

local function isDock(device)
  return device.vendorID == C.dock.target_alt.vendorID and device.productID == C.dock.target_alt.productID
end

local function isKeyboard(device)
  return device.vendorID == C.dock.keyboard.vendorID and device.productID == C.dock.keyboard.productID
end

function M.isDocked() return enum.find(hs.usb.attachedDevices() or {}, isDock) ~= nil end

function M.isExternalKeyboardConnected()
  local devices = hs.usb.attachedDevices()
  if not devices then return nil end
  return enum.find(devices, isKeyboard) ~= nil
end

local debounceKeyboard

local function sampleKeyboard()
  local connected = M.isExternalKeyboardConnected()
  if connected == nil then
    if not M._keyboardScanFailed then U.log.w("Cannot read USB keyboards; keeping Kanata profile and retrying scan") end
    M._keyboardScanFailed = true
    debounceKeyboard()
    return
  end

  M._keyboardScanFailed = false
  keyboardChangedState(connected and "added" or "removed")
  resumeKanataSwitch()
end

debounceKeyboard = function()
  if M._keyboardTimer then M._keyboardTimer:stop() end
  local timer
  timer = hs.timer.doAfter(C.dock.keyboard.debounceSeconds or 3, function()
    if M._stopped or M._keyboardTimer ~= timer then return end
    M._keyboardTimer = nil
    sampleKeyboard()
  end)
  M._keyboardTimer = timer
end

local function usbWatcherCallback(data)
  if M._stopped or (data.eventType ~= "added" and data.eventType ~= "removed") then return end
  if isDock(data) then dockChangedState(data.eventType == "added") end
  if isKeyboard(data) then debounceKeyboard() end
end

function M:start()
  self:stop()
  M._stopped = false
  M.is_docked = nil
  M.is_keyboard_connected = nil
  M._desired_profile = nil

  local watcher
  watcher = hs.usb.watcher.new(function(data)
    if M.watcher == watcher then usbWatcherCallback(data) end
  end)
  M.watcher = watcher
  M.watcher:start()

  dockChangedState(M.isDocked())
  sampleKeyboard()
end

function M:stop()
  M._stopped = true

  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end

  stopTask("_switchTask")
  if M._keyboardTimer then M._keyboardTimer:stop() end
  M._keyboardTimer = nil
  M._pendingSwitchResult = nil
  M._keyboardScanFailed = false
  M._switch_lock = false
  M._desired_profile = nil
end

return M
