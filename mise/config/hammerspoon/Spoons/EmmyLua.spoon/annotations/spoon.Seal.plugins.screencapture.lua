--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- A plugin to capture the screen in various ways
---@class spoon.Seal.plugins.screencapture
local M = {}
spoon.Seal.plugins.screencapture = M

-- Whether or not to show the screen capture UI in macOS 10.14 or later
M.showPostUI = nil

