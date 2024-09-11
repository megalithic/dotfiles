local Settings = require("hs.settings")
local obj = {}
local _appObj = nil

--- Entity.renderScriptTemplate(script[, viewModel]) -> string
--- Method
--- Generates an applescript from templates located in `src/osascripts` with some view model object
---
--- Parameters:
---  * `scriptPath` - The absolute file path to the applescript file or the name of an existing Ki applescript file (in src/osascripts)
---  * `viewModel` - An optional [lustache](http://olivinelabs.com/lustache/) view model
---
--- Returns:
---  * The rendered script string or `nil`
-- function obj.renderScriptTemplate(script, viewModel)
--   viewModel = viewModel or {}
--
--   local scriptPath = script
--
--   local success, file = pcall(function() return assert(io.open(scriptPath, "rb")) end)
--
--   if not success or not file then
--     error("Unable to render script template for the script", script)
--     return nil
--   end
--
--   local scriptTemplate = file:read("*all")
--
--   file:close()
--
--   return lustache:render(scriptTemplate, viewModel)
-- end
--
-- local arcTabsScriptPath = "/scripts/arc-tabs.applescript"
-- local script = Application.renderScriptTemplate(arcTabsScriptPath)

obj.__index = obj
obj.name = "context.brave.nightly"
obj.debug = true
obj.wfilter = {}

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

  -- obj.modal:bind({ "ctrl" }, "j", nil, messageDown, nil, messageDown)
  -- obj.modal:bind({ "ctrl" }, "k", nil, messageUp, nil, messageUp)
  --
  -- -- move up and down slacks (read or unread)
  -- obj.modal:bind({ "ctrl" }, "n", nil, slackDown, nil, slackDown)
  -- obj.modal:bind({ "ctrl" }, "p", nil, slackUp, nil, slackUp)
  --
  -- -- misc
  -- obj.modal:bind({ "ctrl" }, "h", nil, focus.mainMessageBox, nil, focus.mainMessageBox)
  -- obj.modal:bind({ "ctrl" }, "l", nil, focus.threadMessageBox, nil, focus.threadMessageBox)
  --
  -- -- move up and down unread slacks
  -- obj.modal:bind({ "ctrl", "shift" }, "j", function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", _appObj) end)
  -- obj.modal:bind({ "ctrl", "shift" }, "k", function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", _appObj) end)
  -- obj.modal:bind({ "ctrl", "cmd" }, "n", function() hs.eventtap.keyStroke({ "alt", "shift" }, "down", _appObj) end)
  -- obj.modal:bind({ "ctrl", "cmd" }, "p", function() hs.eventtap.keyStroke({ "alt", "shift" }, "up", _appObj) end)
  --
  -- -- "better" jump to a thing
  -- obj.modal:bind({ "ctrl" }, "g", function() hs.eventtap.keyStroke({ "cmd" }, "k", _appObj) end)
  --
  -- -- "better" find a thing
  -- obj.modal:bind({ "ctrl" }, "/", function() hs.eventtap.keyStroke({ "cmd" }, "f", _appObj) end)
  --
  -- -- no-ops:
  -- obj.modal:bind({ "cmd" }, "w", function() hs.eventtap.keyStroke({}, "escape", _appObj) end)
  -- obj.modal:bind({ "cmd" }, "r", function() hs.eventtap.keyStroke({}, "escape", _appObj) end)
  --
  -- obj.modal:bind({ "ctrl" }, "r", nil, startSlackReminder, nil, startSlackReminder)
  -- obj.modal:bind({ "ctrl" }, "t", nil, openSlackThread, nil, openSlackThread)
  -- obj.modal:bind({ "shift", "cmd" }, "delete", nil, focus.leaveChannel, nil, nil)

  dbg(event)

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end

    -- obj.wfilter = hs.window.filter
    --   .new()
    --   :allowApp(appObj:name())
    --   :setAppFilter(appObj:name(), { allowTitles = { "https:?://meet.google.com/*" } })
    --   :subscribe({
    --     ["windowDestroyed"] = function(win, appName, evt) dbg({ win, appName, evt }) end,
    --     ["windowTitleChanged"] = function(win, appName, evt) dbg({ win, appName, evt }) end,
    --   })
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
