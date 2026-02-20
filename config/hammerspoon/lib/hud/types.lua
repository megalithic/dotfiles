-- HUD Types Module
-- Defines HUD type classes: alert, toast, panel, persistent
--
-- Each type is a factory function that returns a HUD instance.
-- HUD instances have common methods: show(), dismiss(), update()
--

--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------

---@class BaseHUD
---@field id string Unique identifier
---@field anchor string Position anchor (e.g., "bottom-center")
---@field ephemeral boolean Whether HUD auto-dismisses
---@field visible boolean Current visibility state
---@field createdAt number Creation timestamp
---@field width number HUD width in points
---@field height number HUD height in points
---@field scaledHeight number Scaled height for stacking
---@field animationIn number Show animation duration (ms)
---@field animationOut number Hide animation duration (ms)
---@field verticalOffset number Offset from anchor position
---@field canvas hs.canvas|nil Canvas object when visible
---@field basePosition table|nil Base position for stacking
---@field timers table Timer references for cleanup
---@field onClick function|nil Click callback
---@field onDismiss function|nil Dismiss callback

---@class Alert : BaseHUD
---@field message string Alert message text
---@field icon hs.image|nil Icon image
---@field iconType string|nil Icon type name
---@field duration number Auto-dismiss delay (seconds)
---@field sizePreset table Size preset values
---@field fontSize number Font size
---@field fontColor table Font color

---@class Toast : BaseHUD
---@field title string Toast title
---@field message string|nil Toast message
---@field subtitle string|nil Toast subtitle
---@field icon hs.image|nil Icon image
---@field appBundleID string|nil App bundle ID for icon
---@field duration number Auto-dismiss delay (seconds)
---@field onIconClick function|nil Icon click callback

---@class Panel : BaseHUD
---@field timeout number Auto-dismiss delay (seconds)
---@field media hs.image|nil Media content (image, future: video/animation)
---@field mediaOpts table|nil Media options (maxWidth, maxHeight, onClick)
---@field mediaClickHandler function|nil Media click callback
---@field status string|nil Status text
---@field statusColor string|table|nil Status color
---@field preview string|nil Preview text (monospace)
---@field previewOpts table|nil Preview options (font, maxLines)
---@field content table|nil Additional content (e.g., keybindings, metadata)
---@field hoverScale number|nil Scale factor on hover

---@class Persistent : BaseHUD
---@field content table Content options
---@field icon hs.image|nil Icon image
---@field text string|nil Text content
---@field color string|table|nil Color

local M = {}

local theme = require("lib.hud.theme")
local position = require("lib.hud.position")
local animator = require("lib.hud.animator")
local renderer = require("lib.hud.renderer")
local stack = require("lib.hud.stack")
local persistence = require("lib.hud.persistence")
local sfsymbol = require("lib.hud.sfsymbol")

--------------------------------------------------------------------------------
-- BASE HUD CLASS
--------------------------------------------------------------------------------

local BaseHUD = {}
BaseHUD.__index = BaseHUD

function BaseHUD:new(opts)
  local hud = setmetatable({}, self)

  hud.id = opts.id or tostring(os.time()) .. math.random(1000)
  hud.anchor = opts.position or "bottom-center"
  hud.ephemeral = opts.ephemeral ~= false  -- Default true
  hud.visible = false
  hud.createdAt = os.time()

  -- Window-relative positioning (optional)
  hud.targetWindow = opts.window

  -- Store dimensions
  hud.width = opts.width or 300
  hud.height = opts.height or 100

  -- Animation settings (milliseconds)
  hud.animationIn = opts.animationIn or opts.animation or 250
  hud.animationOut = opts.animationOut or opts.animation or 200

  -- Dim overlay settings
  hud.dim = opts.dim or false
  hud.dimAlpha = opts.dimAlpha or 0.5
  hud.overlay = nil  -- Canvas for dim overlay

  -- Timers for cleanup (all must be stopped on dismiss)
  hud.timers = {
    dismiss = nil,
    animation = nil,
    hover = nil,
  }

  -- Callbacks
  hud.onClick = opts.onClick
  hud.onDismiss = opts.onDismiss

  -- Vertical offset from anchor position
  -- Default to BOTTOM_OFFSET for bottom anchors
  if opts.offset then
    hud.verticalOffset = opts.offset
  elseif hud.anchor and hud.anchor:match("^bottom") then
    hud.verticalOffset = position.BOTTOM_OFFSET
  else
    hud.verticalOffset = 0
  end

  return hud
