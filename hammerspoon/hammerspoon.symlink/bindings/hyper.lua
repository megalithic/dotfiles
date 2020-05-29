local log = hs.logger.new('[bindings.hyper]', 'debug')

local module = {}

local Modal = require('ext.modal')

-- Set the key you want to be HYPER to F19 in karabiner or keyboard
-- local hyperModal = hs.hotkey.modal.new({}, nil)
local hyperModal = Modal:new({
    name = 'hyper',
    timeout = 0
  })

local pressed = function()
  hyperModal.modal:enter()
end

local released = function()
  hyperModal.modal:exit()
end

local launch = function(app)
  log.df("hyper launching app %s (%s)", app.name, app.id)

  hs.application.launchOrFocusByBundleID(app.id)
end

module.start = function()
  log.df("Starting [bindings.hyper]..")

  -- Bind the Hyper key to the hammerspoon modal
  hs.hotkey.bind({}, config.modifiers.hyper, pressed, released)

  -- Use the hyper key with the application config to use the `hyper_key`
  for _, app in pairs(config.apps) do
    -- Apps that I want to jump to
    if app.hyper_key then
      log.df("hyper_key found for %s (%s)", app.name, app.hyper_key)

      hyperModal:bind({}, app.hyper_key, function() launch(app); end)
    end

    -- I use hyper to power some shortcuts in different apps If the app is closed
    -- and I press the shortcut, open the app and send the shortcut, otherwise
    -- just send the shortcut.
    if app.local_bindings then
      for _, key in pairs(app.local_bindings) do
        hyperModal:bind({}, key, nil, function()
          if hs.application.find(app.id) then
            hs.eventtap.keyStroke(config.modifiers.ultra, key)
          else
            launch(app)

            hs.timer.waitWhile(
              function() return hs.application.find(app.id) == nil end,
              function()
                hs.eventtap.keyStroke(config.modifiers.ultra, key)
              end)
          end
        end)
      end
    end
  end
end

module.stop = function()
  log.df("Stopping [bindings.hyper]..")
end

return module
