local obj = {}
local _appObj = nil
local enum = require("hs.fnutils")
local fmt = string.format

obj.__index = obj
obj.name = "context.teams"
obj.debug = true
obj.actions = {}
obj.stopComplete = false
obj.startComplete = false

local function hasMeetingWindow(app)
  -- Teams: Meeting windows DON'T have "| Microsoft Teams" suffix
  -- The main window is titled like "Chat | Team Name | Microsoft Teams"
  -- Meeting windows are just the meeting name (e.g., "Daily Standup")
  local windows = app:allWindows()
  for _, window in ipairs(windows) do
    local title = window:title()
    if title and window:isStandard() and not title:find("Microsoft Teams", 1, true) then
      -- Found a window without the Teams suffix - likely a meeting
      return window
    end
  end
end

function obj:start(opts)
  opts = opts or {}
  local event = opts.event
  local appObj = opts.appObj

  if obj.modal then obj.modal:enter() end

  -- REFS:
  -- https://github.com/justintout/.hammerspoon/blob/main/teams.lua
  -- https://github.com/fireprophet/TeamsKeepAlive/blob/main/init.lua

  -- if
  --   enum.contains({
  --     hs.application.watcher.launched,
  --     hs.application.watcher.activated,
  --     hs.uielement.watcher.applicationActivated,
  --     hs.uielement.watcher.windowCreated,
  --   }, event)
  -- then
  --   hs.timer.waitUntil(function() return hasMeetingWindow(appObj) ~= nil end, function()
  --     U.dnd(true, "meeting")
  --     hs.spotify.pause()
  --     require("ptt").setState("push-to-talk")
  --   end)
  -- end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts.event
  local appObj = opts.appObj

  if obj.modal then obj.modal:exit() end

  -- if event == hs.application.watcher.terminated or event == hs.uielement.watcher.elementDestroyed then
  --   hs.timer.waitUntil(
  --     function() return appObj == nil or not appObj:isRunning() or not hasMeetingWindow(appObj) end,
  --     function()
  --       U.dnd(false)
  --       require("ptt").setState("push-to-talk")
  --       --
  --     end
  --   )
  -- end

  return self
end

return obj
