local obj = {}
local appObj = nil

obj.__index = obj
obj.name = "context.slack"
obj._bindingsCreated = false -- Guard to prevent duplicate bindings

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

  -- Only create bindings once - prevents accumulation from repeated start() calls
  -- (titleChanged and other activation events trigger start() repeatedly)
  if obj._bindingsCreated then
    return self
  end

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

  obj._bindingsCreated = true
  -- NOTE: Modal enter/exit is now handled by the context orchestrator (contexts/init.lua)
  -- Do not manually call obj.modal:enter() here

  return self
end

function obj:stop(opts)
  -- NOTE: Modal enter/exit is now handled by the context orchestrator (contexts/init.lua)
  -- Do not manually call obj.modal:exit() here
  -- Bindings persist across deactivation - they'll be reused on next activation
  return self
end

return obj
