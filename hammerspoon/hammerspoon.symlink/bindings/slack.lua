-- remaps certain keybindings in slack (desired -> original):
local log = hs.logger.new('bindings.slack', 'debug')

local cache  = { bindings = {} }
local module = { cache = cache, targetAppName = 'Slack' }

local rebindKeys = function(appName, options)
  print('bindings.slack - rebindKeys - appName: ' .. hs.inspect(appName))
  print('bindings.slack - rebindKeys - options: ' .. hs.inspect(options))
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
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl', 'shift' }, 'j', function()
      hs.eventtap.keyStroke({ 'alt', 'shift' }, 'down')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl', 'shift' }, 'k', function()
      hs.eventtap.keyStroke({ 'alt', 'shift' }, 'up')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'cmd' }, 'w', function()
      hs.eventtap.keyStroke({}, 'esc')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'cmd' }, 'r', function()
      hs.eventtap.keyStroke({}, 'esc')
    end)
    -- FIXME: this still affects kitty :P
    -- cache.bindings[appName] = hs.hotkey.bind({ 'ctrl' }, 'g', function()
    --   hs.eventtap.keyStroke({ 'cmd' }, 'k')
    -- end)
  end
end

module.start = function()
  cache.filter = hs.window.filter.new({ module.targetAppName })
  -- cache.filter = hs.window.filter.new(false):setAppFilter('Slack')

  cache.filter:subscribe({
    hs.window.filter.windowFocused,
    hs.window.filter.windowUnfocused
  }, function(_, appName, event)
    print('bindings.slack - appName: ' .. hs.inspect(appName))
    print('bindings.slack - module.targetAppName: ' .. hs.inspect(module.targetAppName))
    print('bindings.slack - event: ' .. hs.inspect(event))

    if event == "windowFocused" then
      rebindKeys(appName, { enabled = (event == "windowFocused") })
    elseif event == "windowUnfocused" then
      rebindKeys(appName, { disabled = (event == "windowUnfocused") })
    end
  end)
end

module.stop = function()
  cache.filter:unsubscribeAll()
end

return module
