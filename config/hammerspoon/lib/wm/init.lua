local Window = require("hs.window")
local Screen = require("hs.screen")
local Geometry = require("hs.geometry")
local Spoons = require("hs.spoons")
local load = require("utils.loader").load

local obj = {}

obj.__index = obj
obj.original_author = "roeybiran <roeybiran@icloud.com>"

function obj:init(opts)
  opts = opts or {}
  print(string.format("wm:init(opts: %s) loaded.", hs.inspect(opts)))
  load("lib/wm/snap", opts)
end
function obj:start() print(string.format("wm:start() executed.")) end
function obj:stop() print(string.format("wm:stop() executed.")) end

return obj
