local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.watchers = {}
obj.watched = {}

function obj:init(opts)
  opts = opts or {}
  P(fmt("watchers:init(%s) loaded.", hs.inspect(opts)))

  obj.watchers = Settings.get("_mega_config").watchers

  return obj
end

function obj:start()
  P(fmt("watchers:start() executed."))
  -- start each of our watchers
  -- TODO: add ability for a watcher to refuse auto-starting
  FNUtils.each(obj.watchers, function(modTarget)
    local ok, mod = pcall(require, "lib.watchers." .. modTarget)
    if ok and type(mod) == "table" then
      obj.watched[modTarget] = mod
      if type(mod.start) == "function" then obj.watched[modTarget]:start() end
    end
  end)

  return obj
end

function obj:stop()
  P(fmt("watchers:stop() executed."))
  FNUtils.each(obj.watched, function(mod) mod:stop() end)
end

return obj
