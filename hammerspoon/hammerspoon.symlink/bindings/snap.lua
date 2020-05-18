local log = hs.logger.new('[bindings.snap]', 'debug')

local module = {}

module.start = function()
  -- :: window-manipulation (manual window snapping)
  for _, snap in pairs(config.snap) do
    hs.hotkey.bind(snap.superKey, snap.shortcut, snap.locations)

    if (snap.hyperKey ~= nil) then
      hs.hotkey.bind(snap.hyperKey, snap.shortcut, snap.locations)
    end
  end
end

module.stop = function()
  -- nil
end

return module
