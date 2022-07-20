-- Loader to mimic Spoon-like behaviour
local obj = {}

obj.__index = obj
obj.name = "loader"
obj.debug = false

local I = function(msg, debug)
  if not obj.debug then return "" end
  if debug then
    return hs.inspect(msg)
  else
    return tostring(msg)
  end
end

function obj.load(loadTarget, opts)
  if loadTarget == nil then return end

  opts = opts or {}

  local ok, mod = pcall(require, loadTarget)

  if not ok or mod == nil then
    error(fmt("[ERROR] %s (%s) -> %s", loadTarget, I(opts), mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    local target = mod.name or loadTarget

    if opts["unload"] then
      if type(mod.stop) == "function" then
        info(fmt("[STOP] %s (%s)", target, I(opts, false)))
        return mod:stop(opts)
      end
    else
      if type(mod.init) == "function" then
        info(fmt("[INIT] %s (%s)", target, I(opts, false)))
        return mod:init(opts)
      else
        return mod
      end
    end
  end
end

function obj.unload(loadTarget) obj.load(loadTarget, { unload = true }) end

return obj
