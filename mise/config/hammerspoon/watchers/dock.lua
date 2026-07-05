local fmt = string.format
local enum = require("hs.fnutils")

local M = {}

M.is_docked = nil
M.is_keyboard_connected = nil -- tracks combined USB + BT keyboard state
M.bt_last_connected = nil -- tracks last known BT connection state
M.defaultWifiDevice = "en0"

local function wifiDevice()
  local device = U.run(U.bin("network-status -f -d wifi", true))

  -- If device is nil or empty, use default
  if device == nil or device == "" then
    U.log.wf("defaulting wifi device to %s", M.defaultWifiDevice)
    return M.defaultWifiDevice
  end

  return device
end

local function setWifi(state) U.run(fmt("networksetup -setairportpower %s %s", wifiDevice(), state), true) end

local function docked()
  if M.is_docked ~= nil and M.is_docked == true then
    U.log.w("already docked; skipping setup.")
    return
  end

  U.log.i("running docked setup..")
  M.is_docked = true
  setWifi(C.dock.docked.wifi)
end

local function undocked()
  U.log.i("running undocked setup..")
  M.is_docked = false
  setWifi(C.dock.undocked.wifi)
end

local function dockChangedState(state)
  if state == "removed" then
    undocked()
  elseif state == "added" then
    docked()
  else
    U.log.wf("unknown dock state: ", state)
  end
end

local function switchKanataProfile(profile)
  if not C.dock.kanata.enabled then return end

  local profilePath = fmt("%s/%s", C.dock.kanata.configPath, profile)
  local mainConfig = fmt("%s/kanata.kbd", C.dock.kanata.configPath)

  -- Verify target profile exists
  local fileExists = U.run(fmt("test -f %s && echo 'exists' || echo 'missing'", profilePath), true)
  if not fileExists or not fileExists:match("exists") then
    U.log.wf("Kanata config file not found: %s", profilePath)
    return
  end

  U.log.df("Switching Kanata profile to: %s", profile)

  -- Update the main kanata.kbd symlink to point to the new profile
  U.run(fmt("ln -sf %s %s", profilePath, mainConfig), true)

  -- Restart kanata daemon via launchctl
  -- The daemon runs as a user agent with sudo, so we use gui domain
  local uid = U.run("id -u", true):gsub("%s+", "")
  U.run(fmt("launchctl kickstart -k gui/%s/org.kanata.daemon", uid), true)

  -- Wait briefly for kanata to restart, then verify
  hs.timer.doAfter(2, function()
    local isRunning = U.run("pgrep -x kanata", true)
    if isRunning and isRunning ~= "" then
      U.log.df("Kanata profile switched to %s (PID: %s)", profile, isRunning:gsub("%s+", ""))
    else
      -- Check logs for errors
      local lastErr = U.run("tail -3 /tmp/kanata.err 2>/dev/null", true)
      U.log.wf("Kanata did not restart. Last error: %s", lastErr or "no log")
    end
  end)
end

local function keyboardChangedState(state, source)
  source = source or "usb"
  local was_connected = M.is_keyboard_connected

  if state == "removed" then
    -- Only disconnect if neither USB nor BT is connected
    local usb_connected = M.isExternalKeyboardUSB()
    local bt_connected = M.isExternalKeyboardBT()
    if usb_connected or bt_connected then
      U.log.df("Keyboard %s disconnected via %s, but still connected via %s", C.dock.keyboard.productName, source, usb_connected and "USB" or "BT")
      return
    end
    M.is_keyboard_connected = false
    if was_connected ~= false then
      U.log.df("External keyboard disconnected (via %s)", source)
      if C.dock.kanata.enabled then switchKanataProfile(C.dock.kanata.disconnected) end
    end
  elseif state == "added" then
    M.is_keyboard_connected = true
    if was_connected ~= true then
      U.log.df("External keyboard connected — %s (via %s)", C.dock.keyboard.productName, source)
      if C.dock.kanata.enabled then switchKanataProfile(C.dock.kanata.connected) end
    end
  else
    U.log.wf("unknown keyboard state: ", state)
  end
end

local function usbWatcherCallback(data)
  if data.productID == C.dock.target_alt.productID then dockChangedState(data.eventType) end
  if data.productID == C.dock.keyboard.productID then keyboardChangedState(data.eventType, "usb") end
end

function M.isDocked()
  return enum.find(
    hs.usb.attachedDevices(),
    function(device) return device.productID == C.dock.target_alt.productID end
  ) ~= nil
end

function M.isExternalKeyboardUSB()
  return enum.find(
    hs.usb.attachedDevices(),
    function(device) return device.productID == C.dock.keyboard.productID end
  ) ~= nil
end

function M.isExternalKeyboardBT()
  local name = C.dock.keyboard.productName
  if not name or not C.dock.keyboard.bluetoothAddress then return false end
  -- hidutil is fast (~90ms) and works for BLE devices (blueutil doesn't)
  local result = U.run(fmt("hidutil list 2>/dev/null | grep -c 'Bluetooth Low Energy.*%s'", name), true)
  return result and tonumber(result) ~= nil and tonumber(result) > 0
end

function M.isExternalKeyboardConnected()
  return M.isExternalKeyboardUSB() or M.isExternalKeyboardBT()
end

local function startBluetoothPoller()
  local addr = C.dock.keyboard.bluetoothAddress
  if not addr then return end

  local interval = C.dock.keyboard.bluetoothPollInterval or 5

  -- Stop existing poller
  if M.btPoller then
    M.btPoller:stop()
    M.btPoller = nil
  end

  M.btPoller = hs.timer.new(interval, function()
    local connected = M.isExternalKeyboardBT()
    if connected ~= M.bt_last_connected then
      M.bt_last_connected = connected
      keyboardChangedState(connected and "added" or "removed", "bluetooth")
    end
  end)
  M.btPoller:start()
end

function M:start()
  -- Stop existing watchers to avoid duplicates
  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end
  if M.btPoller then
    M.btPoller:stop()
    M.btPoller = nil
  end

  -- Check initial dock state
  if M.isDocked() == true then
    dockChangedState("added")
    M.is_docked = true
    U.log.of("%s %s mode active", "🖥️", "desktop")
  else
    dockChangedState("removed")
    M.is_docked = false
    U.log.of("%s %s mode active", "💻", "laptop")
  end

  -- Check initial keyboard state (USB or BT)
  local usb = M.isExternalKeyboardUSB()
  local bt = M.isExternalKeyboardBT()
  M.bt_last_connected = bt

  if usb or bt then
    local source = usb and "usb" or "bluetooth"
    keyboardChangedState("added", source)
    U.log.of("%s External keyboard connected on startup (via %s)", "⌨️", source)
  else
    keyboardChangedState("removed", "startup")
  end

  -- USB watcher for dock + keyboard
  M.watcher = hs.usb.watcher.new(usbWatcherCallback)
  M.watcher:start()

  -- Bluetooth poller for keyboard
  startBluetoothPoller()
end

function M:stop()
  if M.watcher then M.watcher:stop() end
  if M.btPoller then
    M.btPoller:stop()
    M.btPoller = nil
  end
end

return M
