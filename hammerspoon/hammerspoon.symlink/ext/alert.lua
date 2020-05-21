-- TODO: move hs.alert config from init.lua to this module

local log = hs.logger.new('[ext.alert]', 'debug')
local module = {}

module.defaultDuration = 2
module.defaultScreen = hs.screen.primaryScreen()
module.defaultSize = 24

function module.showOnly(opts)
  module.close()
  module.show({ text=opts.text, duration=opts.duration, size=opts.size })
end

function module.close()
  hs.alert.closeAll(0)
end

function module.show(opts)
  local duration = opts.duration or module.defaultDuration
  local screen = opts.screen or module.defaultScreen
  local size = opts.size or module.defaultSize
  local radius = size - 4

  hs.alert.show(
      opts.text,
      {
        textSize = size,
        radius   = radius,
        textStyle = { paragraphStyle = { alignment = "center" } },
      },
      screen,
      duration
    )
end

return module
