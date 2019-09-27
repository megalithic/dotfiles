-- TODO: extract events and device things to config.lua if possible

local log = hs.logger.new('[hubitat]', 'debug')
local officeDeviceId = 171
local weatherDeviceId = 32

local M = {}

M.executeCommand = function(command, id)
  hs.execute("hubitat " .. command .. " " .. id, true)
  log.df("executing hubitat command (%s) for device (%s)", command, id)
  -- hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/hubitat", {"'" .. command .. "'", "'" .. id .. "'"}):start()
end

M.lampToggle = function(command)
  M.executeCommand(command, officeDeviceId)
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

M.isNight = function()
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

M.handleEnvironmentBasedOfficeAutomations = function()
  if (M.isNight()) then
    log.df('night time; turning on office lamp, regardless of weather conditions')
    M.lampToggle("on")
  else
    log.df('day time; turning on office lamp based on weather conditions')
    if (isCloudy()) then
      log.df('is presently cloudy, turning on')
      M.lampToggle("on")
    else
      log.df('is not cloudy, turning off')
      M.lampToggle("off")
    end
  end
end

return M
