local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local browser = hs.application.get(Settings.get(CONFIG_KEY).preferred.browser)
local defaultKittyFont = 15.0
local defaultKittyFontDelta = 4.0

obj.__index = obj
obj.name = "context.pop"
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
    do
      local kitty = hs.application.get("kitty")
      local pop = hs.application.get("Pop")

      L.req("lib.dnd").on("meeting")
      hs.spotify.pause()
      L.req("lib.menubar.keyshowr"):start()
      L.req("lib.menubar.ptt").setState("push-to-mute")

      local layouts = {
        { browser:name(), nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
        { "kitty", nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
      }
      hs.layout.apply(layouts)
      kitty:setFrontmost(true)
      hs.execute("kitty @ --to unix:/tmp/mykitty set-font-size " .. (defaultKittyFont + defaultKittyFontDelta), true)
    end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  if
    _appObj
    and (event == hs.application.watcher.hidden or event == hs.application.watcher.deactivated)
    and (#_appObj:allWindows() == 0 or (#_appObj:allWindows() == 1 and _appObj:getWindow("") ~= nil))
  then
    _appObj:kill()
    -- FIXME: verify this needs or doesn't need to be called when we invoke `:kill()` on an hs.application object:
    -- onStop()
  elseif event == hs.application.watcher.terminated then
    L.req("lib.menubar.ptt").setState("push-to-talk")
    L.req("lib.dnd").off()

    do
      L.req("lib.menubar.keyshowr"):stop()

      if browser ~= nil then
        local browser_win = browser:mainWindow()
        if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
      end

      local kitty = hs.application.get("kitty")
      if kitty ~= nil then
        hs.execute("kitty @ --to unix:/tmp/mykitty set-font-size " .. defaultKittyFont, true)
        local kitty_win = kitty:mainWindow()
        if kitty_win ~= nil then kitty_win:moveToUnit(hs.layout.maximized) end
      end
    end
  end

  return self
end

return obj
