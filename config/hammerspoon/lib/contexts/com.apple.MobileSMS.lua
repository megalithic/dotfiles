local UI = require("utils.ui")
local fuzzyChooser = require("utils.fuzzychooser")
local Settings = require("hs.settings")
local mods = C.keys.mods

local obj = {}
local _appObj = nil
local _appModal = nil

obj.__index = obj
obj.name = "context.messages"
obj.debug = true

local function chooserCallback(choice) os.execute(string.format([["/usr/bin/open" "%s"]], choice.text)) end

local function getChatMessageLinks(appObj)
  local linkElements = UI.getUIElement(appObj:mainWindow(), {
    { "AXSplitGroup", 1 },
    { "AXScrollArea", 2 },
    { "AXWebArea", 1 },
  }):attributeValue("AXLinkUIElements")
  local choices = {}
  for _, link in ipairs(linkElements) do
    local url = link:attributeValue("AXChildren")[1]:attributeValue("AXValue")
    table.insert(choices, { text = url })
  end
  if U.tlen(choices) == 0 then table.insert(choices, { text = "No Links" }) end
  fuzzyChooser:start(chooserCallback, choices, { "text" })
end

obj.modal = true
obj.actions = {
  getMessageLinks = {
    action = function() getChatMessageLinks(_appObj) end,
    hotkey = { "alt", "o" },
  },
  nextConversation = {
    -- action = function() _appObj:selectMenuItem({ "Window", "Go to Next Conversation" }) end,
    action = function() hs.eventtap.keyStroke({ "cmd", "shift" }, "]") end,
    hotkey = { mods.casC, "n" },
  },
  prevConversation = {
    -- action = function() _appObj:selectMenuItem({ "Window", "Go to Previous Conversation" }) end,
    action = function() hs.eventtap.keyStroke({ "cmd", "shift" }, "[") end,
    hotkey = { mods.casC, "p" },
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
}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if event == hs.application.watcher.activated then
    if obj.modal then obj.modal:enter() end
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  obj.modal:exit()

  return self
end

return obj
