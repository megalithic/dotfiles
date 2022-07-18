local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj

function obj:start() print(string.format("audio:start() executed.")) end

function obj:stop() print(string.format("audio:stop() executed.")) end

return obj
