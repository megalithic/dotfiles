local obj = {}

function obj.template(template, vars) return string.gsub(template, "{(.-)}", vars) end

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

function obj.eventEnums(e)
  local a = hs.application.watcher

  if type(e) == "string" then return e end

  local enum_tbl = {
    [0] = { "launching", a.launching },
    [1] = { "launched", a.launched },
    [2] = { "terminated", a.terminated },
    [3] = { "hidden", a.hidden },
    [4] = { "unhidden", a.unhidden },
    [5] = { "activated", a.activated },
    [6] = { "deactivated", a.deactivated },
  }

  return table.unpack(enum_tbl[e])
end

return obj
