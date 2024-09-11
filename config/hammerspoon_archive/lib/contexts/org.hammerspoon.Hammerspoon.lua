local Settings = require("hs.settings")
local mods = C.keys.mods

local obj = {}
local _appObj = nil
obj.__index = obj
obj.name = "context.hammerspoon"
obj.debug = true

obj.modal = true
obj.actions = {
  reload = {
    action = function() hs.reload() end,
    hotkey = { mods.Casc, "r" },
  },
}

local function info(...)
  if obj.debug then
    return _G.info(...)
  else
    return print("")
  end
end
local function dbg(...)
  if obj.debug then
    return _G.dbg(...)
  else
    return print("")
  end
end
local function note(...)
  if obj.debug then
    return _G.note(...)
  else
    return print("")
  end
end
local function success(...)
  if obj.debug then
    return _G.success(...)
  else
    return print("")
  end
end

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]

  if obj.modal then obj.modal:enter() end

  return self
end

function obj:stop(opts)
  opts = opts or {}

  if obj.modal then obj.modal:exit() end

  return self
end

return obj
