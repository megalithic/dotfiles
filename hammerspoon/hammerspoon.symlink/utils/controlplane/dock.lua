local config = require('config')
local utils = require('utils')
local log = hs.logger.new('[docking]', 'debug')
local is_docked = false
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

local enableFastKeypress = (function(state)
  hs.execute('defaults write NSGlobalDomain KeyRepeat -int 1')
  -- https://superuser.com/questions/40061/what-is-the-mac-os-x-terminal-command-to-log-out-the-current-user
end)

local disableFastKeypress = (function(state)
  hs.execute('defaults write NSGlobalDomain KeyRepeat -int 0')
  -- https://superuser.com/questions/40061/what-is-the-mac-os-x-terminal-command-to-log-out-the-current-user
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

local setKittyConfig = (function(c)
    log.i('Setting kitty font-size to:', c.fontSize)
    hs.execute('kitty @ --to unix:/tmp/kitty set-font-size ' .. c.fontSize, true)
    -- hs.execute('kitty @ set-font-size ' .. c.fontSize)
end)

local isDeviceConnected = (function()
  log.i('Checking if devices are connected..')

  local found_device = false

  if utils.tableLength(hs.usb.attachedDevices()) == 0 then
    log.i('nope!')
    found_device = false
  else
    for _, device in pairs(hs.usb.attachedDevices()) do
      if (deviceConfig.vendorID == device.vendorID and deviceConfig.productID == device.productID) then
        found_device = true
      end
    end
  end

  log.i('Did we find anything?', hs.inspect(found_device))

  return found_device
end)

local dockedAction = function()
  local dockedConfig =  config.docking.docked
  log.i('Target USB device plugged in; laptop presumably docked..')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(dockedConfig.profile)
    toggleWifi(dockedConfig.wifi)
  end)
  hs.timer.doAfter(4, function ()
    selectAudioOutput(dockedConfig.output)
    selectAudioInput(dockedConfig.input)
    setKittyConfig(dockedConfig)
    require('layout').setLayoutForAll()
  end)
end

local undockedAction = function()
  local undockedConfig =  config.docking.undocked
  log.i('Target USB device unplugged; laptop presumably undocked..')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(undockedConfig.profile)
    toggleWifi(undockedConfig.wifi)
  end)
  hs.timer.doAfter(4, function ()
    selectAudioOutput(undockedConfig.output)
    selectAudioInput(undockedConfig.input)
    setKittyConfig(undockedConfig)
    require('layout').setLayoutForAll()
  end)
end

local handleUsbWatcherEvent = (function(event)
  -- Safe assumption that connecting my keyboard means we are "docked", so do
  -- things based on being "docked".
  if event.vendorID == deviceConfig.vendorID and event.productID == deviceConfig.productID then
    if event.eventType == 'added' then
      is_docked = true
      dockedAction()
    else
      is_docked = false
      undockedAction()
    end
  end
end)

return {
  init = (function()
    log.i('Creating USB watchers..')
    watcher = hs.usb.watcher.new(handleUsbWatcherEvent):start()

    is_docked = isDeviceConnected()

    if (is_docked) then
      dockedAction()
    else
      undockedAction()
    end

    return is_docked
  end),
  teardown = (function()
    log.i('Tearing down USB watchers..')
    watcher:stop()
  end),
  isDocked = function()
    return isDeviceConnected()
  end,
  isCurrentlyDocked = function()
    return isDeviceConnected()
  end
}
