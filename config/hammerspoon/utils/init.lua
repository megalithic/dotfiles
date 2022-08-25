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
  local spoonpath = obj.scriptPath(3)
  for name, key in pairs(map) do
    if def[name] ~= nil then
      local keypath = spoonpath .. name
      if obj._keys[keypath] then obj._keys[keypath]:delete() end
      obj._keys[keypath] = hotkey.bindSpec(key, key["message"], def[name])
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

function obj.table_merge(t1, t2, opts)
  opts = opts or { strategy = "deep" }

  if opts.strategy == "deep" then
    -- # deep_merge:
    for k, v in pairs(t2) do
      if (type(v) == "table") and (type(t1[k] or false) == "table") then
        obj.table_merge(t1[k], t2[k])
      else
        t1[k] = v
      end
    end
  else
    -- # shallow_merge:
    for k, v in pairs(t2) do
      t1[k] = v
    end
  end

  return t1
end

function obj.deep_merge(...) obj.table_merge(..., { strategy = "deep" }) end

function obj.shallow_merge(...) obj.table_merge(..., { strategy = "shallow" }) end

function obj.template(template, replacements) return string.gsub(template, "{(.-)}", replacements) end

function obj.tlen(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end
  return len
end

-- WIP: BROKE
function obj.tfn(t)
  local fnstr = table.remove(t, 1)
  -- THIS conversion doesn't do it..
  local fn = _G[fnstr]

  local args = t
  dbg(fmt("[TFN] (%s, %s, %s, %s)", t, fnstr, fn, args))

  if not fn and not type(fn) == "function" then return end

  if args then
    fn(args)
  else
    fn()
  end
end

function obj.eventName(evtId)
  -- REF: https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/application/libapplication_watcher.m#L29
  local events = {
    [0] = "launching",
    [1] = "launched",
    [2] = "terminated",
    [3] = "hidden",
    [4] = "unhidden",
    [5] = "activated",
    [6] = "deactivated",
  }
  local event = events[0]

  for i, value in ipairs(events) do
    if evtId == i then
      event = value
      break
    end
  end

  return event
end

function obj.truncate(str, width, at_tail)
  local ellipsis = "…"
  local n_ellipsis = #ellipsis

  -- HT: https://github.com/lunarmodules/Penlight/blob/master/lua/pl/stringx.lua#L771-L796
  --- Return a shortened version of a string.
  -- Fits string within w characters. Removed characters are marked with ellipsis.
  -- @string s the string
  -- @int w the maxinum size allowed
  -- @bool tail true if we want to show the end of the string (head otherwise)
  -- @usage ('1234567890'):shorten(8) == '12345...'
  -- @usage ('1234567890'):shorten(8, true) == '...67890'
  -- @usage ('1234567890'):shorten(20) == '1234567890'
  local function shorten(s, w, tail)
    if #s > w then
      if w < n_ellipsis then return ellipsis:sub(1, w) end
      if tail then
        local i = #s - w + 1 + n_ellipsis
        return ellipsis .. s:sub(i)
      else
        return s:sub(1, w - n_ellipsis) .. ellipsis
      end
    end
    return s
  end

  return shorten(str, width, at_tail)
end

return obj
