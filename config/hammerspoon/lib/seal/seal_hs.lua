-- luacheck: no self
local obj = {}
obj.__index = obj
obj.__name = "seal_hammerspoon"
obj.__icon = hs.image.imageFromAppBundle("org.hammerspoon.Hammerspoon")
obj.__logger = hs.logger.new(obj.__name)
obj.__caffeine = nil

function obj.clipboardToFile()
  local success, _, _ =
    hs.applescript([[do shell script "open 'hammerspoon://clipboard?clipboard=/tmp/clipboard.json"]])
  if not success then obj.__logger.e("Got an error while opening Hammerspoon/Clipboard url handler.") end
end

function obj.clearClipboard()
  local success, _, _ = hs.applescript([[do shell script "open 'hammerspoon://clipboard?clear_all=True'"]])
  if not success then obj.__logger.e("Got an error while opening Hammerspoon/Clipboard url handler.") end
end

-- local secrets = require("secrets")
-- obj.headphones_mac = secrets.headphones_mac
--
-- function obj.connectToHeadphones()
--   local path = "/run/current-system/sw/bin/blueutil"
--   if hs.fs.displayName(path) == nil then path = "/opt/homebrew/bin/blueutil" end
--   local function f()
--     local success, _, errors =
--       hs.applescript([[do shell script "]] .. path .. [[ --connect ]] .. secrets.headphones_mac .. [["]])
--     if not success then
--       obj.__logger.e("Got an error while connecting to headphones: " .. errors["OSAScriptErrorMessageKey"])
--     end
--   end
--   U.spawn(f)
-- end

function obj.showCaffeineMenubar(isEnabled)
  if isEnabled == nil then isEnabled = hs.caffeinate.get("displayIdle") end
  if isEnabled then
    if obj.__caffeine ~= nil then return end
    obj.__caffeine = hs.menubar.new():setIcon("icons/caffeine-on.pdf"):setTooltip("Caffine is active"):setMenu({
      { title = "Caffine is active", disabled = true },
      { title = "-" },
      { title = "Disable Caffeine", fn = obj.toggleCaffeine },
    })
  else
    if obj.__caffeine == nil then return end
    obj.__caffeine:delete()
    obj.__caffeine = nil
  end
end

function obj.toggleCaffeine() obj.showCaffeineMenubar(hs.caffeinate.toggle("displayIdle")) end

function obj.toggleForceBuiltInInput() require("audio").toggleForceBuiltInInput() end

obj.cmds = {
  { text = "Save Clipboard to File", type = "clipboardToFile" },
  { text = "Clear Clipboard", type = "clearClipboard" },
  { text = "Toggle Caffeine", type = "toggleCaffeine" },
  { text = "Toggle Force Built-in Input", type = "toggleForceBuiltInInput" },
  { text = "Connect to Headphones", type = "connectToHeadphones" },
}

function obj:commands()
  return {
    hs = {
      cmd = "hs",
      fn = obj.choicesMacOS,
      name = "Hammerspoon command",
      description = "Send a command to Hammerspoon",
      plugin = obj.__name,
      icon = obj.__icon,
    },
  }
end

function obj:bare() return nil end

function obj.choicesMacOS(query)
  query = query:lower()
  local choices = {}

  for _, command in pairs(obj.cmds) do
    if string.match(command.text:lower(), query) or string.match((command.subText or ""):lower(), query) then
      command["plugin"] = obj.__name
      command["image"] = obj.__icon
      table.insert(choices, command)
    end
  end
  table.sort(choices, function(a, b) return a["text"] < b["text"] end)

  return choices
end

function obj.completionCallback(row_info)
  if not row_info then return end
  obj[row_info.type]()
end

obj.showCaffeineMenubar()
return obj
