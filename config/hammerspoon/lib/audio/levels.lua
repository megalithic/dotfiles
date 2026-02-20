local M = {}

local task = nil
local callback = nil
local buffer = ""
local isMonitoring = false
local isReady = false
local SCRIPT_PATH = hs.configdir .. "/scripts/level-monitor.swift"
local MAX_BUFFER = 1024

local function sendCommand(cmd)
  if task and task:isRunning() then
    task:setInput(cmd .. "\n")
  end
end

local function processLine(line)
  if line == "ready" then
    isReady = true
    return
  end
  if line == "started" then
    isMonitoring = true
    return
  end
  if line == "stopped" then
    isMonitoring = false
    return
  end
  
  local level = tonumber(line)
  if level and callback and isMonitoring then
    callback(level)
  end
end

function M.preload()
  if task then return true end
  
  isReady = false
  isMonitoring = false
  buffer = ""
  
  local function onTerminate()
    task = nil
    callback = nil
    buffer = ""
    isReady = false
    isMonitoring = false
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
      processLine(line)
    end
    return true
  end
  
  task = hs.task.new(SCRIPT_PATH, onTerminate, onStream, {"--interactive"})
  if task then
    task:setStreamingCallback(onStream)
    task:start()
    return true
  end
  return false
end

---@param onLevel fun(level: number)
function M.start(onLevel)
  callback = onLevel
  
  if not task then
    M.preload()
  end
  
  if not isMonitoring then
    sendCommand("start")
  end
  
  return true
end

function M.stop()
  if isMonitoring then
    sendCommand("stop")
  end
  callback = nil
end

function M.shutdown()
  M.stop()
  if task then
    sendCommand("quit")
    task:terminate()
    task = nil
  end
  isReady = false
  isMonitoring = false
  buffer = ""
end

---@return boolean
function M.isRunning()
  return task ~= nil and task:isRunning()
end

---@return boolean
function M.isReady()
  return isReady
end

---@return boolean
function M.isMonitoring()
  return isMonitoring
end

return M
