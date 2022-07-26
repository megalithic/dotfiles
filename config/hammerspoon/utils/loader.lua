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

local dbg = function(msg)
  if obj.debug then
    return _G.dbg(msg)
  else
    return ""
  end
end

function obj.load(loadTarget, opts)
  if loadTarget == nil then return end

  opts = opts or {}

  local ok, mod = pcall(require, loadTarget)

  dbg(fmt(":: [load] %s -- ok: %s, mod: %s", loadTarget, ok, I(mod, true)))

  if not ok or mod == nil then
    error(fmt("[ERROR] %s (%s) -> %s", loadTarget, I(opts), mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    local target = mod.name or loadTarget
    local id = opts.id or nil

    if opts["unload"] then
      if type(mod.stop) == "function" then
        info(fmt("[STOP] %s (%s)", target, I(opts, false)))
        return mod:stop(opts)
      end
    else
      if type(mod.init) == "function" then
        local loaded = mod:init(opts) or mod
        local cache_key = id and fmt("%s_%s", loadTarget, id) or fmt("%s", loadTarget)
        local cache_mod = loaded

        mega.__loaded_modules[cache_key] = { name = target, id = id, mod = cache_mod }

        if id then mega.__loaded_modules[cache_key]["id"] = id end

        dbg(fmt("[cache] cache_key: %s, cached_mod: %s", cache_key, mega.__loaded_modules[cache_key]))

        local tag = mega.__loaded_modules[cache_key]["id"] and fmt("%s_%s", target, id) or fmt("%s", target)
        info(fmt("[INIT] %s (%s)", tag, I(opts, false)))

        return loaded
      else
        note(fmt("[INIT] %s (%s) no init/1; returning uncached module", target, I(opts, false)))
        return mod
      end
    end
  end
end

function obj.unload(loadTarget, id)
  if id then
    obj.load(loadTarget, { unload = true, id = id })
  else
    obj.load(loadTarget, { unload = true })
  end
end

return obj
