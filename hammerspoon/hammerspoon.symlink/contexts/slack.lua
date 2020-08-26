local cache  = {}
local module = { cache = cache, }
local wh = require('utils.wm.window-handlers')

local enter = function(log)
  cache.bindings:enter()

  log.df("entering slack hotkey modal..")

  cache.bindings:bind({ 'ctrl' }, 'j', function()
    hs.eventtap.keyStroke({ 'alt' }, 'down')
  end)
  cache.bindings:bind({ 'ctrl' }, 'k', function()
    hs.eventtap.keyStroke({ 'alt' }, 'up')
  end)
  cache.bindings:bind({ 'ctrl', 'shift' }, 'j', function()
    hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
  end)
  cache.bindings:bind({ 'ctrl', 'shift' }, 'k', function()
    hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
  end)
  cache.bindings:bind({ 'cmd' }, 'w', function()
    hs.eventtap.keyStroke({}, 'escape')
  end)
  cache.bindings:bind({ 'cmd' }, 'r', function()
    hs.eventtap.keyStroke({}, 'escape')
  end)
  cache.bindings:bind({ 'ctrl' }, 'g', function()
    hs.eventtap.keyStroke({ 'cmd' }, 'k')
  end)
end

local exit = function(log)
  cache.bindings:exit()

  log.df("exiting slack hotkey modal..")
end

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, log)
  local app = win:application()
  if app == nil then return end

  ----------------------------------------------------------------------
  -- set-up hotkey modal
  if cache.bindings == nil then
    cache.bindings = hs.hotkey.modal.new({}, nil)
  end

  if hs.fnutils.contains({"windowFocused"}, event) then
    enter(log)
    log.df("enabled bindings -> %s", #cache.bindings)
  elseif hs.fnutils.contains({"windowUnfocused"}, event) then
    exit(log)
    log.df("disabled bindings -> %s", #cache.bindings)
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
