-- HUD Elements Module
-- Drawing primitives for HUD content
--
-- These are stateless helper functions that add elements to a canvas.
-- The canvas and positioning are provided by the caller.
--

local M = {}

--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------

---@class CircleOpts
---@field x number Center X coordinate (required)
---@field y number Center Y coordinate (required)
---@field radius? number Circle radius (default: 20)
---@field color? table Fill color table (default: red)
---@field id? string Element ID (default: "circle")

---@class RectangleOpts
---@field x number Top-left X coordinate (required)
---@field y number Top-left Y coordinate (required)
---@field w number Width (required)
---@field h number Height (required)
---@field color? table Fill color table (default: white)
---@field radius? number Corner radius for rounded rect (default: none)
---@field id? string Element ID (default: "rectangle")

---@class TextOpts
---@field y number Y position (required)
---@field text string Text content (required)
---@field x? number X position (default: 0)
---@field width? number|string Frame width (default: "100%")
---@field color? table Text color (default: white 80% alpha)
---@field fontSize? number Font size (default: 12)
---@field alignment? string Text alignment (default: "center")
---@field id? string Element ID (default: "text")

---@class SFSymbolOpts
---@field x number Center X coordinate (required)
---@field y number Center Y coordinate (required)
---@field symbol string SF Symbol name (required)
---@field size? number Symbol size (default: 32)
---@field color? string Hex color without # (default: "FFFFFF")
---@field id? string Element ID (default: "symbol")

---@class WaveformOpts
---@field x number Center X coordinate (required)
---@field y number Center Y coordinate (required)
---@field barCount? number Number of bars (default: 5)
---@field barWidth? number Width of each bar (default: 4)
---@field maxHeight? number Maximum bar height (default: 20)
---@field spacing? number Space between bars (default: 3)
---@field color? table Fill color table (default: white)
---@field idPrefix? string ID prefix for bars (default: "waveform_bar_")

---@class WaveformInfo
---@field barCount number Number of bars
---@field barWidth number Width of each bar
---@field maxHeight number Maximum bar height
---@field baseY number Center Y for animation
---@field idPrefix string ID prefix for bars

--------------------------------------------------------------------------------
-- BASIC SHAPES
--------------------------------------------------------------------------------

---Add a filled circle
---@param canvas hs.canvas Canvas to add to
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

---Add a rectangle
---@param canvas hs.canvas Canvas to add to
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

--------------------------------------------------------------------------------
-- TEXT
--------------------------------------------------------------------------------

---Add text label
---@param canvas hs.canvas Canvas to add to
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

--------------------------------------------------------------------------------
-- SF SYMBOLS
--------------------------------------------------------------------------------

---Add SF Symbol icon
---@param canvas hs.canvas Canvas to add to
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

--------------------------------------------------------------------------------
-- WAVEFORM
--------------------------------------------------------------------------------

---Add waveform bars (for audio visualization)
---@param canvas hs.canvas Canvas to add to
---@param opts WaveformOpts
---@return WaveformInfo info Info needed for animator.waveform()
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
  
  -- Return info needed for animator.waveform()
  return {
    barCount = barCount,
    barWidth = barWidth,
    maxHeight = maxHeight,
    baseY = opts.y,
    idPrefix = idPrefix,
  }
end

return M
