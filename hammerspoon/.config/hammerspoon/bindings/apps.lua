local log = hs.logger.new('[bindings.apps]', 'debug')

local module = {}

local toggle = require('ext.application').toggle
local focusOnly = require('ext.application').focusOnly

module.start = function()
  for bundleID, app_config in pairs(config.apps) do
    if app_config.modifier ~= nil and app_config.shortcut ~= nil then
      hs.hotkey.bind(app_config.modifier, app_config.shortcut, function()
        log.df('Toggling or focusing %s (%s) - %s %s (launchMode: %s)', hs.inspect(app_config.name), bundleID, hs.inspect(app_config.modifier), hs.inspect(app_config.shortcut), hs.inspect(app_config.launchMode))

        if app_config.launchMode ~= nil then
          if app_config.launchMode == 'focus' then
            focusOnly(bundleID)
          else
            toggle(bundleID)
          end
        else
          toggle(bundleID)
        end
      end)
    end
  end
end

module.stop = function()
  -- nil
end

return module
