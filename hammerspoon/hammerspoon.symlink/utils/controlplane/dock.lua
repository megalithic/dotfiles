local log = hs.logger.new('[dock]', 'info')

local cache = {}
local M = { cache = cache }

local set_karabiner_profile = function(state)
  hs.execute(
    '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli ' ..
    '--select-profile ' ..
    state,
    true
  )

  log.f('toggling karabiner-elements profile -> %s', state)
end

-- TODO: toggle wifi when on ethernet; https://github.com/mje-nz/dotfiles/blob/master/osx-only/hammerspoon.symlink/autoconnect-thunderbolt-ethernet.lua
local toggle_wifi = function(state)
  hs.execute(
    'networksetup -setairportpower airport ' ..
    state,
    true
  )

  log.f('toggling wifi -> %s', state)
end

local set_audio_output = function(state)
  local output, status, type, rc = hs.execute(
    'SwitchAudioSource -t output -s "' .. hs.inspect(state) .. '"', true)

  if status then
    log.f('toggling audio output::success -> %s', hs.inspect(state))
  else
    log.f('toggling audio output::failed -> %s [%s, %s, %s]', hs.inspect(state), output, status, type, rc)
  end
end

local set_audio_input = function(state)
  local output, status, type, rc = hs.execute(
    'SwitchAudioSource -t input -s "' .. hs.inspect(state) .. '"', true)

  if status then
    log.f('toggling audio input::success -> %s', hs.inspect(state))
  else
    log.f('toggling audio input::failed -> %s [%s, %s, %s]', hs.inspect(state), output, status, type, rc)
  end
end

local set_kitty_config = function(state)
  hs.execute('kitty @ --to unix:/tmp/kitty set-font-size ' .. state, true)

  log.f('toggling kitty font-size -> %s', state)
end

local toggle = function(dockingConfig)
  toggle_wifi(dockingConfig.wifi)
  set_karabiner_profile(dockingConfig.profile)
  set_kitty_config(dockingConfig.fontSize)
  set_audio_output(dockingConfig.output)
  set_audio_input(dockingConfig.input)
end

local dockedWatcher = function(_, _, _, _, isDocked)
  if isDocked then
    log.f('toggling::docked..')
    toggle(config.docking.docked)
  else
    log.f('toggling::undocked..')
    toggle(config.docking.undocked)
  end
end

M.start = function()
  cache.watcher = hs.watchable.watch('status.isDocked', dockedWatcher)
end

M.stop = function()
  cache.watcher:release()
end

return M
