-- REF: https://github.com/leafac/hammerspoon/blob/main/init.lua

local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local browser = hs.application.get(C.preferred.browser)
local defaultKittyFont = 15.0
local defaultKittyFontDelta = 8.0
local currentAudioOutputLevel

obj.__index = obj
obj.name = "context.obs"
obj.debug = true

obj.modal = nil
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  if event == hs.application.watcher.launched then
    do
      local kitty = hs.application.get("kitty")
      currentAudioOutputLevel = hs.audiodevice.defaultOutputDevice():outputVolume()

      hs.spotify.pause()
      L.req("lib.menubar.keyshowr"):start()
      L.req("lib.dnd").on("obs")
      L.req("lib.menubar.ptt").setState("push-to-mute")
      hs.audiodevice.defaultOutputDevice():setOutputVolume(15)

      hs.layout.apply({
        { browser:name(), nil, 1, hs.layout.maximized, nil, nil },
        { kitty:name(), nil, 1, hs.layout.maximized, nil, nil },
      })
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
  elseif event == hs.application.watcher.terminated then
    hs.audiodevice.defaultOutputDevice():setOutputVolume(currentAudioOutputLevel)

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
