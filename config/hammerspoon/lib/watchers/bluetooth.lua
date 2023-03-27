local alert = require("utils.alert")

local obj = {}
local Hyper
local lowBatteryTimer

-- REF:
-- https://github.com/jasonrudolph/dotfiles/commit/8bc3e6c55bd9c95eb83e4cfa265cc32d9da6edc3
-- https://github.com/wangshub/hammerspoon-config/blob/master/headphone/headphone.lua
-- https://gist.github.com/ysimonson/fea48ee8a68ed2cbac12473e87134f58
-- https://github.com/drn/dots/blob/master/bin/hd1
-- https://github.com/drn/dots/blob/master/hammerspoon/bluetooth.lua

obj.__index = obj
obj.name = "watcher.bluetooth"
obj.devices = {
  ["phonak"] = {
    name = "R-Phonak hearing aid",
    id = "70-66-1b-c8-cc-b5",
    icon = "🎧",
  },
  ["leeloo"] = {
    name = "Leeloo",
    id = "F3-D9-8D-01-16-54",
    icon = "⌨️",
  },
}
obj.btUtil = hostname() == "megabookpro" and "/opt/homebrew/bin/blueutil" or "/usr/local/bin/blueutil"
obj.interval = (10 * 60)

local function connectDevice(deviceStr)
  local device = obj.devices[deviceStr]
  if not device then return end

  alert.close()
  alert.show(fmt("Connecting %s %s", device.name, device.icon))
  hs.task
    .new(
      obj.btUtil,
      function() hs.notify.new({ title = obj.name, subTitle = fmt("%s %s Connected", device.name, device.icon) }):send() end,
      {
        "--connect",
        device.id,
      }
    )
    :start()
end

local function checkDevice(deviceStr, fn)
  local device = obj.devices[deviceStr]
  if not device then return end

  hs.task
    .new(obj.btUtil, function(_, stdout)
      stdout = string.gsub(stdout, "\n$", "")
      local isConnected = stdout == "1"

      fn(isConnected)
    end, {
      "--is-connected",
      device.id,
    })
    :start()
end

local function toggleDevice(deviceStr)
  connectDevice(deviceStr)
  checkDevice(deviceStr, function(isConnected)
    if not isConnected then connectDevice(deviceStr) end
  end)
end

local function updateTitle()
  checkDevice(function(isConnected)
    if isConnected then
      obj.menubar:setTitle("on")
    else
      obj.menubar:setTitle(nil)
    end
  end)
end

local function checkAndAlertLowBattery()
  local batteryInfoForConnectedDevices = hs.battery.privateBluetoothBatteryInfo()

  hs.fnutils.each(batteryInfoForConnectedDevices, function(device)
    local percentage = device["batteryPercentSingle"]
    local name = device["name"]

    -- TODO: add a watcheable watch for bluetooth
    -- watching

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
  obj.menubar = hs.menubar.new()

  Hyper = L.load("lib.hyper", { id = "bluetooth" })
  Hyper:bind({ "shift" }, "H", nil, function() toggleDevice("phonak") end)

  lowBatteryTimer = hs.timer.doEvery(obj.interval, checkAndAlertLowBattery)
  checkAndAlertLowBattery()

  return self
end

function obj:stop()
  lowBatteryTimer:stop()
  return self
end

return obj
