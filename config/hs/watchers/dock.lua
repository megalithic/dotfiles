local obj = {}

obj.__index = obj
obj.name = "watcher.dock"
obj.audioInput = nil
obj.audioOutput = nil
obj.audioBin = "/opt/homebrew/bin/SwitchAudioSource"
obj.watchers = {
  dock = {},
}

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

local function handleDockingStateChanges(_watcher, _path, _key, _oldValue, isConnected)
  local connectedState = isConnected and "docked" or "undocked"
  local notifier = isConnected and _G.success or _G.warn
  notifier = _G.warn
  local icon = isConnected and "🖥️" or "💻"
  local label = isConnected and "desktop mode" or "laptop mode"

  info(fmt("[dock] handling docking state changes (%s)", connectedState))

  obj.setWifi(DOCK[connectedState].wifi)
  obj.setInput(DOCK[connectedState].input)
  obj.setOutput(DOCK[connectedState].output)

  notifier(fmt("[watcher.dock] %s transitioned to %s", icon, label))

  hs.alert.closeAll()
  hs.alert.show(fmt("%s Transitioned to %s", icon, label))

  -- hs.timer.doAfter(1, function() WM.layoutRunningApps(C.bindings.apps) end)
  -- WM.layoutRunningApps(C.bindings.apps)
end

function obj:start()
  info(fmt("[START] %s", self.name))
  obj.watchers.dock = hs.watchable.watch("status.dock", handleDockingStateChanges)
  return self
end

function obj:stop() return self end

return obj
