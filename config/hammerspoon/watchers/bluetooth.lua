local enum = require("hs.fnutils")
local obj = {}

local default_balance = 0.5

-- REF:
-- https://github.com/jasonrudolph/dotfiles/commit/8bc3e6c55bd9c95eb83e4cfa265cc32d9da6edc3
-- https://github.com/wangshub/hammerspoon-config/blob/master/headphone/headphone.lua
-- https://gist.github.com/ysimonson/fea48ee8a68ed2cbac12473e87134f58
-- https://github.com/drn/dots/blob/master/bin/hd1
-- https://github.com/drn/dots/blob/master/hammerspoon/bluetooth.lua

obj.__index = obj
obj.name = "watcher.bluetooth"
obj.debug = false
obj.devices = {
  -- ["phonak"] = {
  --   alias = "phonak",
  --   name = "Seth R-Phonak hearing aid",
  --   bt = "Seth R-Phonak hearing aid",
  --   id = "80-28-3c-1c-7f-27",
  --   icon = "🎧",
  -- },
  ["leeloo"] = {
    alias = "leeloo",
    name = "Leeloo",
    bt = "Leeloo",
    id = "F3-D9-8D-01-16-54",
    icon = "⌨️ ⌨️⌨️⌨️",
  },
  ["airpods"] = {
    alias = "airpods",
    name = "megapods",
    bt = "AirPods Pro",
    id = "ac-90-85-c2-75-ab",
    icon = "🎧",
  },
  ["bose"] = {
    alias = "bose",
    name = "Bose QC Ultra Headphones",
    bt = "Bose QC Ultra Headphones",
    id = "BC-87-FA-28-CE-0F",
    icon = "🎧",
  },
}

obj.devices["fallback"] = {
  alias = "fallback",
  name = obj.devices["bose"].name,
  bt = obj.devices["bose"].bt,
  icon = obj.devices["bose"].icon,

  -- name = "MacBook Pro Speakers",
  -- bt = "MacBook Pro Speakers",
  -- icon = "💻",
}

obj.preferredOutputDevices = { "bose", "airpods" }
obj.btUtil = "/usr/local/bin/blueutil"
obj.interval = (10 * 60)
obj.lowBatteryTimer = nil

function obj.toggle_bt_device(device_alias, state)
  -- https://coderwall.com/p/fyfp0w/applescript-to-connect-bluetooth-headphones
  -- https://stuartmccoll.github.io/posts/2020-05-02-applescript-bluetooth-devices/
  -- https://github.com/aesadde/dotfiles/blob/master/ARCHIVE/hammerspoon/bluetooth.lua
  -- https://github.com/mgriffin/dotfiles/blob/main/hammerspoon/init.lua
  -- https://github.com/juanedi/dotfiles/blob/master/hammerspoon/sound_control.lua

  local bt_name = obj.devices[device_alias].bt

  if bt_name == nil then return end
  print(bt_name)

  local s = [[
    activate application "SystemUIServer"
    tell application "System Events"
      tell process "SystemUIServer"
        set btMenu to (menu bar item 1 of menu bar 1 whose description contains "bluetooth")
        tell btMenu
          click
  ]] .. "tell (menu item \"" .. bt_name .. "\" of menu 1)\n" .. [[
            click
            if exists menu item "Connect" of menu 1 then
              click menu item "Connect" of menu 1
              return "Connecting ..."
            else
              click menu item "Disconnect" of menu 1
              return "Disconnecting ..."
            end if
          end tell
        end tell
      end tell
    end tell
  ]]

  return hs.osascript.applescript(s)
end

function obj.preferredBluetoothDevicesConnected()
  local connectedDevices = enum.filter(
    obj.preferredOutputDevices,
    function(deviceStr) return obj.isBluetoothDeviceConnected(deviceStr) end
  )

  if #connectedDevices > 0 then return true end

  return false
end

