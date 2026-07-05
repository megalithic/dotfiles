--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Implements push-to-talk and push-to-mute functionality with `fn` key.
-- I implemented this after reading Gitlab remote handbook https://about.gitlab.com/handbook/communication/ about Shush utility.
--
-- My workflow:
--
-- When Zoom starts, PushToTalk automatically changes mic state from `default`
-- to `push-to-talk`, so I need to press `fn` key to unmute myself and speak.
-- If I need to actively chat in group meeting or it's one-on-one meeting,
-- I'm switching to `push-to-mute` state, so mic will be unmute by default and `fn` key mutes it.
--
-- PushToTalk has menubar with colorful icons so you can easily see current mic state.
--
-- Sample config: `spoon.SpoonInstall:andUse("PushToTalk", {start = true, config = { app_switcher = { ['zoom.us'] = 'push-to-talk' }}})`
-- and separate keybinding to toggle states with lambda function `function() spoon.PushToTalk.toggleStates({'push-to-talk', 'release-to-talk'}) end`
--
-- Check out my config: https://github.com/skrypka/hammerspoon_config/blob/master/init.lua
---@class spoon.PushToTalk
local M = {}
spoon.PushToTalk = M

-- Takes mapping from application name to mic state.
-- For example this `{ ['zoom.us'] = 'push-to-talk' }` will switch mic to `push-to-talk` state when Zoom app starts.
M.app_switcher = nil

-- Initial setup. It's empty currently
function M:init() end

-- Starts menu and key watcher
function M:init() end

-- Stops PushToTalk
function M:stop() end

-- Cycle states in order
--
-- Parameters:
--  * states - A array of states to toggle. For example: `{'push-to-talk', 'release-to-talk'}`
function M:toggleStates() end

