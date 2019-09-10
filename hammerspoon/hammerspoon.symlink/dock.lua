local config = require('config')
local log = hs.logger.new('[docking]', 'debug')
local isDocked = false
local watcher = nil

local selectKarabinerProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )
  log.i('Switching to Karabiner-Elements profile:', profile)
end)

local toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )
  log.i('Switching wifi', state)
end)

local selectAudioOutput = (function(output)
  hs.execute(
    'SwitchAudioSource -t output -s ' ..
    output
  )
  log.i('Switching to audio output:', output)
end)

local selectAudioInput = (function(input)
  hs.execute(
    'SwitchAudioSource -t input -s ' ..
    input
  )
  log.i('Switching to audio input:', input)
end)

local isDeviceConnected = (function()
  for _, device in pairs(hs.usb.attachedDevices()) do
    if (config.docking.device.vendorID == device.vendorID and config.docking.device.productID == device.productID) then
      return true
    end
  end
end)

local dockedAction = function()
  log.i('Target USB device plugged in; laptop presumably docked')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(config.docking['docked'].profile)
    toggleWifi(config.docking['docked'].wifi)
  end)
  hs.timer.doAfter(4, function ()
    selectAudioOutput(config.docking['docked'].output)
    selectAudioInput(config.docking['docked'].input)
  end)
end

local undockedAction = function()
  log.i('Target USB device unplugged; laptop presumably undocked')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(config.docking['undocked'].profile)
    toggleWifi(config.docking['undocked'].wifi)
  end)
  hs.timer.doAfter(4, function ()
    selectAudioOutput(config.docking['undocked'].output)
    selectAudioInput(config.docking['undocked'].input)
  end)
end

local handleUsbWatcherEvent = (function(event)
  -- Safe assumption that connecting my keyboard means we are "docked", so do
  -- things based on being "docked".
  if event.vendorID == config.docking['device'].vendorID and event.productID == config.docking['device'].productID then
    if event.eventType == 'added' then
      isDocked = true
      dockedAction()
    else
      isDocked = false
      undockedAction()
    end
  end
end)

return {
  init = (function()
    log.i('Creating laptop-docking-mode watchers')
    watcher = hs.usb.watcher.new(handleUsbWatcherEvent):start()

    isDocked = isDeviceConnected()

    if (isDocked) then
      dockedAction()
    else
      undockedAction()
    end

    log.i('Docked status:', isDocked)
    return isDocked
  end),
  teardown = (function()
    log.i('Tearing down laptop-docking-mode watchers')
    watcher:stop()
  end),
  isDocked = isDeviceConnected()
}