---@params device table|string
function obj.isBluetoothDeviceConnected(device)
  local targetDevice = device

  if type(device) == "string" then targetDevice = obj.devices[device] end

  -- FIXME: the bose qc ultra headphones i have do not show up here, only my hearing aids and my keyboard
  local connectedDevices = hs.battery.privateBluetoothBatteryInfo()

  local connected = hs.fnutils.find(connectedDevices, function(d) return d.name == targetDevice.bt end) ~= nil

  return connected
end

local function connectDevice(deviceStr)
  dbg(deviceStr, true)
  local device = obj.devices[deviceStr]
  dbg(device, true)
  if not device then return end

  note(fmt("[%s] connecting %s %s..", obj.name, device.icon, device.name))

  hs.task
    .new(obj.btUtil, function(_exitCode, _stdOut, _stdErr) end, {
      "--use-system-profiler",
      "--connect",
      device.id,
    })
    :start()
end

local function toggleDevice(deviceStr, fn)
  hs.timer.doUntil(function()
    local isConnected = obj.isBluetoothDeviceConnected(deviceStr)
    fn(isConnected)

    if isConnected then require("watchers.dock"):setAudio(DOCK.docked) end

    return isConnected
  end, function() connectDevice(deviceStr) end)
end

local function checkAndAlertLowBattery()
  local batteryInfoForConnectedDevices = hs.battery.privateBluetoothBatteryInfo()

  hs.fnutils.each(batteryInfoForConnectedDevices, function(device)
    local percentage = device["batteryPercentSingle"]
    local name = device["name"]

    if tonumber(percentage) < 10 then
      error(fmt("[bluetooth] %s: %s%%", name, percentage))
    elseif tonumber(percentage) < 25 then
      warn(fmt("[bluetooth] %s: %s%%", name, percentage))
    else
      note(fmt("[bluetooth] %s: %s%%", name, percentage))
    end
  end)
end

function obj:start()
  self.menubar = hs.menubar.new()

  -- local btModality = spoon.HyperModal
  -- btModality
  --   :start(function(is_open)
  --     if is_open then hs.alert.show("bluetooth toggle initiated", hs.alert.defaultStyle, 0, true) end
  --   end)
  --   :bind({}, "b", function() obj.toggle_bt_device("bose") end, function() btModality:exit(0.1) end)
  --   :bind({}, "p", function() obj.toggle_bt_device("phonak") end, function() btModality:exit(0.1) end)
  --   :bind({}, "escape", function() btModality:exit() end)
  -- req("hyper", { id = "bluetooth" }):bind({ "shift" }, "h", function() btModality:toggle() end)

  req("hyper", { id = "bluetooth" }):start():bind({ "shift" }, "h", nil, function()
    local device = nil

    local connectedDevices = enum.map(obj.preferredOutputDevices, function(deviceStr)
      if obj.isBluetoothDeviceConnected(deviceStr) then return obj.devices[deviceStr] end
      -- if obj.isBluetoothDeviceConnected(deviceStr) then device = obj.devices[deviceStr] end
    end)

    device = connectedDevices[1]

    if not device then
      warn(fmt("[%s] no bluetooth devices found", obj.name))
      require("watchers.dock"):setAudio(DOCK.docked)

      return
    end

    local toggledDevice = false
    toggleDevice(device.alias, function(isConnected)
      if isConnected and not toggledDevice then
        success(fmt("[%s] connected %s %s", obj.name, device.icon, device.name))

        local audioDevice = hs.audiodevice.defaultOutputDevice()
        if audioDevice:balance() ~= default_balance then audioDevice:setBalance(default_balance) end

        hs.notify.withdrawAll()
        hs.notify.new({ title = self.name, subTitle = fmt("%s %s Connected", device.name, device.icon) }):send()
        toggledDevice = true
      end
    end)
  end)

  -- TODO: use an audio watcher callback instead?
  -- REF https://github.com/ivirshup/hammerspoon-config/blob/main/bluetooth_headphones.lua

  -- self.lowBatteryTimer = hs.timer.doEvery(self.interval, checkAndAlertLowBattery)
  -- checkAndAlertLowBattery()

  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop()
  self.lowBatteryTimer:stop()

  info(fmt("[STOP] %s", self.name))
  return self
end

return obj
