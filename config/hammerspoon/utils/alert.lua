local obj = {}

obj.__index = obj
obj.name = "loader"

-- default alert configuration
hs.alert.defaultStyle["textSize"] = 24
hs.alert.defaultStyle["radius"] = 20
hs.alert.defaultStyle["strokeColor"] = {
  white = 1,
  alpha = 0,
}
hs.alert.defaultStyle["fillColor"] = {
  red = 9 / 255,
  green = 8 / 255,
  blue = 32 / 255,
  alpha = 0.9,
}
hs.alert.defaultStyle["textColor"] = {
  red = 209 / 255,
  green = 236 / 255,
  blue = 240 / 255,
  alpha = 1,
}
hs.alert.defaultStyle["textFont"] = "JetBrainsMono Nerd Font"

obj.defaultDuration = 2
obj.defaultScreen = hs.screen.primaryScreen()
obj.defaultSize = 24
obj.defaultRadius = 10

function obj.showOnly(opts)
  obj.close()
  obj.show({
    text = opts.text,
    image = opts.image or nil,
    duration = opts.duration,
    size = opts.size,
    screen = opts.screen,
  })
end

function obj.close() hs.alert.closeAll(0) end

function obj.show(opts)
  local text
  if type(opts) == "string" then
    text = opts
  else
    text = opts.text
  end
  local duration = opts.duration or obj.defaultDuration
  local screen = opts.screen or obj.defaultScreen
  local size = opts.size or obj.defaultSize
  local radius = opts.radius or obj.defaultRadius
  local image = opts.image or nil

  if image ~= nil then
    hs.alert.showWithImage(text, image, {
      textSize = size,
      radius = radius,
      textStyle = { paragraphStyle = { alignment = "center" } },
    }, screen, duration)
  else
    hs.alert.show(text, {
      textSize = size,
      radius = radius,
      textStyle = { paragraphStyle = { alignment = "center" } },
    }, screen, duration)
  end
end

return obj
