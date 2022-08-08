local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local browser = hs.application.get(Settings.get(CONFIG_KEY).preferred.browser)

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

  note(fmt("[START] %s: %s", obj.name, opts))

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end
  end

  if event == hs.application.watcher.launched then -- and _appObj:isRunning() then
    L.req("lib.dnd").on()
    hs.spotify.pause()
    L.req("lib.menubar.ptt").setState("push-to-talk")
    L.req("lib.browser").killTabsByDomain("us02web.zoom.us")

    do
      local zoom = hs.application.get("zoom.us")
      local kitty = hs.application.get("kitty")

      hs.timer.waitUntil(function() return zoom:getWindow("Zoom Meeting") end, function()
        local target_close_window = zoom:getWindow("Zoom")
        if target_close_window ~= nil then target_close_window:close() end

        local layouts = {
          { "zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, nil, nil },
          { browser:name(), nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
          { "kitty", nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
        }
        hs.layout.apply(layouts)
        kitty:setFrontmost(true)
      end)
    end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  note(fmt("[STOP] %s: %s", obj.name, self))

  if event == hs.application.watcher.deactivated then
    if obj.modal then obj.modal:exit() end
  end

  if event == hs.application.watcher.terminated then
    L.req("lib.menubar.ptt").setState("push-to-talk")
    L.req("lib.dnd").off()

    do
      local kitty = hs.application.get("kitty")

      if browser ~= nil then
        local browser_win = browser:mainWindow()
        if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
      end

      if kitty ~= nil then
        local kitty_win = kitty:mainWindow()
        if kitty_win ~= nil then kitty_win:moveToUnit(hs.layout.maximized) end
      end
    end
  end

  return self
end

return obj