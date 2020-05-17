-- remaps certain keybindings in slack (desired -> original):
local log = hs.logger.new('bindings.slack', 'warning')

local cache  = { bindings = {} }
local module = { cache = cache, targetAppName = {'Slack'} }

local rebindKeys = function(appName, options)
  log.df('Rebinding keys for %s (%s)', hs.inspect(appName), hs.inspect(options))

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
      hs.eventtap.keyStroke({}, 'escape')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'cmd' }, 'r', function()
      hs.eventtap.keyStroke({}, 'escape')
    end)
    cache.bindings[appName] = hs.hotkey.bind({ 'ctrl' }, 'g', function()
      hs.eventtap.keyStroke({ 'cmd' }, 'k')
    end)
  end
end

module.start = function()
  cache.filter = hs.window.filter.new(module.targetAppName)
  -- cache.filter = hs.window.filter.new(false):setAppFilter('Slack')

  cache.filter:subscribe({
    hs.window.filter.windowFocused,
    hs.window.filter.windowUnfocused
  }, function(_, appName, event)
    if event == "windowFocused" then
      rebindKeys(appName, { enabled = (event == "windowFocused"), disabled = not (event == "windowFocused") })
    elseif event == "windowUnfocused" then
      rebindKeys(appName, { disabled = (event == "windowUnfocused"), enabled = not (event == "windowUnfocused") })
    end
  end)
end

module.stop = function()
  cache.filter:unsubscribeAll()
end

return module
