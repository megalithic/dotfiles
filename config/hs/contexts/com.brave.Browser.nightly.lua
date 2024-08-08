local Settings = require("hs.settings")
local obj = {}

obj.__index = obj
obj.name = "context.brave.nightly"
obj.debug = true
obj.wfilter = {}

obj.modal = true
obj.actions = {}
function obj:start(opts)
  opts = opts or {}
  local appObj = opts["appObj"]
  local event = opts["event"]

  if event == hs.uielement.watcher.titleChanged then -- and _appObj:isRunning() then
    local winTitle = appObj:mainWindow():title()
    if string.match(winTitle, "Camera and microphone recording") then info(winTitle) end
  end

  if event == hs.application.watcher.activated then -- and _appObj:isRunning() then
    if obj.modal then obj.modal:enter() end

    obj.wfilter = hs.window.filter
      .new()
      :allowApp(appObj:name())
      :setAppFilter(appObj:name(), { allowTitles = { "Camera and microphone recording" } })
      :subscribe({
        ["windowDestroyed"] = function(win, appName, evt) dbg(true, { win, appName, evt }) end,
        ["windowTitleChanged"] = function(win, appName, evt) dbg(true, { win, appName, evt }) end,
      })
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  if event == hs.uielement.watcher.titleChanged then -- and _appObj:isRunning() then
    local winTitle = appObj:mainWindow():title()
    if string.match(winTitle, "Camera and microphone recording") then info(winTitle) end
  end

  return self
end

return obj
