-- remaps certain keybindings in slack (desired -> original):
--
-- REF: https://github.com/bkudria/dotfiles/blob/develop/.hammerspoon/init.lua#L45-L51

local log = hs.logger.new('[bindings.slack]', 'debug')

local cache  = { bindings = {} }
local module = { cache = cache, targetAppName = 'Slack' }

local rebindKeys = function(appName, options)
  local enabled = options.enabled or false
  log.df("Rebinding for appName: %s, targetAppName: %s; enabled? %s; cached bindings? %s", appName, module.targetAppName, hs.inspect(enabled), hs.inspect(cache.bindings[appName]))

  if not enabled and cache.bindings[appName] then
    cache.bindings[appName]:disable()
    log.df('Should be disabling for %s and bindings %s', appName, hs.inspect(cache.bindings[appName]))

    return
  end

  if enabled and cache.bindings[appName] then
    cache.bindings[appName]:enable()

    -- log.df('Binding exists, and forced ENABLED; so enabling for %s and bindings %s', appName, hs.inspect(cache.bindings[appName]))
  -- elseif not enabled and cache.bindings[appName] then
    -- cache.bindings[appName]:disable()

    -- log.df('Binding exists, and forced DISABLED; so disabling for %s and bindings %s', appName, hs.inspect(cache.bindings[appName]))
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
      log.df('Executing binding for cmd+w for %s and bindings %s', appName, hs.inspect(cache.bindings[appName]))

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
  log.df("Starting [bindings.slack]..")
  cache.filter = hs.window.filter.new({module.targetAppName})

  cache.filter:subscribe({
      hs.window.filter.windowFocused,
      hs.window.filter.windowUnfocused
    }, function(_, appName, event)

      rebindKeys(module.targetAppName, { enabled = (event == "windowFocused") })
    end)
  end

  module.stop = function()
    log.df("Stopping [bindings.slack]..")

    cache.filter:unsubscribeAll()
  end

  return module
