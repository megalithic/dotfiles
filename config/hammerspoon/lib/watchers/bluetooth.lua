local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")
local alert = require("utils.alert")

local obj = {}
local Hyper

-- REF:
-- https://github.com/wangshub/hammerspoon-config/blob/master/headphone/headphone.lua

obj.__index = obj
obj.name = "watcher.bluetooth"
obj.btDeviceId = { name = "R-Phonak hearing aid", id = "70-66-1b-c8-cc-b5", icon = "🎧" }
obj.btUtil = "/usr/local/bin/blueutil"
obj.refreshInterval = 1

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

function obj.checkDevice(fn)
  hs.task
    .new(obj.btUtil, function(_, stdout)
      stdout = string.gsub(stdout, "\n$", "")
      local isConnected = stdout == "1"

      fn(isConnected)
    end, {
      "--is-connected",
      obj.btDeviceId.id,
    })
    :start()
end

local function toggleDevice()
  connectDevice()
  obj.checkDevice(function(isConnected)
    if not isConnected then connectDevice() end
  end)
end

local function updateTitle()
  obj.checkDevice(function(isConnected)
    if isConnected then
      obj.menubar:setTitle("on")
    else
      obj.menubar:setTitle(nil)
    end
  end)
end

function obj:start()
  obj.menubar = hs.menubar.new()
  -- obj.menubar:setTitle(nil)

  Hyper = L.load("lib.hyper", { id = "bluetooth" })
  Hyper:bind({ "shift" }, "H", nil, function() toggleDevice() end)

  -- hs.timer.doEvery(obj.refreshInterval, updateTitle)

  return self
end

function obj:stop() return self end

return obj
