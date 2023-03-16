--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Visual, searchable pasteboard (ie clipboard) history
---@class spoon.Seal.plugins.pasteboard
local M = {}
spoon.Seal.plugins.pasteboard = M

-- 
-- The number of history items to keep. Defaults to 50
M.historySize = nil

-- 
-- A boolean, true if Seal should automatically load/save clipboard history. Defaults to true
M.saveHistory = nil

