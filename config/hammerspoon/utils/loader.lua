-- Loader to mimic Spoon-like behaviour
local FS = require("hs.fs")

local obj = {}

obj.__index = obj

local function init(loadTarget, opts)
  opts = opts or {}
  local shouldLazyLoad = opts["opt"] ~= nil and opts["opt"]
  local ok, mod = pcall(require, loadTarget)

  if not ok then
    P(fmt("[ERROR] %s -> %s", loadTarget, mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    local loaded = mod

    if type(mod.init) == "function" and mega.__loaded_modules[loadTarget] ~= loaded then
      -- NOTE:
      -- this requires modules to return `self` on :init() to keep track of this;
      -- non-conforming modules just return themselves on load if there is no
      -- :init() fn.
      loaded = mod:init(opts)

      -- store our cache of loaded modules so we don't re-init a bajillion times
      mega.__loaded_modules[loadTarget] = loaded
    end

    if type(mod.start) == "function" and not shouldLazyLoad then loaded = mod:start() end

    return loaded
  end
end

local function stop(loadTarget, opts)
  opts = opts or {}
  local ok, mod = pcall(require, loadTarget)
  if not ok then
    P(fmt("[ERROR] %s -> %s", loadTarget, mod))
    return
  end

  if ok and mod ~= nil and type(mod) == "table" then
    if type(mod.stop) == "function" then mod:stop() end
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
    for file in FS.dir(string.format("./%s", loadTarget)) do
      if loadAllChildren then
        -- we should load all the individual files in this dir..
        if string.sub(file, -3) == "lua" then
          if shouldUnload then
            stop(string.format("%s%s", loadTarget, file))
          else
            return init(string.sub(string.format("%s%s", loadTarget, file), 1, -2), opts)
          end
        end
      else
        -- we should only load the `init.lua` file within this dir..
        if string.sub(file, -3) == "lua" then
          local modName = string.sub(file, 1, -5)
          if modName == "init" then
            if shouldUnload then
              stop(string.sub(loadTarget, 1, -2))
            else
              return init(string.sub(loadTarget, 1, -2), opts)
            end
          end
        end
      end
    end
  else
    -- we're just a file to be required..
    if shouldUnload then
      stop(loadTarget)
    else
      return init(loadTarget, opts)
    end
  end
end

function obj.unload(loadTarget) obj.load(loadTarget, { unload = true }) end

return obj
