local fnutils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.name = "watchers"
obj.watchers = {}
obj.watched = {}

function obj:init(opts)
  opts = opts or {}
  if opts.watchers ~= nil then obj.watchers = opts.watchers end

  return self
end

function obj:start()
  -- obj.watchers = obj.watchers or watchers

  fnutils.each(obj.watchers, function(modTarget)
    local modPath = "lib.watchers." .. modTarget
    local mod = L.load(modPath):start()

    obj.watched[modPath] = mod
  end)

  return self
end

function obj:stop()
  if obj.watchers == nil or obj.watched == nil then return end

  fnutils.each(obj.watched, function(mod) L.unload("lib." .. mod.name:gsub("watcher", "watchers")) end)
  obj.watchers = {}
  obj.watched = {}

  return self
end

return obj
