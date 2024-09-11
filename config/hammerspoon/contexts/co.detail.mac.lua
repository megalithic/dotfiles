-- REF: https://github.com/leafac/hammerspoon/blob/main/init.lua

local obj = {}
local _appObj = nil
local browser = hs.application.get(BROWSER)
local defaultKittyFont = 15.0
local fontSizeDelta = "+8.0"

obj.__index = obj
obj.name = "context.detail"
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
      local term = hs.application.get(TERMINAL)

      hs.spotify.pause()
      -- L.req("lib.menubar.keycastr"):start()
      -- L.req("lib.dnd").on("obs")
      require("ptt").setState("push-to-mute")

      -- hs.layout.apply({
      --   { browser:name(), nil, 1, hs.layout.maximized, nil, nil },
      --   { term:name(), nil, 1, hs.layout.maximized, nil, nil },
      -- })
      term:setFrontmost(true)
      if term:name() == "kitty" then
        hs.execute("kitty @ --to unix:/tmp/mykitty set-font-size " .. (defaultKittyFont + fontSizeDelta), true)
      elseif term:name() == "wezterm" then
        -- hs.execute("wezterm-cli SCREEN_SHARE_MODE on", true)
        -- hs.task
        --   .new(
        --     os.getenv("HOME") .. "/.dotfiles/bin/wezterm-cli",
        --     function(stdTask, stdOut, stdErr)
        --       dbg(fmt("wezterm SCREEN_SHARE_MODE set to on, %s / %s", I(stdOut), I(stdErr)))
        --     end,
        --     { "SCREEN_SHARE_MODE", "on" }
        --   )
        --   :start()
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
    require("ptt").setState("push-to-talk")
    -- L.req("lib.dnd").off()

    do
      -- L.req("lib.menubar.keycastr"):stop(2)

      if browser ~= nil then
        local browser_win = browser:mainWindow()
        if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
      end

      local term = hs.application.get(TERMINAL)
      if term ~= nil then
        if term:name() == "kitty" then
          hs.execute("kitty @ --to unix:/tmp/mykitty set-font-size " .. defaultKittyFont, true)
        elseif term:name() == "wezterm" then
          hs.execute("wezterm-cli font_size 20.0", true)
          -- hs.task
          --   .new(
          --     os.getenv("HOME") .. "/.dotfiles/bin/wezterm-cli",
          --     function(stdTask, stdOut, stdErr)
          --       dbg(fmt("wezterm SCREEN_SHARE_MODE set to off, %s / %s", I(stdOut), I(stdErr)))
          --     end,
          --     { "SCREEN_SHARE_MODE", "off" }
          --   )
          --   :start()
        end

        local term_win = term:mainWindow()
        if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
      end
    end
  end

  return self
end

return obj
