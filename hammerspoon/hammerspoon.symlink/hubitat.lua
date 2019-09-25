-- TODO: extract events and device things to config.lua if possible

local log = hs.logger.new('[hubitat]', 'debug')
local officeDeviceId = 171
local weatherDeviceId = 32

local executeCommand = function(command, id)
  -- hs.execute("hubitat " .. command .. " " .. id, true)
  hs.task.new(
    os.getenv("HOME") ..  "/.dotfiles/bin/hubitat",
    nil,
    nil,
    {command, id}
    ):start()
end

local lampToggle = function(command)
  executeCommand(command, officeDeviceId)
end

local isCloudy = function()
  local isCloudy = hs.task.new(
    os.getenv("HOME") ..  "/.dotfiles/bin/hubitat",
    function(...)
      print("exit", hs.inspect(table.pack(...)))
    end,
    function(...)
      print("stream", hs.inspect(table.pack(...)))
      return true
    end,
    {"status", "".. weatherDeviceId .. "", '.attributes[] | select(.name == "cloud").currentValue | tonumber >= 75'}
  ):start()
  log.df("isCloudy? %s", isCloudy)
  -- return hs.execute("hubitat status " .. weatherDeviceId .. " '.attributes[] | select(.name == \"cloud\").currentValue | tonumber >= 75'")
end

local isNight = function()
  local isNight = hs.task.new(
    os.getenv("HOME") ..  "/.dotfiles/bin/hubitat",
    function(...)
      print("exit", hs.inspect(table.pack(...)))
    end, function(...)
      print("stream", hs.inspect(table.pack(...)))
      return true
    end,
    {"status", "".. weatherDeviceId .. "", '.attributes[] | select(.name == "is_day").currentValue | tonumber == 0'}
  ):start()
  log.df("isNight? %s", isNight)
  -- return hs.execute("hubitat status " .. weatherDeviceId .. " '.attributes[] | select(.name == \"is_day\").currentValue | tonumber == 0'")
end

return {
  lampToggle = lampToggle,
  isNight = isNight,
  isCloudy = isCloudy,
  exec = executeCommand
}
