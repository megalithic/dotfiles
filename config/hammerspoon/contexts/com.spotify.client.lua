-- REF: https://github.com/leafac/hammerspoon/blob/main/init.lua

local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.spotify"
obj.debug = true

obj.modal = nil
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if obj.modal then
    obj.modal:enter()
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then
    obj.modal:exit()
  end

  if
    _appObj
    and (event == hs.application.watcher.hidden or event == hs.application.watcher.deactivated)
    and (#_appObj:allWindows() == 0 or (#_appObj:allWindows() == 1 and _appObj:getWindow("") ~= nil))
  then
    _appObj:kill()
  end

  return self
end

return obj
