local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local defaultKittyFont = 15.0

obj.__index = obj
obj.name = "context.loom"
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

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end
  end

  if event == hs.application.watcher.launched then -- and _appObj:isRunning() then
    do
      local loom = hs.application.get("Loom")

      hs.timer.waitUntil(function() return loom:getWindow("Loom Countdown") end, function()
        hs.application.launchOrFocus("KeyCastr")
        L.req("lib.dnd").on()
        hs.spotify.pause()
        L.req("lib.menubar.ptt").setState("push-to-mute")

        hs.execute("kitty @ --to tcp:localhost:45876 set-font-size " .. (defaultKittyFont + 8.0), true)
      end)
    end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  if
    event == hs.application.watcher.terminated
    or hs.application.get("com.loom.desktop"):getWindow("Loom Control Menu") == nil
  then
    L.req("lib.menubar.ptt").setState("push-to-talk")
    L.req("lib.dnd").off()

    local keycastr = hs.application.get("KeyCastr")
    if keycastr ~= nil then keycastr:kill() end

    hs.execute("kitty @ --to tcp:localhost:45876 set-font-size " .. defaultKittyFont, true)
  end

  return self
end

return obj
