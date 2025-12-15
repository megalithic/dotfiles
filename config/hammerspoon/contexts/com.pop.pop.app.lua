local obj = {}
local _appObj = nil
local utils = req("utils")
local enum = require("hs.fnutils")

obj.__index = obj
obj.name = "context.pop"
obj.debug = true
obj.launched = false

obj.modal = nil
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  -- if
  --   enum.contains(
  --     { hs.application.watcher.launched, hs.application.watcher.activated, hs.uielement.watcher.applicationActivated },
  --     event
  --   )
  -- then
  --   hs.timer.waitUntil(function() return hasMeetingWindow(appObj) ~= nil end, function()
  --     U.dnd(true, "meeting")
  --     hs.spotify.pause()
  --     require("ptt").setState("push-to-talk")
  --   end)
  --
  --   -- local pop = hs.application.get("com.pop.pop.app")
  --   -- req("utils").dnd(true, "zoom")
  --   -- hs.spotify.pause()
  --   -- req("ptt").setState("push-to-talk")
  --   -- req("watchers.dock").refreshInput("docked")
  --
  --   local browser = req("browser")
  --   if browser.hasTab("pop.com") then
  --     browser.killTabsByDomain("pop.com")
  --     pop:activate()
  --   end
  -- end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  -- if event == hs.application.watcher.terminated then
  --   U.dnd(true, "meeting")
  --   require("ptt").setState("push-to-talk")
  -- end

  return self
end

return obj
