local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local browser = hs.application.get(C.preferred.browser)

obj.__index = obj
obj.name = "context.zoom"
obj.debug = true

obj.modal = nil
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  -- TODO: add ability to auto-quit zoom when all relevant windows are closed;
  -- aka, the meeting has ended.
  -- REF: https://github.com/mrjones2014/dotfiles/blob/master/.config/hammerspoon/zoom-killer.lua
  if event == hs.application.watcher.launched then
    do
      local term = hs.application.get("com.github.wez.wezterm") or hs.application.get("kitty")
      local zoom = hs.application.get("zoom.us")

      hs.timer.waitUntil(function() return zoom:getWindow("Zoom Meeting") end, function()
        L.req("lib.dnd").on("zoom")
        L.req("lib.watchers.dock").refreshInput("docked")
        hs.spotify.pause()
        L.req("lib.menubar.ptt").setState("push-to-talk")
        L.req("lib.browser").killTabsByDomain("us05web.zoom.us")

        local target_close_window = zoom:getWindow("Zoom")
        if target_close_window ~= nil then target_close_window:close() end

        local layouts = {
          { "zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, nil, nil },
          { browser:name(), nil, hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil },
          { term:name(), nil, hs.screen.primaryScreen():name(), hs.layout.maximized, nil, nil },
        }
        hs.layout.apply(layouts)
        term:setFrontmost(true)
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
    _appObj
    and (event == hs.application.watcher.hidden or event == hs.application.watcher.deactivated)
    and (#_appObj:allWindows() == 0 or (#_appObj:allWindows() == 1 and _appObj:getWindow("") ~= nil))
  then
    -- make Zoom kill itself when I leave a meeting or there's just the "ending meeting" window like when someone else kills the meeting.
    -- REF: https://github.com/mrjones2014/dotfiles/blob/master/.config/hammerspoon/zoom-killer.lua
    _appObj:kill()
  elseif event == hs.application.watcher.terminated then
    L.req("lib.menubar.ptt").setState("push-to-talk")
    L.req("lib.dnd").off()

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