end

function BaseHUD:show()
  if self.visible then return self end

  -- Load saved position preference
  local savedPosition = persistence.getPosition(self.id)
  if savedPosition then
    self.anchor = savedPosition
  end

  -- Calculate position (use focused window's screen, not mouse position)
  local screen = hs.screen.mainScreen() or hs.mouse.getCurrentScreen()

  -- Create dim overlay if requested
  if self.dim then
    local screenFrame = screen:fullFrame()
    self.overlay = hs.canvas.new(screenFrame)
    self.overlay:appendElements({
      type = "rectangle",
      action = "fill",
      fillColor = { red = 0, green = 0, blue = 0, alpha = self.dimAlpha },
      frame = { x = 0, y = 0, w = "100%", h = "100%" },
    })
    self.overlay:level("overlay")
    self.overlay:show()
  end

  local pos = position.calculate(self.anchor, self.width, self.height, {
    screen = screen,
    window = self.targetWindow,
    offset = self.verticalOffset or 0,
  })

  -- Store base position and dimensions for stacking
  self.basePosition = pos
  self.scaledHeight = self.height  -- No scaling - work in points

  -- Make room for this HUD before creating it
  stack.makeRoom(self.anchor, self.height)

  -- Create canvas (subclasses override _createCanvas)
  -- Canvas works in points - system handles retina automatically
  self.canvas = self:_createCanvas({
    x = pos.x,
    y = pos.startY,  -- Start at animation start position
    w = self.width,
    h = self.height,
  }, 1)  -- scale=1, we work in points

  -- Register with stack manager
  stack.register(self)

  -- Animate in
  self.timers.animation = animator.slideIn(
    self.canvas,
    pos.startY,
    pos.y,
    {
      duration = self.animationIn,
      onComplete = function()
        self.timers.animation = nil
      end,
    }
  )

  self.visible = true

  -- Set up auto-dismiss if duration specified
  if self.duration and self.duration > 0 then
    self.timers.dismiss = hs.timer.doAfter(self.duration, function()
      self.timers.dismiss = nil
      self:dismiss()
    end)
  end

  return self
end

function BaseHUD:dismiss(opts)
  opts = opts or {}
  local animate = opts.animate ~= false

  -- Stop ALL pending timers
  for name, timer in pairs(self.timers) do
    if timer then
      animator.stop(timer)
      self.timers[name] = nil
    end
  end

  -- Clean up dim overlay
  if self.overlay then
    self.overlay:delete()
    self.overlay = nil
  end

  -- Unregister from stack
  stack.unregister(self.id)

  -- Animate out or instant delete
  if self.canvas then
    local canvas = self.canvas
    self.canvas = nil

    if animate and self.visible then
      animator.slideOut(canvas, {
        duration = self.animationOut,
        deleteAfter = true,
        onComplete = function()
          if self.onDismiss then self.onDismiss() end
        end,
      })
    else
      canvas:delete(0)
      if self.onDismiss then self.onDismiss() end
    end
  end

  self.visible = false

  -- Restack remaining HUDs at this anchor
  stack.restack(self.anchor)

  return self
end

function BaseHUD:_createCanvas(frame, scale)
  -- Subclasses override this
  return renderer.createCanvas(frame)
end

function BaseHUD:_cleanup()
  self:dismiss({ animate = false })
end

--------------------------------------------------------------------------------
-- ALERT TYPE
-- Simple text + optional icon, auto-dismiss
--------------------------------------------------------------------------------

local Alert = setmetatable({}, { __index = BaseHUD })
Alert.__index = Alert

-- Size presets: small, medium (default), large
-- Base values - scaled by DPI multiplier at runtime
Alert.SIZES = {
  small = {
    padding = 12,
    iconSize = 14,
    iconSpacing = 8,
    fontSize = 14,
    cornerRadius = 10,
  },
  medium = {
    padding = 16,
    iconSize = 18,
    iconSpacing = 10,
    fontSize = 18,
    cornerRadius = 12,
  },
  large = {
    padding = 20,
    iconSize = 24,
    iconSpacing = 12,
    fontSize = 20,
    cornerRadius = 14,
  },
}

--- Get DPI multiplier for current screen
--- External displays (viewed from further away) get larger sizes
---@param screen hs.screen|nil
---@return number multiplier (1.0 for laptop, 1.25 for external)
function Alert.getDpiMultiplier(screen)
  screen = screen or hs.screen.mainScreen() or hs.mouse.getCurrentScreen()
  return position.isExternalDisplay(screen) and 1.25 or 1.0
end

--- Get scaled size preset for current screen
---@param name string Preset name ("small", "medium", "large")
---@param screen hs.screen|nil
---@return table Scaled preset values
function Alert.getScaledPreset(name, screen)
  local base = Alert.SIZES[name] or Alert.SIZES.medium
  local mult = Alert.getDpiMultiplier(screen)
  
  return {
    padding = math.floor(base.padding * mult),
    iconSize = math.floor(base.iconSize * mult),
    iconSpacing = math.floor(base.iconSpacing * mult),
    fontSize = math.floor(base.fontSize * mult),
    cornerRadius = math.floor(base.cornerRadius * mult),
  }
end

function Alert:new(message, opts)
  opts = opts or {}
  opts.ephemeral = true

  local hud = BaseHUD.new(self, opts)

  hud.message = message
  hud.icon = opts.icon           -- SF Symbol name (string) or hs.image
  hud.iconType = opts.iconType   -- "checkmark", "warning", "error", "info"
  hud.iconColor = opts.iconColor -- Hex color (e.g., "4CD964") or color table
  hud.duration = opts.duration or 3  -- seconds

  -- Size preset (default: medium) - scaled for DPI
  local screen = hs.screen.mainScreen() or hs.mouse.getCurrentScreen()
  hud.sizePreset = Alert.getScaledPreset(opts.size or "medium", screen)

  -- Style options (can override preset)
  hud.style = opts.style or {}
  hud.fontSize = hud.style.fontSize or hud.sizePreset.fontSize
  hud.fontColor = hud.style.color or theme.getColor("title")

  -- Calculate dimensions based on content
  local hasIcon = hud.icon ~= nil or hud.iconType ~= nil
  local textWidth = 300
  local measured = renderer.measureText(message, textWidth, { size = hud.fontSize })

  local padding = hud.sizePreset.padding
  local iconSize = hasIcon and hud.sizePreset.iconSize or 0
  local iconSpacing = hasIcon and hud.sizePreset.iconSpacing or 0

  hud.width = padding + iconSize + iconSpacing + measured.w + padding
  hud.height = padding + math.max(iconSize, measured.h) + padding

  -- Cap dimensions
  hud.width = math.min(hud.width, 400)
  hud.height = math.min(hud.height, 100)

  return hud
end

function Alert:_createCanvas(frame, scale)
  -- NOTE: We ignore 'scale' - canvas works in points, system handles retina
  local canvas = renderer.createCanvas(frame, {
    cornerRadius = self.sizePreset.cornerRadius,
  })

  local padding = self.sizePreset.padding
  local hasIcon = self.icon ~= nil or self.iconType ~= nil
  local iconSize = hasIcon and self.sizePreset.iconSize or 0
  local iconSpacing = hasIcon and self.sizePreset.iconSpacing or 0
  local centerY = frame.h / 2

  -- Create styled text to measure actual dimensions
  local textStyle = {
    font = { name = theme.fonts.system, size = self.fontSize },
    color = self.fontColor,
  }
  -- Add center alignment if no icon
  if not hasIcon then
    textStyle.paragraphStyle = { alignment = "center" }
  end
  local styledText = hs.styledtext.new(self.message, textStyle)

  -- Add temporary text element to measure
  canvas:appendElements({
    type = "text",
    text = styledText,
    frame = { x = 0, y = 0, w = frame.w, h = frame.h }
  })
  local textSize = canvas:minimumTextSize(canvas:elementCount(), styledText)
  canvas:removeElement(canvas:elementCount())

  -- Calculate horizontal centering for icon + text as a unit
  local contentWidth = iconSize + iconSpacing + textSize.w
  local startX = (frame.w - contentWidth) / 2

  -- Add icon (custom-drawn or image)
  if self.iconType then
    -- Draw colored icon using canvas primitives
    local iconColor = self.fontColor
    local iconX = startX
    local iconY = centerY - iconSize / 2

    if self.iconType == "checkmark" then
      renderer.drawCheckmark(canvas, iconX, iconY, iconSize, iconColor)
    elseif self.iconType == "warning" then
      renderer.drawWarning(canvas, iconX, iconY, iconSize, iconColor)
    elseif self.iconType == "error" then
      renderer.drawError(canvas, iconX, iconY, iconSize, iconColor)
    elseif self.iconType == "info" then
      renderer.drawInfo(canvas, iconX, iconY, iconSize, iconColor)
    elseif self.iconType == "gear" then
      renderer.drawGear(canvas, iconX, iconY, iconSize, iconColor)
    end
  elseif self.icon then
    -- Use SF Symbol name (string) or provided image
    local iconImage = self.icon
    if type(self.icon) == "string" then
      -- Load SF Symbol with optional color (hex string)
      local color = self.iconColor  -- Already hex string or nil
      iconImage = sfsymbol.image(self.icon, { size = iconSize, color = color })
    end

    if iconImage then
      renderer.addImage(canvas, iconImage, {
        x = startX, y = centerY - iconSize / 2,
        w = iconSize, h = iconSize,
      })
    end
  end

  -- Add message text, vertically centered using measured height
  local textX = hasIcon and (startX + iconSize + iconSpacing) or padding
  local textW = hasIcon and textSize.w or (frame.w - padding * 2)

  canvas:appendElements({
    type = "text",
    text = styledText,
    frame = { x = textX, y = centerY - textSize.h / 2, w = textW, h = textSize.h },
  })

  -- Set up click to dismiss
  renderer.setupMouseCallbacks(canvas, {
    onClick = function()
      self:dismiss()
      return true
    end,
  })

  return canvas
end

--------------------------------------------------------------------------------
-- TOAST TYPE
-- Notification replacement with title, subtitle, message, icon
--------------------------------------------------------------------------------

local Toast = setmetatable({}, { __index = BaseHUD })
Toast.__index = Toast

function Toast:new(opts)
  opts = opts or {}
  opts.ephemeral = true
  opts.position = opts.position or "bottom-left"

  local hud = BaseHUD.new(self, opts)

  hud.title = opts.title or ""
  hud.subtitle = opts.subtitle or ""
  hud.message = opts.message or ""
  hud.appBundleID = opts.appBundleID
  hud.duration = opts.duration or 5  -- seconds

  -- Resolve icon upfront (separation of concerns - not in renderer)
  -- Priority: explicit icon > appBundleID lookup
  if opts.icon then
    hud.icon = opts.icon
  elseif opts.appBundleID then
    hud.icon = renderer.getAppIcon(opts.appBundleID)
  else
    hud.icon = nil
  end

  -- Click callback for icon
  hud.onIconClick = opts.onIconClick

  -- Calculate dimensions
  local hasIcon = hud.icon ~= nil
  local padding = renderer.DEFAULTS.padding
  local iconSize = renderer.DEFAULTS.iconSize
  local iconSpacing = renderer.DEFAULTS.iconSpacing

  local baseWidth = 420
  local textWidth = baseWidth - padding * 2
  if hasIcon then textWidth = textWidth - iconSize - iconSpacing end

  local heights = renderer.calculateContentHeight({
    title = hud.title,
    subtitle = hud.subtitle,
    message = hud.message,
  }, textWidth)

  hud.width = baseWidth
  hud.height = padding + math.max(iconSize, heights.total) + padding + 18  -- +18 for timestamp

  -- Clamp height
  hud.height = math.max(100, math.min(400, hud.height))

  -- Store for rendering
  hud._hasIcon = hasIcon
  hud._textWidth = textWidth
  hud._heights = heights

  return hud
end

function Toast:_createCanvas(frame, scale)
  local canvas = renderer.createCanvas(frame)
  local colors = theme.getColors()

  local padding = renderer.DEFAULTS.padding * scale
  local iconSize = renderer.DEFAULTS.iconSize * scale
  local iconSpacing = renderer.DEFAULTS.iconSpacing * scale

  local x = padding
  local y = padding
  local textX = x

  -- Add icon if present (already resolved in Toast:new)
  if self.icon then
    -- Offset icon up slightly to align with text top (text has internal leading)
    local iconY = y - 2 * scale
    renderer.addImage(canvas, self.icon, {
      x = x, y = iconY,
      w = iconSize, h = iconSize,
    }, {
      id = "icon",
      trackMouse = true,
    })
    textX = x + iconSize + iconSpacing
  end

  local textWidth = frame.w - textX - padding
  local textY = y

  -- Title
  if self.title and self.title ~= "" then
    renderer.addText(canvas, self.title, {
      x = textX, y = textY,
      w = textWidth, h = self._heights.title * scale,
    }, {
      size = theme.sizes.title * scale,
      font = theme.fonts.systemBold,
      color = colors.title,
      wrap = true,
      id = "title",
      trackMouse = true,
    })
    textY = textY + self._heights.title * scale + 4 * scale
  end

  -- Subtitle
  if self.subtitle and self.subtitle ~= "" then
    renderer.addText(canvas, self.subtitle, {
      x = textX, y = textY,
      w = textWidth, h = self._heights.subtitle * scale,
    }, {
      size = theme.sizes.subtitle * scale,
      color = colors.subtitle,
      wrap = true,
      id = "subtitle",
      trackMouse = true,
    })
    textY = textY + self._heights.subtitle * scale + 6 * scale
  end

  -- Message
  if self.message and self.message ~= "" then
    renderer.addText(canvas, self.message, {
      x = textX, y = textY,
      w = textWidth, h = self._heights.message * scale,
    }, {
      size = theme.sizes.body * scale,
      color = colors.message,
      wrap = true,
      id = "message",
      trackMouse = true,
    })
  end

  -- Timestamp (bottom-right)
  local timestamp = os.date("%b %d, %I:%M %p")
  local timestampWidth = 120 * scale
  renderer.addText(canvas, timestamp, {
    x = frame.w - timestampWidth - padding,
    y = frame.h - 18 * scale - padding / 2,
    w = timestampWidth, h = 18 * scale,
  }, {
    size = theme.sizes.tiny * scale,
    color = colors.timestamp,
    align = "right",
    id = "timestamp",
  })

  -- Click handling
  renderer.setupMouseCallbacks(canvas, {
    onElementClick = function(id, x, y)
      if id == "icon" then
        if self.onIconClick then
          self.onIconClick()
          return true
        elseif self.appBundleID then
          hs.application.launchOrFocusByBundleID(self.appBundleID)
          self:dismiss()
          return true
        end
      end
      return false
    end,
    onClick = function()
      self:dismiss()
      return true
    end,
  })

  return canvas
end

--------------------------------------------------------------------------------
-- PANEL TYPE
-- Rich multi-element HUD (for clipper, etc.)
--------------------------------------------------------------------------------

local Panel = setmetatable({}, { __index = BaseHUD })
Panel.__index = Panel

function Panel:new(opts)
  opts = opts or {}
  opts.ephemeral = opts.ephemeral ~= false  -- Default true

  local hud = BaseHUD.new(self, opts)

  hud.duration = opts.timeout or opts.duration  -- seconds (nil = manual dismiss)

  -- Panel content (set via methods)
  hud.media = nil
  hud.mediaOpts = nil
  hud.mediaClickHandler = nil
  hud.status = nil
  hud.statusColor = nil
  hud.content = nil  -- Additional content (e.g., array of { key, desc } for keybindings)

  -- Hover-to-zoom
  hud.hoverScale = opts.onHover and opts.onHover.scale or nil
  hud._originalFrame = nil
  hud._isHovered = false

  -- Default dimensions (will be recalculated)
  hud.width = 320
  hud.height = 200

  return hud
end

---Set media content (image, future: video/animation)
---
---Currently supports: hs.image (static images, GIFs show first frame only)
---Future: For video/animated GIF, embed hs.webview as fallback
---Research: hs.canvas has no native video support; webview can render HTML5 video
---
---@param image hs.image Media image
---@param opts? { maxWidth?: number, maxHeight?: number, onClick?: function }
---@return Panel self
function Panel:setMedia(image, opts)
  opts = opts or {}
  self.media = image
  self.mediaOpts = opts  -- Store for rendering (maxWidth, maxHeight)
  self.mediaClickHandler = opts.onClick
  return self
end

function Panel:setStatus(text, opts)
  opts = opts or {}
  self.status = text
  self.statusColor = opts.color  -- "success", "warning", "error", or color table
  self:_updateCanvas()
  return self
end

function Panel:setContent(content)
  self.content = content
  self:_updateCanvas()
  return self
end

---Set preview text (monospace, below status, above cheatsheet)
---@param text string|nil Preview text (nil to clear)
---@param opts? { font?: string, maxLines?: number }
function Panel:setPreview(text, opts)
  opts = opts or {}
  self.preview = text
  self.previewOpts = {
    font = opts.font or "JetBrainsMono Nerd Font Mono",
    maxLines = opts.maxLines or 5,
  }
  self:_updateCanvas()
  return self
end

---Recalculate panel dimensions based on content
function Panel:_recalculateDimensions()
  local dims = self:_calculateDimensions(1)  -- scale=1 for points
  self.width = dims.width
  self.height = dims.height
end

---Override show to recalculate dimensions first
function Panel:show()
  self:_recalculateDimensions()
  return BaseHUD.show(self)
end

function Panel:_calculateDimensions(scale)
  local margin = 16 * scale

  -- Media section - calculate based on actual image size and constraints
  local mediaWidth = 0
  local mediaHeight = 0

  if self.media then
    local sourceSize = self.media:size()
    local minW = (self.mediaOpts and self.mediaOpts.minWidth) or 280
    local maxW = (self.mediaOpts and self.mediaOpts.maxWidth) or 320
    local maxH = (self.mediaOpts and self.mediaOpts.maxHeight) or 180

    -- Scale down for retina (source is 2x or more)
    local scaleFactor = 4
    local scaledW = sourceSize.w / scaleFactor
    local scaledH = sourceSize.h / scaleFactor

    -- Guard against zero dimensions
    if scaledW < 1 then scaledW = 1 end
    if scaledH < 1 then scaledH = 1 end

    local aspectRatio = scaledW / scaledH

    -- Scale UP to minimum width if too small
    if scaledW < minW then
      scaledW = minW
      scaledH = scaledW / aspectRatio
    end

    -- Scale DOWN to fit max constraints
    if scaledW > maxW then
      scaledW = maxW
      scaledH = scaledW / aspectRatio
    end
    if scaledH > maxH then
      scaledH = maxH
      scaledW = scaledH * aspectRatio
    end

    mediaWidth = math.floor(scaledW * scale)
    mediaHeight = math.floor(scaledH * scale)
  end

  -- Panel width based on media or minimum (320pt)
  local width = math.max(mediaWidth + margin * 2, 320)

  -- Status section
  local statusHeight = self.status and 24 * scale or 0

  -- Preview section (monospace text, max 5 lines, 5px padding)
  local previewLineHeight = 16 * scale
  local previewPadding = 5 * scale
  local previewMaxLines = (self.previewOpts and self.previewOpts.maxLines) or 5
  local previewHeight = 0
  if self.preview and #self.preview > 0 then
    -- Count actual lines (up to max)
    local lines = 0
    for _ in self.preview:gmatch("[^\n]*") do
      lines = lines + 1
      if lines >= previewMaxLines then break end
    end
    previewHeight = math.min(lines, previewMaxLines) * previewLineHeight + previewPadding * 2
  end

  -- Cheat sheet section
  local keyRowHeight = 20 * scale
  local keysHeight = self.content and #self.content * keyRowHeight or 0

  local totalHeight = margin
    + (mediaHeight > 0 and (mediaHeight + margin / 2) or 0)
    + (statusHeight > 0 and (statusHeight + margin / 2) or 0)
    + (previewHeight > 0 and (previewHeight + margin / 2) or 0)
    + keysHeight
    + margin

  local contentWidth = width - margin * 2

  return {
    width = width,
    height = totalHeight,
    margin = margin,
    contentWidth = contentWidth,
    mediaWidth = mediaWidth,
    mediaHeight = mediaHeight,
    statusHeight = statusHeight,
    previewHeight = previewHeight,
    previewLineHeight = previewLineHeight,
    previewMaxLines = previewMaxLines,
    keyRowHeight = keyRowHeight,
    keysHeight = keysHeight,
  }
end

function Panel:_createCanvas(frame, scale)
  local canvas = renderer.createCanvas(frame)
  local colors = theme.getColors()

  local dims = self:_calculateDimensions(scale)
  local margin = dims.margin
  local y = margin

  -- Media (image, future: video/animation)
  if self.media and dims.mediaWidth > 0 and dims.mediaHeight > 0 then
    -- Center media if panel is wider than media
    local mediaX = margin + (dims.contentWidth - dims.mediaWidth) / 2

    renderer.addImage(canvas, self.media, {
      x = mediaX, y = y,
      w = dims.mediaWidth, h = dims.mediaHeight,
    }, {
      id = "media",
      trackMouse = true,
    })
    y = y + dims.mediaHeight + margin / 2
  end

  -- Status
  if self.status then
    local statusColor = colors.subtitle
    if self.statusColor then
      if type(self.statusColor) == "string" then
        -- Check if it's a hex color (6 chars, no spaces)
        if self.statusColor:match("^%x%x%x%x%x%x$") then
          statusColor = theme.hexToColor(self.statusColor)
        else
          statusColor = colors[self.statusColor] or colors.subtitle
        end
      else
        statusColor = self.statusColor
      end
    end

    renderer.addText(canvas, self.status, {
      x = margin, y = y,
      w = dims.contentWidth, h = dims.statusHeight,
    }, {
      size = theme.sizes.small * scale,
      color = statusColor,
      align = "center",
      id = "status",
    })
    y = y + dims.statusHeight + margin / 2
  end

  -- Preview (monospace text section with 5px padding)
  if self.preview and #self.preview > 0 and dims.previewHeight > 0 then
    local previewPadding = 5 * scale

    -- Truncate to max lines
    local lines = {}
    local count = 0
    for line in self.preview:gmatch("([^\n]*)") do
      count = count + 1
      if count > dims.previewMaxLines then
        -- Add ellipsis to last line
        if #lines > 0 then
          lines[#lines] = lines[#lines] .. "..."
        end
        break
      end
      table.insert(lines, line)
    end
    local truncatedText = table.concat(lines, "\n")

    local previewFont = (self.previewOpts and self.previewOpts.font) or "JetBrainsMono Nerd Font Mono"

    renderer.addText(canvas, truncatedText, {
      x = margin + previewPadding, y = y + previewPadding,
      w = dims.contentWidth - previewPadding * 2, h = dims.previewHeight,
    }, {
      size = theme.sizes.tiny * scale,
      font = previewFont,
      color = colors.subtitle,
      id = "preview",
    })
    y = y + dims.previewHeight + previewPadding * 2 + margin / 2
  end

  -- Cheat sheet
  if self.content then
    local keyColWidth = 24 * scale

    for i, kb in ipairs(self.content) do
      -- Dim unavailable bindings (50% opacity)
      local available = kb.available ~= false
      local keyColor = colors.accent
      local descColor = colors.subtitle
      if not available then
        keyColor = { red = keyColor.red, green = keyColor.green, blue = keyColor.blue, alpha = 0.5 }
        descColor = { red = descColor.red, green = descColor.green, blue = descColor.blue, alpha = 0.5 }
      end

      -- Key
      renderer.addText(canvas, kb.key, {
        x = margin, y = y,
        w = keyColWidth, h = dims.keyRowHeight,
      }, {
        size = theme.sizes.tiny * scale,
        font = theme.fonts.mono,
        color = keyColor,
      })

      -- Description
      renderer.addText(canvas, kb.desc, {
        x = margin + keyColWidth + 8 * scale, y = y,
        w = dims.contentWidth - keyColWidth - 8 * scale,
        h = dims.keyRowHeight,
      }, {
        size = theme.sizes.tiny * scale,
        color = descColor,
      })

      y = y + dims.keyRowHeight
    end
  end

  -- Click handling
  renderer.setupMouseCallbacks(canvas, {
    onElementClick = function(id, x, y)
      if id == "media" and self.mediaClickHandler then
        self.mediaClickHandler()
        return true
      end
      return false
    end,
    onClick = function()
      self:dismiss()
      return true
    end,
    onHover = self.hoverScale and function(id, isEnter)
      if id == "media" then
        self:_handleHover(isEnter)
      end
    end or nil,
  })

  return canvas
end

function Panel:_handleHover(isEnter)
  if not self.hoverScale or not self.canvas then return end

  -- Stop any existing hover animation first
  if self.timers.hover then
    animator.stop(self.timers.hover)
    self.timers.hover = nil
  end

  if isEnter and not self._isHovered then
    self._isHovered = true
    self._originalFrame = self.canvas:frame()
    self.timers.hover = animator.scaleUp(self.canvas, self.hoverScale, {
      duration = 150,
      onComplete = function() self.timers.hover = nil end,
    })
  elseif not isEnter and self._isHovered then
    self._isHovered = false
    if self._originalFrame then
      self.timers.hover = animator.scaleDown(self.canvas, self._originalFrame, {
        duration = 150,
        onComplete = function() self.timers.hover = nil end,
      })
    end
  end
end

function Panel:_updateCanvas()
  if self.visible and self.canvas then
    -- Stop any running animations
    if self.timers.hover then
      animator.stop(self.timers.hover)
      self.timers.hover = nil
    end
    if self.timers.resize then
      animator.stop(self.timers.resize)
      self.timers.resize = nil
    end

    local oldFrame = self.canvas:frame()

    -- Recalculate dimensions (content may have changed)
    self:_recalculateDimensions()

    -- Animate resize if size changed significantly
    self.timers.resize = animator.resizeFromEdge(self.canvas, self.width, self.height, {
      edge = "bottom",
      duration = 150,
      onComplete = function()
        self.timers.resize = nil
        -- Recreate canvas at final size for proper content rendering
        local finalFrame = self.canvas:frame()
        self.canvas:delete(0)
        self.canvas = self:_createCanvas({
          x = finalFrame.x, y = finalFrame.y,
          w = self.width, h = self.height,
        }, 1)
        self.canvas:show()
      end,
    })

    -- If no animation started (size unchanged), just recreate immediately
    if not self.timers.resize then
      local oldBottom = oldFrame.y + oldFrame.h
      local targetY = oldBottom - self.height
      self.canvas:delete(0)
      self.canvas = self:_createCanvas({
        x = oldFrame.x, y = targetY,
        w = self.width, h = self.height,
      }, 1)
      self.canvas:show()
    end
  end
end

--------------------------------------------------------------------------------
-- PERSISTENT TYPE
-- Stays visible until explicitly dismissed (indicators, etc.)
--------------------------------------------------------------------------------

local Persistent = setmetatable({}, { __index = BaseHUD })
Persistent.__index = Persistent

function Persistent:new(opts)
  opts = opts or {}
  opts.ephemeral = false
  opts.position = opts.position or "top-right"

  local hud = BaseHUD.new(self, opts)

  hud.content = opts.content or {}  -- { icon?, text?, color? }

  -- Calculate dimensions
  local hasIcon = hud.content.icon ~= nil
  local hasText = hud.content.text and hud.content.text ~= ""

  local iconSize = hasIcon and 24 or 0
  local textWidth = hasText and 100 or 0
  local padding = 12
  local spacing = (hasIcon and hasText) and 8 or 0

  hud.width = padding + iconSize + spacing + textWidth + padding
  hud.height = padding + math.max(iconSize, 20) + padding

  return hud
end

function Persistent:_createCanvas(frame, scale)
  local canvas = renderer.createCanvas(frame, {
    cornerRadius = 8,
  })
  local colors = theme.getColors()

  local padding = 12 * scale
  local x = padding
  local centerY = frame.h / 2

  -- Icon
  if self.content.icon then
    local iconSize = 24 * scale
    local iconColor = self.content.color
    if type(iconColor) == "string" then
      iconColor = colors[iconColor] or colors.accent
    end

    renderer.addImage(canvas, self.content.icon, {
      x = x, y = centerY - iconSize / 2,
      w = iconSize, h = iconSize,
    }, {
      id = "icon",
      trackMouse = true,
    })
    x = x + iconSize + 8 * scale
  end

  -- Text
  if self.content.text and self.content.text ~= "" then
    local textColor = self.content.textColor
    if type(textColor) == "string" then
      textColor = colors[textColor] or colors.title
    end

    renderer.addText(canvas, self.content.text, {
      x = x, y = centerY - 10 * scale,
      w = frame.w - x - padding, h = 20 * scale,
    }, {
      size = theme.sizes.small * scale,
      color = textColor or colors.title,
      id = "text",
      trackMouse = true,
    })
  end

  -- Click handling
  renderer.setupMouseCallbacks(canvas, {
    onClick = function()
      if self.onClick then
        self.onClick()
      else
        self:dismiss()
      end
      return true
    end,
  })

  return canvas
end

function Persistent:update(content)
  for k, v in pairs(content) do
    self.content[k] = v
  end

  if self.visible and self.canvas then
    -- Stop any running animation before rebuilding
    if self.timers.animation then
      animator.stop(self.timers.animation)
      self.timers.animation = nil
    end

    local pos = self.canvas:topLeft()
    local frame = self.canvas:frame()
    self.canvas:delete(0)

    local scale = position.getScaleFactor()
    self.canvas = self:_createCanvas({
      x = pos.x, y = pos.y,
      w = frame.w, h = frame.h,
    }, scale)
    self.canvas:show()
  end

  return self
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

M.Alert = Alert
M.Toast = Toast
M.Panel = Panel
M.Persistent = Persistent

return M
