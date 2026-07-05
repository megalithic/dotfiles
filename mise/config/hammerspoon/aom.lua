local M = {}

M.name = "aom"
M.description = "Application Object Model"

function M.traverseChildren(element, matchFn)
  if matchFn(element) then
    return element
  else
    local children = element:attributeValue("AXChildren")

    if children and #children > 0 then
      for _, child in ipairs(children) do
        local result = M.traverseChildren(child, matchFn)
        if result then return result end
      end
    end

    return nil
  end
end

function M.searchByChain(startElement, fns, debugPrint)
  debugPrint = debugPrint or false
  local current = startElement

  for _, predicate in ipairs(fns) do
    current = M.traverseChildren(current, predicate)

    if debugPrint then p("Got: " .. hs.inspect.inspect(current)) end
    if not current then return nil end
  end

  return current
end

function M.find()
  local m = {}

  return m
end

function M.load()
  local function getAxAppWindow()
    if not M.app then return end

    -- Electron apps require this attribute to be set or else you cannot
    -- read the accessibility tree
    local axApp = hs.axuielement.applicationElement(M.app)
    axApp:setAttributeValue("AXManualAccessibility", true)

    local window = M.app:mainWindow()
    window:focus()

    return hs.axuielement.windowElement(window)
  end

  local function hasClass(element, class)
    local classList = element:attributeValue("AXDOMClassList")
    if not classList then return false end

    return hs.fnutils.contains(classList, class)
  end

  function M.mainMessageBox()
    local window = getAxAppWindow()
    if not window then return end

    local textarea = M.searchByChain(window, {
      function(elem) return hasClass(elem, "p-workspace-layout") end,
      function(elem) return elem:attributeValue("AXSubrole") == "AXLandmarkMain" end,
      function(elem) return hasClass(elem, "p-workspace__primary_view_contents") end,
      function(elem) return hasClass(elem, "c-wysiwyg_container") end,
      function(elem) return elem:attributeValue("AXRole") == "AXTextArea" end,
    })

    if textarea then textarea:setAttributeValue("AXFocused", true) end
  end

  function M.threadMessageBox(withRetry)
    withRetry = withRetry or false

    local window = getAxAppWindow()
    if not window then return end

    local findTextarea = function()
      return M.searchByChain(window, {
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

  function M.leaveChannel()
    local window = getAxAppWindow()
    if not window then return end

    local button = M.searchByChain(window, {
      function(elem) return hasClass(elem, "p-workspace-layout") end,
      function(elem)
        return elem:attributeValue("AXRole") == "AXPopUpButton" and hasClass(elem, "p-view_header__big_button--channel")
      end,
    })

    if not button then return end

    button:performAction("AXPress")

    local leaveButton = nil

    local findLeaveButton = function()
      return M.searchByChain(window, {
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

    local buttonTimer = hs.timer.waitUntil(leaveButtonVisible, function() leaveButton:performAction("AXPress") end)

    hs.timer.doAfter(2, function()
      -- Prevent infinite spinning
      buttonTimer:stop()
    end)
  end

  return M
end

function M:init(opts)
  if opts.appObj == nil then
    U.log.e("an application object is required.")
    return
  end

  if opts.appObj:name() ~= "Slack" then
    U.log.e("currently, Slack is the only supported app")
    return
  end

  self.app = opts.appObj

  return self.load()
end

return M
