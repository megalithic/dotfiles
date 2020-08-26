local module = {}

local wh = require('utils.wm.window-handlers')

local enter = function(modal)
  modal:bind({ 'ctrl' }, 'j', function()
    hs.eventtap.keyStroke({ 'alt' }, 'down')
  end)
  modal:bind({ 'ctrl' }, 'k', function()
    hs.eventtap.keyStroke({ 'alt' }, 'up')
  end)
  modal:bind({ 'ctrl', 'shift' }, 'j', function()
    hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
  end)
  modal:bind({ 'ctrl', 'shift' }, 'k', function()
    hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
  end)
  modal:bind({ 'cmd' }, 'w', function()
    hs.eventtap.keyStroke({}, 'escape')
  end)
  modal:bind({ 'cmd' }, 'r', function()
    hs.eventtap.keyStroke({}, 'escape')
  end)
  modal:bind({ 'ctrl' }, 'g', function()
    hs.eventtap.keyStroke({ 'cmd' }, 'k')
  end)

  modal:enter()
end

local exit = function(modal)
  modal:exit()
end

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, log)
  local app = win:application()
  if app == nil then return end

  local modal = hs.hotkey.modal.new({}, nil)

  ----------------------------------------------------------------------
  -- set-up hotkey modal
  if hs.fnutils.contains({"windowFocused"}, event) then
    enter(modal)
    log.df("%s::enabled modal bindings -> %s", app:bundleID(), #modal.keys)
  elseif hs.fnutils.contains({"windowUnfocused"}, event) then
    exit(modal)
    log.df("%s::disabled modal bindings -> %s", app:bundleID(), #modal.keys)
  end

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 5, event)

  ----------------------------------------------------------------------
  -- handle window rules
  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil or appConfig.rules == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
    wh.applyRules(appConfig.rules, win, appConfig)
  end
end

return module
