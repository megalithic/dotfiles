local log = require 'log'

handleEvent = (function(event)
  -- Safe assumption that connecting my keyboard means we are "docked", so do
  -- things based on being "docked".
  if event.vendorID == 1241 and event.productID == 321 then
    if event.eventType == 'added' then
      log.i('Pok3r keyboard plugged in; laptop presumably docked.')
      hs.timer.doAfter(1, function ()
        selectProfile('pok3r')
        toggleWifi('off')
        selectAudioOutput('"Audioengine D1"')
        hs.reload()
      end)
    else
      log.i('Pok3r keyboard unplugged; laptop presumably undocked.')
      hs.timer.doAfter(1, function ()
        selectProfile('internal')
        toggleWifi('on')
        selectAudioOutput('"Built-in Output"')
        hs.reload()
      end)
    end
  end
end)

selectProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )
end)

toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )
end)

selectAudioOutput = (function(output)
  hs.execute(
    'SwitchAudioSource -t output -s ' ..
    output
  )
end)

selectAudioInput = (function(input)
  hs.execute(
    'SwitchAudioSource -t input -s ' ..
    input
  )
end)

return {
  init = (function()
    utils.log.df('[laptop-docking-mode] - creating laptop-docking-mode watchers')

    watcher = hs.usb.watcher.new(handleEvent):start()
  end),
  teardown = (function()
    utils.log.df('[laptop-docking-mode] - tearing down laptop-docking-mode watchers')

    watcher:stop()
    watcher = nil
  end)
}
