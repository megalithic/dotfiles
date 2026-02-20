local M = {}

---@class CircleOpts
---@field x number
---@field y number
---@field radius? number
---@field color? table
---@field id? string

---@class RectangleOpts
---@field x number
---@field y number
---@field w number
---@field h number
---@field color? table
---@field radius? number
---@field id? string

---@class TextOpts
---@field y number
---@field text string
---@field x? number
---@field width? number|string
---@field color? table
---@field fontSize? number
---@field alignment? string
---@field id? string

---@class SFSymbolOpts
---@field x number
---@field y number
---@field symbol string
---@field size? number
---@field color? string
---@field id? string

---@class WaveformOpts
---@field x number
---@field y number
---@field barCount? number
---@field barWidth? number
---@field maxHeight? number
---@field spacing? number
---@field color? table
---@field idPrefix? string

---@class WaveformInfo
---@field barCount number
---@field barWidth number
---@field maxHeight number
---@field baseY number
---@field idPrefix string

---@param canvas hs.canvas
---@param opts CircleOpts
function M.circle(canvas, opts)
  assert(opts.x, "circle requires opts.x")
  assert(opts.y, "circle requires opts.y")
  
  canvas:appendElements({
    id = opts.id or "circle",
    type = "circle",
    action = "fill",
    fillColor = opts.color or { red = 1, green = 0.23, blue = 0.19, alpha = 1 },
    center = { x = opts.x, y = opts.y },
    radius = opts.radius or 20,
  })
end

---@param canvas hs.canvas
---@param opts RectangleOpts
function M.rectangle(canvas, opts)
  assert(opts.x, "rectangle requires opts.x")
  assert(opts.y, "rectangle requires opts.y")
  assert(opts.w, "rectangle requires opts.w")
  assert(opts.h, "rectangle requires opts.h")
  
  local element = {
    id = opts.id or "rectangle",
    type = "rectangle",
    action = "fill",
    fillColor = opts.color or { white = 1, alpha = 1 },
    frame = { x = opts.x, y = opts.y, w = opts.w, h = opts.h },
  }
  if opts.radius then
    element.roundedRectRadii = { xRadius = opts.radius, yRadius = opts.radius }
  end
  canvas:appendElements(element)
end

---@param canvas hs.canvas
---@param opts TextOpts
function M.text(canvas, opts)
  assert(opts.y, "text requires opts.y")
  assert(opts.text, "text requires opts.text")
  
  local fontSize = opts.fontSize or 12
  canvas:appendElements({
    id = opts.id or "text",
    type = "text",
    text = opts.text,
    textColor = opts.color or { white = 1, alpha = 0.8 },
    textFont = ".AppleSystemUIFont",
    textSize = fontSize,
    textAlignment = opts.alignment or "center",
    frame = {
      x = opts.x or 0,
      y = opts.y,
      w = opts.width or "100%",
      h = fontSize + 4,
    },
  })
end

---@param canvas hs.canvas
---@param opts SFSymbolOpts
function M.sfSymbol(canvas, opts)
  assert(opts.x, "sfSymbol requires opts.x")
  assert(opts.y, "sfSymbol requires opts.y")
  assert(opts.symbol, "sfSymbol requires opts.symbol")
  
  local ok, sfsymbol = pcall(require, "lib.hud.sfsymbol")
  if not ok then
    hs.logger.new("hud.elements"):w("sfsymbol module not available")
    return
  end
  
  local size = opts.size or 32
  local color = opts.color or "FFFFFF"
  
  local image = sfsymbol.image(opts.symbol, { size = size, color = color })
  if not image then return end
  
  canvas:appendElements({
    id = opts.id or "symbol",
    type = "image",
    image = image,
    imageAlignment = "center",
    imageScaling = "none",
    frame = {
      x = opts.x - size / 2,
      y = opts.y - size / 2,
      w = size,
      h = size,
    },
  })
end

---@param canvas hs.canvas
---@param opts WaveformOpts
---@return WaveformInfo
function M.waveformBars(canvas, opts)
  assert(opts.x, "waveformBars requires opts.x")
  assert(opts.y, "waveformBars requires opts.y")
  
  local barCount = opts.barCount or 5
  local barWidth = opts.barWidth or 4
  local maxHeight = opts.maxHeight or 20
  local spacing = opts.spacing or 3
  local idPrefix = opts.idPrefix or "waveform_bar_"
  local totalWidth = barCount * barWidth + (barCount - 1) * spacing
  local startX = opts.x - totalWidth / 2
  
  for i = 1, barCount do
    local barX = startX + (i - 1) * (barWidth + spacing)
    local barHeight = maxHeight * 0.3  -- Initial height
    
    canvas:appendElements({
      id = idPrefix .. i,
      type = "rectangle",
      action = "fill",
      fillColor = opts.color or { white = 1, alpha = 1 },
      roundedRectRadii = { xRadius = barWidth / 2, yRadius = barWidth / 2 },
      frame = {
        x = barX,
        y = opts.y - barHeight / 2,
        w = barWidth,
        h = barHeight,
      },
    })
  end
  
  return {
    barCount = barCount,
    barWidth = barWidth,
    maxHeight = maxHeight,
    baseY = opts.y,
    idPrefix = idPrefix,
  }
end

return M
