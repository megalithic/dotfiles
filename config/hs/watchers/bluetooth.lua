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
    alias = "phonak",
    name = "R-Phonak hearing aid",
    bt = "R-Phonak hearing aid",
    id = "70-66-1b-c8-cc-b5",
    icon = "🎧",
    connected = false,
  },
  ["leeloo"] = {
    alias = "leeloo",
    name = "Leeloo",
    bt = "Leeloo",
    id = "F3-D9-8D-01-16-54",
    icon = "⌨️ ⌨️⌨️⌨️",
    connected = false,
  },
  ["airpods"] = {
    alias = "airpods",
    name = "megapods",
    bt = "AirPods Pro",
    id = "ac-90-85-c2-75-ab",
    icon = "🎧",
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

---@params device table|string
function obj.isBluetoothDeviceConnected(device)
  local targetDevice = device

  if type(device) == "string" then targetDevice = obj.devices[device] end

  local connectedDevices = hs.battery.privateBluetoothBatteryInfo()

  local connected = hs.fnutils.find(connectedDevices, function(device) return device.name == targetDevice.bt end) ~= nil

  return connected
end

local function connectDevice(deviceStr)
  local device = obj.devices[deviceStr]
  if not device then return end

  note(fmt("[%s] connecting %s %s..", obj.name, device.icon, device.name))

  hs.task
    .new(obj.btUtil, function(_exitCode, _stdOut, _stdErr) end, {
      "--connect",
      device.id,
    })
    :start()
end

-- local function checkDevice(deviceStr, fn)
--   local device = obj.devices[deviceStr]
--   if not device then return end
--
--   local isConnected = obj.isBluetoothDeviceConnected()
--
--   -- hs.task
--   --   .new(obj.btUtil, function(_, stdout)
--   --     stdout = string.gsub(stdout, "\n$", "")
--   --     local isConnected = stdout == "1"
--   --
--   --     connectedState = isConnected
--   --
--   --     fn(connectedState)
--   --   end, {
--   --     "--is-connected",
--   --     device.id,
--   --   })
--   --   :start()
--
--   return isConnected
-- end

local function toggleDevice(deviceStr, fn)
  -- local isConnected = false
  -- TODO: try the hearing aids first (maybe after 5 tries), then try megapods (again, 5 tries), then abort with a message
  -- local counter = 0
  hs.timer.doUntil(function()
    local isConnected = obj.isBluetoothDeviceConnected(deviceStr)
    fn(isConnected)

    if isConnected then require("watchers.dock"):setAudio(DOCK.docked) end

    return isConnected

    -- checkDevice(deviceStr, function(connectedState)
    --   isConnected = connectedState
    --
    --   local device = obj.devices[deviceStr]
    --
    --   device.connected = connectedState
    --
    --   fn(connectedState)
    --
    --   return connectedState
    -- end)

    -- if isConnected then require("watchers.dock"):setAudio(DOCK.docked) end
    --
    -- return isConnected
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

  local hyper = require("hyper"):start({ id = "bluetooth" })
  hyper:bind({ "shift" }, "h", nil, function()
    local device = self.devices["phonak"]

    if not obj.isBluetoothDeviceConnected("phonak") then device = self.devices["airpods"] end

    local toggledDevice = false
    toggleDevice(device.alias, function(isConnected)
      if isConnected and not toggledDevice then
        success(fmt("[%s] connected %s %s", obj.name, device.icon, device.name))

        local audioDevice = hs.audiodevice.defaultOutputDevice()
        cur_balance = audioDevice:balance()
        if cur_balance ~= default_balance then audioDevice:setBalance(default_balance) end

        hs.notify.withdrawAll()
        hs.notify.new({ title = self.name, subTitle = fmt("%s %s Connected", device.name, device.icon) }):send()
        toggledDevice = true
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
