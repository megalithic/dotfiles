local log = hs.logger.new('[controlplane.dock]', 'debug')

local cache = {}
local module = { cache = cache }

local setLayoutForAll = require('utils.wm').setLayoutForAll

local selectKarabinerProfile = (function(profile)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    profile
  )

  log.i('Switching to keyboard profile', profile)
end)

local toggleWifi = (function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state
  )

  log.i('Switching wifi state to', state)
end)

local selectAudioOutput = (function(output)
  hs.execute(
    'SwitchAudioSource -t output -s ' ..
    output
  )
  log.i('Switching to audio output', output)
end)

local selectAudioInput = (function(input)
  hs.execute(
    'SwitchAudioSource -t input -s ' ..
    input
  )
  log.i('Switching to audio input', input)
end)

local setKittyConfig = (function(c)
    log.i('Setting kitty font-size to', c.fontSize)
    hs.execute('kitty @ --to unix:/tmp/kitty set-font-size ' .. c.fontSize, true)
    -- hs.execute('kitty @ set-font-size ' .. c.fontSize)
end)

-- FIXME: do is till need this for keyboard switching?
-- local enableFastKeypress = (function(state)
--   hs.execute('defaults write NSGlobalDomain KeyRepeat -int 1')
--   -- https://superuser.com/questions/40061/what-is-the-mac-os-x-terminal-command-to-log-out-the-current-user
-- end)

-- local disableFastKeypress = (function(state)
--   hs.execute('defaults write NSGlobalDomain KeyRepeat -int 0')
--   -- https://superuser.com/questions/40061/what-is-the-mac-os-x-terminal-command-to-log-out-the-current-user
-- end)

local dockedAction = function()
  local dockedConfig =  config.docking.docked
  log.i('Executing docked actions..')

  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(dockedConfig.profile)
    toggleWifi(dockedConfig.wifi)

    hs.timer.doAfter(2, function ()
      selectAudioOutput(dockedConfig.output)
      selectAudioInput(dockedConfig.input)
      setKittyConfig(dockedConfig)
      setLayoutForAll()
    end)
  end)
end

local undockedAction = function()
  local undockedConfig =  config.docking.undocked

  log.i('Executing undocked actions..')

  hs.timer.doAfter(1, function ()
    selectKarabinerProfile(undockedConfig.profile)
    toggleWifi(undockedConfig.wifi)

    hs.timer.doAfter(2, function ()
      selectAudioOutput(undockedConfig.output)
      selectAudioInput(undockedConfig.input)
      setKittyConfig(undockedConfig)
      setLayoutForAll()
    end)
  end)
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
