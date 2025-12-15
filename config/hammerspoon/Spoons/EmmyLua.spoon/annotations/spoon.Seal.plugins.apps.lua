--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- A plugin to add launchable apps/scripts, making Seal act as a launch bar
---@class spoon.Seal.plugins.apps
local M = {}
spoon.Seal.plugins.apps = M

-- Table containing the paths to search for launchable items
--
-- Notes:
--  * If you change this, you will need to call `spoon.Seal.plugins.apps:restart()` to force Spotlight to search for new items.
M.appSearchPaths = nil

-- Restarts the Spotlight app searcher
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function M:restart() end

-- Starts the Spotlight app searcher
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
--
-- Notes:
--  * This is called automatically when the plugin is loaded
function M:start() end

-- Stops the Spotlight app searcher
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function M:stop() end

