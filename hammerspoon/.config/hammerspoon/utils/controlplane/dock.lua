local log = hs.logger.new("[dock]", "info")

local cache = {}
local M = { cache = cache }

-- TODO: toggle wifi when on ethernet; https://github.com/mje-nz/dotfiles/blob/master/osx-only/hammerspoon.symlink/autoconnect-thunderbolt-ethernet.lua
local toggle_wifi = function(state)
  hs.execute("networksetup -setairportpower airport " .. state, true)

  log.df("toggling wifi -> %s", state)
end

local set_karabiner_profile = function(state)
  hs.execute(
    "/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli " .. "--select-profile " .. state,
    true
  )

  log.df("toggling karabiner-elements profile -> %s", state)
end

local set_kitty_config = function(state)
  hs.execute("kitty @ --to unix:/tmp/kitty set-font-size " .. state, true)

  log.df("toggling kitty font-size -> %s", state)
end

local set_audio_output = function(state)
  local task = hs.task.new(
    "/usr/local/bin/SwitchAudioSource",
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local continue = task ~= string.format('output audio device set to "%s"', state)

      log.df(
        "toggling audio input::streaming -> %s [%s, %s, %s, continuing? %s] -> %s",
        state,
        task,
        stdOut,
        stdErr,
        continue,
        string.format('output audio device set to "%s"', state)
      )

      return continue
    end,
    { "-t", "output", "-s", state }
  )
  task:start()
end

local set_audio_input = function(state)
  local task = hs.task.new(
    "/usr/local/bin/SwitchAudioSource",
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local continue = task ~= string.format('input audio device set to "%s"', state)

      log.df(
        "toggling audio input::streaming -> %s [%s, %s, %s, continuing? %s] -> %s",
        state,
        task,
        stdOut,
        stdErr,
        continue,
        string.format('input audio device set to "%s"', state)
      )

      return continue
    end,
    { "-t", "input", "-s", state }
  )
  task:start()
end

local toggle = function(docking_config)
  toggle_wifi(docking_config.wifi)
  set_karabiner_profile(docking_config.profile)
  set_kitty_config(docking_config.fontSize)
  set_audio_output(docking_config.output)
  set_audio_input(docking_config.input)
end

local docked_watcher = function(_, _, _, _, is_docked)
  if is_docked then
    log.f("toggling::docked..")
    toggle(Config.docking.docked)
  else
    log.f("toggling::undocked..")
    toggle(Config.docking.undocked)
  end
end

M.start = function()
  cache.watcher = hs.watchable.watch("status.isDocked", docked_watcher)
end

M.stop = function()
  cache.watcher:release()
end

return M
