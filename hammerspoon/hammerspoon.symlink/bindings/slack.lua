-- remaps the following in slack (desired -> original):
--
-- ({'ctrl'},          'k', {'alt'},          'up')
-- ({'ctrl'},          'j', {'alt'},          'down')
-- ({'ctrl'},          'g', {'cmd'},          'k')
-- ({'ctrl', 'shift'}, 'k', {'alt', 'shift'}, 'down')
-- ({'ctrl', 'shift'}, 'j', {'alt', 'shift'}, 'up')
-- ({'cmd'},           'w', {},               'esc')

local cache  = { bindings = {} }
local module = { cache = cache }

local rebindCtrlI = function(appName, options)
  local enabled = options.enabled or false

  if not enabled and cache.bindings[appName] then
    cache.bindings[appName]:disable()
    return
  end

  if cache.bindings[appName] then
    cache.bindings[appName]:enable()
  else
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl' }, 'j', function()
      hs.eventtap.keyStroke({ 'alt' }, 'down')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl' }, 'k', function()
      hs.eventtap.keyStroke({ 'alt' }, 'up')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl' }, 'g', function()
      hs.eventtap.keyStroke({ 'cmd' }, 'k')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl', 'shift' }, 'j', function()
      hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl', 'shift' }, 'k', function()
      hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'cmd' }, 'w', function()
      hs.eventtap.keyStroke({}, 'esc')
    end)
  end
end

module.start = function()
  cache.filter = hs.window.filter.new({ 'Slack' })

  cache.filter:subscribe({
    hs.window.filter.windowFocused,
    hs.window.filter.windowUnfocused
  }, function(_, appName, event)
    rebindCtrlI(appName, { enabled = (event == "windowFocused") })
  end)
end

module.stop = function()
  cache.filter:unsubscribeAll()
end

return module
