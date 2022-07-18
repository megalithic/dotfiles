local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj

function obj:start() print(string.format("wifi:start() executed.")) end

function obj:stop() print(string.format("wifi:stop() executed.")) end
