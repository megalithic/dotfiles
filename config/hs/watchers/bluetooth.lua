local obj = {}

local default_balance = 0.7

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
obj.btUtil = Hostname() == "megabookpro" and "/opt/homebrew/bin/blueutil" or "/usr/local/bin/blueutil"
obj.interval = (10 * 60)
obj.lowBatteryTimer = nil

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

local function leelooBluetoothConnected()
  local connectedDevices = hs.battery.privateBluetoothBatteryInfo()
  local connected = hs.fnutils.find(connectedDevices, function(device) return device.name == "Leeloo" end) ~= nil
  dbg("leeloo (bt): %s", connected)
  return connected
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

      info(connectedState)

      fn(connectedState)
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

    if isConnected then
      dbg("%s is connected..", deviceStr)

      require("watchers.dock"):setAudio(DOCK.docked)
    end

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
  self.menubar = hs.menubar.new()

  local hyper = require("hyper"):start({ id = "bluetooth" })
  hyper:bind({ "shift" }, "h", nil, function()
    local device = self.devices["phonak"]
    toggleDevice("phonak", function(isConnected)
      if isConnected then
        info(fmt(":: connected %s %s", device.name, device.icon))
        require("watchers.dock"):setAudio(DOCK.docked)

        local audioDevice = hs.audiodevice.defaultOutputDevice()
        cur_balance = audioDevice:balance()
        if cur_balance ~= default_balance then audioDevice:setBalance(default_balance) end

        hs.notify.withdrawAll()
        hs.notify.new({ title = self.name, subTitle = fmt("%s %s Connected", device.name, device.icon) }):send()
      end
    end)
  end)

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
