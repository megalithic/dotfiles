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
  if obj.debug then return _G.dbg(msg) end
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
    local id = opts.id or nil
    local bust = opts.bust or false
    local cache_key = id and fmt("%s_%s", loadTarget, id) or fmt("%s", loadTarget)
    local silent = opts["silent"] or false

    if silent then
      local function note() end
      local function dbg() end
      local function info() end
    end

    if opts["raw"] then
      note(fmt("[REQ] %s (%s)", target, I(opts, false)))
      return mod
    elseif opts["unload"] then
      if type(mod.stop) == "function" then
        if mega.__loaded_modules[cache_key] then
          info(fmt("[STOP] %s (%s)", cache_key, I(opts, false)))
          return mega.__loaded_modules[cache_key].mod:stop()
        end
        info(fmt("[STOP] %s (%s)", loadTarget, I(opts, false)))
        return mod:stop(opts)
      end
    else
      if type(mod.init) == "function" then
        local loaded = mod

        if bust then
          if mega.__loaded_modules[cache_key]["mod"] then mega.__loaded_modules[cache_key] = nil end
          local tag = id and fmt("%s_%s", loadTarget, id) or fmt("%s", loadTarget)
          if not silent then note(fmt("[INIT] %s (%s)", tag, I(opts, false))) end
        else
          loaded = mod:init(opts)

          if mega.__loaded_modules[cache_key] then
            loaded = mega.__loaded_modules[cache_key]["mod"]
          else
            mega.__loaded_modules[cache_key] = { name = target, id = id, mod = loaded }
          end

          dbg(fmt("[cache] cache_key: %s, cached_mod: %s", cache_key, I(mega.__loaded_modules[cache_key]["mod"], true)))

          if id then mega.__loaded_modules[cache_key]["id"] = id end

          local tag = mega.__loaded_modules[cache_key]["id"] and fmt("%s_%s", loadTarget, id) or fmt("%s", loadTarget)
          info(fmt("[INIT] %s (%s)", tag, I(opts, false)))
        end

        return loaded
      else
        local tag = id and fmt("%s_%s", loadTarget, id) or fmt("%s", loadTarget)
        if not silent then note(fmt("[INIT] %s (%s)", tag, I(opts, false))) end

        return mod
      end
    end
  end
end

function obj.unload(loadTarget, id)
  if id then
    return obj.load(loadTarget, { unload = true, id = id })
  else
    return obj.load(loadTarget, { unload = true })
  end
end

function obj.req(loadTarget, id)
  if id then
    return obj.load(loadTarget, { raw = true, id = id })
  else
    return obj.load(loadTarget, { raw = true })
  end
end

return obj
