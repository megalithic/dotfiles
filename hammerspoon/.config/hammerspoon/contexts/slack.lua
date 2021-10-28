-- HT @dbalatero
-- REF: https://github.com/dbalatero/dotfiles/tree/master/hammerspoon/slack

local cache = {}

local M = { cache = cache }
local wh = require("utils.wm.window-handlers")

local function _find()
  local module = {}

  module.traverseChildren = function(element, matchFn)
    if matchFn(element) then
      return element
    else
      local children = element:attributeValue("AXChildren")

      if children and #children > 0 then
        for _, child in ipairs(children) do
          local result = module.traverseChildren(child, matchFn)
          if result then
            return result
          end
        end
      end

      return nil
    end
  end

  module.searchByChain = function(startElement, fns, debugPrint)
    debugPrint = debugPrint or false
    local current = startElement

    for _, predicate in ipairs(fns) do
      current = module.traverseChildren(current, predicate)

      if debugPrint then
        p("Got: " .. hs.inspect.inspect(current))
      end
      if not current then
        return nil
      end
    end

    return current
  end

  return module
end

local function _focus()
  local find = _find()
  local function getAxSlackWindow()
    local app = hs.application.find("Slack")
    if not app then
      return
    end

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
    if not classList then
      return false
    end

    return hs.fnutils.contains(classList, class)
  end

  local module = {}

  module.mainMessageBox = function()
    local window = getAxSlackWindow()
    if not window then
      return
    end

    local textarea = find.searchByChain(window, {
      function(elem)
        return hasClass(elem, "p-workspace-layout")
      end,
      function(elem)
        return elem:attributeValue("AXSubrole") == "AXLandmarkMain"
      end,
      function(elem)
        return hasClass(elem, "p-workspace__primary_view_contents")
      end,
      function(elem)
        return hasClass(elem, "c-wysiwyg_container")
      end,
      function(elem)
        return elem:attributeValue("AXRole") == "AXTextArea"
      end,
    })

    if textarea then
      textarea:setAttributeValue("AXFocused", true)
    end
  end

  module.threadMessageBox = function(withRetry)
    withRetry = withRetry or false

    local window = getAxSlackWindow()
    if not window then
      return
    end

    local findTextarea = function()
      return find.searchByChain(window, {
        function(elem)
          return hasClass(elem, "p-workspace-layout")
        end,
        function(elem)
          return hasClass(elem, "p-flexpane")
        end,
        function(elem)
          return hasClass(elem, "p-threads_flexpane")
        end,
        function(elem)
          return hasClass(elem, "c-wysiwyg_container")
        end,
        function(elem)
          return elem:attributeValue("AXRole") == "AXTextArea"
        end,
      })
    end

    local textarea = nil

    local textareaVisible = function()
      textarea = findTextarea()
      return not not textarea
    end

    local focusTextarea = function()
      textarea:setAttributeValue("AXFocused", true)
    end

    if withRetry then
      -- Do it in a retry loop
      local loopTimer = hs.timer.waitUntil(textareaVisible, focusTextarea)

      -- Give up after 2 seconds
      hs.timer.doAfter(2, function()
        loopTimer:stop()
      end)
    elseif textareaVisible() then
      -- fire it once
      focusTextarea()
    end
  end

  module.leaveChannel = function()
    local window = getAxSlackWindow()
    if not window then
      return
    end

    local button = find.searchByChain(window, {
      function(elem)
        return hasClass(elem, "p-workspace-layout")
      end,
      function(elem)
        return elem:attributeValue("AXRole") == "AXPopUpButton" and hasClass(elem, "p-view_header__big_button--channel")
      end,
    })

    if not button then
      return
    end

    button:performAction("AXPress")

    local leaveButton = nil

    local findLeaveButton = function()
      return find.searchByChain(window, {
        function(elem)
          return elem:attributeValue("AXSubrole") == "AXApplicationDialog" and hasClass(elem, "p-about_modal")
        end,
        function(elem)
          return elem:attributeValue("AXRole") == "AXButton" and elem:attributeValue("AXTitle") == "Leave channel"
        end,
      })
    end

    local leaveButtonVisible = function()
      leaveButton = findLeaveButton()
      return not not leaveButton
    end

    local buttonTimer = hs.timer.waitUntil(leaveButtonVisible, function()
      leaveButton:performAction("AXPress")
    end)

    hs.timer.doAfter(2, function()
      -- Prevent infinite spinning
      buttonTimer:stop()
    end)
  end

  return module
end

-- apply(hs.application, hs.window, running.events, hs.logger) :: nil
M.apply = function(app, _, _, _)
  local focus = _focus()
  local function slackUp()
    hs.eventtap.keyStroke({ "alt" }, "up", app)
  end

  local function slackDown()
    hs.eventtap.keyStroke({ "alt" }, "down", app)
  end

  -- local function startSlackReminder()
  --   focus.mainMessageBox()

  --   hs.timer.doAfter(0.3, function()
  --     hs.eventtap.keyStrokes("/remind me at ")
  --   end)
  -- end

  -- local function openSlackThread()
  --   focus.mainMessageBox()

  --   hs.timer.doAfter(0.1, function()
  --     slackUp()
  --     hs.eventtap.keyStroke({}, "t", 0)
  --     focus.threadMessageBox(true)
  --   end)
  -- end

  local slackModal = hs.hotkey.modal.new()

  slackModal:bind({ "ctrl" }, "h", nil, focus.mainMessageBox, nil, focus.mainMessageBox)
  slackModal:bind({ "ctrl" }, "j", nil, slackDown, nil, slackDown)
  slackModal:bind({ "ctrl" }, "k", nil, slackUp, nil, slackUp)
  slackModal:bind({ "ctrl" }, "l", nil, focus.threadMessageBox, nil, focus.threadMessageBox)
  slackModal:bind({ "ctrl", "shift" }, "j", function()
    hs.eventtap.keyStroke({ "alt", "shift" }, "down", app)
  end)
  slackModal:bind({ "ctrl", "shift" }, "k", function()
    hs.eventtap.keyStroke({ "alt", "shift" }, "up", app)
  end)
  slackModal:bind({ "ctrl" }, "g", function()
    hs.eventtap.keyStroke({ "cmd" }, "k", app)
  end)

  -- basically no-ops:
  slackModal:bind({ "cmd" }, "w", function()
    hs.eventtap.keyStroke({}, "escape", app)
  end)
  slackModal:bind({ "cmd" }, "r", function()
    hs.eventtap.keyStroke({}, "escape", app)
  end)

  -- slackModal:bind({ "ctrl" }, "r", nil, startSlackReminder, nil, startSlackReminder)
  -- slackModal:bind({ "ctrl" }, "t", nil, openSlackThread, nil, openSlackThread)
  -- slackModal:bind({ "shift", "cmd" }, "delete", nil, focus.leaveChannel, nil, nil)

  local slackWatcher = hs.application.watcher.new(function(applicationName, eventType)
    if applicationName ~= "Slack" then
      return
    end

    if eventType == hs.application.watcher.activated then
      slackModal:enter()
    elseif eventType == hs.application.watcher.deactivated then
      slackModal:exit()
    end
  end)

  slackWatcher:start()

  wh.onAppQuit(app, function()
    slackModal:exit()
    slackWatcher:stop()
  end)
end

return M
