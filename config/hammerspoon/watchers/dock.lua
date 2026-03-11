local fmt = string.format
local enum = require("hs.fnutils")

local M = {}

M.is_docked = nil
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

  U.log.f("Switching Kanata profile to: %s", profile)

  -- Update the main kanata.kbd symlink to point to the new profile
  -- kanata-bar reads from kanata.kbd, so this is what we need to change
  U.run(fmt("ln -sf %s %s", profilePath, mainConfig), true)

  -- Kill kanata - kanata-bar will auto-restart it with the new config
  -- (kanata_bar.autorestart_kanata = true in nix config)
  U.run("pkill -x kanata", true)

  -- Wait briefly for kanata-bar to restart kanata
  hs.timer.doAfter(1.5, function()
    -- Verify kanata restarted
    local isRunning = U.run("pgrep -x kanata", true)
    if isRunning and isRunning ~= "" then
      U.log.of("Kanata profile switched to %s (PID: %s)", profile, isRunning:gsub("%s+", ""))
    else
      U.log.wf("Kanata did not restart - check kanata-bar menu")
    end
  end)
end

local function keyboardChangedState(state)
  if state == "removed" then
    U.log.of("External keyboard disconnected")
    -- Switch to normal internal keyboard config
    if C.dock.kanata.enabled then switchKanataProfile(C.dock.kanata.disconnected) end
  elseif state == "added" then
    U.log.of("External keyboard connected (Leeloo)")
    -- Switch to config that disables internal keyboard
    if C.dock.kanata.enabled then switchKanataProfile(C.dock.kanata.connected) end
  else
    U.log.wf("unknown keyboard state: ", state)
  end
end

local function usbWatcherCallback(data)
  if data.productID == C.dock.target_alt.productID then dockChangedState(data.eventType) end
  if data.productID == C.dock.keyboard.productID then keyboardChangedState(data.eventType) end
end

function M.isDocked()
  return enum.find(
    hs.usb.attachedDevices(),
    function(device) return device.productID == C.dock.target_alt.productID end
  ) ~= nil
end

function M:start()
  -- Stop existing watcher first to avoid duplicates
  if M.watcher then
    M.watcher:stop()
    M.watcher = nil
  end

  if M.isDocked() == true then
    dockChangedState("added")
    M.is_docked = true
    U.log.of("%s %s mode active", "🖥️", "desktop")
  else
    dockChangedState("removed")
    M.is_docked = false
    U.log.of("%s %s mode active", "💻", "laptop")
  end

  -- Set up watcher for future dock connects/disconnects
  M.watcher = hs.usb.watcher.new(usbWatcherCallback)
  M.watcher:start()
end

function M:stop()
  if M.watcher then M.watcher:stop() end
end

return M
