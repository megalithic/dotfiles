local log = hs.logger.new('bindings.apps', 'debug')
local module = {}

module.start = function()
  -- application toggling
  for bundleID, app_config in pairs(config.apps) do
    if app_config.superKey ~= nil and app_config.shortcut ~= nil then
      hs.hotkey.bind(app_config.superKey, app_config.shortcut, function()
        keys.toggle(bundleID)
        log.df('Toggling %s with bindings: %s %s', bundleID, hs.inspect(app_config.superKey), hs.inspect(app_config.shortcut))
      end)
    end

    -- TODO: future hyper key things?
    -- if (app.hyperKey ~= nil) then
    --   hotkey.bind(app.hyperKey, app.shortcut, app.locations)
    -- end
  end
end

module.stop = function()
  -- nil
end

return module
