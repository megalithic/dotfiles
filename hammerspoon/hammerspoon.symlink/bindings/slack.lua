-- remaps certain keybindings in slack (desired -> original):

local log = hs.logger.new('[bindings.slack]', 'warning')

local cache  = {}
local module = { cache = cache, targetAppName = 'Slack' }

module.start = function()
  log.df("Starting [bindings.slack]..")

  cache.slack  = hs.hotkey.modal.new({}, nil)
  cache.filter = hs.window.filter.new({module.targetAppName})

  cache.filter
  :subscribe(hs.window.filter.windowFocused, function(win, appName, event)
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
  :subscribe(hs.window.filter.windowUnfocused , function(_, appName, event)
    cache.slack:exit()
  end)
end

module.stop = function()
  log.df("Stopping [bindings.slack]..")

  cache.slack:exit()
end

return module
