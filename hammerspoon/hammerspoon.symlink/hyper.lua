-- Set the key you want to be HYPER to F19 in karabiner or keyboard
local hyper = hs.hotkey.modal.new({}, nil)
local config = require('config')

local pressedHyper = function()
  hyper:enter()
end

local releasedHyper = function()
  hyper:exit()
end

-- Bind the Hyper key
hs.hotkey.bind({}, 'F19', pressedHyper, releasedHyper)

local launch = function(app)
  hs.application.launchOrFocusByBundleID(app.hint)
end

for _, app in pairs(config.apps) do
  -- Apps that I want to jump to
  if app.hyper_shortcut then
    hyper:bind({}, app.hyper_shortcut, function() launch(app); end)
  end

  -- I use hyper to power some shortcuts in different apps If the app is closed
  -- and I press the shortcut, open the app and send the shortcut, otherwise
  -- just send the shortcut.
  if app.local_bindings then
    for _, key in pairs(app.local_bindings) do
      hyper:bind({}, key, nil, function()
        if hs.application.find(app.hint) then
          hs.eventtap.keyStroke({'cmd','alt','shift','ctrl'}, key)
        else
          launch(app)
          hs.timer.waitWhile(
            function() return hs.application.find(app.hint) == nil end,
            function()
              hs.eventtap.keyStroke({'cmd','alt','shift','ctrl'}, key)
            end)
        end
      end)
    end
  end
end


return hyper
