local obj = {}

obj.__index = obj
obj.name = "watcher.usb"
obj.debug = false
obj.watchers = {
  usb = {},
  status = {},
}

local function leelooHandler(_watcher, _path, _key, _oldValue, isConnected)
  local function setProfile(profile)
    dbg("attempting to set profile to: %s", profile)
    local task = hs.task.new(
      [[/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli]],
      function() end, -- Fake callback
      function(_task, stdOut, stdErr)
        if stdErr then
          error(fmt("[%s.keyboard] error occurred for setProfile: %s", obj.name, stdErr))
        else
          dbg("setProfile output: %s", stdOut)
        end
        local continue = stdOut == ""
        return continue
      end,
      { "--select-profile", profile }
    )
    task:start()
  end

  if isConnected then
    setProfile(DOCK.keyboard.connected)
    success(fmt("[%s.keyboard] leeloo connected (%s)", obj.name, DOCK.keyboard.connected))
  else
    setProfile(DOCK.keyboard.disconnected)
    warn(fmt("[%s.keyboard] leeloo disconnected (%s)", obj.name, DOCK.keyboard.disconnected))
  end
end

local function usbHandler(device)
  local leelooConnected = false
  if device.productID == DOCK.keyboard.productID then
    if device.eventType == "added" then
      leelooConnected = true
    elseif device.eventType == "removed" then
      leelooConnected = false
    end

    leelooHandler(nil, nil, nil, nil, leelooConnected)
  end

  if device.productID == DOCK.target.productID then
    if device.eventType == "added" then
      obj.watchers.status.dock = true
    elseif device.eventType == "removed" then
      obj.watchers.status.dock = false
    end
  end
end

obj.watchExistingDevices = function()
  for _, device in ipairs(hs.usb.attachedDevices()) do
    if device.productID == DOCK.keyboard.productID then leelooHandler(nil, nil, nil, nil, true) end
    if device.productID == DOCK.target.productID then
      obj.watchers.status.dock = true
    else
    end
  end
end

function obj:start()
  self.watchers.usb = hs.usb.watcher.new(usbHandler):start()
  self.watchers.status = hs.watchable.new("status", false) -- don't allow bi-directional status updates

  self.watchExistingDevices()
  info(fmt("[START] %s", self.name))
  return self
end

function obj:stop()
  if self.watchers.usb then self.watchers.usb:stop() end
  if self.watchers.status then self.watchers.status = nil end

  info(fmt("[STOP] %s", self.name))
  return self
end

return obj
