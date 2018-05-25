--
-- Until Karabiner-Elements gets the ability to target specific devices, this
-- module does auto-switching of profiles based on what's plugged in.
--

local events = require 'pubsub'
local log = require 'log'

local handleEvent = nil
local reload = nil
local selectProfile = nil
local watcher = nil

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
      end)
    else
      log.i('Pok3r keyboard unplugged; laptop presumably undocked.')
      hs.timer.doAfter(1, function ()
        selectProfile('internal')
        toggleWifi('on')
        selectAudioOutput('"Built-in Output"')
      end)
    end
  end
end)

reload = (function()
  watcher:stop()
  watcher = nil
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

events.subscribe('reload', reload)

return {
  init = (function()
    watcher = hs.usb.watcher.new(handleEvent)
    watcher:start()
  end),
}
