-- remaps certain keybindings in slack (desired -> original):

local cache  = { bindings = {} }
local module = { cache = cache }

local rebindKeys = function(appName, options)
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
  cache.filter = hs.window.filter.new({ 'Slack' })
  -- cache.filter = hs.window.filter.new(false):setAppFilter('Slack')

  cache.filter:subscribe({
    hs.window.filter.windowFocused,
    hs.window.filter.windowUnfocused
  }, function(_, appName, event)
    rebindKeys(appName, { enabled = (event == "windowFocused") })
  end)
end

module.stop = function()
  cache.filter:unsubscribeAll()
end

return module
