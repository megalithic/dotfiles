local log = hs.logger.new('[bindings.snap]', 'warning')
local chain = require('ext.window').chain

local module = {}

module.start = function()
  -- :: window-manipulation (manual window snapping)
  for _, snap in pairs(config.snap) do
    hs.hotkey.bind(snap.modifier, snap.shortcut, chain(snap.locations))
  end
end

module.stop = function()
  -- nil
end

return module
