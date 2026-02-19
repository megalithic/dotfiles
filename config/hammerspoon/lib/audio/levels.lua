--- Audio Level Monitor
--- Monitors microphone input levels via external script
---
--- Usage:
---   local levels = require("lib.audio.levels")
---   levels.start(function(level) print("Level:", level) end)
---   levels.stop()

local M = {}

local task = nil
local callback = nil
local buffer = ""

--- Path to the level monitor script
local SCRIPT_PATH = hs.configdir .. "/lib/audio/level-monitor.sh"

--- Start monitoring audio levels
---@param onLevel function(level: number) Called with level 0.0-1.0 on each update
function M.start(onLevel)
  if task then
    M.stop()
  end
  
  callback = onLevel
  buffer = ""
  
  -- Create streaming callback that processes stdout line by line
  local function streamCallback(task, stdout, stderr)
    if stdout then
      buffer = buffer .. stdout
      -- Process complete lines
      while true do
        local newline = buffer:find("\n")
        if not newline then break end
        local line = buffer:sub(1, newline - 1)
        buffer = buffer:sub(newline + 1)
        
        local level = tonumber(line)
        if level and callback then
          callback(level)
        end
      end
    end
    return true  -- Keep streaming
  end
  
  -- hs.task.new(launchPath, terminationCallback, streamCallback, arguments)
  -- arguments is required when using streamCallback
  task = hs.task.new(SCRIPT_PATH, nil, streamCallback, {})
  
  if task then
    task:setStreamingCallback(streamCallback)
    task:start()
    return true
  else
    return false
  end
end

--- Stop monitoring audio levels
function M.stop()
  if task then
    task:terminate()
    task = nil
  end
  callback = nil
  buffer = ""
end

--- Check if currently monitoring
---@return boolean
function M.isRunning()
  return task ~= nil and task:isRunning()
end

return M
