-- -- Found on: https://gist.githubusercontent.com/daGrevis/79b27b9c156ba828ad52976a118b29e0/raw/0e77383f4eb9301527caac3f0b71350e9499210b/init.lua
-- -- FIXME: look at using https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/headphones.lua

local log = hs.logger.new("[bindings.airpods]", "debug")
local M = {}

local alert = require("ext.alert")

-- R-Phonak hearing aid
local headphoneDeviceId = "70-66-1b-c8-cc-b5"
local blueUtil = "/usr/local/bin/blueutil"

local function disconnectHeadphones()
  hs.task.new(blueUtil, function()
    hs.alert("Disconnected headphones")
  end, {
    "--disconnect",
    headphoneDeviceId,
  }):start()
end

local function connectHeadphones()
  hs.task.new(blueUtil, function()
    hs.alert("Connected headphones")
  end, {
    "--connect",
    headphoneDeviceId,
  }):start()
end

local function checkHeadphonesConnected(fn)
  hs.task.new(blueUtil, function(_, stdout)
    stdout = string.gsub(stdout, "\n$", "")
    local isConnected = stdout == "1"

    fn(isConnected)
  end, {
    "--is-connected",
    headphoneDeviceId,
  }):start()
end

local function toggleHeadphones()
  connectHeadphones()
  -- checkHeadphonesConnected(function(isConnected)
  --   if isConnected then
  --     disconnectHeadphones()
  --   else
  --     connectHeadphones()
  --   end
  -- end)
end

M.start = function()
  local hyper = require("bindings.hyper")
  hyper:bind({ "shift" }, "H", nil, function()
    toggleHeadphones()
    alert.show({ text = "Toggle 🎧 connection" })
    -- local ok, output = toggle("megapods")

    -- if ok then
    --   alert.show({ text = output })
    -- else
    --   alert.show({ text = "Couldn't connect to AirPods!" })
    -- end
  end)
end

M.stop = function()
  -- nil
end

return M
