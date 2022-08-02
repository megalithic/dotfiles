local UI = require("utils.ui")
local fuzzyChooser = require("utils.fuzzychooser")
local Settings = require("hs.settings")
local mods = Settings.get(CONFIG_KEY).keys.mods

local obj = {}
local _appObj = nil
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
  deleteConversation = {
    action = function() _appObj:selectMenuItem({ "File", "Delete Conversation…" }) end,
    hotkey = { "cmd", "delete" },
  },
  nextConversation = {
    action = function() _appObj:selectMenuItem({ "Window", "Go to Next Conversation" }) end,
    hotkey = { mods.casC, "n" },
  },
  prevConversation = {
    action = function() _appObj:selectMenuItem({ "Window", "Go to Previous Conversation" }) end,
    hotkey = { mods.casC, "p" },
  },
}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  if obj.modal then
    -- bind cmd-1 bindings to ctrl-1 (my preferred)
    -- for i = 1, 10 do
    --   obj.modal:bind(mods.casC, i, function() hs.eventtap.keyStroke(mods.Casc, i, _appObj) end)
    -- end

    obj.modal:enter()
  end

  note(fmt("[START] %s: %s", obj.name, opts))

  return self
end

function obj:stop()
  if obj.modal then obj.modal:exit() end

  note(fmt("[STOP] %s: %s", obj.name, self))

  return self
end

return obj
