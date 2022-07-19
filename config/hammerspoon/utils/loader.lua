-- Loader to mimic Spoon-like behaviour
local FS = require("hs.fs")

local obj = {}

obj.__index = obj

function obj.init(loadTarget, opts)
  opts = opts or {}
  local shouldLazyLoad = opts["opt"] ~= nil and opts["opt"] or false
  local shouldBustCache = opts["bust"] ~= nil and opts["bust"] or false

  local ok, mod = pcall(require, loadTarget)
  if not ok then
    error(fmt("[ERROR.init] %s -> %s", loadTarget, mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    local loaded = nil

    if
      type(mod.init) == "function"
      and (
        mega.__loaded_modules[loadTarget] == nil
        or mega.__loaded_modules[loadTarget].mod ~= loaded and not shouldBustCache
      )
    then
      info(fmt("[INIT] %s (bust: %s, lazy: %s)", loadTarget, shouldBustCache, shouldLazyLoad))

      -- NOTE:
      -- this requires modules to return `self` on :init() to keep track of this;
      -- non-conforming modules just return themselves on load if there is no
      -- :init() fn.
      loaded = mod:init(opts)

      -- store our cache of loaded modules so we don't re-init a bajillion times
      mega.__loaded_modules[loadTarget] = { mod = loaded, lazy = shouldLazyLoad }
    end

    -- should we auto-run :start() for this module?
    if type(mod.start) == "function" and not shouldLazyLoad then
      success(fmt("[AUTOSTART] %s (bust: %s, lazy: %s)", loadTarget, shouldBustCache, shouldLazyLoad))

      loaded = obj.start(loadTarget)
    end

    if loaded == nil then
      warn(fmt("[WARN.init] %s not loaded (bust: %s, lazy: %s)", loadTarget, shouldBustCache, shouldLazyLoad))
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
    error(fmt("[ERROR.start] %s -> %s", loadTarget, mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    if type(mod.start) == "function" then
      success(fmt("[START] %s (%s)", loadTarget, I(opts)))
      return mod:start()
    end
  end
end

function obj.stop(loadTarget, opts)
  opts = opts or {}
  local ok, mod = pcall(require, loadTarget)
  if not ok then
    error(fmt("[ERROR.stop] %s -> %s", loadTarget, mod))
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
