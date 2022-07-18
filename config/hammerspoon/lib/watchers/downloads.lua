local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj

function obj:start() print(string.format("downloads:start() executed.")) end

function obj:stop() print(string.format("downloads:stop() executed.")) end

return obj
