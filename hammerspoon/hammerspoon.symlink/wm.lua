-------------------------------------------------------------------------------
--/ window management /--
-------------------------------------------------------------------------------
-- originally thieved from https://github.com/wincent/wincent/blob/master/roles/dotfiles/files/.hammerspoon/init.lua
-- is now heavily modified from the original thievery

-- we basically just setup for our events and configuration to load up, so
-- `init` doesn't have to import a bunch of extra stuff it doesn't care about.

local utils = require 'utils'
utils.log.df('[wm] event; loading window management')

local wm = {}
wm.events = require 'events'
wm.config = require 'config'

return wm
