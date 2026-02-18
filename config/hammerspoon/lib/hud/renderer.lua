-- HUD Renderer Module
-- Canvas creation and element composition
--
-- Handles:
--   - Creating canvas with proper styling
--   - Adding elements (text, icons, images, etc.)
--   - Dynamic text measurement
--   - Click handling
--

---@class CanvasFrame
---@field x number X position
---@field y number Y position
---@field w number Width
---@field h number Height

---@class CanvasOpts
---@field cornerRadius? number Corner radius
---@field borderWidth? number Border width
---@field borderColor? HudColor Border color

---@class TextMeasurement
---@field w number Text width
---@field h number Text height

---@class HudRendererModule
---@field DEFAULTS table Default rendering values
---@field createCanvas fun(frame: CanvasFrame, opts?: CanvasOpts): hs.canvas Create styled canvas
---@field measureText fun(text: string, maxWidth: number, opts?: table): TextMeasurement Measure text dimensions
---@field addText fun(canvas: hs.canvas, text: string, frame: CanvasFrame, opts?: table): number Add text element
---@field addImage fun(canvas: hs.canvas, image: hs.image, frame: CanvasFrame, opts?: table): number Add image element
---@field addRect fun(canvas: hs.canvas, frame: CanvasFrame, opts?: table): number Add rectangle element
---@field setupMouseCallbacks fun(canvas: hs.canvas, callbacks: table) Setup mouse event handlers
---@field drawCheckmark fun(canvas: hs.canvas, x: number, y: number, size: number, color: HudColor) Draw checkmark icon
---@field drawWarning fun(canvas: hs.canvas, x: number, y: number, size: number, color: HudColor) Draw warning icon
---@field drawError fun(canvas: hs.canvas, x: number, y: number, size: number, color: HudColor) Draw error icon
---@field drawInfo fun(canvas: hs.canvas, x: number, y: number, size: number, color: HudColor) Draw info icon
---@field drawGear fun(canvas: hs.canvas, x: number, y: number, size: number, color: HudColor) Draw gear icon

local M = {}

local theme = require("lib.hud.theme")

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

M.DEFAULTS = {
  cornerRadius = 12,
  borderWidth = 1.5,
  padding = 16,
  iconSize = 48,
  iconSpacing = 12,
  shadow = {
    blurRadius = 25,
    offset = { h = 6, w = 0 },
    alpha = 0.5,
  },
}

--------------------------------------------------------------------------------
-- CANVAS CREATION
--------------------------------------------------------------------------------

--- Create a new HUD canvas with standard styling
---@param frame table { x, y, w, h }
---@param opts? table { cornerRadius?, hasBorder?, hasBackground?, level? }
---@return hs.canvas Canvas instance
function M.createCanvas(frame, opts)
  opts = opts or {}
  local colors = theme.getColors()
  local radius = opts.cornerRadius or M.DEFAULTS.cornerRadius

  local canvas = hs.canvas.new(frame)

  -- Prevent clicking on canvas from activating Hammerspoon
  canvas:clickActivating(false)

  -- Set canvas level
  canvas:level(opts.level or "overlay")

  -- Add shadow layer (if background enabled)
  if opts.hasBackground ~= false then
    canvas:appendElements({
      type = "rectangle",
      action = "fill",
      fillColor = colors.shadow,
      roundedRectRadii = { xRadius = radius + 2, yRadius = radius + 2 },
      frame = { x = "0.5%", y = "1%", h = "99%", w = "99%" },
      shadow = {
        blurRadius = M.DEFAULTS.shadow.blurRadius,
        color = { red = 0, green = 0, blue = 0, alpha = M.DEFAULTS.shadow.alpha },
        offset = M.DEFAULTS.shadow.offset,
      },
    })

    -- Main background
    canvas:appendElements({
      type = "rectangle",
      action = "fill",
      fillColor = colors.background,
      roundedRectRadii = { xRadius = radius, yRadius = radius },
      frame = { x = "0%", y = "0%", h = "100%", w = "100%" },
      id = "background",
      trackMouseDown = true,
    })
  end

  -- Border (if enabled)
  if opts.hasBorder ~= false then
    canvas:appendElements({
      type = "rectangle",
      action = "stroke",
      strokeColor = colors.border,
      strokeWidth = M.DEFAULTS.borderWidth,
      roundedRectRadii = { xRadius = radius, yRadius = radius },
      frame = { x = 0, y = 0, h = frame.h, w = frame.w },
      id = "border",
    })
  end

  return canvas
