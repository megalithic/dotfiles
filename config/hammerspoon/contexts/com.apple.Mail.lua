-- local fuzzyChooser = require("utils.fuzzychooser")
local AX = req("hs.axuielement")
local enum = req("hs.fnutils")
local utils = req("utils")

local obj = {}

obj.__index = obj
obj.name = "context.mail"
obj.debug = true
obj.appObj = nil
-- USAGE
-- { ..., {"AXWindow", "AXRoleDescription", "standard window"}, ..., {"AXSplitGroup", 1}, ...}
function obj.getUIElement(appOrWindowOrAx, uiPathTable)
  local n
  local match
  local numeralIndexReferenceMode
  local role
  local indexOrAttribute
  local attributeValue
  local children

  local targetElement

  -- if an hsapp
  if appOrWindowOrAx.bundleID then
    targetElement = AX.applicationElement(appOrWindowOrAx)
  elseif appOrWindowOrAx.maximize then
    targetElement = AX.windowElement(appOrWindowOrAx)
  else
    targetElement = appOrWindowOrAx
  end

  -- pathItem is sent by the user
  for _, pathItem in ipairs(uiPathTable) do
    role = pathItem[1]
    indexOrAttribute = pathItem[2]
    -- iterator
    n = 1
    -- all child UI elements
    children = targetElement:attributeValue("AXChildren")

    -- if 0 children, return
    print(hs.inspect(children))
    if not children or utils.tlen(children) == 0 then return nil end

    -- for the current pathItem, checking for an index/attribute-value reference
    if tonumber(indexOrAttribute) then
      numeralIndexReferenceMode = true
    else
      numeralIndexReferenceMode = false
      attributeValue = pathItem[3]
    end
    match = false
    for _, childElement in ipairs(children) do
      -- checking for matching role
      if childElement:attributeValue("AXRole") == role then
        -- checking if a numeral index
        if numeralIndexReferenceMode then
          if indexOrAttribute == n then
            match = true
          else
            n = n + 1
          end
        elseif childElement:attributeValue(indexOrAttribute) == attributeValue then
          match = true
        end
      end
      if match then
        -- break the current loop as there's no need to continue traversing the current children heirarchy
        -- assign the newly found targetElement back to the targetElement var
        targetElement = childElement
        break
      end
    end
    if not match then return nil end
  end

  return targetElement
end

function obj.cycleUIElements(hsAppObj, parentUIGroup, elementRole, direction)
  -- cycles left (next) or right (prev) through a group of similar ui elements, under a common parent
  local axParent = obj.getUIElement(hsAppObj, parentUIGroup)
  local elements = axParent:attributeValue("AXChildren")
  local totalElements = 0
  local selectedElement = 0
  local targetElement
  for _, element in ipairs(elements) do
    if element:attributeValue("AXRole") == elementRole then
      totalElements = totalElements + 1
      if element:attributeValue("AXValue") == 1 then selectedElement = totalElements end
    end
  end
  if direction == "next" then
    if selectedElement == totalElements then
      targetElement = 1
    else
      targetElement = selectedElement + 1
    end
  elseif direction == "prev" then
    if selectedElement == 1 then
      targetElement = totalElements
    else
      targetElement = selectedElement - 1
    end
  end
  -- create the new target element as string, add it to the ui path
  targetElement = { elementRole, targetElement }
  table.insert(parentUIGroup, targetElement)
  obj.getUIElement(hsAppObj, parentUIGroup):performAction("AXPress")
end

-- local function chooserCallback(choice) os.execute(string.format([["/usr/bin/open" "%s"]], choice.text)) end
--
function obj.getChatMessageLinks(app)
  local linkElements = obj
    .getUIElement(app:mainWindow(), {
      { "AXSplitGroup", 1 },
      { "AXScrollArea", 2 },
      { "AXWebArea", 1 },
    })
    :attributeValue("AXLinkUIElements")

  local choices = {}
  for _, link in ipairs(linkElements) do
    local url = link:attributeValue("AXChildren")[1]:attributeValue("AXValue")
    table.insert(choices, { text = url })
  end
  if utils.tlen(choices) == 0 then table.insert(choices, { text = "No Links" }) end
  dbg(I(choices), true)
  -- fuzzyChooser:start(chooserCallback, choices, { "text" })
end

obj.modal = true
obj.actions = {
  getMessageLinks = {
    action = function() obj.getChatMessageLinks(obj.appObj) end,
    hotkey = { "alt", "o" },
  },
  nextConversation = {
    -- action = function() _appObj:selectMenuItem({ "Window", "Go to Next Conversation" }) end,
    action = function() hs.eventtap.keyStroke({ "cmd", "shift" }, "]") end,
    hotkey = { { "ctrl" }, "n" },
  },
  prevConversation = {
    -- action = function() _appObj:selectMenuItem({ "Window", "Go to Previous Conversation" }) end,
    action = function() hs.eventtap.keyStroke({ "cmd", "shift" }, "[") end,
    hotkey = { { "ctrl" }, "p" },
  },
  -- FIXME: it's saying ctrl-1,2,3,4 are all being used somewhere?! sooo, we use ctrl-h,j,k,l instead.
  gotoConversation1 = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "1") end,
    hotkey = { { "ctrl" }, "h" },
  },
  gotoConversation2 = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "2") end,
    hotkey = { { "ctrl" }, "j" },
  },
  gotoConversation3 = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "3") end,
    hotkey = { { "ctrl" }, "k" },
  },
  gotoConversation4 = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "4") end,
    hotkey = { { "ctrl" }, "l" },
  },
  replyToLastMessage = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "r") end,
    hotkey = { { "ctrl" }, "r" },
  },
  tapbackLastMessage = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "t") end,
    hotkey = { { "ctrl" }, "t" },
  },
  editLastMessage = {
    action = function() hs.eventtap.keyStroke({ "cmd" }, "e") end,
    hotkey = { { "ctrl" }, "u" },
  },
}

function obj:start(opts)
  opts = opts or {}
  self.appObj = opts["appObj"]
  local event = opts["event"]

  if enum.contains({ hs.application.watcher.activated, hs.uielement.watcher.applicationActivated }, event) then
    -- function obj.modal:entered() dbg(I(obj.actions), true) end
    -- if self.modal ~= nil then self.modal:enter() end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  -- if self.modal ~= nil then self.modal:exit() end

  return self
end

return obj
