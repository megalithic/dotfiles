local cache  = {}

-- FIXME: figure out why/where/how/when to instantiate our modal for correct
-- enabling/disabling of bindings for our various window events. Presently, it
-- works, but we're instantiating THREE TIMES!!1!1!
cache.modal = hs.hotkey.modal.new({}, nil)

local module = { cache = cache }
local wh = require('utils.wm.window-handlers')

local enter = function(log)
  log.df("entering slack hotkey modal..")

  cache.modal:bind({ 'ctrl' }, 'j', function()
    hs.eventtap.keyStroke({ 'alt' }, 'down')
  end)
  cache.modal:bind({ 'ctrl' }, 'k', function()
    hs.eventtap.keyStroke({ 'alt' }, 'up')
  end)
  cache.modal:bind({ 'ctrl', 'shift' }, 'j', function()
    hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
  end)
  cache.modal:bind({ 'ctrl', 'shift' }, 'k', function()
    hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
  end)
  cache.modal:bind({ 'cmd' }, 'w', function()
    hs.eventtap.keyStroke({}, 'escape')
  end)
  cache.modal:bind({ 'cmd' }, 'r', function()
    hs.eventtap.keyStroke({}, 'escape')
  end)
  cache.modal:bind({ 'ctrl' }, 'g', function()
    hs.eventtap.keyStroke({ 'cmd' }, 'k')
  end)

  cache.modal:enter()
end

local exit = function(log)
  log.df("exiting slack hotkey modal..")

  cache.modal:exit()
end

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, log)
  local app = win:application()
  if app == nil then return end

  ----------------------------------------------------------------------
  -- set-up hotkey modal
  if hs.fnutils.contains({"windowFocused"}, event) then
    if win:application():isFrontmost() then
      cache.modal = hs.hotkey.modal.new({}, nil)
      enter(log)
      log.df("enabled bindings -> %s", #cache.modal.keys)
    end
  elseif hs.fnutils.contains({"windowUnfocused"}, event) then
    if not win:application():isFrontmost() then
      exit(log)
      log.df("disabled bindings -> %s", #cache.modal.keys)
      cache.modal = hs.hotkey.modal.new({}, nil)
    end
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
