--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- 
-- Note: Apple has changed the way Safari stores bookmarks and this plugin no longer works on recent macOS releases.
---@class spoon.Seal.plugins.safari_bookmarks
local M = {}
spoon.Seal.plugins.safari_bookmarks = M

-- If `true` (default), bookmarks are always opened with Safari, otherwise they are opened with the default application using the `/usr/bin/open` command.
M.always_open_with_safari = nil

