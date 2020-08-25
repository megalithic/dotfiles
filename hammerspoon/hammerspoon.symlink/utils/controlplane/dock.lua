local log = hs.logger.new('[dock]', 'debug')

local cache = {}
local module = { cache = cache }

local selectKarabinerProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )

  log.i('Switching to keyboard profile', profile)
end)

-- TODO: toggle wifi when on ethernet; https://github.com/mje-nz/dotfiles/blob/master/osx-only/hammerspoon.symlink/autoconnect-thunderbolt-ethernet.lua
local toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )

  log.i('Switching wifi state to', state)
end)

local selectAudioOutput = (function(outputDevice)
  -- hs.execute(
  --   'SwitchAudioSource -t output -s ' ..
  --   outputDevice
  -- )
  -- log.i('Switching to audio output', outputDevice)


  -- TODO: wait until the devices in question are available; then switch: https://github.com/mje-nz/dotfiles/blob/master/osx-only/hammerspoon.symlink/autoconnect-usb-audio.lua
  hs.timer.waitUntil(
    function()
      -- Wait until the USB audio output is ready
      local output = hs.audiodevice.findOutputByName(outputDevice)

      return output ~= nil
    end,
    function ()
      -- Switch to the USB audio output
      local success = hs.audiodevice.findOutputByName(outputDevice):setDefaultOutputDevice()

      if success then
        log.i('Switching to audio output', outputDevice)
        hs.notify.new({title='Hammerspoon', informativeText='Switching to USB audio output'}):send()
      else
        log.w('Could not switch the audio output device..')
      end
    end,
    -- Run check every 200ms
    0.2
    )
end)

local selectAudioInput = (function(inputDevice)
  -- hs.execute(
  --   'SwitchAudioSource -t input -s ' ..
  --   inputDevice
  -- )
  -- log.i('Switching to audio input', inputDevice)

  -- TODO: wait until the devices in question are available; then switch: https://github.com/mje-nz/dotfiles/blob/master/osx-only/hammerspoon.symlink/autoconnect-usb-audio.lua
  hs.timer.waitUntil(
    function()
      -- Wait until the USB audio input is ready
      local input = hs.audiodevice.findInputByName(inputDevice)

      return input ~= nil
    end,
    function ()
      -- Switch to the USB audio input
      local success = hs.audiodevice.findInputByName(inputDevice):setDefaultOutputDevice()

      if success then
        log.i('Switching to audio output', inputDevice)
        hs.notify.new({title='Hammerspoon', informativeText='Switching to USB audio input'}):send()
      else
        log.w('Could not switch the audio input device..')
      end
    end,
    -- Run check every 200ms
    0.2
    )
end)

local setKittyConfig = (function(c)
    log.i('Setting kitty font-size to', c.fontSize)
    hs.execute('kitty @ --to unix:/tmp/kitty set-font-size ' .. c.fontSize, true)
    -- hs.execute('kitty @ set-font-size ' .. c.fontSize)
end)

local dockedAction = function()
  local dockedConfig =  config.docking.docked
  log.i('Executing docked actions..')

  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(dockedConfig.profile)
    toggleWifi(dockedConfig.wifi)
  end)

  selectAudioOutput(dockedConfig.output)
  selectAudioInput(dockedConfig.input)
  setKittyConfig(dockedConfig)
end

local undockedAction = function()
  local undockedConfig =  config.docking.undocked

  log.i('Executing undocked actions..')

  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(undockedConfig.profile)
    toggleWifi(undockedConfig.wifi)
  end)

  selectAudioOutput(undockedConfig.output)
  selectAudioInput(undockedConfig.input)
  setKittyConfig(undockedConfig)
end

local dockedWatcher = function(_, _, _, _, isDocked)
  if isDocked then
    dockedAction()
  else
    undockedAction()
  end
end

module.start = function()
  cache.watcher = hs.watchable.watch('status.isDocked', dockedWatcher)
end

module.stop = function()
  cache.watcher:release()
end

return module
