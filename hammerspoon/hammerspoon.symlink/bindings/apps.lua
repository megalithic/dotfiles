local log = hs.logger.new('[bindings.apps]', 'warning')

local module = {}

local smartLaunchOrFocus = require('ext.application').smartLaunchOrFocus
local forceLaunchOrFocus = require('ext.application').forceLaunchOrFocus
local toggle = require('ext.application').toggle

module.start = function()
  -- application toggling
  for bundleID, app_config in pairs(config.apps) do
    if app_config.modifier ~= nil and app_config.shortcut ~= nil then
      hs.hotkey.bind(app_config.modifier, app_config.shortcut, function()
        log.df('Toggling %s (%s) - %s %s', hs.inspect(app_config.name), bundleID, hs.inspect(app_config.modifier), hs.inspect(app_config.shortcut))
        toggle(bundleID)
      end)
    end
  end
end

module.stop = function()
  -- nil
end

return module
