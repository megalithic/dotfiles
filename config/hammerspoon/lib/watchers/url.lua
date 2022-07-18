local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj

function obj:start() print(string.format("url:start() executed.")) end

function obj:stop() print(string.format("url:stop() executed.")) end

return obj
