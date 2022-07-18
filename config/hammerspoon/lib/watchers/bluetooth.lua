local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj

function obj:start() print(string.format("bluetooth:start() executed.")) end

function obj:stop() print(string.format("bluetooth:stop() executed.")) end

return obj
