local log = hs.logger.new('[contexts.slack]', 'debug')

local cache  = {}
local module = { cache = cache, }
local wh = require('utils.wm.window-handlers')

local rules = {
    {title = 'Slack Call Minipanel', rule = 'ignore'},
}

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
  log.df("applying [contexts.slack] for %s (%s)..", event, win:title())

  ----------------------------------------------------------------------
  -- set-up hotkey modal
  if cache.bindings == nil then
    cache.bindings = hs.hotkey.modal.new({}, nil, "slack bindings inbound..")
    log.df("creating hotkey modal -> %s", cache.bindings)
  end

  if hs.fnutils.contains({"windowFocused"}, event) then
    log.i("enabling bindings..")
    enter()
  else -- FIXME: too naive on the events with disable with
    log.i("disabling bindings..")
    exit()
  end

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 5, event)

  ----------------------------------------------------------------------
  -- handle window rules
  local app = win:application()
  if app == nil then return end

  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil then return end

  if not hs.fnutils.contains({"windowDestroyed"}, event) then
    wh.applyRules(rules, win, appConfig)
  end
end

return module
