local log = hs.logger.new('[contexts.slack]', 'debug')

local cache  = {}
local module = { cache = cache, }
local wh = require('utils.wm.window-handlers')

local enter = function()
  cache.bindings:enter()
  log.i("entering slack hotkey modal..")

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

local exit = function()
  cache.bindings:exit()
  log.i("exiting slack hotkey modal..")
end

-- apply(string, hs.window)
module.apply = function(event, win)
  log.df("applying [contexts.slack] for %s..", event)

  if cache.bindings == nil then
    cache.bindings = hs.hotkey.modal.new({}, nil, "slack bindings inbound..")
    log.df("creating hotkey modal -> %s", cache.bindings)
  end

  if hs.fnutils.contains({"windowFocused"}, event) then
    log.i("enabling bindings..")
    enter()
  else
    log.i("disabling bindings..")
    exit()
  end

  -- handle hide-after interval
  wh.hideAfterHandler(win, 5, event)
end

return module