end

--------------------------------------------------------------------------------
-- ELEMENT HELPERS
--------------------------------------------------------------------------------

--- Add a text element to a canvas
---@param canvas hs.canvas Canvas to add to
---@param text string Text content
---@param frame table { x, y, w, h }
---@param opts? table { color?, size?, font?, align?, wrap?, id?, trackMouse? }
---@return number Element index
function M.addText(canvas, text, frame, opts)
  opts = opts or {}
  local colors = theme.getColors()

  local element = {
    type = "text",
    text = text,
    textColor = opts.color or colors.title,
    textSize = opts.size or theme.sizes.body,
    textFont = opts.font or theme.fonts.system,
    textAlignment = opts.align or "left",
    textLineBreak = opts.wrap and "wordWrap" or "truncateTail",
    frame = frame,
  }

  if opts.id then element.id = opts.id end
  if opts.trackMouse then element.trackMouseDown = true end

  return canvas:appendElements(element)
end

--- Add an icon/image element to a canvas
---@param canvas hs.canvas Canvas to add to
---@param image hs.image Image to display
---@param frame table { x, y, w, h }
---@param opts? table { id?, trackMouse?, scaling? }
---@return number Element index
function M.addImage(canvas, image, frame, opts)
  opts = opts or {}

  local element = {
    type = "image",
    image = image,
    frame = frame,
    imageScaling = opts.scaling or "scaleProportionally",
    imageAlignment = "center",
  }

  if opts.id then element.id = opts.id end
  if opts.trackMouse then
    element.trackMouseDown = true
    element.trackMouseEnterExit = true
  end

  return canvas:appendElements(element)
end

--- Add a rectangle element to a canvas
---@param canvas hs.canvas Canvas to add to
---@param frame table { x, y, w, h }
---@param opts? table { color?, radius?, id?, trackMouse? }
---@return number Element index
function M.addRect(canvas, frame, opts)
  opts = opts or {}
  local colors = theme.getColors()

  local element = {
    type = "rectangle",
    action = "fill",
    fillColor = opts.color or colors.backgroundSubtle,
    frame = frame,
  }

  if opts.radius then
    element.roundedRectRadii = { xRadius = opts.radius, yRadius = opts.radius }
  end

  if opts.id then element.id = opts.id end
  if opts.trackMouse then element.trackMouseDown = true end

  return canvas:appendElements(element)
end

--------------------------------------------------------------------------------
-- TEXT MEASUREMENT
--------------------------------------------------------------------------------

--- Measure text dimensions with wrapping
---@param text string Text to measure
---@param maxWidth number Maximum width for wrapping
---@param opts? table { size?, font?, bold? }
---@return table { w, h } Dimensions
function M.measureText(text, maxWidth, opts)
  opts = opts or {}
  local colors = theme.getColors()

  local font = opts.bold and theme.fonts.systemBold or theme.fonts.system
  local size = opts.size or theme.sizes.body

  local styledText = hs.styledtext.new(text, {
    font = { name = font, size = size },
    color = colors.title,
    paragraphStyle = { lineBreak = "wordWrap" },
  })

  -- Create temp canvas for measurement
  local tempCanvas = hs.canvas.new({ x = 0, y = 0, w = maxWidth, h = 1000 })
  tempCanvas:appendElements({
    type = "text",
    text = styledText,
    frame = { x = 0, y = 0, w = maxWidth, h = 1000 },
  })

  local measuredSize = tempCanvas:minimumTextSize(1, styledText)
  tempCanvas:delete()

  -- Account for wrapping
  local height = measuredSize.h
  if measuredSize.w > maxWidth and not text:match("\n") then
    height = math.ceil(measuredSize.w / maxWidth) * measuredSize.h
  end

  return { w = math.min(measuredSize.w, maxWidth), h = height }
