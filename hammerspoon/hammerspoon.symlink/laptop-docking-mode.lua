isDocked = false

dockedAction = function()
  log.i('[laptop-docking-mode] - Target USB device plugged in; laptop presumably docked')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(config.docking['docked'].profile)
    toggleWifi(config.docking['docked'].wifi)
    selectAudioOutput(config.docking['docked'].output)
    selectAudioInput(config.docking['docked'].input)
  end)
end

undockedAction = function()
  log.i('[laptop-docking-mode] - Target USB device unplugged; laptop presumably undocked')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(config.docking['undocked'].profile)
    toggleWifi(config.docking['undocked'].wifi)
    selectAudioOutput(config.docking['undocked'].output)
    selectAudioInput(config.docking['undocked'].input)
  end)
end

handleUsbWatcherEvent = (function(event)
  -- Safe assumption that connecting my keyboard means we are "docked", so do
  -- things based on being "docked".
  if event.vendorID == config.docking['device'].vendorID and event.productID == config.docking['device'].productID then
    if event.eventType == 'added' then
      require('home-assistant').init()
      isDocked = true
      dockedAction()
    else
      isDocked = false
      undockedAction()
    end
  end
end)

selectKarabinerProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )
  log.i('[laptop-docking-mode] - Switching to Karabiner-Elements profile:', profile)
end)

toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )
  log.i('[laptop-docking-mode] - Switching wifi', state)
end)

selectAudioOutput = (function(output)
  hs.execute(
    'SwitchAudioSource -t output -s ' ..
    output
  )
  log.i('[laptop-docking-mode] - Switching to audio output:', output)
end)

selectAudioInput = (function(input)
  hs.execute(
    'SwitchAudioSource -t input -s ' ..
    input
  )
  log.i('[laptop-docking-mode] - Switching to audio input:', input)
end)

isDeviceConnected = (function()
  for _, device in pairs(hs.usb.attachedDevices()) do
    if (config.docking.device.vendorID == device.vendorID and config.docking.device.productID == device.productID) then
      return true
    end
  end
end)

return {
  init = (function()
    log.i('[laptop-docking-mode] - Creating laptop-docking-mode watchers')
    watcher = hs.usb.watcher.new(handleUsbWatcherEvent):start()

    isDocked = isDeviceConnected()

    if (isDocked) then
      dockedAction()
    else
      undockedAction()
    end

    return isDocked
  end),
  teardown = (function()
    log.i('[laptop-docking-mode] - Tearing down laptop-docking-mode watchers')
    watcher:stop()
    watcher = nil
  end),
  isDocked = isDeviceConnected()
}
