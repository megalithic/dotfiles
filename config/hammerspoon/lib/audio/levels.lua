local M = {}

local task = nil
local callback = nil
local buffer = ""
local SCRIPT_PATH = hs.configdir .. "/scripts/level-monitor.swift"
local MAX_BUFFER = 1024

---@param onLevel fun(level: number)
function M.start(onLevel)
  if task then M.stop() end
  
  callback = onLevel
  buffer = ""
  
  local function onTerminate(exitCode, stdout, stderr)
    task = nil
    callback = nil
    buffer = ""
  end
  
  local function onStream(_, stdout, _)
    if not stdout then return true end
    
    buffer = buffer .. stdout
    if #buffer > MAX_BUFFER then
      buffer = buffer:sub(-MAX_BUFFER)
    end
    
    while true do
      local nl = buffer:find("\n")
      if not nl then break end
      
      local line = buffer:sub(1, nl - 1)
      buffer = buffer:sub(nl + 1)
      
      local level = tonumber(line)
      if level and callback then
        callback(level)
      end
    end
    return true
  end
  
  task = hs.task.new(SCRIPT_PATH, onTerminate, onStream, {})
  if task then
    task:setStreamingCallback(onStream)
    task:start()
    return true
  end
  return false
end

function M.stop()
  if task then
    task:terminate()
    task = nil
  end
  callback = nil
  buffer = ""
end

---@return boolean
function M.isRunning()
  return task ~= nil and task:isRunning()
end

return M
