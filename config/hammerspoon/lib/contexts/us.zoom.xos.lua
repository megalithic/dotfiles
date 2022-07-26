local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.zoom"
obj.debug = true

obj.modal = nil
obj.actions = {}

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

function obj:start(opts)
  opts = opts or {}

  _appObj = opts["appObj"]
  obj.modal:enter()

  success(fmt("[%s]: %s", obj.name, I(opts)))

  return self
end

function obj:stop()
  obj.modal:exit()
  return self
end

return obj
