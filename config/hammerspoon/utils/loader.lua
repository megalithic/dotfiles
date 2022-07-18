-- Loader to mimic Spoon behaviour
local FS = require("hs.fs")

local obj = {}

obj.__index = obj

function obj.load(loadTarget, opts)
  if loadTarget == nil then return end
  opts = opts or {}

  local shouldUnload = false

  if opts["unload"] then shouldUnload = true end

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
            require(string.format("%s%s", loadTarget, file)):stop(opts)
          else
            require(string.format("%s%s", loadTarget, file)):init(opts)
          end
        end
      else
        -- we should only load the `init.lua` file within this dir..
        if string.sub(file, -3) == "lua" then
          local modName = string.sub(file, 1, -5)
          if modName == "init" then
            if shouldUnload then
              require(string.sub(loadTarget, 1, -2)):stop(opts)
            else
              require(string.sub(loadTarget, 1, -2)):init(opts)
            end
          end
        end
      end
    end
  else
    -- we're just a file in the root hammerspoon config dir..
    for file in FS.dir("./") do
      if string.sub(file, -3) == "lua" then
        local modName = string.sub(file, 1, -5)
        if loadTarget == modName then
          if shouldUnload then
            require(loadTarget):stop(opts)
          else
            require(loadTarget):init(opts)
          end
        end
      end
    end
  end
end

function obj.unload(loadTarget) obj.load(loadTarget, { unload = true }) end

return obj