end

--- Calculate dynamic height for multi-line content
---@param content table { title?, subtitle?, message? }
---@param textWidth number Available width for text
---@param opts? table { hasIcon?, titleSize?, bodySize? }
---@return table { total, title, subtitle, message }
function M.calculateContentHeight(content, textWidth, opts)
  opts = opts or {}
  local titleSize = opts.titleSize or theme.sizes.title
  local bodySize = opts.bodySize or theme.sizes.body

  local heights = {
    title = 0,
    subtitle = 0,
    message = 0,
  }

  if content.title and content.title ~= "" then
    local measured = M.measureText(content.title, textWidth, { size = titleSize, bold = true })
    heights.title = measured.h
  end

  if content.subtitle and content.subtitle ~= "" then
    local measured = M.measureText(content.subtitle, textWidth, { size = bodySize })
    heights.subtitle = measured.h
  end

  if content.message and content.message ~= "" then
    local measured = M.measureText(content.message, textWidth, { size = bodySize })
    heights.message = measured.h
  end

  -- Calculate total with spacing
  local spacing = 4
  local total = heights.title

  if heights.subtitle > 0 then
    total = total + spacing + heights.subtitle
  end

  if heights.message > 0 then
    total = total + (spacing + 2) + heights.message
  end

  heights.total = total

  return heights
end

--------------------------------------------------------------------------------
-- CLICK HANDLING
--------------------------------------------------------------------------------

--- Set up mouse callback for a canvas
---@param canvas hs.canvas Canvas to configure
---@param callbacks table { onClick?, onElementClick?, onHover? }
function M.setupMouseCallbacks(canvas, callbacks)
  canvas:canvasMouseEvents(true, callbacks.onHover ~= nil, callbacks.onHover ~= nil, false)

  canvas:mouseCallback(function(obj, message, id, x, y)
    if message == "mouseDown" then
      if id and callbacks.onElementClick then
        local handled = callbacks.onElementClick(id, x, y)
        if handled then return true end
      end
      if callbacks.onClick then
        return callbacks.onClick(x, y)
      end
    elseif message == "mouseEnter" or message == "mouseExit" then
      if callbacks.onHover then
        callbacks.onHover(id, message == "mouseEnter")
      end
    end
    return false
  end)
end

--------------------------------------------------------------------------------
-- APP ICON HELPERS
--------------------------------------------------------------------------------

--- Get app icon from bundle ID or app name
---@param identifier string Bundle ID or app name
---@return hs.image|nil App icon
function M.getAppIcon(identifier)
  -- Check for special markers
  if identifier == "hal9000" then
    local iconPath = hs.configdir .. "/assets/hal9000.png"
    return hs.image.imageFromPath(iconPath)
  end

  -- Try as running app first
  local app = hs.application.get(identifier)
  if app then
    return hs.image.imageFromAppBundle(app:bundleID())
  end

  -- Try as bundle ID directly
  return hs.image.imageFromAppBundle(identifier)
end

--- Get SF Symbol or named system image
---@param name string Symbol name (e.g., "checkmark.circle.fill")
---@return hs.image|nil Image
function M.getSystemImage(name)
  return hs.image.imageFromName(name)
end

--------------------------------------------------------------------------------
-- CANVAS ICON DRAWING (colored icons using segments)
--------------------------------------------------------------------------------

--- Draw a checkmark icon on a canvas
---@param canvas hs.canvas Canvas to draw on
---@param x number X position
---@param y number Y position
---@param size number Icon size
---@param color table Color table
function M.drawCheckmark(canvas, x, y, size, color)
  canvas:appendElements({
    type = "segments",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(2, size / 8),
    strokeCapStyle = "round",
    strokeJoinStyle = "round",
    coordinates = {
      { x = x, y = y + size * 0.5 },
      { x = x + size * 0.35, y = y + size * 0.8 },
      { x = x + size, y = y + size * 0.15 },
    },
  })
end

