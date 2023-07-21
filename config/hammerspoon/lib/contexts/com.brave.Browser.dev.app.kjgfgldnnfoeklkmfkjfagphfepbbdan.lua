local Settings = require("hs.settings")
local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.meet"
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
    local term = hs.application.get("com.github.wez.wezterm") or hs.application.get("kitty")
    local meet = hs.application.get("Google Meet")
    local browser = hs.application.get(C.preferred.browser)

    hs.timer.waitUntil(function() return meet:isRunning() end, function()
      L.req("lib.dnd").on("zoom")
      hs.spotify.pause()
      L.req("lib.menubar.ptt").setState("push-to-talk")

      local layouts = {
        { meet:name(), nil, hs.screen.primaryScreen():name(), hs.layout.maximized, nil, nil },
        { browser:name(), nil, hs.screen.primaryScreen():name(), hs.layout.maximized, nil, nil },
        { term:name(), nil, hs.screen.primaryScreen():name(), hs.layout.maximized, nil, nil },
      }
      hs.layout.apply(layouts)
      meet:setFrontmost(true)

      L.req("lib.watchers.dock").refreshInput("docked")
      L.req("lib.menubar.ptt").setAllInputsMuted(true)
    end)
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  if event == hs.application.watcher.terminated then
    L.req("lib.menubar.ptt").setState("push-to-talk")
    L.req("lib.dnd").off()
    local browser = hs.application.get(C.preferred.browser)

    do
      if browser ~= nil then
        local browser_win = browser:mainWindow()
        if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
      end

      local term = hs.application.get("com.github.wez.wezterm") or hs.application.get("kitty")
      if term ~= nil then
        local term_win = term:mainWindow()
        if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
      end
    end
  end

  return self
end

return obj
