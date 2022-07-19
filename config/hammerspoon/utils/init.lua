-- Loader to mimic Spoon behaviour
local FS = require("hs.fs")
local hotkey = require("hs.hotkey")

local obj = {}

obj.__index = obj

--- utils.bindHotkeysToSpec(def, map) -> none
--- Function
--- Map a number of hotkeys according to a definition table
---
--- Parameters:
---  * def - table containing name-to-function definitions for the hotkeys supported by the Spoon. Each key is a hotkey name, and its value must be a function that will be called when the hotkey is invoked.
---  * map - table containing name-to-hotkey definitions and an optional message to be displayed via `hs.alert()` when the hotkey has been triggered, as supported by [bindHotkeys in the Spoon API](https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md#hotkeys). Not all the entries in `def` must be bound, but if any keys in `map` don't have a definition, an error will be produced.
---
--- Returns:
---  * None
function obj.bindHotkeysToSpec(def, map)
  local spoonpath = module.scriptPath(3)
  for name, key in pairs(map) do
    if def[name] ~= nil then
      local keypath = spoonpath .. name
      if module._keys[keypath] then module._keys[keypath]:delete() end
      module._keys[keypath] = hotkey.bindSpec(key, key["message"], def[name])
    else
      log.ef("Error: Hotkey requested for undefined action '%s'", name)
    end
  end
end

--- utils.scriptPath([n]) -> string
--- Function
--- Return path of the current spoon.
---
--- Parameters:
---  * n - (optional) stack level for which to get the path. Defaults to 2, which will return the path of the spoon which called `scriptPath()`
---
--- Returns:
---  * String with the path from where the calling code was loaded.
function obj.scriptPath(n)
  if n == nil then n = 2 end
  local str = debug.getinfo(n, "S").source:sub(2)
  return str:match("(.*/)")
end

--- utils.resourcePath(partial) -> string
--- Function
--- Return full path of an object within a spoon directory, given its partial path.
---
--- Parameters:
---  * partial - path of a file relative to the Spoon directory. For example `images/img1.png` will refer to a file within the `images` directory of the Spoon.
---
--- Returns:
---  * Absolute path of the file. Note: no existence or other checks are done on the path.
function obj.resourcePath(partial) return (obj.scriptPath(3) .. partial) end

--- obj.bundleIDForApp(app) -> bundleID
function obj.bundleIDForApp(app)
  return (
    hs.execute(
      [[mdls -name kMDItemCFBundleIdentifier -r "$(mdfind 'kMDItemKind==Application' | grep /]]
        .. app
        .. [[.app | head -1)"]]
    )
  )
end

return obj
