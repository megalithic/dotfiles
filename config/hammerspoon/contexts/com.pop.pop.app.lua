local obj = {}
local _appObj = nil
local utils = req("utils")
local enum = require("hs.fnutils")

obj.__index = obj
obj.name = "context.pop"
obj.debug = true
obj.launched = false

obj.modal = nil
obj.actions = {}

function obj:start(opts)
  opts = opts or {}
  _appObj = opts["appObj"]
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  if
    enum.contains(
      { hs.application.watcher.launched, hs.application.watcher.activated, hs.uielement.watcher.applicationActivated },
      event
    ) and not obj.launched
  then
    local pop = hs.application.get("com.pop.pop.app")
    req("utils").dnd(true, "zoom")
    hs.spotify.pause()
    req("ptt").setState("push-to-talk")
    req("watchers.dock").refreshInput("docked")

    local browser = req("browser")
    if browser.hasTab("pop.com") then
      browser.killTabsByDomain("pop.com")
      pop:activate()
    end

    obj.launched = true
  end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  if event == hs.application.watcher.terminated then
    req("ptt").setState("push-to-talk")
    req("utils").dnd(false, nil)

    local browser = hs.application.get(BROWSER)
    if browser ~= nil then
      local browser_win = browser:mainWindow()
      if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
    end

    local term = hs.application.get(TERMINAL)
    if term ~= nil then
      local term_win = term:mainWindow()
      if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
    end

    obj.launched = false
  end

  return self
end

return obj
