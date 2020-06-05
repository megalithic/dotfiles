-- remaps certain keybindings in slack (desired -> original):

local log = hs.logger.new('[bindings.slack]', 'debug')

local cache  = {}
local module = { cache = cache, targetAppName = 'Slack' }

module.start = function()
  log.df("starting..")

  cache.slack  = hs.hotkey.modal.new({}, nil)
  cache.filter = hs.window.filter.new({module.targetAppName})

  cache.filter
  :subscribe({hs.window.filter.windowCreated, hs.window.filter.windowFocused}, function(win, appName, event)
    log.df("slack binding event: %s", event)
    if appName == module.targetAppName then
      cache.slack:enter()

      cache.slack:bind({ 'ctrl' }, 'j', function()
        hs.eventtap.keyStroke({ 'alt' }, 'down')
      end)
      cache.slack:bind({ 'ctrl' }, 'k', function()
        hs.eventtap.keyStroke({ 'alt' }, 'up')
      end)
      cache.slack:bind({ 'ctrl', 'shift' }, 'j', function()
        hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
      end)
      cache.slack:bind({ 'ctrl', 'shift' }, 'k', function()
        hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
      end)
      cache.slack:bind({ 'cmd' }, 'w', function()
        hs.eventtap.keyStroke({}, 'escape')
      end)
      cache.slack:bind({ 'cmd' }, 'r', function()
        hs.eventtap.keyStroke({}, 'escape')
      end)
      cache.slack:bind({ 'ctrl' }, 'g', function()
        hs.eventtap.keyStroke({ 'cmd' }, 'k')
      end)
    end
  end)
  :subscribe({hs.window.filter.windowDestroyed, hs.window.filter.windowUnfocused}, function(_, appName, event)
    log.df("slack binding event: %s", event)
    cache.slack:exit()
  end)
end

module.stop = function()
  log.df("stopping..")

  cache.slack:exit()
end

return module
