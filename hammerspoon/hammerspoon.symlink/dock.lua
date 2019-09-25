local config = require('config')
local log = hs.logger.new('[docking]', 'debug')
local isDocked = false
local watcher = nil
local deviceConfig =  config.docking.device

local selectKarabinerProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )
  log.i('Switching to keyboard profile:', profile)
end)

local toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )
  log.i('Switching WiFi state:', state)
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
    if (deviceConfig.vendorID == device.vendorID and deviceConfig.productID == device.productID) then
      return true
    end
  end
end)

local dockedAction = function()
  local dockedConfig =  config.docking.docked
  log.i('Target USB device plugged in; laptop presumably docked..')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(dockedConfig.profile)
    toggleWifi(dockedConfig.wifi)
    log.i('Setting kitty font-size to:', dockedConfig.fontSize)
    hs.execute('kitty @ --to unix:/tmp/kitty set-font-size --all ' .. dockedConfig.fontSize)
    -- hs.execute('kitty @ set-font-size ' .. dockedConfig.fontSize)
  end)
  hs.timer.doAfter(4, function ()
    selectAudioOutput(dockedConfig.output)
    selectAudioInput(dockedConfig.input)
  end)
end

local undockedAction = function()
  local undockedConfig =  config.docking.undocked
  log.i('Target USB device unplugged; laptop presumably undocked..')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(undockedConfig.profile)
    toggleWifi(undockedConfig.wifi)
    log.i('Setting kitty font-size to:', undockedConfig.fontSize)
    hs.execute('kitty @ --to unix:/tmp/kitty set-font-size --all ' .. undockedConfig.fontSize)
    -- hs.execute('kitty @ set-font-size ' .. undockedConfig.fontSize)
  end)
  hs.timer.doAfter(4, function ()
    selectAudioOutput(undockedConfig.output)
    selectAudioInput(undockedConfig.input)
  end)
end

local handleUsbWatcherEvent = (function(event)
  -- Safe assumption that connecting my keyboard means we are "docked", so do
  -- things based on being "docked".
  if event.vendorID == deviceConfig.vendorID and event.productID == deviceConfig.productID then
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
    log.i('Creating USB watchers..')
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
    log.i('Tearing down USB watchers..')
    watcher:stop()
  end),
  isDocked = isDeviceConnected()
}
