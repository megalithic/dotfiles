local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.hammerspoon"
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
  obj.modal:enter()

  note(fmt("[START]: %s", I(opts)))

  return self
end

function obj:stop(opts)
  opts = opts or {}
  obj.modal:exit()
  note(fmt("[STOP]: %s", I(self)))
  return self
end

return obj
