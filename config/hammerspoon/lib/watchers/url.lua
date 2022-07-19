local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.name = "watcher.url"

function obj:start() return self end

function obj:stop() return self end

return obj
