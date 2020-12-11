local log = hs.logger.new('[ext.alert]', 'warning')
local module = {}


-- default alert configuration
hs.alert.defaultStyle['textSize'] = 24
hs.alert.defaultStyle['radius'] = 20
hs.alert.defaultStyle['strokeColor'] = {
  white = 1,
  alpha = 0
}
hs.alert.defaultStyle['fillColor'] = {
  red   = 9/255,
  green = 8/255,
  blue  = 32/255,
  alpha = 0.9
}
hs.alert.defaultStyle['textColor'] = {
  red   = 209/255,
  green = 236/255,
  blue  = 240/255,
  alpha = 1
}
hs.alert.defaultStyle['textFont'] = 'JetBrainsMono Nerd Font'


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
