local log = require 'log'
local inspect = require('inspect')

local dockedDevice = {
  -- my pok3r keyboard's USB identifiers:
  vendorID = 1241,
  productID = 321
}

dockedAction = function()
  log.i('Pok3r keyboard plugged in; laptop presumably docked.')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile('pok3r')
    toggleWifi('off')
    selectAudioOutput('"Audioengine D1"')
    selectAudioInput('"Logitech Webcam C930e"')
  end)
end

undockedAction = function()
  log.i('Pok3r keyboard unplugged; laptop presumably undocked.')
  hs.timer.doAfter(1, function ()
    selectKarabinerProfile('internal')
    toggleWifi('on')
    selectAudioOutput('"Built-in Output"')
    selectAudioInput('"Built-in Microphone"')
  end)
end

handleEvent = (function(event)
  -- Safe assumption that connecting my keyboard means we are "docked", so do
  -- things based on being "docked".
  if event.vendorID == dockedDevice.vendorID and event.productID == dockedDevice.productID then
    if event.eventType == 'added' then
      dockedAction()
    else
      undockedAction()
    end
    -- hs.reload()
  end
end)

selectKarabinerProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )
  log.i('Selecting Karabiner profile: %s', profile)
end)

toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )
  log.i('Turning wifi %s', state)
end)

selectAudioOutput = (function(output)
  hs.execute(
    'SwitchAudioSource -t output -s ' ..
    output
  )
  log.i('Switching to audio output: %s', output)
end)

selectAudioInput = (function(input)
  hs.execute(
    'SwitchAudioSource -t input -s ' ..
    input
  )
  log.i('Switching to audio input: %s', input)
end)

return {
  init = (function()
    utils.log.df('[laptop-docking-mode] - creating laptop-docking-mode watchers')
    watcher = hs.usb.watcher.new(handleEvent):start()

--     for _, device in pairs(hs.usb.attachedDevices()) do
--       if device.vendorID == dockedDevice.vendorID and device.productID == dockedDevice.productID then
--         -- return dockedAction()
--       else
--         -- return undockedAction()
--       end
--     end
  end),
  teardown = (function()
    utils.log.df('[laptop-docking-mode] - tearing down laptop-docking-mode watchers')
    watcher:stop()
    watcher = nil
  end)
}
