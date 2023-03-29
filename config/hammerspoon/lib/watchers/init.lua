local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.name = "watchers"
obj.watchers = {}
obj.watched = {}

function obj:init(opts)
  opts = opts or {}

obj.watchers = C.watchers

  return self
end

function obj:start()
  -- start each of our watchers
  -- TODO: add ability for a watcher to refuse auto-starting
  FNUtils.each(obj.watchers, function(modTarget)
    local modPath = "lib.watchers." .. modTarget
    local mod = L.load(modPath):start()

    obj.watched[modPath] = mod
  end)

  return self
end

function obj:stop()
  FNUtils.each(obj.watched, function(mod) L.unload("lib." .. mod.name:gsub("watcher", "watchers")) end)
  obj.watchers = {}
  obj.watched = {}

  return self
end

return obj
