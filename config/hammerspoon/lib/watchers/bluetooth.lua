local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")
local alert = require("utils.alert")

local obj = {}
local Hyper

obj.__index = obj
obj.name = "watcher.bluetooth"
obj.btDeviceId = { name = "R-Phonak hearing aid", id = "70-66-1b-c8-cc-b5", icon = "🎧" }
obj.btUtil = "/usr/local/bin/blueutil"

-- local function disconnectDevice()
--   hs.task.new(blueUtil, function()
--     alert.show(fmt("%s %s Disconnected", obj.btDeviceId.name, obj.btDeviceId.icon))
--   end, {
--     "--disconnect",
--     headphoneDeviceId,
--   }):start()
-- end

local function connectDevice()
  alert.show(fmt("Connecting %s %s", obj.btDeviceId.name, obj.btDeviceId.icon))
  hs.task
    .new(
      obj.btUtil,
      function()
        hs.notify
          .new({ title = obj.name, subTitle = fmt("%s %s Connected", obj.btDeviceId.name, obj.btDeviceId.icon) })
          :send()
      end,
      {
        "--connect",
        obj.btDeviceId.id,
      }
    )
    :start()
end

local function checkDevice(fn)
  hs.task
    .new(obj.btUtil, function(_, stdout)
      stdout = string.gsub(stdout, "\n$", "")
      local isConnected = stdout == "1"

      fn(isConnected)
    end, {
      "--is-connected",
      obj.btDeviceId,
    })
    :start()
end

local function toggleDevice()
  connectDevice()
  checkDevice(function(isConnected)
    if not isConnected then connectDevice() end
  end)
end

function obj:start()
  Hyper = L.load("lib.hyper", { id = "bluetooth" })
  Hyper:bind({ "shift" }, "H", nil, function() toggleDevice() end)

  return self
end

function obj:stop() return self end

return obj
