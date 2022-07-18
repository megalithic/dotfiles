local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj

function obj:start() print(string.format("dock:start() executed.")) end

function obj:stop() print(string.format("dock:stop() executed.")) end

return obj
--
-- local log = hs.logger.new("[dock]", "info")

-- local cache = {}
-- local M = { cache = cache }

-- -- TODO: toggle wifi when on ethernet; https://github.com/mje-nz/dotfiles/blob/master/osx-only/hammerspoon.symlink/autoconnect-thunderbolt-ethernet.lua
-- M.toggle_wifi = function(state)
--   hs.execute("networksetup -setairportpower airport " .. state, true)

--   log.df("toggling wifi -> %s", state)
-- end

-- M.set_karabiner_profile = function(state)
--   hs.execute(
--     "/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli " .. "--select-profile " .. state,
--     true
--   )

--   log.df("toggling karabiner-elements profile -> %s", state)
-- end

-- M.set_kitty_config = function(state)
--   hs.execute("kitty @ --to unix:/tmp/kitty set-font-size " .. state, true)

--   log.f("toggling kitty font-size -> %s", state)
-- end

-- M.set_audio_output = function(state)
--   local task = hs.task.new(
--     "/usr/local/bin/SwitchAudioSource",
--     function() end, -- Fake callback
--     function(task, stdOut, stdErr)
--       local continue = task ~= string.format("output audio device set to \"%s\"", state)

--       log.df(
--         "toggling audio input::streaming -> %s [%s, %s, %s, continuing? %s] -> %s",
--         state,
--         task,
--         stdOut,
--         stdErr,
--         continue,
--         string.format("output audio device set to \"%s\"", state)
--       )

--       return continue
--     end,
--     { "-t", "output", "-s", state }
--   )
--   task:start()
-- end

-- M.set_audio_input = function(state)
--   local task = hs.task.new(
--     "/usr/local/bin/SwitchAudioSource",
--     function() end, -- Fake callback
--     function(task, stdOut, stdErr)
--       local continue = task ~= string.format("input audio device set to \"%s\"", state)

--       log.df(
--         "toggling audio input::streaming -> %s [%s, %s, %s, continuing? %s] -> %s",
--         state,
--         task,
--         stdOut,
--         stdErr,
--         continue,
--         string.format("input audio device set to \"%s\"", state)
--       )

--       return continue
--     end,
--     { "-t", "input", "-s", state }
--   )
--   task:start()
-- end

-- M.toggle = function(docking_config)
--   M.toggle_wifi(docking_config.wifi)
--   M.set_karabiner_profile(docking_config.profile)
--   M.set_kitty_config(docking_config.fontSize)
--   M.set_audio_output(docking_config.output)
--   M.set_audio_input(docking_config.input)
-- end

-- local docked_watcher = function(_, _, _, _, is_docked)
--   if is_docked then
--     log.f("toggling::docked..")
--     M.toggle(Config.docking.docked)
--   else
--     log.f("toggling::undocked..")
--     M.toggle(Config.docking.undocked)
--   end
-- end

-- function M:start() cache.watcher = hs.watchable.watch("status.isDocked", docked_watcher) end

-- function M:stop() cache.watcher:release() end

-- return M