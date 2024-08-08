local obj = {}

obj.__index = obj
obj.name = "dock"
obj.audioInput = nil
obj.audioOutput = nil
obj.audioBin = "/opt/homebrew/bin/SwitchAudioSource"

function obj.setWifi(connectedState)
  hs.execute("networksetup -setairportpower airport " .. connectedState, true)
  success(fmt("[dock] wifi set to %s", connectedState))
end

function obj.setInput(device)
  local task = hs.task.new(
    obj.audioBin,
    function() end, -- Fake callback
    function(_task, stdOut, _stdErr)
      local continue = stdOut == string.format([[input audio device set to "%s"]], device)
      success(fmt("[dock] audio input set to %s", device))
      return continue
    end,
    { "-t", "input", "-s", device }
  )
  task:start()
end

function obj.setOutput(device)
  local task = hs.task.new(
    obj.audioBin,
    function() end, -- Fake callback
    function(_task, stdOut, _stdErr)
      local continue = stdOut == string.format([[output audio device set to "%s"]], device)
      success(fmt("[dock] audio output set to %s", device))
      return continue
    end,
    { "-t", "output", "-s", device }
  )
  task:start()
end

function obj:setAudio(devices)
  self.audioInput = devices.input
  self.audioOutput = devices.output

  obj.setInput(self.audioInput)
  obj.setOutput(self.audioOutput)

  return self
end

function obj:start()
  info(fmt("[START] %s", self.name))
  return self
end

function obj:stop() return self end

return obj
