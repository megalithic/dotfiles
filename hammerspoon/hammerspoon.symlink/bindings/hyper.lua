local log = hs.logger.new('[bindings.hyper]', 'warning')

local module = {}
local forceLaunchOrFocus = require('ext.application').forceLaunchOrFocus
local smartLaunchOrFocus = require('ext.application').smartLaunchOrFocus
local toggle = require('ext.application').toggle

local hyper = hs.hotkey.modal.new({}, nil)

-- Set the key you want to be HYPER to F19 in karabiner or keyboard

local pressed = function()
  hyper:enter()
end

local released = function()
  hyper:exit()
end

local hyperLocalBindingsTap = function(key)
  return hs.eventtap.keyStroke(config.modifiers.ultra, key)
end

local hyperArrowBindingsTap = function(key)
  return hs.eventtap.keyStroke({}, key)
end

-- Bind the Hyper key to the hammerspoon modal

module.start = function()
  log.df("starting..")
  hs.hotkey.bind({}, config.modifiers.hyper, pressed, released)

  -- Use the hyper key with the application config to use the `hyper_key`
  for _, app in pairs(config.apps) do
    -- Apps that I want to jump to
    if app.hyper_key then
      log.df("hyper_key found for %s (%s)", app.name, app.hyper_key)
      hyper:bind({}, app.hyper_key, function() toggle(app.bundleID, false); end)
    end

    -- I use hyper to power some shortcuts in different apps If the app is closed
    -- and I press the shortcut, open the app and send the shortcut, otherwise
    -- just send the shortcut.
    if app.local_bindings then
      for _, key in pairs(app.local_bindings) do
        log.df("hyper local_bindings found for %s (%s)", app.name, hs.inspect(app.local_bindings))

        hyper:bind({}, key, nil, function()
          if hs.application.find(app.bundleID) then
            log.df("hyper local_bindings tap %s (%s)", app.name, app.bundleID)
            hyperLocalBindingsTap(key)
          else
            toggle(app.bundleID, false)
            hs.timer.waitWhile(
              function() return hs.application.find(app.bundleID) == nil end,
              function()
                hyperLocalBindingsTap(key)
              end)
            end
          end)
        end
      end
    end

    -- Bind arrow keys to standard vim bindings

    hyper:bind({'shift'}, 'h', function() hyperArrowBindingsTap('left') end)
    hyper:bind({'shift'}, 'j', function() hyperArrowBindingsTap('down') end)
    hyper:bind({'shift'}, 'k', function() hyperArrowBindingsTap('up') end)
    hyper:bind({'shift'}, 'l', function() hyperArrowBindingsTap('right') end)
  end

  module.stop = function()
    log.df("stopping..")
    -- nil
  end

  return module
