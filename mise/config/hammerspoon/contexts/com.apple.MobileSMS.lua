-- Messages.app context
-- Modal hotkeys are managed automatically by contexts/init.lua
-- Only define actions and any custom helpers needed

local AX = req("hs.axuielement")
local utils = req("utils")

local obj = {}

obj.__index = obj
obj.name = "context.messages"

-- Actions define hotkey bindings - modal enter/exit handled by loader
obj.actions = {
  getMessageLinks = {
    action = function() obj.getChatMessageLinks() end,
    hotkey = { { "alt" }, "o" },
  },
  nextConversation = {
    action = function() hs.eventtap.keyStroke({ "cmd", "shift" }, "]") end,
    hotkey = { { "ctrl" }, "n" },
  },
  prevConversation = {
    action = function() hs.eventtap.keyStroke({ "cmd", "shift" }, "[") end,
    hotkey = { { "ctrl" }, "p" },
  },
  -- Jump to pinned conversations 1-4 via Ctrl+H/J/K/L (vim-style)
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

--------------------------------------------------------------------------------
-- AX Helpers (unique to Messages context)
--------------------------------------------------------------------------------

-- Traverse AX hierarchy to find specific UI element
-- Usage: { {"AXWindow", "AXRoleDescription", "standard window"}, {"AXSplitGroup", 1} }
function obj.getUIElement(appOrWindowOrAx, uiPathTable)
  local targetElement

  -- Determine starting element type
  if appOrWindowOrAx.bundleID then
    targetElement = AX.applicationElement(appOrWindowOrAx)
  elseif appOrWindowOrAx.maximize then
    targetElement = AX.windowElement(appOrWindowOrAx)
  else
    targetElement = appOrWindowOrAx
  end

  for _, pathItem in ipairs(uiPathTable) do
    local role = pathItem[1]
    local indexOrAttribute = pathItem[2]
    local children = targetElement:attributeValue("AXChildren")

    if not children or utils.tlen(children) == 0 then return nil end

    local numeralIndexReferenceMode = tonumber(indexOrAttribute) ~= nil
    local attributeValue = not numeralIndexReferenceMode and pathItem[3] or nil
    local n = 1
    local match = false

    for _, childElement in ipairs(children) do
      if childElement:attributeValue("AXRole") == role then
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
        targetElement = childElement
        break
      end
    end

    if not match then return nil end
  end

  return targetElement
end

-- Get all links from current chat conversation
function obj.getChatMessageLinks()
  local app = hs.application.get("com.apple.MobileSMS")
  if not app then return end

  local linkElements = obj.getUIElement(app:mainWindow(), {
    { "AXSplitGroup", 1 },
    { "AXScrollArea", 2 },
    { "AXWebArea", 1 },
  })

  if not linkElements then return end

  local links = linkElements:attributeValue("AXLinkUIElements")
  if not links then return end

  local choices = {}
  for _, link in ipairs(links) do
    local children = link:attributeValue("AXChildren")
    if children and children[1] then
      local url = children[1]:attributeValue("AXValue")
      if url then table.insert(choices, { text = url }) end
    end
  end

  if utils.tlen(choices) == 0 then table.insert(choices, { text = "No Links" }) end

  dbg(I(choices), true)
end

return obj
