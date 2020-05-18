local log = hs.logger.new('[bindings.snap]', 'debug')
local chain = require('ext.window').chain

local module = {}

module.start = function()
  -- :: window-manipulation (manual window snapping)
  for _, snap in pairs(config.snap) do

    hs.hotkey.bind(snap.superKey, snap.shortcut, function() chain(snap.locations)() end)

    if (snap.hyperKey ~= nil) then
      hs.hotkey.bind(snap.hyperKey, snap.shortcut, function() chain(snap.locations)() end)
    end
  end
end

module.stop = function()
  -- nil
end

return module
