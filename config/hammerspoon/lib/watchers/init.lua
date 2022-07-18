local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")

local obj = {}

obj.__index = obj
obj.watchers = {}
obj.watched = {}

function obj:init(opts)
  opts = opts or {}
  print(string.format("watchers:init(opts: %s) loaded.", hs.inspect(opts)))

  obj.watchers = Settings.get("_mega_config").watchers

  if not opts["lazy"] then obj:start() end
end

function obj:start()
  FNUtils.each(obj.watchers, function(modTarget)
    local ok, mod = pcall(require, "lib.watchers." .. modTarget)
    if ok and type(mod) == "table" then
      obj.watched[modTarget] = mod
      if type(mod.start) == "function" then obj.watched[modTarget]:start() end
    end
  end)
end

function obj:stop()
  FNUtils.each(obj.watched, function(mod) mod:stop() end)
end

return obj
