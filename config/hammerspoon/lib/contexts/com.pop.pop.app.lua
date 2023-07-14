local Settings = require("hs.settings")
local obj = {}
local _appObj = nil
local browser = hs.application.get(C.preferred.browser)

obj.__index = obj
obj.name = "context.pop"
obj.debug = true

obj.modal = nil
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  -- if event == hs.application.watcher.launched or event == hs.application.watcher.activated then
  --   local pop = hs.application.get("Pop")
  --
  --   -- hs.timer.waitUntil(function() return pop:getWindow("'s Screen") end, function()
  --   L.req("lib.dnd").on("meeting")
  --   L.req("lib.watchers.dock").refreshInput("docked")
  --   hs.spotify.pause()
  --   -- L.req("lib.menubar.keycastr"):start()
  --   L.req("lib.menubar.ptt").setState("push-to-mute")
  --
  --   if event == hs.application.watcher.launched then
  --     hs.timer.waitUntil(
  --       function() return #pop:allWindows() > 1 or pop:selectMenuItem({ "Window", "Focus Meeting Window" }) end,
  --       function()
  --         local wins = {}
  --         for _, win in ipairs(pop:allWindows()) do
  --           table.insert(wins, { pop, win, hs.screen.primaryScreen(), hs.layout.maximized, nil, nil })
  --         end
  --         hs.layout.apply(wins)
  --       end
  --     )
  --   end
  -- end

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
    L.req("lib.menubar.keycastr"):stop(2)

    if browser ~= nil then
      local browser_win = browser:mainWindow()
      if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
    end

    local term = hs.application.get("wezterm") or hs.application.get("kitty")
    if term ~= nil then
      local term_win = term:mainWindow()
      if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
    end
  end

  return self
end

return obj
