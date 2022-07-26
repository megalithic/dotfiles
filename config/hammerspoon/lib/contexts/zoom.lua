local obj = {}

obj.__index = obj
obj.name = "context.zoom"
obj.debug = true

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

function obj:init(opts)
  opts = opts or {}

  dbg(fmt("%s: %s", obj.name, I(opts)))

  return self
end

function obj:start(opts)
  opts = opts or {}

  return self
end

function obj:stop() return self end
