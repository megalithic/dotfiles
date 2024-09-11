local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.name = "watcher.files"
obj.watcher = nil

function obj:start()
  if obj.watcher then return end

  obj.watcher = hs.pathwatcher.new(hs.configdir, function() hs.timer.doAfter(0.25, hs.reload) end)
  obj.watcher:start()

  return self
end

function obj:stop()
  if not obj.watcher then return end

  obj.watcher:stop()
  obj.watcher = nil

  return self
end

return obj
