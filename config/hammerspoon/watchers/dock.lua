local fmt = string.format
local enum = req("hs.fnutils")

local M = {}

M.is_docked = nil
M.is_keyboard_connected = nil
M._stopped = true
M._switch_lock = false
M._desired_profile = nil
M._switchTask = nil

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

local function notifyWifi(message)
  U.log.w(message)
  hs.notify.new({ title = "Hammerspoon dock", subTitle = message }):send()
end

local function setWifi(power)
  local wifi = hs.wifi.interfaceDetails()
  if not wifi or not wifi.interface or type(wifi.power) ~= "boolean" then
    notifyWifi("Cannot read Wi-Fi interface")
    return
  end

  if wifi.power == power then return end

  local ok, err = hs.wifi.setPower(power, wifi.interface)
  if not ok then
    notifyWifi("Cannot change Wi-Fi power: " .. tostring(err or "interface unavailable"))
    return
  end

  U.log.of("Wi-Fi %s on %s", power and "on" or "off", wifi.interface)
end

local startKanataSwitch

local function notifyKanataFailure(profile, detail)
  local message = fmt("Kanata could not switch to %s after one retry", profile)
  U.log.wf("%s: %s", message, detail)
  hs.notify.new({ title = "Hammerspoon dock", subTitle = message }):send()
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

  if M._desired_profile ~= profile then
    startKanataSwitch(M._desired_profile, 0)
  elseif exitCode ~= 0 and attempt < 1 then
    startKanataSwitch(profile, attempt + 1)
  elseif exitCode ~= 0 then
    notifyKanataFailure(profile, trim(stdErr))
  end
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
  if not M._switchTask then startKanataSwitch(profile, 0) end
end

local function dockChangedState(connected)
  if M._stopped or M.is_docked == connected then return end

  M.is_docked = connected
  U.log.i(connected and "Dock connected" or "Dock disconnected")
  setWifi(not connected)
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

local function usbWatcherCallback(data)
  if M._stopped then return end
  if isDock(data) and (data.eventType == "added" or data.eventType == "removed") then
    dockChangedState(data.eventType == "added")
  end
  if data.productID == C.dock.keyboard.productID then keyboardChangedState(data.eventType) end
end

function M.isDocked() return enum.find(hs.usb.attachedDevices() or {}, isDock) ~= nil end

function M.isExternalKeyboardConnected()
  return enum.find(
    hs.usb.attachedDevices() or {},
    function(device) return device.productID == C.dock.keyboard.productID end
  ) ~= nil
end

function M:start()
  self:stop()
  M._stopped = false
  M.is_docked = nil
  M.is_keyboard_connected = nil
  M._desired_profile = nil

  M.watcher = hs.usb.watcher.new(usbWatcherCallback)
  M.watcher:start()

  dockChangedState(M.isDocked())

  local keyboardConnected = M.isExternalKeyboardConnected()
  keyboardChangedState(keyboardConnected and "added" or "removed", true)
end

function M:stop()
  M._stopped = true

  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end

  stopTask("_switchTask")
  M._switch_lock = false
  M._desired_profile = nil
end

return M
