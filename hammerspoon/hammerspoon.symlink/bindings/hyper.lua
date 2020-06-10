local log = hs.logger.new('[bindings.hyper]', 'warning')

local module = {}
local forceLaunchOrFocus = require('ext.application').forceLaunchOrFocus
local smartLaunchOrFocus = require('ext.application').smartLaunchOrFocus
local toggle = require('ext.application').toggle
local media = require('bindings.media')

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

local appLaunchOrFocus = function(app)
  if app.hyper_key then
    log.df("hyper_key found for %s (%s)", app.name, app.hyper_key)
    hyper:bind({}, app.hyper_key, function() toggle(app.bundleID, false); end)
  end
end

local localBindingLaunchOrFocus = function(app)
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
            end
            )
        end
      end)
    end
  end
end

local vimNavigationKeyBindings = function()
  hyper:bind({'shift'}, 'h', nil, function() hyperArrowBindingsTap('left') end, function() hyperArrowBindingsTap('left') end)
  hyper:bind({'shift'}, 'j', nil, function() hyperArrowBindingsTap('down') end, function() hyperArrowBindingsTap('down') end)
  hyper:bind({'shift'}, 'k', nil, function() hyperArrowBindingsTap('up') end, function() hyperArrowBindingsTap('up') end)
  hyper:bind({'shift'}, 'l', nil, function() hyperArrowBindingsTap('right') end, function() hyperArrowBindingsTap('right') end)
end

local miscKeyBindings = function(misc)
  if misc.hyper_key and misc.fn ~= nil then
    log.df("hyper_key found for %s (%s)", misc.name, misc.hyper_key)
    hyper:bind(misc.hyper_mod, misc.hyper_key, misc.fn)
  end
end

module.start = function()
  log.df("starting..")
  hs.hotkey.bind({}, config.modifiers.hyper, pressed, released)

  for _, app in pairs(config.apps) do
    -- :: apps
    appLaunchOrFocus(app)

    -- :: local_bindings
    localBindingLaunchOrFocus(app)
  end

  -- :: vim movements
  -- TODO: figure out why `NSGlobalDomain KeyRepeat -int 1` doesn't affect the repeatfn interval..
  vimNavigationKeyBindings()

  -- :: misc (utilities)
  for _, misc in pairs(config.utilities) do
    miscKeyBindings(misc)
  end

  -- :: media (spotify/volume)
  for _, media in pairs(config.media) do
    hyper:bind(media.hyper_mod, media.hyper_key, function() media.spotify(media.action, media.label) end)
  end

  -- :: volume control
  for _, vol in pairs(config.volume) do
    hyper:bind(vol.hyper_mod, vol.hyper_key, function() media.adjustVolume(vol) end)
  end
end

module.stop = function()
  log.df("stopping..")
end

return module
