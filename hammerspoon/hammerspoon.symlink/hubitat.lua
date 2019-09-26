-- TODO: extract events and device things to config.lua if possible

local log = hs.logger.new('[hubitat]', 'debug')
local officeDeviceId = 171
local weatherDeviceId = 32

local executeCommand = function(command, id)
  -- hs.execute("hubitat " .. command .. " " .. id, true)
  hs.task.new(os.getenv("HOME") ..  "/.dotfiles/bin/hubitat", (function() end), (function() end), {command, id}):start()
  -- hs.task.new(
  --   os.getenv("HOME") ..  "/.dotfiles/bin/hubitat",
  --   function(...)
  --     print("exit", hs.inspect(table.pack(...)))
  --   end,
  --   function(...)
  --     print("stream", hs.inspect(table.pack(...)))
  --   end,
  --   {command, id}
  --   ):start()
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

local handleEnvironmentBasedOfficeAutomations = function()
  if (isNight()) then
    log.df('night time; turning on office lamp, regardless of weather conditions')
    lampToggle("on")
  else
    log.df('day time; turning on office lamp based on weather conditions')
    if (isCloudy()) then
      log.df('is presently cloudy, turning on')
      lampToggle("on")
    else
      log.df('is not cloudy, turning off')
      lampToggle("off")
    end
  end
end

return {
  exec = executeCommand,
  handleEnvironmentBasedOfficeAutomations = handleEnvironmentBasedOfficeAutomations,
  isCloudy = isCloudy,
  isNight = isNight,
  lampToggle = lampToggle,
}
