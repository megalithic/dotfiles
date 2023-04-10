-- REF: https://github.com/leafac/hammerspoon/blob/main/init.lua

local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local browser = hs.application.get(C.preferred.browser)
local defaultKittyFont = 15.0
local fontSizeDelta = "+8.0"
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
      local term = hs.application.get("wezterm") or hs.application.get("kitty")
      currentAudioOutputLevel = hs.audiodevice.defaultOutputDevice():outputVolume()

      hs.spotify.pause()
      L.req("lib.menubar.keyshowr"):start()
      L.req("lib.dnd").on("obs")
      L.req("lib.menubar.ptt").setState("push-to-mute")
      hs.audiodevice.defaultOutputDevice():setOutputVolume(15)

      hs.layout.apply({
        { browser:name(), nil, 1, hs.layout.maximized, nil, nil },
        { term:name(), nil, 1, hs.layout.maximized, nil, nil },
      })
      term:setFrontmost(true)
      if term:name() == "kitty" then
        hs.execute("kitty @ --to unix:/tmp/mykitty set-font-size " .. (defaultKittyFont + defaultKittyFontDelta), true)
      elseif term:name() == "wezterm" then
        -- hs.execute("wezterm-cli SCREEN_SHARE_MODE on", true)
        hs.task
          .new(
            os.getenv("HOME") .. "/.dotfiles/bin/wezterm-cli",
            function(stdTask, stdOut, stdErr)
              dbg(fmt("wezterm SCREEN_SHARE_MODE set to on, %s / %s", I(stdOut), I(stdErr)))
            end,
            { "SCREEN_SHARE_MODE", "on" }
          )
          :start()
      end
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

      local term = hs.application.get("wezterm") or hs.application.get("kitty")
      if term ~= nil then
        if term:name() == "kitty" then
          hs.execute("kitty @ --to unix:/tmp/mykitty set-font-size " .. defaultKittyFont, true)
        elseif term:name() == "wezterm" then
          -- hs.execute("wezterm-cli SCREEN_SHARE_MODE off", true)
          hs.task
            .new(
              os.getenv("HOME") .. "/.dotfiles/bin/wezterm-cli",
              function(stdTask, stdOut, stdErr)
                dbg(fmt("wezterm SCREEN_SHARE_MODE set to off, %s / %s", I(stdOut), I(stdErr)))
              end,
              { "SCREEN_SHARE_MODE", "off" }
            )
            :start()
        end

        local term_win = term:mainWindow()
        if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
      end
    end
  end

  return self
end

return obj