--- Draw a warning triangle icon on a canvas
---@param canvas hs.canvas Canvas to draw on
---@param x number X position
---@param y number Y position
---@param size number Icon size
---@param color table Color table
function M.drawWarning(canvas, x, y, size, color)
  -- Triangle outline
  canvas:appendElements({
    type = "segments",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(2, size / 8),
    strokeCapStyle = "round",
    strokeJoinStyle = "round",
    closed = true,
    coordinates = {
      { x = x + size * 0.5, y = y },
      { x = x + size, y = y + size * 0.9 },
      { x = x, y = y + size * 0.9 },
    },
  })
  -- Exclamation mark
  canvas:appendElements({
    type = "segments",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(2, size / 8),
    strokeCapStyle = "round",
    coordinates = {
      { x = x + size * 0.5, y = y + size * 0.3 },
      { x = x + size * 0.5, y = y + size * 0.55 },
    },
  })
  canvas:appendElements({
    type = "circle",
    action = "fill",
    fillColor = color,
    center = { x = x + size * 0.5, y = y + size * 0.72 },
    radius = size * 0.06,
  })
end

--- Draw an error X icon on a canvas
---@param canvas hs.canvas Canvas to draw on
---@param x number X position
---@param y number Y position
---@param size number Icon size
---@param color table Color table
function M.drawError(canvas, x, y, size, color)
  local padding = size * 0.15
  canvas:appendElements({
    type = "segments",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(2, size / 8),
    strokeCapStyle = "round",
    coordinates = {
      { x = x + padding, y = y + padding },
      { x = x + size - padding, y = y + size - padding },
    },
  })
  canvas:appendElements({
    type = "segments",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(2, size / 8),
    strokeCapStyle = "round",
    coordinates = {
      { x = x + size - padding, y = y + padding },
      { x = x + padding, y = y + size - padding },
    },
  })
end

--- Draw an info icon on a canvas
---@param canvas hs.canvas Canvas to draw on
---@param x number X position
---@param y number Y position
---@param size number Icon size
---@param color table Color table
function M.drawInfo(canvas, x, y, size, color)
  -- Circle
  canvas:appendElements({
    type = "circle",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(1.5, size / 10),
    center = { x = x + size * 0.5, y = y + size * 0.5 },
    radius = size * 0.45,
  })
  -- Dot
  canvas:appendElements({
    type = "circle",
    action = "fill",
    fillColor = color,
    center = { x = x + size * 0.5, y = y + size * 0.3 },
    radius = size * 0.07,
  })
  -- Line
  canvas:appendElements({
    type = "segments",
    action = "stroke",
    strokeColor = color,
    strokeWidth = math.max(1.5, size / 10),
    strokeCapStyle = "round",
    coordinates = {
      { x = x + size * 0.5, y = y + size * 0.42 },
      { x = x + size * 0.5, y = y + size * 0.72 },
    },
  })
end

--- Draw a gear/settings icon on a canvas
---@param canvas hs.canvas Canvas to draw on
---@param x number X position
---@param y number Y position
---@param size number Icon size
---@param color table Color table
function M.drawGear(canvas, x, y, size, color)
  local cx, cy = x + size * 0.5, y + size * 0.5
  local outerR = size * 0.45
  local innerR = size * 0.25
  local teeth = 6
  local strokeWidth = math.max(1.5, size / 10)

  -- Draw gear teeth as lines radiating out
  for i = 0, teeth - 1 do
    local angle = (i / teeth) * math.pi * 2
    local x1 = cx + math.cos(angle) * innerR
    local y1 = cy + math.sin(angle) * innerR
    local x2 = cx + math.cos(angle) * outerR
    local y2 = cy + math.sin(angle) * outerR
    canvas:appendElements({
      type = "segments",
      action = "stroke",
      strokeColor = color,
      strokeWidth = strokeWidth * 1.5,
      strokeCapStyle = "round",
      coordinates = { { x = x1, y = y1 }, { x = x2, y = y2 } },
    })
  end

  -- Center circle
  canvas:appendElements({
    type = "circle",
    action = "stroke",
    strokeColor = color,
    strokeWidth = strokeWidth,
    center = { x = cx, y = cy },
    radius = innerR * 0.6,
  })
end

return M
