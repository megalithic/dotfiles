local Settings = require("hs.settings")
local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.wezterm"
obj.debug = true
obj.modal = false
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end
    -- L.req("lib.menubar.spotify").toggle(false)
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  -- local event = opts["event"]

  if obj.modal then obj.modal:exit() end
  -- L.req("lib.menubar.spotify").toggle(true)

  return self
end

return obj
