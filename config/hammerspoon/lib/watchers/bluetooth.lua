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
obj.debug = false
obj.devices = {
  ["phonak"] = {
    name = "R-Phonak hearing aid",
    id = "70-66-1b-c8-cc-b5",
    icon = "🎧",
    connected = false,
  },
  ["leeloo"] = {
    name = "Leeloo",
    id = "F3-D9-8D-01-16-54",
    icon = "⌨️ ⌨️⌨️⌨️",
    connected = false,
  },
  ["megapods"] = {
    name = "megapods",
    id = "ac-90-85-c2-75-ab",
    icon = "⌨️ ⌨️⌨️⌨️",
    connected = false,
  },
}
obj.btUtil = hostname() == "megabookpro" and "/opt/homebrew/bin/blueutil" or "/usr/local/bin/blueutil"
obj.interval = (10 * 60)

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

local function connectDevice(deviceStr)
  local device = obj.devices[deviceStr]
  if not device then return end

  info(fmt(":: please wait, connecting %s %s..", device.name, device.icon))

  hs.task
    .new(
      obj.btUtil,
      function(exitCode, stdOut, stdErr)
        dbg("connectDevice/task: \nexitCode: %s\nstdOut: %s\nstdErr: %s", exitCode, stdOut, stdErr)
      end,
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

  local connectedState = false

  hs.task
    .new(obj.btUtil, function(_, stdout)
      stdout = string.gsub(stdout, "\n$", "")
      local isConnected = stdout == "1"

      dbg("checkDevice/isConnected? %s", isConnected)

      connectedState = isConnected
      fn(isConnected)
    end, {
      "--is-connected",
      device.id,
    })
    :start()

  return connectedState
end

local function toggleDevice(deviceStr, fn)
  local isConnected = false
  -- TODO: try the hearing aids first (maybe after 5 tries), then try megapods (again, 5 tries), then abort with a message
  -- local counter = 0
  hs.timer.doUntil(function()
    checkDevice(deviceStr, function(connectedState)
      isConnected = connectedState
      dbg("toggleDevice/checkDevice/callback/isConnected? %s", connectedState)

      local device = obj.devices[deviceStr]

      obj.devices[deviceStr].connected = connectedState

      fn(connectedState)

      return connectedState
    end)

    if isConnected then dbg("%s is connected..", deviceStr) end

    return isConnected
  end, function() connectDevice(deviceStr) end)
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
  Hyper:bind({ "shift" }, "H", nil, function()
    local device = obj.devices["phonak"]
    toggleDevice("phonak", function(isConnected)
      if isConnected then
        info(fmt(":: connected %s %s", device.name, device.icon))
        require("lib.watchers.dock").setInput(C.dock.docked.input)
        hs.notify.new({ title = obj.name, subTitle = fmt("%s %s Connected", device.name, device.icon) }):send()
      end
    end)
  end)

  -- lowBatteryTimer = hs.timer.doEvery(obj.interval, checkAndAlertLowBattery)
  -- checkAndAlertLowBattery()

  return self
end

function obj:stop()
  -- lowBatteryTimer:stop()
  return self
end

return obj
