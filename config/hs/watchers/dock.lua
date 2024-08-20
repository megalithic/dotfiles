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
  success(fmt("[watcher.dock] wifi set to %s", connectedState))
end

function obj.setInput(device)
  local task = hs.task.new(
    obj.audioBin,
    function() end, -- Fake callback
    function(_task, stdOut, _stdErr)
      local continue = stdOut == string.format([[input audio device set to "%s"]], device)
      success(fmt("[%s] audio input set to %s", obj.name, device))
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
      success(fmt("[%s] audio output set to %s", obj.name, device))

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

-- ---@param dockState "docked"|"undocked"
function obj.refreshInput(dockState)
  dockState = dockState or "docked"
  local device = DOCK[dockState].input
  obj.setInput(device)
end

function obj.handleDockingStateChanges(_watcher, _path, _key, _oldValue, isConnected, isInitializing)
  isInitializing = (isInitializing ~= nil and type(isInitializing) == "boolean") and isInitializing or false
  local connectedState = isConnected and "docked" or "undocked"
  local notifier = isConnected and _G.success or _G.warn
  notifier = _G.warn
  local icon = isConnected and "🖥️" or "💻"
  local label = isConnected and "desktop mode" or "laptop mode"

  obj.setWifi(DOCK[connectedState].wifi)
  obj.setInput(DOCK[connectedState].input)
  obj.setOutput(DOCK[connectedState].output)

  notifier(fmt("[watcher.dock] %s transitioned to %s", icon, label))

  if not isInitializing then
    hs.alert.closeAll()
    hs.alert.show(fmt("%s Transitioned to %s", icon, label))

    hs.timer.doAfter(0.5, function()
      info(fmt("[watcher.dock] handling docking state changes (%s)", connectedState))
      req("wm").placeAllApps()
    end)
  end
end

obj.watchExistingDevices = function()
  for _, device in ipairs(hs.usb.attachedDevices()) do
    if device.productID == DOCK.target.productID then
      obj.handleDockingStateChanges(nil, nil, nil, nil, true, true)
      -- else
      --   obj.handleDockingStateChanges(nil, nil, nil, nil, false, true)
    end
  end
end

function obj:start()
  info(fmt("[START] %s", self.name))
  self.watchers.dock = hs.watchable.watch("status.dock", self.handleDockingStateChanges)
  self.watchExistingDevices()

  return self
end

function obj:stop() return self end

return obj
