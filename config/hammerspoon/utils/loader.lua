-- Loader to mimic Spoon-like behaviour
local FS = require("hs.fs")

local obj = {}

obj.__index = obj
obj.name = "loader"

local I = function(msg, debug)
  if debug then
    return hs.inspect(msg)
  else
    return tostring(msg)
  end
end

function obj.init(loadTarget, opts)
  opts = opts or {}
  opts["opt"] = opts["opt"] ~= nil and opts["opt"] or false
  opts["bust"] = opts["bust"] ~= nil and opts["bust"] or false

  local shouldLazyLoad = opts["opt"]
  local shouldBustCache = opts["bust"]

  local ok, mod = pcall(require, loadTarget)
  if not ok then
    error(fmt("[ERROR.init] %s (%s) -> %s", loadTarget, I(opts), mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    local loaded = nil

    local target = mod.name or loadTarget
    dbg(fmt("%s should bust cache? %s", target, shouldBustCache))
    if mega.__loaded_modules[target] == nil or mega.__loaded_modules[target].mod ~= mod or shouldBustCache then
      -- not loaded, nor should bust the cache..
      if type(mod.init) == "function" then
        info(fmt("[INIT] %s (%s)", target, I(opts)))

        -- NOTE:
        -- this requires modules to return `self` on :init() to keep track of this;
        -- non-conforming modules just return themselves on load if there is no
        -- :init() fn.
        loaded = mod:init(opts)

        -- store our cache of loaded modules so we don't re-init a bajillion times
        mega.__loaded_modules[target] = { mod = loaded, opt = shouldLazyLoad, loadTarget = loadTarget }
      end
    elseif mega.__loaded_modules[target] ~= nil then
      -- is loaded or cache wasn't busted
      return mega.__loaded_modules[target].mod
    else
      -- something else; just return the module
      return mod
    end

    -- should we auto-run :start() for this module?
    if not shouldLazyLoad and (mega.__loaded_modules[target] and not mega.__loaded_modules[target]["opt"]) then
      success(fmt("[AUTOSTART] %s (%s)", target, I(opts)))
      loaded = obj.start(loadTarget, { log = false })
    end

    if loaded == nil then
      if mega.__loaded_modules[target] == nil then
        warn(fmt("[WARN.init] %s (%s) has no loaded/stored module", target, I(opts)))
      else
        note(fmt("[NOTE.init] %s (%s) skipping init", target, I(opts)))
      end
      return mod
    end

    return loaded
  end
end

function obj.load(loadTarget, opts)
  if loadTarget == nil then return end
  opts = opts or {}

  local shouldUnload = false
  if opts["unload"] ~= nil and opts["unload"] then shouldUnload = true end

  -- determine if we are a folder or file
  local isDirTarget = false
  if string.find(loadTarget, "/$") then isDirTarget = true end

  -- determine if we should load all individual files in the path
  local loadAllChildren = false
  if string.find(loadTarget, "*$") then loadAllChildren = true end

  if isDirTarget then
    -- we are a directory; begin looping..
    for file in FS.dir(fmt("./%s", loadTarget)) do
      if loadAllChildren then
        -- we should load all the individual files in this dir..
        if string.sub(file, -3) == "lua" then
          if shouldUnload then
            obj.stop(fmt("%s%s", loadTarget, file))
          else
            return obj.init(string.sub(fmt("%s%s", loadTarget, file), 1, -2), opts)
          end
        end
      else
        -- we should only load the `init.lua` file within this dir..
        if string.sub(file, -3) == "lua" then
          local modName = string.sub(file, 1, -5)
          if modName == "init" then
            if shouldUnload then
              obj.stop(string.sub(loadTarget, 1, -2))
            else
              return obj.init(string.sub(loadTarget, 1, -2), opts)
            end
          end
        end
      end
    end
  else
    -- we're just a file to be required..
    if shouldUnload then
      obj.stop(loadTarget)
    else
      return obj.init(loadTarget, opts)
    end
  end
end

function obj.unload(loadTarget) obj.load(loadTarget, { unload = true }) end

function obj.start(loadTarget, opts)
  opts = opts or {}
  local ok, mod = pcall(require, loadTarget)
  if not ok then
    error(fmt("[ERROR.start] %s (%s) -> %s", loadTarget, I(opts), mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    if type(mod.start) == "function" then
      if opts["log"] then success(fmt("[START] %s (%s)", loadTarget, I(opts))) end
      return mod:start()
    end
  end
end

function obj.stop(loadTarget, opts)
  opts = opts or {}
  local ok, mod = pcall(require, loadTarget)
  if not ok then
    error(fmt("[ERROR.stop] %s (%s) -> %s", loadTarget, I(opts), mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    if type(mod.stop) == "function" then
      info(fmt("[STOP] %s (%s)", loadTarget, I(opts)))
      return mod:stop()
    end
  end
end

return obj
