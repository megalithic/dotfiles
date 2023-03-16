--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- A plugin to add file search capabilities, making Seal act as a spotlight file search
---@class spoon.Seal.plugins.filesearch
local M = {}
spoon.Seal.plugins.filesearch = M

-- Maximum time to wait before displaying the results
-- Defaults to 0.2s (200ms).
--
-- Notes:
--  * higher value might give you more results but will give a less snappy experience
M.displayResultsTimeout = nil

-- Table containing the paths to search for files
--
-- Notes:
--  * You will need to authorize hammerspoon to access the folders in this list in order for this to work.
M.fileSearchPaths = nil

-- Maximum number of results to display
M.maxResults = nil

