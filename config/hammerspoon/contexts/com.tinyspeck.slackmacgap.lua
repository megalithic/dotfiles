local Settings = require("hs.settings")
local obj = {}
local appObj = nil

obj.__index = obj
obj.name = "context.slack"
obj.debug = true

-- local function clickOnHistoryMenuItem(appObj)
-- 	appObj:selectMenuItem({"History"})
-- end

-- local function toggleBookmarks(appObj)
-- 	if appObj:selectMenuItem({"Bookmarks", "Show Bookmarks..."}) then
-- 		return
-- 	end
-- 	appObj:selectMenuItem({"Bookmarks", "Hide Bookmarks"})
-- end

obj.modal = true
obj.actions = {}

-- obj.actions = {
-- 	clickOnHistoryMenuItem = {
-- 		hotkey = {"cmd", "y"},
-- 		action = function()
-- 			clickOnHistoryMenuItem(_appObj)
-- 		end
-- 	},
-- 	toggleBookmarks = {
-- 		hotkey = {{"cmd", "alt"}, "b"},
-- 		action = function()
-- 			toggleBookmarks(_appObj)
-- 		end
-- 	}
-- }

function obj:start(opts)
  opts = opts or {}
  appObj = opts["appObj"]
  local event = opts["event"]

  local focus = req("aom", { appObj = appObj })

  local function messageUp() hs.eventtap.keyStroke({}, "up", appObj) end

  local function messageDown() hs.eventtap.keyStroke({}, "down", appObj) end

  local function slackUp() hs.eventtap.keyStroke({ "alt" }, "up", appObj) end

  local function slackDown() hs.eventtap.keyStroke({ "alt" }, "down", appObj) end

  local function startSlackReminder()
    focus.mainMessageBox()

    hs.timer.doAfter(0.3, function() hs.eventtap.keyStrokes("/remind me at ") end)
  end

  local function openSlackThread()
    focus.mainMessageBox()

    hs.timer.doAfter(0.1, function()
      slackUp()
      hs.eventtap.keyStroke({}, "t", 0)
      focus.threadMessageBox(true)
    end)
  end

  obj.modal:bind({ "ctrl" }, "j", nil, messageDown, nil, messageDown)
  obj.modal:bind({ "ctrl" }, "k", nil, messageUp, nil, messageUp)

  -- move up and down slacks (read or unread)
  obj.modal:bind({ "ctrl" }, "n", nil, slackDown, nil, slackDown)
  obj.modal:bind({ "ctrl" }, "p", nil, slackUp, nil, slackUp)

  -- misc
  obj.modal:bind({ "ctrl" }, "h", nil, focus.mainMessageBox, nil, focus.mainMessageBox)
  obj.modal:bind({ "ctrl" }, "l", nil, focus.threadMessageBox, nil, focus.threadMessageBox)

  -- move up and down unread slacks
  obj.modal:bind({ "ctrl", "shift" }, "j", function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", appObj) end)
  obj.modal:bind({ "ctrl", "shift" }, "k", function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", appObj) end)
  obj.modal:bind({ "ctrl", "cmd" }, "n", function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", appObj) end)
  obj.modal:bind({ "ctrl", "cmd" }, "p", function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", appObj) end)

  -- "better" jump to a thing
  obj.modal:bind({ "ctrl" }, "g", function() hs.eventtap.keyStroke({ "cmd" }, "k", appObj) end)

  -- "better" find a thing
  obj.modal:bind({ "ctrl" }, "/", function() hs.eventtap.keyStroke({ "cmd" }, "f", appObj) end)

  -- no-ops:
  obj.modal:bind({ "cmd" }, "w", function() hs.eventtap.keyStroke({}, "escape", appObj) end)
  obj.modal:bind({ "cmd" }, "r", function() hs.eventtap.keyStroke({}, "escape", appObj) end)

  obj.modal:bind({ "ctrl" }, "r", nil, startSlackReminder, nil, startSlackReminder)
  obj.modal:bind({ "ctrl" }, "t", nil, openSlackThread, nil, openSlackThread)
  obj.modal:bind({ "shift", "cmd" }, "delete", nil, focus.leaveChannel, nil, nil)

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  return self
end

return obj
