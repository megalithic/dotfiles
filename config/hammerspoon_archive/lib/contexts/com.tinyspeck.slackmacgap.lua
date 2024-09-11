local Settings = require("hs.settings")
local obj = {}
local _appObj = nil

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

local function _find()
  local m = {}

  m.traverseChildren = function(element, matchFn)
    if matchFn(element) then
      return element
    else
      local children = element:attributeValue("AXChildren")

      if children and #children > 0 then
        for _, child in ipairs(children) do
          local result = m.traverseChildren(child, matchFn)
          if result then return result end
        end
      end

      return nil
    end
  end

  m.searchByChain = function(startElement, fns, debugPrint)
    debugPrint = debugPrint or false
    local current = startElement

    for _, predicate in ipairs(fns) do
      current = m.traverseChildren(current, predicate)

      if debugPrint then p("Got: " .. hs.inspect.inspect(current)) end
      if not current then return nil end
    end

    return current
  end

  return m
end

local function _focus()
  local find = _find()
  local function getAxSlackWindow()
    local app = hs.application.find("Slack")
    if not app then return end

    -- Electron apps require this attribute to be set or else you cannot
    -- read the accessibility tree
    local axApp = hs.axuielement.applicationElement(app)
    axApp:setAttributeValue("AXManualAccessibility", true)

    local window = app:mainWindow()
    window:focus()

    return hs.axuielement.windowElement(window)
  end

  local function hasClass(element, class)
    local classList = element:attributeValue("AXDOMClassList")
    if not classList then return false end

    return hs.fnutils.contains(classList, class)
  end

  local module = {}

  module.mainMessageBox = function()
    local window = getAxSlackWindow()
    if not window then return end

    local textarea = find.searchByChain(window, {
      function(elem) return hasClass(elem, "p-workspace-layout") end,
      function(elem) return elem:attributeValue("AXSubrole") == "AXLandmarkMain" end,
      function(elem) return hasClass(elem, "p-workspace__primary_view_contents") end,
      function(elem) return hasClass(elem, "c-wysiwyg_container") end,
      function(elem) return elem:attributeValue("AXRole") == "AXTextArea" end,
    })

    if textarea then textarea:setAttributeValue("AXFocused", true) end
  end

  module.threadMessageBox = function(withRetry)
    withRetry = withRetry or false

    local window = getAxSlackWindow()
    if not window then return end

    local findTextarea = function()
      return find.searchByChain(window, {
        function(elem) return hasClass(elem, "p-workspace-layout") end,
        function(elem) return hasClass(elem, "p-flexpane") end,
        function(elem) return hasClass(elem, "p-threads_flexpane") end,
        function(elem) return hasClass(elem, "c-wysiwyg_container") end,
        function(elem) return elem:attributeValue("AXRole") == "AXTextArea" end,
      })
    end

    local textarea = nil

    local textareaVisible = function()
      textarea = findTextarea()
      return not not textarea
    end

    local focusTextarea = function() textarea:setAttributeValue("AXFocused", true) end

    if withRetry then
      -- Do it in a retry loop
      local loopTimer = hs.timer.waitUntil(textareaVisible, focusTextarea)

      -- Give up after 2 seconds
      hs.timer.doAfter(2, function() loopTimer:stop() end)
    elseif textareaVisible() then
      -- fire it once
      focusTextarea()
    end
  end

  module.leaveChannel = function()
    local window = getAxSlackWindow()
    if not window then return end

    local button = find.searchByChain(window, {
      function(elem) return hasClass(elem, "p-workspace-layout") end,
      function(elem)
        return elem:attributeValue("AXRole") == "AXPopUpButton" and hasClass(elem, "p-view_header__big_button--channel")
      end,
    })

    if not button then return end

    button:performAction("AXPress")

    local leaveButton = nil

    local findLeaveButton = function()
      return find.searchByChain(window, {
        function(elem) return elem:attributeValue("AXSubrole") == "AXApplicationDialog" and hasClass(elem, "p-about_modal") end,
        function(elem) return elem:attributeValue("AXRole") == "AXButton" and elem:attributeValue("AXTitle") == "Leave channel" end,
      })
    end

    local leaveButtonVisible = function()
      leaveButton = findLeaveButton()
      return not not leaveButton
    end

    local buttonTimer = hs.timer.waitUntil(leaveButtonVisible, function() leaveButton:performAction("AXPress") end)

    hs.timer.doAfter(2, function()
      -- Prevent infinite spinning
      buttonTimer:stop()
    end)
  end

  return module
end

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  local focus = _focus()
  local function messageUp() hs.eventtap.keyStroke({}, "up", _appObj) end

  local function messageDown() hs.eventtap.keyStroke({}, "down", _appObj) end

  local function slackUp() hs.eventtap.keyStroke({ "alt" }, "up", _appObj) end

  local function slackDown() hs.eventtap.keyStroke({ "alt" }, "down", _appObj) end

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
  obj.modal:bind({ "ctrl", "shift" }, "j", function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", _appObj) end)
  obj.modal:bind({ "ctrl", "shift" }, "k", function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", _appObj) end)
  obj.modal:bind({ "ctrl", "cmd" }, "n", function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", _appObj) end)
  obj.modal:bind({ "ctrl", "cmd" }, "p", function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", _appObj) end)

  -- "better" jump to a thing
  obj.modal:bind({ "ctrl" }, "g", function() hs.eventtap.keyStroke({ "cmd" }, "k", _appObj) end)

  -- "better" find a thing
  obj.modal:bind({ "ctrl" }, "/", function() hs.eventtap.keyStroke({ "cmd" }, "f", _appObj) end)

  -- no-ops:
  obj.modal:bind({ "cmd" }, "w", function() hs.eventtap.keyStroke({}, "escape", _appObj) end)
  obj.modal:bind({ "cmd" }, "r", function() hs.eventtap.keyStroke({}, "escape", _appObj) end)

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
