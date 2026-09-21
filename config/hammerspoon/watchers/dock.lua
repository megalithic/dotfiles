local fmt = string.format
local enum = req("hs.fnutils")

local M = {}

M.is_docked = nil
M.is_keyboard_connected = nil
M.defaultWifiDevice = "en0"
M._stopped = true
M._switch_lock = false
M._desired_profile = nil
M._switchTask = nil
M._wifiTask = nil
M._wifiTaskTimer = nil
M._wifiDebounceTimer = nil
M._wifiReconcileQueued = false
M._forceWifiOn = false
M._wifiNotices = {}
M.networkWatcher = nil

local NETWORK_DEBOUNCE_SECONDS = 1
local WIFI_TASK_TIMEOUT_SECONDS = 10

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

local DOCK_RECONCILE_SCRIPT = [[
docked=$1
service=$2
network_status=$3
default_wifi=$4
network_monitoring=$5

wifi_device=$("$network_status" -f -d wifi 2>/dev/null || true)
wifi_lookup_failed=0
if [ -z "$wifi_device" ]; then
  wifi_device=$default_wifi
  wifi_lookup_failed=1
fi

target=on
reason=

if [ "$docked" -eq 1 ]; then
  if [ "$network_monitoring" -ne 1 ]; then
    reason='network monitoring is unavailable'
  elif [ -z "$service" ]; then
    reason='no wired network service is configured'
  elif ! enabled=$(/usr/sbin/networksetup -getnetworkserviceenabled "$service" 2>&1); then
    reason=$(printf "could not query wired service '%s': %s" "$service" "$enabled")
  elif [ "$enabled" != "Enabled" ]; then
    reason=$(printf "wired service '%s' is disabled" "$service")
  elif ! wired_device=$("$network_status" --usable-service "$service" 2>&1); then
    reason=${wired_device:-"wired service '$service' is not connected"}
  elif ! route_info=$(/sbin/route -n get default 2>&1); then
    reason=$(printf 'could not query the default route: %s' "$route_info")
  else
    default_device=$(printf '%s\n' "$route_info" | /usr/bin/awk '/interface:/ { print $2; exit }')
    if [ "$default_device" != "$wired_device" ]; then
      reason=$(printf "default route uses '%s', not wired interface '%s'" "${default_device:-no interface}" "$wired_device")
    elif [ "$wifi_lookup_failed" -eq 1 ]; then
      reason='Wi-Fi device lookup failed'
    else
      target=off
    fi
  fi
fi

set_wifi_on() {
  if output=$(/usr/sbin/networksetup -setairportpower "$wifi_device" on 2>&1); then
    return 0
  fi
  /bin/sleep 1
  if output=$(/usr/sbin/networksetup -setairportpower "$wifi_device" on 2>&1); then
    return 0
  fi
  printf '%s' "$output"
  return 1
}

if [ "$target" = off ]; then
  if ! output=$(/usr/sbin/networksetup -setairportpower "$wifi_device" off 2>&1); then
    off_error=$output
    if restore_error=$(set_wifi_on); then
      printf 'on %s\n' "$wifi_device"
      printf 'Wi-Fi off failed on %s: %s\n' "$wifi_device" "$off_error" >&2
    else
      printf 'Wi-Fi off failed on %s (%s) and restore failed: %s\n' "$wifi_device" "$off_error" "$restore_error" >&2
    fi
    exit 1
  fi
else
  if ! output=$(set_wifi_on); then
    printf 'Wi-Fi on failed on %s: %s\n' "$wifi_device" "$output" >&2
    exit 1
  fi
fi

printf '%s %s\n' "$target" "$wifi_device"
if [ -n "$reason" ]; then printf '%s\n' "$reason" >&2; fi
]]

