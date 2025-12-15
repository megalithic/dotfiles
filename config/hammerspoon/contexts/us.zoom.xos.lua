local obj = {}
local _appObj = nil

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

  -- -- TODO: add ability to auto-quit zoom when all relevant windows are closed;
  -- -- aka, the meeting has ended.
  -- -- REF: https://github.com/mrjones2014/dotfiles/blob/master/.config/hammerspoon/zoom-killer.lua
  -- if event == hs.application.watcher.launched then
  --   do
  --     -- local term = hs.application.get("com.github.wez.wezterm") or hs.application.get("com.github.wez.wezterm") or hs.application.get("kitty")
  --     local zoom = hs.application.get("zoom.us")
  --
  --     hs.timer.waitUntil(function() return zoom:getWindow("Zoom Meeting") end, function()
  --       U.dnd(true, "meeting")
  --       hs.spotify.pause()
  --       require("ptt").setState("push-to-talk")
  --       require("browser").killTabsByDomain("zoom.us")
  --     end)
  --   end
  -- end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  -- if
  --   _appObj
  --   and (event == hs.application.watcher.hidden or event == hs.application.watcher.deactivated)
  --   and (#_appObj:allWindows() == 0 or (#_appObj:allWindows() == 1 and _appObj:getWindow("") ~= nil))
  -- then
  --   -- make Zoom kill itself when I leave a meeting or there's just the "ending meeting" window like when someone else kills the meeting.
  --   -- REF: https://github.com/mrjones2014/dotfiles/blob/master/.config/hammerspoon/zoom-killer.lua
  --   _appObj:kill()
  -- elseif event == hs.application.watcher.terminated then
  --   U.dnd(true, "meeting")
  --   require("ptt").setState("push-to-talk")
  -- end

  return self
end

return obj
