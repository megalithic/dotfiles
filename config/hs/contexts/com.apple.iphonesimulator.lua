local obj = {}
local _appObj = nil
local browser = hs.application.get(BROWSER)

obj.__index = obj
obj.name = "context.iphonesimulator"
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
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  if event == hs.application.watcher.launched then
    local term = hs.application.get(TERMINAL)
    local sim = hs.application.get("Simulator")

    hs.timer.waitUntil(function() return sim:isRunning() end, function()
      local layouts = {
        { term:name(), nil, hs.screen.find(DISPLAYS.external), hs.layout.maximized, nil, nil },
        { sim:name(), nil, hs.screen.find(DISPLAYS.internal), hs.layout.left25, nil, nil },
      }
      hs.layout.apply(layouts)
      term:setFrontmost(true)
    end)
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  if event == hs.application.watcher.terminated then
    local term = hs.application.get(TERMINAL)
    if term ~= nil then
      local term_win = term:mainWindow()
      if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
    end
  end

  return self
end

return obj
