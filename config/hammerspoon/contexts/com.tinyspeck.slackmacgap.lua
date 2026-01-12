local Settings = require("hs.settings")
local fmt = string.format
local obj = {}
local appObj = nil

obj.__index = obj
obj.name = "context.slack"
obj.debug = true
obj._bindingsCreated = false -- Guard to prevent duplicate bindings

-- Debug wrapper: logs keybinding invocation to HS console
local function debugBind(modal, mods, key, name, pressFn, releaseFn, repeatFn)
  local modsStr = type(mods) == "table" and table.concat(mods, "+") or tostring(mods)
  local bindingStr = fmt("%s+%s", modsStr, key)

  local wrappedPress = pressFn and function()
    print(fmt("[SLACK KEY] PRESSED: %s (%s) | modal=%s", bindingStr, name, modal and "active" or "nil"))
    pressFn()
  end or nil

  local wrappedRelease = releaseFn and function()
    print(fmt("[SLACK KEY] RELEASED: %s (%s)", bindingStr, name))
    releaseFn()
  end or nil

  local wrappedRepeat = repeatFn and function()
    print(fmt("[SLACK KEY] REPEAT: %s (%s)", bindingStr, name))
    repeatFn()
  end or nil

  print(fmt("[SLACK BIND] Creating: %s -> %s", bindingStr, name))
  modal:bind(mods, key, wrappedPress, wrappedRelease, wrappedRepeat)
end

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
  local eventStr = U and U.eventString and U.eventString(event) or tostring(event)

  print(fmt("[SLACK] start() called | event=%s | _bindingsCreated=%s | modal=%s",
    eventStr,
    tostring(obj._bindingsCreated),
    obj.modal and "exists" or "nil"))

  -- Only create bindings once - prevents accumulation from repeated start() calls
  -- (titleChanged and other activation events trigger start() repeatedly)
  if obj._bindingsCreated then
    print("[SLACK] start() early return - bindings already created")
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

  print("[SLACK] Creating modal bindings...")

  debugBind(obj.modal, { "ctrl" }, "j", "messageDown", nil, messageDown, messageDown)
  debugBind(obj.modal, { "ctrl" }, "k", "messageUp", nil, messageUp, messageUp)

  -- move up and down slacks (read or unread)
  debugBind(obj.modal, { "ctrl" }, "n", "slackDown", nil, slackDown, slackDown)
  debugBind(obj.modal, { "ctrl" }, "p", "slackUp", nil, slackUp, slackUp)

  -- misc
  debugBind(obj.modal, { "ctrl" }, "h", "mainMessageBox", nil, focus.mainMessageBox, focus.mainMessageBox)
  debugBind(obj.modal, { "ctrl" }, "l", "threadMessageBox", nil, focus.threadMessageBox, focus.threadMessageBox)

  -- move up and down unread slacks
  local unreadDown = function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", appObj) end
  local unreadUp = function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", appObj) end
  debugBind(obj.modal, { "ctrl", "shift" }, "j", "unreadDown", unreadDown, nil, nil)
  debugBind(obj.modal, { "ctrl", "shift" }, "k", "unreadUp", unreadUp, nil, nil)
  debugBind(obj.modal, { "ctrl", "cmd" }, "n", "unreadDown2", unreadDown, nil, nil)
  debugBind(obj.modal, { "ctrl", "cmd" }, "p", "unreadUp2", unreadUp, nil, nil)

  -- "better" jump to a thing
  debugBind(obj.modal, { "ctrl" }, "g", "quickSwitch", function() hs.eventtap.keyStroke({ "cmd" }, "k", appObj) end, nil, nil)

  -- "better" find a thing
  debugBind(obj.modal, { "ctrl" }, "/", "find", function() hs.eventtap.keyStroke({ "cmd" }, "f", appObj) end, nil, nil)

  -- no-ops:
  debugBind(obj.modal, { "cmd" }, "w", "noopCloseTab", function() hs.eventtap.keyStroke({}, "escape", appObj) end, nil, nil)
  debugBind(obj.modal, { "cmd" }, "r", "noopRefresh", function() hs.eventtap.keyStroke({}, "escape", appObj) end, nil, nil)

  debugBind(obj.modal, { "ctrl" }, "r", "startReminder", nil, startSlackReminder, startSlackReminder)
  debugBind(obj.modal, { "ctrl" }, "t", "openThread", nil, openSlackThread, openSlackThread)
  debugBind(obj.modal, { "shift", "cmd" }, "delete", "leaveChannel", nil, focus.leaveChannel, nil)

  print("[SLACK] Modal bindings created successfully")

  obj._bindingsCreated = true
  -- NOTE: Modal enter/exit is now handled by the context orchestrator (contexts/init.lua)
  -- Do not manually call obj.modal:enter() here

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]
  local eventStr = U and U.eventString and U.eventString(event) or tostring(event)

  print(fmt("[SLACK] stop() called | event=%s | _bindingsCreated=%s",
    eventStr,
    tostring(obj._bindingsCreated)))

  -- NOTE: Modal enter/exit is now handled by the context orchestrator (contexts/init.lua)
  -- Do not manually call obj.modal:exit() here
  -- Bindings persist across deactivation - they'll be reused on next activation
  return self
end

return obj
