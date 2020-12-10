local log = hs.logger.new('[bindings.tabjump]', 'debug')
local module = {}

local browser = require('bindings.browser')

module.start = function()
  for _, appConfig in pairs(config.apps) do
    if appConfig.modifier ~= nil and appConfig.shortcut ~= nil then

      if (appConfig.tabjump ~= nil) then
        hs.hotkey.bind(appConfig.modifier, appConfig.shortcut, function()
          browser.jump(appConfig.tabjump)
        end)
      end

    end
  end
end

module.stop = function()
  -- nil
end

return module