local FORCE_WIFI_ON_SCRIPT = [[
device=$1

if output=$(/usr/sbin/networksetup -setairportpower "$device" on 2>&1); then
  printf 'on %s\n' "$device"
  exit 0
fi
/bin/sleep 1
if output=$(/usr/sbin/networksetup -setairportpower "$device" on 2>&1); then
  printf 'on %s\n' "$device"
  exit 0
fi
printf 'Wi-Fi on failed on %s: %s\n' "$device" "$output" >&2
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

local startWifiReconcile
local scheduleWifiReconcile

local function stopTimer(slot)
  local timer = M[slot]
  M[slot] = nil
  if timer then timer:stop() end
end

local function stopWifiTask()
  stopTimer("_wifiTaskTimer")
  stopTask("_wifiTask")
end

local function notifyWifi(message)
  U.log.w(message)
  if M._wifiNotices[message] then return end

  M._wifiNotices[message] = true
  hs.notify.new({ title = "Hammerspoon dock", subTitle = message }):send()
end

local function finishWifiTask(exitCode, stdOut, stdErr)
  stopTimer("_wifiTaskTimer")

  local state, device = trim(stdOut):match("^(%a+)%s+(%S+)")
  if state ~= "on" and state ~= "off" then state, device = nil, nil end
  local detail = trim(stdErr)
  if exitCode == 0 and state then
    if state == "off" then M._wifiNotices = {} end
    U.log.of("Wi-Fi %s on %s", state, device)
    if detail ~= "" then notifyWifi(fmt("Keeping Wi-Fi on: %s", detail)) end
  else
    if detail == "" then detail = fmt("reconciliation failed with exit code %d", exitCode) end
    notifyWifi(fmt("Dock reconciliation failed: %s", detail))
  end

  if M._wifiReconcileQueued then
    M._wifiReconcileQueued = false
    scheduleWifiReconcile(NETWORK_DEBOUNCE_SECONDS, false)
  end
end

local function startWifiTask(args, isForcedOn)
  local task = startTrackedTask("_wifiTask", "/bin/sh", args, finishWifiTask)
  if not task then return end

  local timeoutTimer
  timeoutTimer = hs.timer.doAfter(WIFI_TASK_TIMEOUT_SECONDS, function()
    if M._wifiTask ~= task then return end
    M._wifiTaskTimer = nil
    stopTask("_wifiTask")
    notifyWifi(isForcedOn and "Wi-Fi-on recovery timed out" or "Dock reconciliation timed out; restoring Wi-Fi")
    if not isForcedOn then
      M._forceWifiOn = true
      startWifiReconcile()
    end
  end)
  M._wifiTaskTimer = timeoutTimer
end

startWifiReconcile = function()
  if M._stopped or M._wifiTask then return end
  stopTimer("_wifiDebounceTimer")

  local forceOn = M._forceWifiOn
  M._forceWifiOn = false
  if forceOn then
    startWifiTask({ "-c", FORCE_WIFI_ON_SCRIPT, "hammerspoon-wifi-on", M.defaultWifiDevice }, true)
    return
  end

  local service = C.dock.docked.wiredService or ""
  startWifiTask(
    {
      "-c",
      DOCK_RECONCILE_SCRIPT,
      "hammerspoon-dock-reconcile",
      M.is_docked and "1" or "0",
      service,
      U.bin("network-status"),
      M.defaultWifiDevice,
      M.networkWatcher and "1" or "0",
    },
    false
  )
end

scheduleWifiReconcile = function(delay, forceOn)
  if M._stopped then return end
  if forceOn then
    M._forceWifiOn = true
    M._wifiReconcileQueued = false
  end

  if M._wifiTask then
    if forceOn then
      stopWifiTask()
      startWifiReconcile()
    else
      M._wifiReconcileQueued = true
    end
    return
  end

  if M._wifiDebounceTimer then
    if not forceOn then return end
    stopTimer("_wifiDebounceTimer")
  end

  if forceOn or delay <= 0 then
    startWifiReconcile()
    return
  end

  local debounceTimer
  debounceTimer = hs.timer.doAfter(delay, function()
    if M._wifiDebounceTimer ~= debounceTimer then return end
    M._wifiDebounceTimer = nil
    startWifiReconcile()
  end)
  M._wifiDebounceTimer = debounceTimer
end

local function networkConfigurationChanged()
  if not M._stopped and M.is_docked then scheduleWifiReconcile(NETWORK_DEBOUNCE_SECONDS, false) end
end

local function startNetworkWatcher()
  local ok, watcher = pcall(function()
    local store = hs.network.configuration.open()
    store:setCallback(networkConfigurationChanged)
    store:monitorKeys("State:/Network/.*", true)
    store:start()
    return store
  end)

  if ok then
    M.networkWatcher = watcher
    return true
  end

  notifyWifi(fmt("Network monitoring failed: %s", tostring(watcher)))
  return false
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

local function dockChangedState(state, force)
  local isDocked
  if state == "added" then
    isDocked = true
  elseif state == "removed" then
    isDocked = false
  else
    U.log.wf("unknown dock state: %s", tostring(state))
    return
  end

  if not force and M.is_docked == isDocked then
    U.log.df("dock state unchanged: %s", state)
    return
  end

  M.is_docked = isDocked
  U.log.i(isDocked and "running docked setup" or "running undocked setup")
  scheduleWifiReconcile(0, not isDocked)
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

local function usbWatcherCallback(data)
  if data.productID == C.dock.target_alt.productID then dockChangedState(data.eventType) end
  if data.productID == C.dock.keyboard.productID then keyboardChangedState(data.eventType) end
end

function M.isDocked()
  return enum.find(
    hs.usb.attachedDevices() or {},
    function(device) return device.productID == C.dock.target_alt.productID end
  ) ~= nil
end

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
  M._wifiReconcileQueued = false
  M._forceWifiOn = false
  M._wifiNotices = {}

  M.watcher = hs.usb.watcher.new(usbWatcherCallback)
  M.watcher:start()

  startNetworkWatcher()
  local isDocked = M.isDocked()
  dockChangedState(isDocked and "added" or "removed", true)
  U.log.of("%s mode active", isDocked and "desktop" or "laptop")

  local keyboardConnected = M.isExternalKeyboardConnected()
  keyboardChangedState(keyboardConnected and "added" or "removed", true)
end

function M:stop()
  M._stopped = true

  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end

  stopTimer("_wifiDebounceTimer")
  stopWifiTask()
  if M.networkWatcher then
    local watcher = M.networkWatcher
    M.networkWatcher = nil
    pcall(function() watcher:stop() end)
    pcall(function() watcher:setCallback(nil) end)
  end

  stopTask("_switchTask")
  M._switch_lock = false
  M._desired_profile = nil
  M._wifiReconcileQueued = false
  M._forceWifiOn = false
  M._wifiNotices = {}
end

return M
